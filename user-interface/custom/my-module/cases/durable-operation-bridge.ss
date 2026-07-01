;;; -*- Gerbil -*-
;;; Boundary: downstream durable operation bridge case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this bridges user-visible durable rows to Marlin operation
;;; receipts only; Scheme does not execute runtime store side effects.

(let* ((durable-policy
        (poo-flow-durable-policy
         'durable/custom-operation-bridge
         'objects.shared.durable
         '((journal-owner . runtime/fact-log)
           (checkpoint-store . runtime/checkpoint-store)
           (resume-identity . session-id)
           (repair-mode . rebuild)
           (action-classes . (replayable idempotent compensatable)))))
       (runtime-store
        (poo-flow-durable-runtime-store-contract
         'runtime-store/custom-project
         'marlin-runtime-store
         durable-policy
         '((metadata . ((source . user-interface)
                        (case . durable-operation-bridge))))))
       (contract-receipt
        (poo-flow-durable-runtime-store-contract->receipt
         runtime-store
         '((project-id . custom/project)
           (root-session-id . custom/root-session)
           (session-id . custom/audit-session))))
       (backend-receipt
        (poo-flow-durable-runtime-store-backend->receipt
         poo-flow-durable-runtime-store-backend/default))
       (negotiation
        (poo-flow-durable-runtime-store-backend-negotiation
         contract-receipt
         backend-receipt
         '((metadata . ((source . user-interface)
                        (case . durable-operation-bridge))))))
       (memory-intent
        (poo-flow-session-memory-intent
         'memory/operation-bridge-context
         'memory/durable-project
         'project
         '("last-40-turns")
         'review-only))
       (memory-job
        (poo-flow-memory-recall-job-receipt
         'memory-job/operation-bridge-context
         'custom/project
         'custom/root-session
         'custom/audit-session
         'agent/audit
         poo-flow-memory-core-default-catalog
         memory-intent
         (list (cons 'durable-policy durable-policy)
               (cons 'source-watermark 'turn/40)
               (cons 'target-watermark 'memory/index/40)
               (cons 'metadata '((source . user-interface)
                                 (case . durable-operation-bridge))))))
       (communication
        (poo-flow-session-communication-receipt
         'custom/project
         'sibling
         'custom/root-session
         'custom/root-session
         'custom/build-session
         'custom/audit-session
         'agent/build
         'agent/audit
         'channel/build-audit
         'artifact-ready
         '((artifact . artifact/custom-package))
         'at-least-once
         (list (cons 'communication-ledger-ref 'runtime/communication-ledger)
               (cons 'durable-policy durable-policy)
               (cons 'metadata '((source . user-interface)
                                 (case . durable-operation-bridge))))))
       (session-graph-row
        '((kind . poo-flow.session.agent-graph)
          (project-id . custom/project)
          (root-session-ref . custom/root-session)
          (agent-ids . (agent/build agent/audit))
          (session-ids . (custom/root-session custom/build-session
                         custom/audit-session))
          (lineage-edge-pairs . ((custom/root-session . custom/build-session)
                                 (custom/root-session . custom/audit-session)))
          (runtime-executed . #f)))
       (communication-rows
        (poo-flow-session-communication-receipts->alists
         (list communication)))
       (memory-job-rows
        (poo-flow-memory-durable-job-receipts->alists (list memory-job)))
       (workflow-task-rows
        '(((kind . poo-flow.workflow.cicd.check-receipt)
           (check . build)
           (durable-task-id . workflow/custom-build)
           (action-class . idempotent)
           (checkpoint-ref . checkpoint/custom-build)
           (artifact-refs . (artifact/custom-log artifact/custom-package))
           (sandbox-refs . (agent/nono))
           (valid? . #t)
           (runtime-executed . #f))))
       (operations
        (poo-flow-durable-runtime-store-operations-from-rows
         negotiation
         session-graph-row
         communication-rows
         memory-job-rows
         workflow-task-rows
         '(agent/nono))))
  (list
   (poo-flow-durable-runtime-store-negotiation-receipt->alist negotiation)
   (poo-flow-durable-runtime-store-operation-receipts->alists operations)
   (poo-flow-durable-runtime-store-operations->marlin-handoff negotiation
                                                                 operations)))
