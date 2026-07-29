(import (only-in :gslph/src/building/facade make-package-source-stage)
        :std/test
        :clan/poo/object
        (only-in :gerbil/gambit getenv setenv)
        (only-in :std/text/json
                 json-object->string
                 string->json-object
                 write-json-sort-keys?)
        "../src/build-api/project-compile-guard.ss")

(import (only-in :gslph/src/building/std-builder
                 make-adaptive-execution-window-result
                 make-execution-window-observation))

(export build-api-project-compile-guard-test)

(def (build-api-project-compile-guard-available-cpu-count)
  (max 1 (##cpu-count)))

(def (make-project-compile-guard-test-controller)
  (letrec
      ((controller
        (object<-alist
         `((kind . gslph.execution-window-controller.v1)
           (worker-count . 2)
           (hard-max-rss-bytes . 4096)
           (headroom-bytes . 0)
           (window-size . 2)
           (.observe-run! .
            ,(lambda (_label thunk)
               (make-execution-window-observation
                (thunk) 'completed 0 0 4096 0)))
           (.next-state .
            ,(lambda (_observation _spec-count)
               controller))))))
    controller))

(def build-api-project-compile-guard-test
  (test-suite "POO project compile guard"
    (test-case "delegates one standard project to Building Framework"
      (poo-flow/src/cli-support/project-build#poo-flow-project-configure-build-root!
       (current-directory))
      (def config (poo-flow-project-compile-guard-config '()))
      (check (.ref config 'schema)
             => 'poo-flow.project-compile-guard.v1)
      (check (.ref config 'build-owner)
             => 'gslph-building-framework)
      (check (.ref config 'build-mode)
             => 'standard-gerbil-make-project)
      (check (.ref config 'execution-policy)
             => 'topology)
      (check (>= (.ref config 'worker-count) 1) => #t)
      (check (> (.ref config 'system-memory-bytes) 0) => #t)
      (check (> (.ref config 'available-memory-bytes) 0) => #t)
      (check (.ref config 'request-labels)
             => '("nono-c-ffi" "runtime" "user-interface")))
    (test-case "source identity is deterministic for one materialized build graph"
      (let* ((stages
              (list
               (make-package-source-stage
                "source-identity-fixture"
                (current-directory)
                "poo-flow"
                '("src/cli-support/project-build.ss"
                  "src/build-api/project-compile-guard.ss")
                'topology)))
             (left
              (poo-flow/src/cli-support/project-build#poo-flow-project-build-source-identity
               stages))
             (right
              (poo-flow/src/cli-support/project-build#poo-flow-project-build-source-identity
               stages)))
        (check (.ref left 'digest) => (.ref right 'digest))
        (check (.ref left 'stage-count) => 1)
        (check (.ref left 'spec-count) => 2)
        (check (.ref left 'spec-count) => (.ref right 'spec-count))))
    (test-case "derives the RSS ceiling from live allocatable memory"
      (check
       (poo-flow/src/build-api/project-compile-guard#poo-flow-project-compile-adaptive-max-rss-bytes
        (* 1 1024 1024 1024)
        (* 3 1024 1024 1024))
       => (* 4 1024 1024 1024))
      (check
       (poo-flow/src/build-api/project-compile-guard#poo-flow-project-compile-adaptive-max-rss-bytes
        (* 1 1024 1024 1024)
        (* 10 1024 1024 1024))
       => (* 5 1024 1024 1024)))
    (test-case "does not let an explicit request exceed the project RSS ceiling"
      (let* ((overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "17179869184")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "12884901888")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "1073741824")
               (cons "POO_FLOW_BUILD_BASELINE_RSS_BYTES" "1073741824")
               (cons "POO_FLOW_BUILD_MAX_RSS_BYTES" "12884901888")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT" "4")
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES" "1")
               (cons "GERBIL_BUILD_CORES" "4")))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'admission-outcome) => 'ready)
              (check (.ref config 'requested-max-rss-bytes) => 5368709120)
              (check (.ref config 'max-rss-bytes) => 5368709120)
              (check (.ref config 'configured-worker-count) => 4)
              (check (.ref config 'worker-count) => 4)))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "translates host allocation into an absolute RSS cap"
      (let* ((overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "8589934592")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "3758096384")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "2147483648")
               (cons "POO_FLOW_BUILD_BASELINE_RSS_BYTES" "1073741824")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT" "12")
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES" "1")
               (cons "GERBIL_BUILD_CORES" "12")))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'admission-outcome) => 'ready)
              (check (.ref config 'baseline-rss-bytes) => 1073741824)
              (check (.ref config 'allocatable-memory-bytes) => 1610612736)
              (check (.ref config 'requested-max-rss-bytes) => 2684354560)
              (check (.ref config 'admitted-memory-bytes) => 1610612736)
              (check (.ref config 'max-rss-bytes) => 2684354560)
              (check (.ref config 'configured-worker-count) => 12)
              (check (.ref config 'memory-per-worker-bytes) => 805306368)
              (check (.ref config 'memory-worker-capacity) => 2)
              (check (.ref config 'worker-count) => 2)))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "reduces workers from the observed machine memory envelope"
      (let* ((overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "17179869184")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "3758096384")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "1073741824")
               (cons "POO_FLOW_BUILD_BASELINE_RSS_BYTES" "805306368")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT" "4")
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES" "1")
               (cons "GERBIL_BUILD_CORES" "4")))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'configured-worker-count) => 4)
              (check (.ref config 'memory-per-worker-bytes) => 805306368)
              (check (.ref config 'memory-worker-capacity) => 3)
              (check (.ref config 'worker-count) => 3)))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "blocks a requested RSS cap that cannot cover baseline plus floor"
      (let* ((overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "8589934592")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "6442450944")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "2147483648")
               (cons "POO_FLOW_BUILD_BASELINE_RSS_BYTES" "1073741824")
               (cons "POO_FLOW_BUILD_MAX_RSS_BYTES" "1879048191")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT" "12")
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES" "1")
               (cons "GERBIL_BUILD_CORES" "12")))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'admission-outcome)
                     => 'blocked-host-pressure)
              (check (.ref config 'admission-reasons)
                     => '(insufficient-requested-rss-cap))
              (check (.ref config 'requested-max-rss-bytes) => 1879048191)
              (check (.ref config 'admitted-memory-bytes) => 805306367)
              (check (.ref config 'max-rss-bytes) => 1879048191)
              (check (.ref config 'memory-worker-capacity) => 1)
              (check (.ref config 'worker-count) => 1)))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "does not impose a machine-independent timeout"
      (check
       (poo-flow/src/build-api/project-compile-guard#poo-flow-project-compile-optional-timeout-from-env
       "POO_FLOW_TEST_UNSET_BUILD_TIMEOUT")
       => #f))
    (test-case "RSS guard does not implicitly rewrite the compile graph"
      (let ((previous-cap
             (getenv "POO_FLOW_BUILD_MAX_RSS_BYTES" #f))
            (previous-policy
             (getenv "POO_FLOW_BUILD_EXECUTION_POLICY" #f)))
        (dynamic-wind
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" "4294967296")
            (setenv "POO_FLOW_BUILD_EXECUTION_POLICY" ""))
          (lambda ()
            (check
             (.ref (poo-flow-project-compile-guard-config '())
                   'execution-policy)
             => 'topology)
            (check
             (poo-flow/src/cli-support/project-build#poo-flow-project-adaptive-controller-from-env)
             => #f))
           (lambda ()
             (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES"
                     (or previous-cap ""))
             (setenv "POO_FLOW_BUILD_EXECUTION_POLICY"
                    (or previous-policy ""))))))
    (test-case "adaptive windows require an explicit policy"
      (let ((previous-cap
             (getenv "POO_FLOW_BUILD_MAX_RSS_BYTES" #f))
            (previous-policy
             (getenv "POO_FLOW_BUILD_EXECUTION_POLICY" #f)))
        (dynamic-wind
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" "4294967296")
            (setenv "POO_FLOW_BUILD_EXECUTION_POLICY"
                    "adaptive-window"))
          (lambda ()
            (check
             (.ref (poo-flow-project-compile-guard-config '())
                   'execution-policy)
             => 'adaptive-window)
            (check
             (poo-flow/src/cli-support/project-build#poo-flow-project-build-execution-policy)
             => 'adaptive-window))
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES"
                    (or previous-cap ""))
             (setenv "POO_FLOW_BUILD_EXECUTION_POLICY"
                     (or previous-policy ""))))))
     (test-case "keeps runnable saturation advisory without rewriting worker count"
      (let* ((available-cpu-count
              (build-api-project-compile-guard-available-cpu-count))
             (saturated-runnable-count
              (+ (* available-cpu-count 2) 1))
             (overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "8589934592")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "6442450944")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "2147483648")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT"
                     (number->string available-cpu-count))
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES"
                     (number->string saturated-runnable-count))
               (cons "GERBIL_BUILD_CORES"
                     (number->string available-cpu-count))))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'admission-outcome) => 'ready)
              (check (.ref config 'admission-advisories)
                     => '(runnable-saturation))
              (check (.ref config 'admission-reasons) => '())
              (check (.ref config 'configured-worker-count)
                     => available-cpu-count)
              (check (.ref config 'worker-count)
                     => (min available-cpu-count
                             (.ref config 'memory-worker-capacity)))))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "blocks only when the memory safety floor cannot be admitted"
      (let* ((available-cpu-count
              (build-api-project-compile-guard-available-cpu-count))
             (overrides
              (list
               (cons "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" "8589934592")
               (cons "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" "2147483648")
               (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "2147483648")
               (cons "POO_FLOW_BUILD_LOGICAL_CPU_COUNT"
                     (number->string available-cpu-count))
               (cons "POO_FLOW_BUILD_RUNNABLE_PROCESSES"
                     (number->string available-cpu-count))
               (cons "GERBIL_BUILD_CORES"
                     (number->string available-cpu-count))))
             (previous
              (map (lambda (entry)
                     (cons (car entry) (getenv (car entry) #f)))
                   overrides)))
        (dynamic-wind
          (lambda ()
            (for-each
             (lambda (entry) (setenv (car entry) (cdr entry)))
             overrides))
          (lambda ()
            (let (config (poo-flow-project-compile-guard-config '()))
              (check (.ref config 'admission-outcome)
                     => 'blocked-host-pressure)
              (check (.ref config 'admission-advisories) => '())
              (check (.ref config 'admission-reasons)
                     => '(insufficient-memory-headroom))
              (check (.ref config 'worker-count)
                     => 1)))
          (lambda ()
            (for-each
             (lambda (entry)
               (setenv (car entry) (or (cdr entry) "")))
             previous)))))
    (test-case "emits a canonical native Scheme JSON receipt"
      (let* ((available-cpu-count
              (build-api-project-compile-guard-available-cpu-count))
             (receipt
             (.o (schema 'poo-flow.project-compile-guard.v1)
                  (outcome 'completed)
                  (failure-kind #f)
                  (failure-exit-code #f)
                  (build-owner 'gslph-building-framework)
                  (build-mode 'standard-gerbil-make-project)
                  (execution-policy 'topology)
                  (request-labels '("runtime" "user-interface"))
                  (source-identity
                   (.o
                    (schema 'poo-flow.project-build-source-identity.v1)
                    (algorithm 'sha256)
                    (digest
                     "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
                    (stage-count 2)
                    (spec-count 387)
                    (stages
                     (list
                      (.o (label "runtime") (spec-count 379))
                      (.o (label "user-interface") (spec-count 8))))))
                  (source-identity-materialization-elapsed-ms 7)
                  (admission-outcome 'ready)
                  (admission-advisories '())
                  (admission-reasons '())
                  (logical-cpu-count available-cpu-count)
                  (runnable-process-count 4)
                  (available-memory-bytes 25769803776)
                  (rss-headroom-bytes 2147483648)
                  (baseline-rss-bytes 536870912)
                  (allocatable-memory-bytes 23622320128)
                  (requested-max-rss-bytes 5368709120)
                  (admitted-memory-bytes 4831838208)
                  (configured-worker-count available-cpu-count)
                  (memory-per-worker-bytes 805306368)
                  (memory-worker-capacity 6)
                  (runnable-worker-capacity available-cpu-count)
                  (worker-count (min available-cpu-count 6))
                  (system-memory-bytes 34359738368)
                  (max-rss-bytes 5368709120)
                  (peak-rss-bytes 2460680192)
                  (elapsed-ms 199289)
                  (timeout-ms 540000)
                  (build
                   `((version . 1)
                     (stage-count . 3)
                     (compiled . 1)
                     (skipped . 2)
                     (elapsed-jiffies . 3482)
                     (active-stages
                      . (((label . "runtime")
                          (kind . std/make)
                          (status . compiled)
                          (description . "runtime stage")
                  (result . ,(make-adaptive-execution-window-result
                              '(("fast-a.ss" "fast-b.ss")
                                ("slow-a.ss" "slow-b.ss")
                                ("middle.ss"))
                              '(("fast-a.ss" "fast-b.ss")
                                ("slow-a.ss" "slow-b.ss")
                                ("middle.ss"))
                              (list
                               (make-execution-window-observation
                                'fast 'completed 512 768 4096 3)
                               (make-execution-window-observation
                                'slow 'completed 512 2048 4096 12)
                               (make-execution-window-observation
                                'middle 'completed 512 1024 4096 7))
                              (make-project-compile-guard-test-controller)))
                          (elapsed-jiffies . 3400))))))))
             (json-string
              (poo-flow-project-compile-receipt->json-string receipt))
             (object (string->json-object json-string)))
        (check (hash-get object "schema")
               => "poo-flow.project-compile-guard.v1")
        (check (hash-get object "kind")
               => "poo-flow.project-compile-guard.v1")
        (check (hash-get object "version") => 1)
        (check (hash-get object "elapsed-ms") => 199289)
        (check (hash-get object "execution-policy") => "topology")
        (check (hash-get object "failure-kind") => #f)
        (check (hash-get object "failure-exit-code") => #f)
        (let (source-identity (hash-get object "source-identity"))
          (check (hash-get source-identity "algorithm") => "sha256")
          (check (hash-get source-identity "spec-count") => 387))
        (check
         (hash-get object "source-identity-materialization-elapsed-ms")
         => 7)
        (check (hash-get object "admission-outcome") => "ready")
        (check (hash-get object "admission-advisories") => '())
        (check (hash-get object "baseline-rss-bytes") => 536870912)
        (check (hash-get object "allocatable-memory-bytes") => 23622320128)
        (check (hash-get object "requested-max-rss-bytes") => 5368709120)
        (check (hash-get object "admitted-memory-bytes") => 4831838208)
        (check (hash-get object "memory-per-worker-bytes") => 805306368)
        (check (hash-get object "memory-worker-capacity") => 6)
        (check (hash-get object "worker-count")
               => (min available-cpu-count 6))
        (check
         (hash-get (hash-get object "build-summary") "stage-count")
         => 3)
    (let* ((build-summary (hash-get object "build-summary"))
           (runtime-stage (car (hash-get build-summary "active-stages")))
           (adaptive-execution
            (hash-get runtime-stage "adaptive-execution"))
           (adaptive-diagnostics
            (hash-get runtime-stage "adaptive-diagnostics"))
           (slowest
            (hash-get adaptive-diagnostics "slowest-windows")))
      (check
       (hash-get adaptive-execution "attempted-window-count")
       => 3)
      (check
       (hash-get adaptive-diagnostics "selection-policy")
       => "ceil-log2-window-count")
      (check
       (hash-get adaptive-diagnostics "selected-window-count")
       => 2)
      (check
       (map (lambda (window) (hash-get window "elapsed-ms")) slowest)
       => '(12 7)))
    (check
     (parameterize ((write-json-sort-keys? #t))
           (json-object->string object))
         => json-string)))

    (test-case "failed build preserves the stopped Scheme guard receipt"
      (let* ((config (poo-flow-project-compile-guard-config '()))
             (guard-receipt
              (.o (outcome 'child-failed)
                  (child-exit-code 138)
                  (peak-rss-bytes 4831838208)
                  (elapsed-ms 108226)
                  (timeout-ms #f)))
             (receipt
              (poo-flow-project-compile-failed-receipt
               config guard-receipt))
             (object
              (string->json-object
               (poo-flow-project-compile-receipt->json-string receipt))))
        (check (hash-get object "outcome") => "failed-build")
        (check (hash-get object "failure-kind") => "child-failed")
        (check (hash-get object "failure-exit-code") => 138)
        (check (hash-get object "source-identity") => #f)
        (check (hash-get object "peak-rss-bytes") => 4831838208)
        (check (hash-get object "elapsed-ms") => 108226)
        (check (hash-get object "timeout-ms") => #f)
        (check
         (hash-get (hash-get object "build-summary") "stage-count")
         => 0)))

    (test-case "failure boundary stops emits and rethrows exactly once"
      (let ((config (poo-flow-project-compile-guard-config '()))
            (stop-count 0)
            (emitted '())
            (caught #f))
        (set! caught
              (with-catch
                (lambda (exception) exception)
                (lambda ()
                  (poo-flow-project-compile-call-with-failure-receipt
                   config
                   (lambda ()
                     (set! stop-count (+ stop-count 1))
                     (.o (outcome 'child-failed)
                         (child-exit-code 138)
                         (peak-rss-bytes 4831838208)
                         (elapsed-ms 108226)
                         (timeout-ms #f)))
                   (lambda () (error "fixture build failure"))
                   (lambda (receipt)
                     (set! emitted (cons receipt emitted))))
                  #f)))
        (check (and caught #t) => #t)
        (check stop-count => 1)
        (check (length emitted) => 1)
        (check (.ref (car emitted) 'outcome) => 'failed-build)
        (check (.ref (car emitted) 'peak-rss-bytes) => 4831838208)))))
