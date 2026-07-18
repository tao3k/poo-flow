(import :std/test
        :clan/poo/object
        (only-in :gerbil/gambit getenv setenv)
        (only-in :std/text/json
                 json-object->string
                 string->json-object
                 write-json-sort-keys?)
        "../src/build-api/project-compile-guard.ss")

(export build-api-project-compile-guard-test)

(def (build-api-project-compile-guard-available-cpu-count)
  (max 1 (##cpu-count)))

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
             => 'adaptive)
      (check (>= (.ref config 'worker-count) 1) => #t)
      (check (> (.ref config 'available-memory-bytes) 0) => #t)
      (check (.ref config 'request-labels)
             => '("nono-c-ffi" "runtime" "user-interface")))
    (test-case "derives the RSS ceiling from machine capacity"
      (check
       (poo-flow/src/build-api/project-compile-guard#poo-flow-project-compile-adaptive-max-rss-bytes
        (* 8 1024 1024 1024))
       => (* 4 1024 1024 1024)))
    (test-case "does not impose a machine-independent timeout"
      (check
       (poo-flow/src/build-api/project-compile-guard#poo-flow-project-compile-optional-timeout-from-env
       "POO_FLOW_TEST_UNSET_BUILD_TIMEOUT")
       => #f))
    (test-case "uses adaptive policy without requiring an explicit RSS cap"
      (let (previous (getenv "POO_FLOW_BUILD_MAX_RSS_BYTES" #f))
        (dynamic-wind
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" ""))
          (lambda ()
            (check
             (.ref (poo-flow-project-compile-guard-config '())
                   'execution-policy)
             => 'adaptive))
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" (or previous ""))))))
    (test-case "degrades runnable saturation to an observable advisory"
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
              (check (.ref config 'worker-count)
                     => available-cpu-count)))
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
                     => available-cpu-count)))
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
                  (build-owner 'gslph-building-framework)
                  (build-mode 'standard-gerbil-make-project)
                  (execution-policy 'topology)
                  (request-labels '("runtime" "user-interface"))
                  (admission-outcome 'ready)
                  (admission-advisories '())
                  (admission-reasons '())
                  (logical-cpu-count available-cpu-count)
                  (runnable-process-count 4)
                  (available-memory-bytes 25769803776)
                  (rss-headroom-bytes 2147483648)
                  (worker-count available-cpu-count)
                  (system-memory-bytes 34359738368)
                  (max-rss-bytes 17179869184)
                  (peak-rss-bytes 2460680192)
                  (elapsed-ms 199289)
                  (timeout-ms 540000)
                  (build
                   '((version . 1)
                     (stage-count . 3)
                     (compiled . 1)
                     (skipped . 2)
                     (elapsed-jiffies . 3482)
                     (active-stages
                      . (((label . "runtime")
                          (kind . std/make)
                          (status . compiled)
                          (description . "runtime stage")
                          (result . internal)
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
        (check (hash-get object "admission-outcome") => "ready")
        (check (hash-get object "admission-advisories") => '())
        (check (hash-get object "worker-count")
               => available-cpu-count)
        (check
         (hash-get (hash-get object "build-summary") "stage-count")
         => 3)
        (check
         (parameterize ((write-json-sort-keys? #t))
           (json-object->string object))
         => json-string)))))
