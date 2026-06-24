;;; -*- Gerbil -*-
;;; Boundary: invalid Funflow POO configs fail at the declarative contract.

(import (only-in :std/test check-equal?)
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/init-syntax)

(export run-funflow-config-pipeline-error-checks)

(def poo-flow-import-side-effect-test-suite? #t)

(def (funflow-config-error? thunk)
  (let (failure (with-catch (lambda (failure) failure) thunk))
    (error-object? failure)))

(def (funflow-config-workflow-category-selection)
  (use-module workflow
    :config
    (pipeline default)))

(def (funflow-config-bad-dependency-selection)
  (use-module funflow
    :config
    (.def (funflow-test/bad @ funflow-check
                            check-name profile-ref command-vector
                            dependency-refs)
      check-name: 'bad
      profile-ref: 'ci/check
      command-vector: '("gxpkg" "build")
      dependency-refs: '("build"))
    (.def (funflow-test/bad-pipeline @ funflow-pipeline
                                     pipeline-name checks)
      pipeline-name: 'bad
      checks: (list funflow-test/bad))))

(def (run-funflow-config-pipeline-error-checks)
  (check-equal?
   (funflow-config-error?
    (lambda ()
      (funflow-config-workflow-category-selection)
      #f))
   #t)
  (check-equal?
   (funflow-config-error?
   (lambda ()
     (funflow-config-bad-dependency-selection)
     #f))
   #t)
  'ok)

(run-funflow-config-pipeline-error-checks)
