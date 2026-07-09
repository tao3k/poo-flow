;;; -*- Gerbil -*-
;;; Boundary: custom user-interface durable operation bridge scenario.
;;; Invariant: user config bridges durable rows to operation receipts only;
;;; Marlin owns runtime store execution.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-durable-operation-bridge-case))

(export user-interface-custom-durable-operation-bridge-test)

;; : (-> Alist Symbol Object)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-durable-operation-bridge-test
  (test-suite "poo-flow custom durable operation bridge case"
    (test-case "bridges downstream rows to runtime store operations"
      (let* ((negotiation-row
              (car poo-flow-custom-my-module-durable-operation-bridge-case))
             (operation-rows
              (cadr poo-flow-custom-my-module-durable-operation-bridge-case))
             (handoff-row
              (caddr poo-flow-custom-my-module-durable-operation-bridge-case)))
        (check-equal? (test-ref negotiation-row 'handoff-ready?) #t)
        (check-equal? (length operation-rows) 7)
        (check-equal? (map (lambda (row) (test-ref row 'operation-kind))
                           operation-rows)
                      '(append-fact
                        append-communication-event
                        claim-job-lease
                        append-fact
                        retain-artifact
                        retain-artifact
                        attach-sandbox-handle))
        (check-equal? (map (lambda (row) (test-ref row 'valid?))
                           operation-rows)
                      '(#t #t #t #t #t #t #t))
        (check-equal? (test-ref handoff-row 'handoff-ready?) #t)
        (check-equal? (test-ref handoff-row 'operation-count) 7)
        (check-equal? (test-ref handoff-row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-durable-operation-bridge-test)
