;;; -*- Gerbil -*-
;;; Boundary: focused test and RSS performance commands for the CLI.

(import :gerbil/gambit
        :poo-flow/src/cli-support/support
        (only-in :std/srfi/1 filter-map fold take drop unfold)
        (only-in :std/srfi/13 string-prefix?))

(export poo-flow-cli-expand-test-args
        poo-flow-cli-read-unit-test-files
        poo-flow-cli-runnable-test-form?
        poo-flow-cli-policy-test-file
        poo-flow-cli-test-files-env-binding
        poo-flow-cli-test
        poo-flow-cli-perf)

;; : (-> Unit String)
(def (poo-flow-cli-unit-test-root)
  "t/unit-tests.ss")

;; : (-> Unit [String])
(def (poo-flow-cli-test-roots)
  '("t/unit-tests.ss"
    "t/contract-tests.ss"
    "t/integration-tests.ss"
    "t/performance-tests.ss"))

;; : (-> Object MaybeString)
(def (poo-flow-cli-unit-test-import->file spec)
  (and (symbol? spec)
       (let ((module-name (symbol->string spec))
             (prefix ":poo-flow/t/"))
         (and (string-prefix? prefix module-name)
              (string-append
               "t/"
               (substring module-name
                          (string-length prefix)
                          (string-length module-name))
               ".ss")))))

;;; Boundary: manifest imports are expanded only for root test aggregators.
;;; Native gxtest files remain leaves so policy checks follow the same files
;;; that the child gxtest process will execute.
;; : (-> [Object] [String])
(def (poo-flow-cli-unit-test-files-from-imports specs)
  (filter-map poo-flow-cli-unit-test-import->file specs))

