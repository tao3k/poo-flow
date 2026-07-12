(import :std/test
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
        (check-equal? (length requests) 2)
        (check-equal? (andmap build-request? requests) #t)
        (check-equal? (map build-request-label requests)
                      '("runtime" "user-interface"))))
    (test-case "keeps tests outside the package compile request"
      (poo-flow-project-configure-build-root! ".")
      (let (spec (poo-flow-project-build-spec []))
        (check-equal? (length spec) 2)
        (check-equal? (member "cli-support-tests.ss" (car (car spec))) #f)
        (check-equal?
         (and (member '(ssi: "src/module-system/init-syntax.ss")
                      (car (car spec)))
              #t)
         #t)))
    (test-case "declares only composition-owning user interface modules"
      (poo-flow-project-configure-build-root! ".")
      (let (interface-modules (car (cadr (poo-flow-project-build-spec []))))
        (check-equal? (length interface-modules) 8)
        (check-equal? (and (member "user-interface/init.ss"
                                   interface-modules)
                           #t)
                      #t)))
    (test-case "keeps root entrypoints on current project-build exports"
      (check-equal? (procedure? poo-flow-project-build-spec) #t)
      (check-equal? (procedure? poo-flow-project-compile!) #t))
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
