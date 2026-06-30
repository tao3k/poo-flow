;;; -*- Gerbil -*-
;;; Boundary: durable runtime store operation receipts for Marlin handoff.
;;; Invariant: tests validate receipt projection only; no durable store runs.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend
        :poo-flow/src/module-system/durable-runtime-store-operation)

(export durable-runtime-store-operation-test)

(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

(def (diagnostic-code-present? diagnostics code)
  (cond
   ((null? diagnostics) #f)
   ((equal? (test-ref (car diagnostics) 'code) code) #t)
   (else
    (diagnostic-code-present? (cdr diagnostics) code))))

(def (test-negotiation)
  (let* ((contract
          (poo-flow-durable-runtime-store-contract
           'runtime-store/project
           'marlin-runtime-store
           (poo-flow-durable-policy
            'durable/runtime-store
            'objects.shared.durable
            '((repair-mode . rebuild)
              (action-classes . (replayable idempotent compensatable))))))
         (contract-receipt
          (poo-flow-durable-runtime-store-contract->receipt
           contract
           '((project-id . project/poo-flow)
             (root-session-id . session/root)
             (session-id . session/root))))
         (backend-receipt
          (poo-flow-durable-runtime-store-backend->receipt
           poo-flow-durable-runtime-store-backend/default)))
    (poo-flow-durable-runtime-store-backend-negotiation contract-receipt
                                                        backend-receipt)))

(def durable-runtime-store-operation-test
  (test-suite "poo-flow durable runtime store operations"
    (test-case "projects one operation per durable store capability"
      (let* ((negotiation (test-negotiation))
             (operations
              (poo-flow-durable-runtime-store-operation-receipts
               negotiation
               '((causal-refs . (event/root))
                 (watermark . event/1))))
             (rows
              (poo-flow-durable-runtime-store-operation-receipts->alists
               operations))
             (handoff
              (poo-flow-durable-runtime-store-operations->marlin-handoff
               negotiation
               operations))
             (manifest (test-ref handoff 'runtime-command-manifest)))
        (check-equal? (length rows)
                      (length +poo-flow-durable-runtime-store-operation-specs+))
        (check-equal? (map (lambda (row) (test-ref row 'operation-kind))
                           rows)
                      (map car
                           +poo-flow-durable-runtime-store-operation-specs+))
        (check-equal? (map (lambda (row) (test-ref row 'valid?)) rows)
                      '(#t #t #t #t #t #t #t #t))
        (check-equal? (map (lambda (row) (test-ref row 'runtime-executed))
                           rows)
                      '(#f #f #f #f #f #f #f #f))
        (check-equal? (test-ref (car rows) 'ledger-kind) 'fact-log)
        (check-equal? (test-ref (car rows) 'capability-flag) 'append-fact)
        (check-equal? (test-ref handoff 'kind)
                      'poo-flow.durable.runtime-store.operation-handoff)
        (check-equal? (test-ref handoff 'handoff-ready?) #t)
        (check-equal? (test-ref handoff 'operation-count) 8)
        (check-equal? (test-ref manifest 'argv)
                      '("marlin-runtime-store"
                        "durable-runtime-store"
                        "operations"))
        (check-equal? (test-ref handoff 'runtime-executed) #f)))

    (test-case "rejects unsupported operation kinds and invalid causal refs"
      (let* ((receipt
              (poo-flow-durable-runtime-store-operation
               'op/invalid
               'teleport
               (test-negotiation)
               '((summary . invalid))
               '((causal-refs . ("not-symbol")))))
             (row
              (poo-flow-durable-runtime-store-operation-receipt->alist
               receipt))
             (diagnostics (test-ref row 'diagnostics)))
        (check-equal? (test-ref row 'valid?) #f)
        (check-equal?
         (diagnostic-code-present? diagnostics 'unsupported-operation-kind)
         #t)
        (check-equal?
         (diagnostic-code-present? diagnostics 'invalid-causal-refs)
         #t)))))

(run-tests! durable-runtime-store-operation-test)
