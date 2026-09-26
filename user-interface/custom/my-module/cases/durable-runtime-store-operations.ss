;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: downstream durable runtime store operation case.
;;; Invariant: this declares operation receipts only; Marlin owns all durable
;;; store side effects.

(import :poo-flow/modules/memory-core/durable/policy
        :poo-flow/modules/memory-core/durable/store
        :poo-flow/modules/memory-core/durable/store-backend
        :poo-flow/modules/memory-core/durable/store-operation)

(export poo-flow-custom-my-module-durable-runtime-store-operations-case)

(def poo-flow-custom-my-module-durable-runtime-store-operations-case
  (let* ((durable-policy
        (poo-flow-durable-policy
         'durable/custom-runtime-store-operations
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
                        (case . durable-runtime-store-operations))))))
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
                        (case . durable-runtime-store-operations))))))
       (operation-options
        '((causal-refs . (custom/root-event))
          (watermark . custom/runtime-store-operation-watermark)
          (metadata . ((source . user-interface)
                       (case . durable-runtime-store-operations)))))
       (operations
        (poo-flow-durable-runtime-store-operation-receipts negotiation
                                                          operation-options)))
  (list
   (poo-flow-durable-runtime-store-negotiation-receipt->alist negotiation)
   (poo-flow-durable-runtime-store-operation-receipts->alists operations)
    (poo-flow-durable-runtime-store-operations->marlin-handoff negotiation
                                                                operations))))
