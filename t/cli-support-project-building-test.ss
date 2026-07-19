(import :std/test
        (only-in :gerbil/gambit
                 call-with-output-file
                 create-directory
                 delete-directory
                 file-exists?)
        (only-in :std/misc/path path-expand)
        (only-in :std/os/temporaries make-temporary-file-name)
        :std/srfi/1
        :std/srfi/13
        :gslph/src/building/facade
        :gslph/src/testing/model
        :poo-flow/src/testing/project
        :poo-flow/src/cli-support/project-build)

(export cli-support-project-building-test)

(def cli-support-project-building-test
  (test-suite "cli-support-project-building"
    (test-case "declares package compilation as upstream BuildRequests"
      (poo-flow-project-configure-build-root! ".")
      (let (requests (poo-flow-project-build-requests []))
        (check-equal? (length requests) 3)
        (check-equal? (andmap build-request? requests) #t)
        (check-equal? (map build-request-label requests)
                      '("nono-c-ffi" "runtime" "user-interface"))))
    (test-case "keeps tests outside the package compile request"
      (poo-flow-project-configure-build-root! ".")
      (let (spec (poo-flow-project-build-spec []))
        (check-equal? (length spec) 3)
        (check-equal? (member "cli-support-tests.ss" (car (cadr spec))) #f)
        (check-equal?
         (and (member '(ssi: "src/module-system/init-syntax.ss")
                      (car (cadr spec)))
              #t)
         #t)))
    (test-case "declares only composition-owning user interface modules"
      (poo-flow-project-configure-build-root! ".")
      (let (interface-modules (car (caddr (poo-flow-project-build-spec []))))
        (check-equal? (length interface-modules) 8)
        (check-equal? (and (member "user-interface/init.ss"
                                   interface-modules)
                           #t)
                      #t)))
    (test-case "keeps root entrypoints on current project-build exports"
      (check-equal? (procedure? poo-flow-project-build-spec) #t)
      (check-equal? (procedure? poo-flow-project-compile!) #t))
    (test-case "emits flat std/make options for enabled build flags"
      (check-equal?
       (poo-flow-project-build-options #t #t #t #t)
       [build-release: #t
        build-optimized: #t
        debug: #t
        verbose: 1]))
    (test-case "cleans the complete package artifact root"
      (let* ((gerbil-path (make-temporary-file-name "poo-flow-clean"))
             (library-root (path-expand "lib" gerbil-path))
             (package-root (path-expand "poo-flow" library-root))
             (source-root (path-expand "src" package-root))
             (artifact (path-expand "stale.ssi" source-root)))
        (create-directory gerbil-path)
        (create-directory library-root)
        (create-directory package-root)
        (create-directory source-root)
        (call-with-output-file artifact
          (lambda (port) (display "stale" port)))
        (check-equal? (file-exists? artifact) #t)
        (poo-flow-project-clean-package-outputs! gerbil-path)
        (check-equal? (file-exists? package-root) #f)
        (check-equal? (file-exists? gerbil-path) #t)
        (delete-directory library-root)
        (delete-directory gerbil-path)))
    (test-case "pins one-file batches and exactly runnable scenario suites"
      (let* ((project (poo-flow-testing-project "." "."))
             (scenario-suites
              (filter (lambda (suite)
                        (string-prefix? "t/scenarios/" (cadr suite)))
                      (testing-object-ref project 'gxtest [])))
             (expected
              '("t/scenarios/user-interface-profile-library-gate-test.ss"
                "t/scenarios/agent-lifecycle-gate-test.ss"
                "t/scenarios/poo-flow-composition-test.ss"
                "t/scenarios/authorized-effect-token-test.ss"
                "t/scenarios/batched-merkle-evidence-test.ss"
                "t/scenarios/canonical-organization-bundle-test.ss"
                "t/scenarios/crewai-user-composition-test.ss"
                "t/scenarios/durable-artifact-policy-test.ss"
                "t/scenarios/langchain-langgraph-core-test.ss"
                "t/scenarios/organization-bundle-five-facets-test.ss"
                "t/scenarios/organization-bundle-kernel-test.ss"
                "t/scenarios/organization-bundle-runtime-v0-batch-test.ss"
                "t/scenarios/organization-bundle-runtime-v0-test.ss"
                "t/scenarios/organization-bundle-shadow-test.ss"
                "t/scenarios/user-interface-composition-test.ss")))
        (check-equal? (testing-project-batch-size project) 1)
        (check-equal? (map cadr scenario-suites) expected)))))
