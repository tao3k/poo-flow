(import :std/test
        :clan/poo/object
        :poo-flow/src/build-api/project-compile-guard)

(export build-api-project-compile-guard-test)

(def build-api-project-compile-guard-test
  (test-suite "POO project compile guard"
    (test-case "constructs a POO-native topology plan"
      (def plan
        (poo-flow-project-compile-plan '() (current-directory) 8))
      (check (.@ plan schema)
             => 'poo-flow.project-compile-guard.v1)
      (check (.@ plan chunk-size) => 8))))
