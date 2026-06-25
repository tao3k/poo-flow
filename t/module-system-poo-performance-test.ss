;;; -*- Gerbil -*-
;;; Boundary: POO performance field tests apply harness scenarios to poo-flow APIs.

(import (only-in :std/test test-suite)
        :poo-flow/t/module-system-poo-performance-test-support/contracts
        :poo-flow/t/module-system-poo-performance-test-support/objects
        :poo-flow/t/module-system-poo-performance-test-support/extensions)

(export module-system-poo-performance-test)

;; : TestSuite
(def module-system-poo-performance-test
  (test-suite "poo-flow module system POO performance"
    module-system-poo-performance-contracts-test
    module-system-poo-performance-objects-test
    module-system-poo-performance-extensions-test))
