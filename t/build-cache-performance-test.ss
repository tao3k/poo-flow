(import :std/test
        :gslph/src/building/facade
        :poo-flow/src/cli-support/project-build)

(export build-cache-performance-test)

(def build-cache-performance-test
  (test-suite "upstream-building-performance-boundary"
    (test-case "projects the package into bounded upstream requests"
      (poo-flow-project-configure-build-root! ".")
      (let (requests (poo-flow-project-build-requests []))
        (check-equal? (length requests) 2)
        (check-equal? (andmap build-request? requests) #t)
        (check-equal? (map build-request-label requests)
                      '("runtime" "user-interface"))))
    (test-case "keeps request planning pure"
      (poo-flow-project-configure-build-root! ".")
      (let ((declaration (poo-flow-project-build-spec []))
            (plans
             (map build-request-stage-plan
                  (poo-flow-project-build-requests []))))
        (check-equal? (> (length (car (car declaration))) 80) #t)
        (check-equal? (andmap list? (cdr plans)) #t)
        (check-equal? (andmap (lambda (plan)
                                (andmap build-stage? plan))
                              plans)
                      #t)))))
