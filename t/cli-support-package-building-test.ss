(import :std/test
        :gslph/src/build-api/framework
        :poo-flow/src/cli-support/package-building
        :poo-flow/src/cli-support/package-build-support/options)

(export cli-support-package-building-test)

(def cli-support-package-building-test
  (test-suite "cli-support-package-building"
    (test-case "declares the package pipeline as direct Framework stages"
      (let (plan
            (poo-flow-package-build-stage-plan
             (poo-flow-entry-options #f #f #f #f #f #f #f)))
        (check-equal? (andmap build-stage? plan) #t)
        (check-equal? (map build-stage-label plan)
                      '("runtime-bootstrap"
                        "ffi"
                        "runtime"
                        "testing-project"
                        "tests"
                        "cli-library"
                        "entry"))))))
