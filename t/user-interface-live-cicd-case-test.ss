;;; -*- Gerbil -*-
;;; Boundary: test entrypoint for root user-interface CI/CD live cases.
;;; Invariant: case content lives in user-interface/custom/my-module.

(import (only-in :std/test run-tests!)
        (only-in :poo-flow/src/testing/user-interface-live-case
                 define-poo-flow-user-interface-live-case-test)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-case))

(export user-interface-live-cicd-case-test)

(define-poo-flow-user-interface-live-case-test
  user-interface-live-cicd-case-test
  poo-flow-custom-my-module-cicd-case)

(run-tests! user-interface-live-cicd-case-test)
