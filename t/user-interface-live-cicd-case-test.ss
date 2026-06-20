;;; -*- Gerbil -*-
;;; Boundary: test entrypoint for root user-interface CI/CD live cases.
;;; Invariant: live execution cases are test fixtures, not user module syntax.

(import (only-in :std/test run-tests!)
        (only-in :poo-flow/src/testing/user-interface-live-case
                 define-poo-flow-user-interface-live-case-test
                 pooFlowUserInterfaceLiveCaseFromModuleSelection)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-case
                 poo-flow-custom-my-module-cicd-module))

(export user-interface-live-cicd-case-test)

;;; The live CI/CD case is inert fixture data: it wires module selection,
;;; profile inheritance, and sandbox config without running gxpkg here.
;; : PooFlowUserInterfaceLiveCase
(def poo-flow-user-interface-live-cicd-case
  (pooFlowUserInterfaceLiveCaseFromModuleSelection
   'current-system-build
   poo-flow-custom-my-module-cicd-module
   poo-flow-custom-my-module-cicd-case))

(define-poo-flow-user-interface-live-case-test
  user-interface-live-cicd-case-test
  poo-flow-user-interface-live-cicd-case)

(run-tests! user-interface-live-cicd-case-test)
