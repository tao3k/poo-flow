;;; -*- Gerbil -*-
;;; Boundary: durable runtime store backend negotiation for Marlin handoff.
;;; Invariant: tests validate backend selection and ABI projection only; no
;;; runtime store process is started.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .o object?)
        :poo-flow/src/core/runtime-protocol
        :poo-flow/src/core/runtime-adapter
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend)

(export durable-runtime-store-backend-test)

;; : (-> Alist Symbol Value)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> [Alist] Symbol Boolean)
(def (diagnostic-code-present? diagnostics code)
  (cond
   ((null? diagnostics) #f)
   ((equal? (test-ref (car diagnostics) 'code) code) #t)
   (else
    (diagnostic-code-present? (cdr diagnostics) code))))

;; : (-> PooDurableRuntimeStoreContractReceipt)
(def (test-runtime-store-contract-receipt)
  (poo-flow-durable-runtime-store-contract->receipt
   (poo-flow-durable-runtime-store-contract
    'runtime-store/project
    'marlin-runtime-store
    (poo-flow-durable-policy
     'durable/runtime-store
     'objects.shared.durable
     '((journal-owner . runtime/fact-log)
       (checkpoint-store . runtime/checkpoint-store)
       (resume-identity . session-id)
       (repair-mode . rebuild)
       (action-classes . (replayable idempotent compensatable)))))
   '((project-id . project/poo-flow)
     (root-session-id . session/root)
     (session-id . session/root))))

;; : TestSuite
(def durable-runtime-store-backend-test
  (test-suite "poo-flow durable runtime store backend"
    (test-case "selects a Marlin backend and emits runtime command handoff"
      (let* ((contract-receipt (test-runtime-store-contract-receipt))
             (backend-receipt
              (poo-flow-durable-runtime-store-backend->receipt
               poo-flow-durable-runtime-store-backend/default))
             (negotiation
              (poo-flow-durable-runtime-store-backend-negotiation
               contract-receipt
               backend-receipt
               '((metadata . ((case . runtime-store-backend))))))
             (row
              (poo-flow-durable-runtime-store-negotiation-receipt->alist
               negotiation))
             (handoff
              (poo-flow-durable-runtime-store-negotiation->marlin-handoff
               negotiation))
             (manifest (test-ref handoff 'runtime-command-manifest)))
        (check-equal? (poo-flow-durable-runtime-store-backend?
                       poo-flow-durable-runtime-store-backend/default)
                      #t)
        (check-equal?
         (poo-flow-durable-runtime-store-backend-receipt? backend-receipt)
         #t)
        (check-equal?
         (poo-flow-durable-runtime-store-negotiation-receipt? negotiation)
         #t)
        (check-equal? (object? row) #f)
        (check-equal? (test-ref row 'valid?) #t)
        (check-equal? (test-ref row 'selected?) #t)
        (check-equal? (test-ref row 'handoff-ready?) #t)
        (check-equal? (test-ref row 'store-id) 'runtime-store/project)
        (check-equal? (test-ref row 'backend-id)
                      'runtime-backend/marlin-store)
        (check-equal? (test-ref row 'missing-ledger-kinds) '())
        (check-equal? (test-ref row 'missing-capability-flags) '())
        (check-equal? (test-ref row 'unsupported-operation-kinds) '())
        (check-equal? (test-ref row 'diagnostic-count) 0)
        (check-equal? (test-ref handoff 'kind)
                      'poo-flow.durable.runtime-store.marlin-handoff)
        (check-equal? (test-ref handoff 'operation)
                      'durable-runtime-store-negotiate)
        (check-equal? (test-ref handoff 'request-schema)
                      +runtime-request-schema+)
        (check-equal? (test-ref handoff 'handoff-ready?) #t)
        (check-equal? (test-ref manifest 'operation)
                      'durable-runtime-store-negotiate)
        (check-equal? (test-ref manifest 'executable)
                      "marlin-runtime-store")
        (check-equal? (test-ref manifest 'argv)
                      '("marlin-runtime-store"
                        "durable-runtime-store"
                        "negotiate"))
        (check-equal? (test-ref handoff 'runtime-executed) #f)
        (check-equal? (test-ref handoff 'runtime-parses-scheme-source) #f)
        (check-equal? (test-ref handoff 'scheme-manufactures-runtime-handlers)
                      #f)))

    (test-case "rejects a backend that cannot satisfy durable store contract"
      (let* ((backend
              (poo-flow-durable-runtime-store-backend
               'runtime-backend/weak
               'marlin-runtime-store
               "marlin-runtime-store"
               'stdout-s-expression
               '(fact-log)
               '(append-fact)
               '(append-fact)))
             (negotiation
              (poo-flow-durable-runtime-store-backend-negotiation
               (test-runtime-store-contract-receipt)
               (poo-flow-durable-runtime-store-backend->receipt backend)))
             (row
              (poo-flow-durable-runtime-store-negotiation-receipt->alist
               negotiation))
             (diagnostics (test-ref row 'diagnostics)))
        (check-equal? (test-ref row 'valid?) #f)
        (check-equal? (test-ref row 'selected?) #f)
        (check-equal? (test-ref row 'handoff-ready?) #f)
        (check-equal? (test-ref row 'missing-ledger-kinds)
                      '(checkpoint derived-index job repair artifact
                        communication sandbox))
        (check-equal? (test-ref row 'missing-capability-flags)
                      '(write-checkpoint rebuild-index claim-job-lease
                        append-repair-event retain-artifact
                        append-communication-event attach-sandbox-handle))
        (check-equal?
         (diagnostic-code-present? diagnostics 'missing-ledger-kinds)
         #t)
        (check-equal?
         (diagnostic-code-present? diagnostics 'missing-capability-flags)
         #t)
        (check-equal?
         (diagnostic-code-present? diagnostics 'unsupported-operation-kinds)
         #t)))

    (test-case "keeps invalid store contracts out of backend selection"
      (let* ((invalid-contract
              (.o durable-runtime-store-kind:
                  +poo-flow-durable-runtime-store-contract-kind+
                  durable-runtime-store-schema:
                  +poo-flow-durable-runtime-store-contract-schema+
                  runtime-store-id: 'runtime-store/invalid
                  runtime-store-owner: #f
                  runtime-store-durable-policy: poo-flow-durable-policy/default
                  runtime-store-schema-version: 1
                  runtime-store-fact-log-ref: 'runtime/fact-log
                  runtime-store-checkpoint-store-ref: 'runtime/checkpoint-store
                  runtime-store-derived-index-ref: 'runtime/derived-index
                  runtime-store-job-store-ref: 'runtime/job-store
                  runtime-store-repair-journal-ref: 'runtime/repair-journal
                  runtime-store-artifact-store-ref: 'runtime/artifact-store
                  runtime-store-communication-ledger-ref:
                  'runtime/communication-ledger
                  runtime-store-sandbox-ledger-ref: 'runtime/sandbox-ledger
                  runtime-store-ledger-kinds:
                  +poo-flow-durable-runtime-store-ledger-kinds+
                  runtime-store-capability-flags:
                  +poo-flow-durable-runtime-store-capability-flags+
                  runtime-store-metadata: '()))
             (contract-receipt
              (poo-flow-durable-runtime-store-contract->receipt
               invalid-contract))
             (negotiation
              (poo-flow-durable-runtime-store-backend-negotiation
               contract-receipt
               (poo-flow-durable-runtime-store-backend->receipt
                poo-flow-durable-runtime-store-backend/default)))
             (row
              (poo-flow-durable-runtime-store-negotiation-receipt->alist
               negotiation))
             (diagnostics (test-ref row 'diagnostics)))
        (check-equal? (test-ref row 'valid?) #f)
        (check-equal? (test-ref row 'selected?) #f)
        (check-equal? (test-ref row 'handoff-ready?) #f)
        (check-equal?
         (diagnostic-code-present? diagnostics 'runtime-store-contract-not-ready)
         #t)))))

(run-tests! durable-runtime-store-backend-test)
