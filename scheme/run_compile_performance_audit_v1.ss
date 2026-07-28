#!/usr/bin/env gxi

(import :gerbil/gambit
        :std/misc/process
        :std/srfi/13
        :std/text/json)

(export main)

(def +comparison-input-schema+
  "poo-flow.ci.scheme-compile-performance-comparison-input.v1")

(def +audit-receipt-schema+
  "poo-flow.ci.scheme-compile-performance-audit.v1")

(def +warm-receipt-schema+
  "poo-flow.ci.scheme-compile-warm-noop.v1")

(def +host-admission-schema+
  "poo-flow.ci.scheme-compile-performance-host-admission.v1")

(def (json-object entries)
  (let (object (make-hash-table))
    (for-each
     (lambda (entry)
       (hash-put! object (car entry) (cdr entry)))
     entries)
    object))

(def (required-key object key)
  (unless (and (hash-table? object) (hash-key? object key))
    (error "required JSON field is absent" key))
  (hash-ref object key))

(def (write-json-file! path object)
  (call-with-output-file
   path
   (lambda (port)
     (parameterize ((write-json-sort-keys? #t))
       (display (json-object->string object) port))
     (newline port))))

(def (read-json-file path)
  (call-with-input-file path read-json))

(def (read-first-line path)
  (call-with-input-file
   path
   (lambda (port)
     (let (line (read-line port))
       (if (eof-object? line)
         (error "expected command output" path)
         (string-trim-both line))))))

(def (path-join left right)
  (cond
   ((string=? left "") right)
   ((string-suffix? "/" left) (string-append left right))
   (else (string-append left "/" right))))

(def (sample-root output-directory side sample-index)
  (path-join
   output-directory
   (string-append side "-" (number->string sample-index))))

(def (run-command! directory argv)
  (run-process/batch
   argv
   directory: directory
   check-status:
   (lambda (exit-status _settings)
     (unless (zero? exit-status)
       (error "command failed" exit-status argv)))))

(def (sample-host-admission!
      gxi
      resource-guard
      directory
      side
      sample-index
      revision
      runner
      host-session-id
      failure-context-path)
  (let* ((guard-receipt-path
          (path-join directory "resource-guard.receipt.json"))
         (admission-receipt-path
          (path-join directory "host-admission.json"))
         (label
          (string-append
           "compile-performance/"
           side
           "-"
           (number->string sample-index))))
    (run-command!
     directory
     (list gxi resource-guard guard-receipt-path label "0" "true"))
    (let* ((guard-receipt (read-json-file guard-receipt-path))
           (logical-cpu-count
            (required-key guard-receipt "logicalCpuCount"))
           (runnable-process-count
            (required-key guard-receipt "runnableProcessCount"))
           (runnable-process-count-available
            (required-key
             guard-receipt
             "runnableProcessCountAvailable"))
           (guard-admission-outcome
            (required-key guard-receipt "admissionOutcome"))
           (reasons
            (append
             (if (string=? guard-admission-outcome "ready")
               '()
               '("resource-guard-blocked"))
             (if runnable-process-count-available
               '()
               '("runnable-process-observation-unavailable"))
             (if (and runnable-process-count-available
                      (> runnable-process-count logical-cpu-count))
               '("runnable-pressure-exceeds-logical-capacity")
               '())))
           (outcome
            (if (null? reasons) "ready" "blocked-host-pressure"))
           (admission-receipt
            (json-object
             (list
              (cons "schema" +host-admission-schema+)
              (cons "side" side)
              (cons "sampleIndex" sample-index)
              (cons "revision" revision)
              (cons "runner" runner)
              (cons "hostSessionId" host-session-id)
              (cons "outcome" outcome)
              (cons "policy"
                    "runnable-at-or-below-logical-cpu-capacity")
              (cons "logicalCpuCount" logical-cpu-count)
              (cons "runnableProcessCount" runnable-process-count)
              (cons "runnableProcessCountAvailable"
                    runnable-process-count-available)
              (cons "guardAdmissionOutcome" guard-admission-outcome)
              (cons "guardAdmissionAdvisories"
                    (required-key
                     guard-receipt
                     "admissionAdvisories"))
              (cons "guardAdmissionReasons"
                    (required-key guard-receipt "admissionReasons"))
              (cons "reasons" reasons)
              (cons "resourceGuardReceipt" guard-receipt-path)))))
      (write-json-file! admission-receipt-path admission-receipt)
      (unless (string=? outcome "ready")
        (write-json-file!
         failure-context-path
         (json-object
          (list
           (cons "schema"
                 "gerbil-bazel.compile-performance-sample-failure.v1")
           (cons "phase" "host-admission")
           (cons "side" side)
           (cons "sampleIndex" sample-index)
           (cons "revision" revision)
           (cons "runner" runner)
           (cons "hostSessionId" host-session-id)
           (cons "terminalReceiptObserved" #f)
           (cons "hostAdmission" admission-receipt-path)
           (cons "reasons" reasons))))
        (error
         "cold compile sample blocked by host pressure"
         failure-context-path))
      admission-receipt)))

(def (run-command/capture! directory argv output-path)
  (let (output
        (run-process
         argv
         directory: directory
         stderr-redirection: #f
         check-status:
         (lambda (exit-status _settings)
           (unless (zero? exit-status)
             (error "command failed" exit-status argv)))))
    (call-with-output-file
     output-path
     (lambda (port)
       (display output port)))
    (read-first-line output-path)))

(def (run-command/capture-status! directory argv output-path)
  (let (exit-status #f)
    (let (output
          (run-process
           argv
           directory: directory
           stdout-redirection: #t
           stderr-redirection: #t
           check-status:
           (lambda (status _settings)
             (set! exit-status status))))
      (display output)
      (call-with-output-file
       output-path
       (lambda (port)
         (display output port)))
      (values exit-status output))))

(def +project-build-receipt-prefix+
  "POO_FLOW_PROJECT_BUILD_RECEIPT ")

(def (prefixed-output-line output prefix)
  (let loop ((lines (string-split output #\newline)))
    (cond
     ((null? lines) #f)
     ((string-prefix? prefix (car lines)) (car lines))
     (else (loop (cdr lines))))))

(def (project-build-receipt-from-output output)
  (let (line
        (prefixed-output-line
         output
         +project-build-receipt-prefix+))
    (and line
         (string->json-object
          (substring
           line
           (string-length +project-build-receipt-prefix+)
           (string-length line))))))

(def (ensure-directory! path)
  (run-command! "/" (list "mkdir" "-p" path)))

(def (canonical-directory! path)
  (ensure-directory! path)
  (let (canonical
        (parameterize ((current-directory path))
          (current-directory)))
    (if (and (> (string-length canonical) 1)
             (string-suffix? "/" canonical))
      (substring canonical 0 (- (string-length canonical) 1))
      canonical)))

(def (bazel-startup-arguments bazel output-base)
  (list bazel
        (string-append "--output_base=" output-base)))

(def (bazel-command bazel output-base command arguments)
  (append (bazel-startup-arguments bazel output-base)
          (list command "--lockfile_mode=off")
          arguments))

(def (shutdown-audit-server! bazel workspace output-base)
  (with-catch
   (lambda (_exception) #f)
   (lambda ()
     (run-command!
      workspace
      (append
       (bazel-startup-arguments bazel output-base)
       (list "shutdown")))
     #t)))

(def (call-with-audit-servers
      bazel baseline-workspace candidate-workspace output-directory thunk)
  (let ((baseline-output-base
         (path-join output-directory "baseline-output-base"))
        (candidate-output-base
         (path-join output-directory "candidate-output-base"))
        (lifecycle-receipt-path
         (path-join output-directory "server-lifecycle.json")))
    (write-json-file!
     lifecycle-receipt-path
     (json-object
      (list
       (cons "schema"
             "gerbil-bazel.audit-server-lifecycle.v1")
       (cons "strategy" "explicit-shutdown")
       (cons "state" "armed")
       (cons "cleanupTrigger" "dynamic-wind")
       (cons "baselineOutputBase" baseline-output-base)
       (cons "candidateOutputBase" candidate-output-base))))
    (let ((failure #f)
          (result #f))
      ;; Catch inside the dynamic extent so an uncaught top-level exception
      ;; cannot terminate the runtime before the after thunk closes both
      ;; Bazel servers. Re-raise only after cleanup has completed.
      (set! result
        (dynamic-wind
          (lambda () #!void)
          (lambda ()
            (with-catch
             (lambda (exception)
               (set! failure exception)
               #f)
             thunk))
          (lambda ()
            (shutdown-audit-server!
             bazel baseline-workspace baseline-output-base)
            (shutdown-audit-server!
             bazel candidate-workspace candidate-output-base))))
      (if failure
        (raise failure)
        result))))

(def (seed-dependencies!
      bazel workspace output-base dependency-cache symlink-prefix)
  (run-command!
   workspace
   (bazel-command
    bazel
    output-base
    "build"
    (list
     (string-append "--disk_cache=" dependency-cache)
     (string-append "--symlink_prefix=" symlink-prefix)
     "//scheme:dependency_packages"))))

(def (clean-sample-output! bazel workspace output-base)
  (run-command!
   workspace
   (bazel-command bazel output-base "clean" '())))

(def (build-native-abi!
      bazel workspace output-base dependency-cache symlink-prefix)
  (run-command!
   workspace
   (bazel-command
    bazel
    output-base
    "build"
    (list
     (string-append "--disk_cache=" dependency-cache)
     (string-append "--symlink_prefix=" symlink-prefix)
     "@local_gerbil//:native_abi.txt"))))

(def (read-native-abi
      bazel workspace output-base sample-directory)
  (let* ((query-output (path-join sample-directory "native-abi.path"))
         (exec-root-output (path-join sample-directory "execution-root.path"))
         (relative-path
          (run-command/capture!
           workspace
           (bazel-command
            bazel
            output-base
            "cquery"
            (list "@local_gerbil//:native_abi.txt" "--output=files"))
           query-output))
         (execution-root
          (run-command/capture!
           workspace
           (bazel-command bazel output-base "info" (list "execution_root"))
           exec-root-output)))
    (read-first-line (path-join execution-root relative-path))))

(def (build-cold-receipt!
      bazel workspace output-base root-cache symlink-prefix build-log-path)
  (run-command/capture-status!
   workspace
   (bazel-command
    bazel
    output-base
    "build"
    (list
     (string-append "--disk_cache=" root-cache)
     (string-append "--symlink_prefix=" symlink-prefix)
     "//scheme:compile_receipt"))
   build-log-path))

(def (toolchain-identity native-abi dependency-resolutions)
  (parameterize ((write-json-sort-keys? #t))
    (json-object->string
     (json-object
      (list
       (cons "nativeAbi" native-abi)
       (cons "dependencySourceResolutions" dependency-resolutions))))))

(def (receipt->observation
      receipt revision runner host-session-id native-abi)
  (let* ((build-receipt (required-key receipt "buildReceipt"))
         (source-identity (required-key build-receipt "source-identity"))
         (dependency-resolutions
          (required-key receipt "dependencySourceResolutions")))
    (json-object
     (list
      (cons "revision" revision)
      (cons "runner" runner)
      (cons "hostSessionId" host-session-id)
      (cons "toolchainIdentity"
            (toolchain-identity native-abi dependency-resolutions))
      (cons "sourceDigest" (required-key source-identity "digest"))
      (cons "executionPolicy"
            (required-key build-receipt "execution-policy"))
      (cons "logicalCpuCount"
            (required-key build-receipt "logical-cpu-count"))
      (cons "workerCount" (required-key build-receipt "worker-count"))
      (cons "specCount" (required-key source-identity "spec-count"))
      (cons "coldnessClass" "isolated-runtime-action-cold")
      (cons "dependencyCacheState" "dependency-actions-seeded")
      (cons "elapsedMs" (required-key build-receipt "elapsed-ms"))))))

(def (run-cold-sample!
      gxi
      resource-guard
      bazel
      workspace
      revision
      runner
      host-session-id
      output-directory
      dependency-cache
      side
      sample-index)
  (let* ((directory (sample-root output-directory side sample-index))
         (output-base
          (path-join output-directory (string-append side "-output-base")))
         (root-cache (path-join directory "root-cache"))
         (symlink-prefix (path-join directory "bazel-"))
         (receipt-path
          (path-join directory "bazel-bin/scheme/compile.receipt.json"))
         (observed-receipt-path
          (path-join directory "compile.receipt.json"))
         (build-log-path
          (path-join directory "build.log"))
         (failure-context-path
          (path-join directory "failure.context.json")))
    (ensure-directory! directory)
    (ensure-directory! output-base)
    (ensure-directory! root-cache)
    (sample-host-admission!
     gxi
     resource-guard
     directory
     side
     sample-index
     revision
     runner
     host-session-id
     failure-context-path)
    (clean-sample-output! bazel workspace output-base)
    (seed-dependencies!
     bazel workspace output-base dependency-cache symlink-prefix)
    (build-native-abi!
     bazel workspace output-base dependency-cache symlink-prefix)
    (let (native-abi
          (read-native-abi bazel workspace output-base directory))
      (let-values
          (((command-status command-output)
            (build-cold-receipt!
             bazel
             workspace
             output-base
             root-cache
             symlink-prefix
             build-log-path)))
        (unless (zero? command-status)
          (let (failed-receipt
                (project-build-receipt-from-output command-output))
            (when failed-receipt
              (write-json-file! observed-receipt-path failed-receipt))
            (write-json-file!
             failure-context-path
             (json-object
              (list
               (cons "schema"
                     "gerbil-bazel.compile-performance-sample-failure.v1")
               (cons "side" side)
               (cons "sampleIndex" sample-index)
               (cons "revision" revision)
               (cons "runner" runner)
               (cons "hostSessionId" host-session-id)
               (cons "rawProcessStatus" command-status)
               (cons "terminalReceiptObserved"
                     (and failed-receipt #t))
               (cons "receiptPath" observed-receipt-path)
               (cons "buildLog" build-log-path))))
            (error
             "cold compile sample failed"
             command-status
             failure-context-path)))
        (let (receipt (read-json-file receipt-path))
          (write-json-file! observed-receipt-path receipt)
          (values
           (receipt->observation
            receipt
            revision
            runner
            host-session-id
            native-abi)
           (json-object
            (list
             (cons "workspace" workspace)
             (cons "outputBase" output-base)
             (cons "rootCache" root-cache)
             (cons "symlinkPrefix" symlink-prefix)
             (cons "receiptPath" observed-receipt-path)))))))))

(def (warm-action-count path)
  (call-with-input-file
   path
   (lambda (port)
     (let loop ((count 0))
       (let (line (read-line port))
         (if (eof-object? line)
           count
           (let* ((event (call-with-input-string line read-json))
                  (event-id
                   (and (hash-table? event)
                        (hash-key? event "id")
                        (hash-ref event "id"))))
             (loop
              (if (and (hash-table? event-id)
                       (hash-key? event-id "actionCompleted"))
                (+ count 1)
                count)))))))))

(def (run-warm-noop!
      bazel candidate-workspace candidate-revision output-directory context)
  (let* ((output-base (required-key context "outputBase"))
         (root-cache (required-key context "rootCache"))
         (symlink-prefix (required-key context "symlinkPrefix"))
         (bep-path (path-join output-directory "warm-noop.bep.json")))
    (run-command!
     candidate-workspace
     (bazel-command
      bazel
      output-base
      "build"
      (list
       (string-append "--disk_cache=" root-cache)
       (string-append "--symlink_prefix=" symlink-prefix)
       (string-append "--build_event_json_file=" bep-path)
       "//scheme:compile_receipt")))
    (let (action-count (warm-action-count bep-path))
      (unless (zero? action-count)
        (error "warm/no-op replay executed actions" action-count))
      (json-object
       (list
        (cons "schema" +warm-receipt-schema+)
        (cons "revision" candidate-revision)
        (cons "target" "//scheme:compile_receipt")
        (cons "actionCount" action-count)
        (cons "outcome" "no-op"))))))

(def (positive-odd-sample-count value)
  (let (count (string->number value))
    (unless (and (exact-integer? count)
                 (>= count 3)
                 (odd? count))
      (error "sample count must be an odd integer >= 3" value))
    count))

(def (nonnegative-basis-points value)
  (let (basis-points (string->number value))
    (unless (and (exact-integer? basis-points)
                 (>= basis-points 0))
      (error "maximum regression basis points must be nonnegative" value))
    basis-points))

(def (main
      gxi
      resource-guard
      bazel
      baseline-workspace
      candidate-workspace
      baseline-revision
      candidate-revision
      host-session-id
      runner
      output-directory
      sample-count-text
      maximum-regression-basis-points-text)
  (let* ((sample-count (positive-odd-sample-count sample-count-text))
         (maximum-regression-basis-points
          (nonnegative-basis-points
           maximum-regression-basis-points-text))
         (output-directory
          (canonical-directory! output-directory))
         (dependency-cache
          (path-join output-directory "dependency-cache")))
    (ensure-directory! output-directory)
    (ensure-directory! dependency-cache)
    (call-with-audit-servers
     bazel
     baseline-workspace
     candidate-workspace
     output-directory
     (lambda ()
      (let loop ((sample-index 1)
                 (baseline-observations [])
                 (candidate-observations [])
                 (last-candidate-context #f))
      (if (> sample-index sample-count)
        (let* ((ordered-baseline (reverse baseline-observations))
               (ordered-candidate (reverse candidate-observations))
               (comparison-input
                (json-object
                 (list
                  (cons "schema" +comparison-input-schema+)
                  (cons "maximumRegressionBasisPoints"
                        maximum-regression-basis-points)
                  (cons "baselineObservations" ordered-baseline)
                  (cons "candidateObservations" ordered-candidate))))
               (comparison-input-path
                (path-join output-directory "comparison-input.json"))
               (warm-receipt
                (run-warm-noop!
                 bazel
                 candidate-workspace
                 candidate-revision
                 output-directory
                 last-candidate-context))
               (warm-receipt-path
                (path-join output-directory "warm-noop-receipt.json"))
               (audit-receipt-path
                (path-join output-directory "audit-receipt.json")))
          (write-json-file! comparison-input-path comparison-input)
          (write-json-file! warm-receipt-path warm-receipt)
          (write-json-file!
           audit-receipt-path
           (json-object
            (list
             (cons "schema" +audit-receipt-schema+)
             (cons "baselineRevision" baseline-revision)
             (cons "candidateRevision" candidate-revision)
                         (cons "hostSessionId" host-session-id)
                         (cons "runner" runner)
                         (cons "outputDirectory" output-directory)
                         (cons "sampleCount" sample-count)
             (cons "comparisonInput" comparison-input-path)
             (cons "warmNoopReceipt" warm-receipt-path)
             (cons "outcome" "observed"))))
          (display audit-receipt-path)
          (newline))
        (let-values
            (((baseline-observation _baseline-context)
              (run-cold-sample!
               gxi
               resource-guard
               bazel
               baseline-workspace
               baseline-revision
               runner
               host-session-id
               output-directory
               dependency-cache
               "baseline"
               sample-index))
             ((candidate-observation candidate-context)
              (run-cold-sample!
               gxi
               resource-guard
               bazel
               candidate-workspace
               candidate-revision
               runner
               host-session-id
               output-directory
               dependency-cache
               "candidate"
               sample-index)))
          (loop
           (+ sample-index 1)
           (cons baseline-observation baseline-observations)
           (cons candidate-observation candidate-observations)
           candidate-context))))))))
