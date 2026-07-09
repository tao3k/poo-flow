;;; -*- Gerbil -*-
;;; Concrete custom loop-engine user-interface case.

(import (only-in :std/test test-case)
        :poo-flow/t/support/custom-loop-engine/fixtures
        :poo-flow/t/support/custom-loop-engine/declaration
        :poo-flow/t/support/custom-loop-engine/agent
        :poo-flow/t/support/custom-loop-engine/operation
        :poo-flow/t/support/custom-loop-engine/presentation)

(export user-interface-custom-loop-engine-concrete-case)

;;; The concrete case is the Flue-alignment proof: one compact loop-engine row
;;; projects the full report-only object graph without runtime execution.
;; : TestCase
(def user-interface-custom-loop-engine-concrete-case
  (test-case "projects custom concrete loop-engine case"
    (let* ((context (custom-loop-concrete-context))
           (presentation (test-ref context 'presentation))
           (intent (test-ref context 'intent))
           (runtime-snapshot (test-ref context 'runtime-snapshot)))
      (check-custom-loop-concrete-declaration presentation intent)
      (check-custom-loop-agent-boundary intent)
      (check-custom-loop-operation-boundary intent)
      (check-custom-loop-presentation-boundary presentation
                                               intent
                                               runtime-snapshot))))
