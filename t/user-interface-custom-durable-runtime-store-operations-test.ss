;;; -*- Gerbil -*-
;;; Boundary: custom user-interface durable runtime store operation scenario.
;;; Invariant: user config projects operation receipts and handoff data only;
;;; Marlin owns runtime store execution.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/src/module-system/durable-runtime-store-operation
                 +poo-flow-durable-runtime-store-operation-specs+)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-durable-runtime-store-operations-case))

(export user-interface-custom-durable-runtime-store-operations-test)

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-durable-runtime-store-operations-test
  (test-suite "poo-flow custom durable runtime store operation case"
    (test-case "projects operation receipts and Marlin handoff"
      (let* ((negotiation-row
              (car poo-flow-custom-my-module-durable-runtime-store-operations-case))
             (operation-rows
              (cadr poo-flow-custom-my-module-durable-runtime-store-operations-case))
             (handoff-row
              (caddr poo-flow-custom-my-module-durable-runtime-store-operations-case))
             (manifest (test-ref handoff-row 'runtime-command-manifest)))
        (check-equal? (test-ref negotiation-row 'handoff-ready?) #t)
        (check-equal? (length operation-rows)
                      (length +poo-flow-durable-runtime-store-operation-specs+))
        (check-equal? (map (lambda (row) (test-ref row 'operation-kind))
                           operation-rows)
                      (map car
                           +poo-flow-durable-runtime-store-operation-specs+))
        (check-equal? (map (lambda (row) (test-ref row 'valid?))
                           operation-rows)
                      '(#t #t #t #t #t #t #t #t))
        (check-equal? (map (lambda (row) (test-ref row 'runtime-executed))
                           operation-rows)
                      '(#f #f #f #f #f #f #f #f))
        (check-equal? (test-ref (car operation-rows) 'ledger-kind)
                      'fact-log)
        (check-equal? (test-ref handoff-row 'kind)
                      'poo-flow.durable.runtime-store.operation-handoff)
        (check-equal? (test-ref handoff-row 'handoff-ready?) #t)
        (check-equal? (test-ref handoff-row 'operation-count)
                      (length +poo-flow-durable-runtime-store-operation-specs+))
        (check-equal? (test-ref manifest 'argv)
                      '("marlin-runtime-store"
                        "durable-runtime-store"
                        "operations"))
        (check-equal? (test-ref handoff-row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-durable-runtime-store-operations-test)
