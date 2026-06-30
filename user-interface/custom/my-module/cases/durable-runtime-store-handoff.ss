;;; -*- Gerbil -*-
;;; Boundary: downstream durable runtime store backend handoff case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this declares backend negotiation data only; Marlin owns the
;;; store implementation and all durable side effects.

(let* ((durable-policy
        (poo-flow-durable-policy
         'durable/custom-runtime-store
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
                        (case . durable-runtime-store-handoff))))))
       (contract-receipt
        (poo-flow-durable-runtime-store-contract->receipt
         runtime-store
         '((project-id . custom/project)
           (root-session-id . custom/root-session)
           (session-id . custom/root-session))))
       (backend-receipt
        (poo-flow-durable-runtime-store-backend->receipt
         poo-flow-durable-runtime-store-backend/default))
       (negotiation
        (poo-flow-durable-runtime-store-backend-negotiation
         contract-receipt
         backend-receipt
         '((metadata . ((source . user-interface)
                        (case . durable-runtime-store-handoff)))))))
  (list
   (poo-flow-durable-runtime-store-negotiation-receipt->alist negotiation)
   (poo-flow-durable-runtime-store-negotiation->marlin-handoff negotiation)))
