;;; -*- Gerbil -*-
;;; Boundary: tests verify custom user-interface loop-engine declarations.
;;; Invariant: custom loop cases project intent data and never execute loops.

(import (only-in :std/test test-suite)
        :poo-flow/t/support/custom-loop-engine/case)

(export user-interface-custom-loop-engine-test)

;; : TestSuite
(def user-interface-custom-loop-engine-test
  (test-suite "poo-flow custom user-interface loop-engine cases"
    user-interface-custom-loop-engine-concrete-case))