;;; Boundary: native gxtest detection looks for test declarations without
;;; evaluating the form. This keeps import-only manifests from being executed
;;; as empty tests.
;; : (-> Object Boolean)
(def (poo-flow-cli-native-gxtest-form? form)
  (or (poo-flow-cli-form-contains-symbol? form 'test-suite)
      (poo-flow-cli-form-contains-symbol? form 'run-tests!)
      (poo-flow-cli-form-contains-symbol?
       form
       'define-poo-flow-module-system-live-case-test)))

;;; Boundary: native gxtest file detection reads forms until the first test
;;; marker. It never loads the module, so source expansion cannot trigger
;;; package side effects during test discovery.
;; poo-flow-cli-native-gxtest-file?
;;   : (-> String Boolean)
;;   | doc m%
;;       `poo-flow-cli-native-gxtest-file?` documents the CLI boundary that the
;;       Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-cli-native-gxtest-file? ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(def (poo-flow-cli-native-gxtest-file? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((poo-flow-cli-native-gxtest-form? form) #t)
                (else (loop)))))))))

;;; Boundary: manifest import reading consumes only the leading import form.
;;; Non-manifest files return no imports and stay as direct gxtest targets.
;; : (-> String [String])
(def (poo-flow-cli-read-test-file-imports file)
  (if (file-exists? file)
    (call-with-input-file file
      (lambda (port)
        (let (expr (read port))
          (if (and (pair? expr)
                   (eq? (car expr) 'import))
            (poo-flow-cli-unit-test-files-from-imports (cdr expr))
            []))))
    []))

;;; Boundary: manifest expansion follows import roots recursively but stops at
;;; native gxtest files. The seen set prevents cyclic manifests from expanding
;;; forever.
;; : (-> String [String] [String])
(def (poo-flow-cli-expand-test-manifest-file file seen)
  (if (member file seen)
    (list file)
    (let (imported (poo-flow-cli-read-test-file-imports file))
      (if (and (not (null? imported))
               (not (poo-flow-cli-native-gxtest-file? file)))
        (apply append
               (map (lambda (imported-file)
                      (poo-flow-cli-expand-test-manifest-file
                       imported-file
                       (cons file seen)))
                    imported))
        (list file)))))

;; : (-> String [String])
(def (poo-flow-cli-read-test-root-files root)
  (poo-flow-cli-expand-test-manifest-file root []))

;; : (-> Unit [String])
(def (poo-flow-cli-read-unit-test-files)
  (poo-flow-cli-read-test-root-files (poo-flow-cli-unit-test-root)))

;; : (-> String Boolean)
(def (poo-flow-cli-test-root? file)
  (member file (poo-flow-cli-test-roots)))

;;; Boundary: CLI test roots expand to leaf files before process launch.
;;; Explicit file lists are preserved so focused agent runs do not widen scope.
;; : (-> [String] [String])
(def (poo-flow-cli-expand-test-args args)
  (cond
   ((null? args) (poo-flow-cli-read-unit-test-files))
   ((and (null? (cdr args))
         (poo-flow-cli-test-root? (car args)))
    (poo-flow-cli-read-test-root-files (car args)))
   (else args)))

;;; Boundary: form symbol search is structural and read-only. It recognizes
;;; runnable test markers without invoking macros or loading imported modules.
;; : (-> Object Symbol Boolean)
(def (poo-flow-cli-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (poo-flow-cli-form-contains-symbol? (car form) symbol)
        (poo-flow-cli-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

;; : (-> Object Boolean)
(def (poo-flow-cli-runnable-test-form? form)
  (and (pair? form)
       (not (eq? (car form) 'import))
       (or (poo-flow-cli-form-contains-symbol? form 'test-suite)
           (poo-flow-cli-form-contains-symbol? form 'run-tests!)
           (poo-flow-cli-form-contains-symbol?
            form
            'define-poo-flow-module-system-live-case-test)
           (poo-flow-cli-form-contains-symbol?
            form
            'poo-flow-import-side-effect-test-suite?))))

;;; Intent: reject stale or side-effect-only files before launching gxtest.
;;; Boundary: reads the test form stream and stops at the first runnable form.
;; poo-flow-cli-runnable-test-file?
;;   : (-> String Boolean)
;;   | doc m%
;;       `poo-flow-cli-runnable-test-file?` documents the CLI boundary that the
;;       Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-cli-runnable-test-file? ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(def (poo-flow-cli-runnable-test-file? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((poo-flow-cli-runnable-test-form? form) #t)
                (else (loop)))))))))

;; : (-> String Integer)
(def (poo-flow-cli-reject-empty-test-file! file)
  (poo-flow-cli-error "poo-flow test: test file has no runnable test suite")
  (poo-flow-cli-error (string-append "file: " file))
  (poo-flow-cli-error "next: add test-suite/run-tests! or an explicit poo-flow-import-side-effect-test-suite? marker")
  65)

;;; Boundary: validation rejects empty import-only files before spawning gxtest.
;;; This keeps CLI failures local to the selected batch and avoids confusing
;;; downstream policy receipts.
;; : (-> [String] Integer)
(def (poo-flow-cli-validate-test-files files)
  (cond
   ((null? files) 0)
   ((poo-flow-cli-runnable-test-file? (car files))
    (poo-flow-cli-validate-test-files (cdr files)))
   (else
    (poo-flow-cli-reject-empty-test-file! (car files)))))

;; : String
(def +poo-flow-cli-test-files-env+
  "POO_FLOW_TEST_FILES")

;; : (-> Unit String)
(def (poo-flow-cli-policy-test-file)
  "t/poo-flow-policy-test.ss")

;;; Boundary: file scope is serialized as a Scheme datum because the static
;;; policy bridge reads it back inside the same gxtest process.
;; : (-> Datum String)
(def (poo-flow-cli-write-datum value)
  (call-with-output-string ""
    (lambda (port) (write value port))))

;; : (-> [String] String)
(def (poo-flow-cli-test-files-env-binding files)
  (string-append +poo-flow-cli-test-files-env+
                 "="
                 (poo-flow-cli-write-datum files)))

;; : (-> [String] [String])
(def (poo-flow-cli-test-argv files)
  (poo-flow-cli-gerbil-env-vars-argv
   [(poo-flow-cli-test-files-env-binding files)]
   "gxtest"
   (append files [(poo-flow-cli-policy-test-file)])))

;; : (-> Unit Integer)
(def (poo-flow-cli-default-test-batch-size)
  4)

;;; Sequential process batch size, not concurrency. Each batch runs in one
;;; gxtest child process; batches run one after another.
;; : (-> Unit Integer)
(def (poo-flow-cli-test-batch-size)
  (let (value (getenv "POO_FLOW_TEST_BATCH_SIZE" #f))
    (if value
      (let (size (string->number value))
        (if (and (integer? size)
                 (> size 0))
          size
          (poo-flow-cli-default-test-batch-size)))
      (poo-flow-cli-default-test-batch-size))))

;; : (-> [String] Boolean)
(def (poo-flow-cli-single-process-performance-root? args)
  (and (not (null? args))
       (null? (cdr args))
       (equal? (car args) "t/performance-tests.ss")))

;; : (-> [String] [String] Integer)
(def (poo-flow-cli-test-batch-size/args args files)
  (if (getenv "POO_FLOW_TEST_BATCH_SIZE" #f)
    (poo-flow-cli-test-batch-size)
    (if (poo-flow-cli-single-process-performance-root? args)
      (if (null? files) 1 (length files))
      (poo-flow-cli-default-test-batch-size))))

;; : (-> [String] Number Void)
(def (poo-flow-cli-display-test-receipt files elapsed)
  (display "[poo-flow-test] done ")
  (write files)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : (-> [String] Number Integer Void)
(def (poo-flow-cli-display-test-failure files elapsed status)
  (display "[poo-flow-test] fail ")
  (write files)
  (display " status=")
  (display status)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;;; Boundary: each batch owns exactly one child gxtest process. The receipt
;;; reports elapsed time and the selected files so CI failures can be mapped
;;; back to the scoped policy input.
;; : (-> [String] Integer)
(def (poo-flow-cli-test-batch files)
  (display "[poo-flow-test] start ")
  (write files)
  (newline)
  (force-output)
  (let* ((started-at (time->seconds (current-time)))
         (status (poo-flow-cli-run-inherited
                  (poo-flow-cli-test-argv files)))
         (elapsed (- (time->seconds (current-time)) started-at)))
    (if (= status 0)
      (poo-flow-cli-display-test-receipt files elapsed)
      (poo-flow-cli-display-test-failure files elapsed status))
    status))

;; : (-> [String] Integer Integer)
(def (poo-flow-cli-batch-width files batch-size)
  (min batch-size (length files)))

;; : (-> [String] Integer [String])
(def (poo-flow-cli-batch-head files batch-size)
  (take files (poo-flow-cli-batch-width files batch-size)))

;; : (-> [String] Integer [String])
(def (poo-flow-cli-batch-tail files batch-size)
  (drop files (poo-flow-cli-batch-width files batch-size)))

;;; Boundary: batching is a pure list partition. It changes process granularity
;;; without changing the set or order of files checked by policy.
;; : (-> [String] Integer [[String]])
(def (poo-flow-cli-test-batches files batch-size)
  (unfold null?
          (lambda (rest) (poo-flow-cli-batch-head rest batch-size))
          (lambda (rest) (poo-flow-cli-batch-tail rest batch-size))
          files))

;;; Intent: execute prevalidated test batches in order and keep first failure.
;;; Boundary: batch construction is pure; process execution stays in test-batch.
;; : (-> [String] Integer Integer)
(def (poo-flow-cli-test-files/batch-size files batch-size)
  (let (validation-status (poo-flow-cli-validate-test-files files))
    (if (= validation-status 0)
      (fold (lambda (batch status)
              (if (= status 0)
                (poo-flow-cli-test-batch batch)
                status))
            0
            (poo-flow-cli-test-batches
             files
             batch-size))
      validation-status)))

;; : (-> [String] Integer)
(def (poo-flow-cli-test-files files)
  (poo-flow-cli-test-files/batch-size files (poo-flow-cli-test-batch-size)))

;; : (-> [String] Integer)
(def (poo-flow-cli-test args)
  (let (files (poo-flow-cli-expand-test-args args))
    (poo-flow-cli-test-files/batch-size
     files
     (poo-flow-cli-test-batch-size/args args files))))

;; : (-> Unit [String])
(def (poo-flow-cli-perf-rss-time-argv)
  (cond-expand
   (darwin (list "/usr/bin/time" "-l"))
   (else (list "/usr/bin/time" "-v"))))

;; : (-> [String] [String])
(def (poo-flow-cli-perf-rss-argv files)
  (append (poo-flow-cli-perf-rss-time-argv)
          (poo-flow-cli-test-argv files)))

;; : (-> Integer Integer Number Void)
(def (poo-flow-cli-display-rss-receipt rss-bytes max-bytes elapsed)
  (display "[poo-flow-perf] rss=")
  (display rss-bytes)
  (display " max=")
  (display max-bytes)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : (-> String Integer)
(def (poo-flow-cli-reject-rss-parse! output)
  (poo-flow-cli-error "poo-flow perf rss: could not parse maximum resident set size")
  (poo-flow-cli-error "expected: time output with `maximum resident set size`")
  66)

;; : (-> Integer Integer Integer)
(def (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
  (poo-flow-cli-error "poo-flow perf rss: memory threshold exceeded")
  (poo-flow-cli-error (string-append "rss-bytes: " (object->string rss-bytes)))
  (poo-flow-cli-error (string-append "max-bytes: " (object->string max-bytes)))
  75)

;;; Boundary: RSS threshold decisions happen after the measured test process
;;; exits. The receipt is printed before failure so CI preserves the measured
;;; value.
;; : (-> Integer Integer Number Integer)
(def (poo-flow-cli-accept-or-reject-rss-threshold! rss-bytes max-bytes elapsed)
  (poo-flow-cli-display-rss-receipt rss-bytes max-bytes elapsed)
  (if (> rss-bytes max-bytes)
    (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
    0))

;;; Boundary: RSS parsing accepts the platform-specific `/usr/bin/time` output
;;; and compares bytes after a single normalization step.
;; : (-> Integer Number String Integer)
(def (poo-flow-cli-perf-rss-parse-output max-megabytes elapsed output)
  (let ((rss-bytes (poo-flow-cli-max-rss-bytes output))
        (max-bytes (poo-flow-cli-megabytes->bytes max-megabytes)))
    (if rss-bytes
      (poo-flow-cli-accept-or-reject-rss-threshold!
       rss-bytes
       max-bytes
       elapsed)
      (poo-flow-cli-reject-rss-parse! output))))

;;; Boundary: measured perf runs capture the child output so the RSS parser can
;;; inspect stderr while still replaying the output to the caller.
;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-measured-files max-megabytes files)
  (let* ((started-at (time->seconds (current-time)))
         (result (poo-flow-cli-run-captured
                  (poo-flow-cli-perf-rss-argv files)))
         (elapsed (- (time->seconds (current-time)) started-at))
         (status (car result))
         (output (cdr result)))
    (display output)
    (force-output)
    (if (= status 0)
      (poo-flow-cli-perf-rss-parse-output max-megabytes elapsed output)
      status)))

;;; Boundary: perf validation reuses the test-file gate before measurement so
;;; RSS failures are not mixed with empty-test-file errors.
;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-validated-files max-megabytes files)
  (let (validation-status (poo-flow-cli-validate-test-files files))
    (if (= validation-status 0)
      (poo-flow-cli-perf-rss-measured-files max-megabytes files)
      validation-status)))

;;; Boundary: RSS gates require `/usr/bin/time`; missing platform support is a
;;; command error, not a skipped performance assertion.
;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-files max-megabytes files)
  (if (file-exists? "/usr/bin/time")
    (poo-flow-cli-perf-rss-validated-files max-megabytes files)
    (begin
      (poo-flow-cli-error "poo-flow perf rss: /usr/bin/time is required for RSS gates")
      69)))

;;; Boundary: perf rss parses the threshold before expanding tests, keeping
;;; argument errors separate from test discovery and process execution.
;; : (-> [String] Integer)
(def (poo-flow-cli-perf-rss args)
  (match args
    (["--max-mb" max-megabytes . test-args]
     (let (max-value (string->number max-megabytes))
       (if (and (integer? max-value)
                (> max-value 0))
         (poo-flow-cli-perf-rss-files
          max-value
          (poo-flow-cli-expand-test-args test-args))
         (begin
           (poo-flow-cli-error "poo-flow perf rss: --max-mb must be a positive integer")
           64))))
    (_
     (poo-flow-cli-error "poo-flow perf rss: usage is `poo-flow perf rss --max-mb <megabytes> [test-file.ss...]`")
     64)))

;;; Boundary: perf dispatch is intentionally narrow; RSS is the only public
;;; measurement mode until another metric has a receipt contract.
;; : (-> [String] Integer)
(def (poo-flow-cli-perf args)
  (match args
    (["rss" . rest] (poo-flow-cli-perf-rss rest))
    (_
     (poo-flow-cli-error "poo-flow perf: usage is `poo-flow perf rss --max-mb <megabytes> [test-file.ss...]`")
     64)))
