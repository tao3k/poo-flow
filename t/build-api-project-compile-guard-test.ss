(import :std/test
        :clan/poo/object
        (only-in :gerbil/gambit getenv setenv)
        (only-in :std/text/json
                 json-object->string
                 string->json-object
                 write-json-sort-keys?)
        "../src/build-api/project-compile-guard.ss")

(export build-api-project-compile-guard-test)

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
    (test-case "records adaptive policy only for an explicit RSS cap"
      (let (previous (getenv "POO_FLOW_BUILD_MAX_RSS_BYTES" #f))
        (dynamic-wind
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" "2147483648"))
          (lambda ()
            (check
             (.ref (poo-flow-project-compile-guard-config '())
                   'execution-policy)
             => 'adaptive))
          (lambda ()
            (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES" (or previous ""))))))
    (test-case "emits a canonical native Scheme JSON receipt"
      (let* ((receipt
              (.o (schema 'poo-flow.project-compile-guard.v1)
                  (outcome 'completed)
                  (build-owner 'gslph-building-framework)
                  (build-mode 'standard-gerbil-make-project)
                  (execution-policy 'topology)
                  (request-labels '("runtime" "user-interface"))
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
        (check
         (hash-get (hash-get object "build-summary") "stage-count")
         => 3)
        (check
         (parameterize ((write-json-sort-keys? #t))
           (json-object->string object))
         => json-string)))))
