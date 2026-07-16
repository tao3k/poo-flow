(import :std/test
        :clan/poo/object
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
       => #f))))
