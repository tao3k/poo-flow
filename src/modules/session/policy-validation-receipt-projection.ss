;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Projects admitted validation receipts into the stable report ABI.
;;; This owner does not construct, validate, or execute a Session.
(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/receipt-syntax
        :poo-flow/src/modules/session/receipt-projection
        :poo-flow/src/modules/session/policy-validation-receipt-core)

(export poo-flow-session-policy-validation-receipt->alist
        poo-flow-session-policy-validation-receipts->alists)

;; : (-> PooSessionPolicyValidationReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-policy-validation-receipt->alist
  (receipt)
  (require poo-flow-session-require
           "session policy validation projection requires a receipt"
           (poo-flow-session-policy-validation-receipt? receipt)
           receipt)
  (bindings ())
  (fields
   (('kind 'poo-flow.session.policy-validation-receipt)
    ('schema 'poo-flow.modules.session.policy-validation-receipt.v1)
    ('validation-id
     (poo-flow-session-policy-validation-receipt-record-validation-id
      receipt))
    ('scope-ref
     (poo-flow-session-policy-validation-receipt-record-scope-ref
      receipt))
    ('valid?
     (poo-flow-session-policy-validation-receipt-valid? receipt))
    ('effective-model-ref
     (poo-flow-session-policy-validation-receipt-effective-model-ref
      receipt))
    ('effective-prompt-session-ref
     (poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
      receipt))
    ('effective-prompt-chunk-refs
     (poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
      receipt))
    ('effective-isolation-mode
     (poo-flow-session-policy-validation-receipt-effective-isolation-mode
      receipt))
    ('isolation-sibling-context
     (poo-flow-session-policy-validation-receipt-record-isolation-sibling-context
      receipt))
    ('isolation-parent-write
     (poo-flow-session-policy-validation-receipt-record-isolation-parent-write
      receipt))
    ('isolation-peer-communication
     (poo-flow-session-policy-validation-receipt-record-isolation-peer-communication
      receipt))
    ('effective-sandbox-profile-ref
     (poo-flow-session-policy-validation-receipt-effective-sandbox-profile-ref
      receipt))
    ('sandbox-inheritance-mode
     (poo-flow-session-policy-validation-receipt-record-sandbox-inheritance-mode
      receipt))
    ('sandbox-sharing-mode
     (poo-flow-session-policy-validation-receipt-record-sandbox-sharing-mode
      receipt))
    ('allowed-context-refs
     (poo-flow-session-policy-validation-receipt-record-allowed-context-refs
      receipt))
    ('denied-context-refs
     (poo-flow-session-policy-validation-receipt-record-denied-context-refs
      receipt))
    ('allowed-history-records
     (poo-flow-session-policy-validation-receipt-record-allowed-history-records
      receipt))
    ('denied-history-records
     (poo-flow-session-policy-validation-receipt-record-denied-history-records
      receipt))
    ('allowed-communication-channels
     (poo-flow-session-policy-validation-receipt-record-allowed-communication-channels
      receipt))
    ('denied-communication-channels
     (poo-flow-session-policy-validation-receipt-record-denied-communication-channels
      receipt))
    ('allowed-communication-channel-receipts
     (poo-flow-session-policy-validation-receipt-allowed-communication-channel-receipts
      receipt))
    ('denied-communication-channel-receipts
     (poo-flow-session-policy-validation-receipt-denied-communication-channel-receipts
      receipt))
    ('allowed-communication-receipts
     (poo-flow-session-policy-validation-receipt-allowed-communication-receipts
      receipt))
    ('denied-communication-receipts
     (poo-flow-session-policy-validation-receipt-denied-communication-receipts
      receipt))
    ('allowed-resource-refs
     (poo-flow-session-policy-validation-receipt-record-allowed-resource-refs
      receipt))
    ('denied-resource-refs
     (poo-flow-session-policy-validation-receipt-record-denied-resource-refs
      receipt))
    ('allowed-agent-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-allowed-agent-tool-attempts
      receipt))
    ('denied-agent-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-denied-agent-tool-attempts
      receipt))
    ('allowed-hook-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-allowed-hook-tool-attempts
      receipt))
    ('denied-hook-tool-attempts
     (poo-flow-session-policy-validation-receipt-record-denied-hook-tool-attempts
      receipt))
    ('tool-catalog-validation-id
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-validation-id
      receipt))
    ('tool-catalog-ref
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-ref
      receipt))
    ('tool-catalog-valid?
     (poo-flow-session-policy-validation-receipt-tool-catalog-valid?
      receipt))
    ('tool-catalog-policy-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-policy-tool-refs
      receipt))
    ('tool-catalog-resolved-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-resolved-tool-refs
      receipt))
    ('tool-catalog-unresolved-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-tool-refs
      receipt))
    ('tool-catalog-sandbox-required-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-sandbox-required-tool-refs
      receipt))
    ('tool-catalog-action-mismatch-grants
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-action-mismatch-grants
      receipt))
    ('tool-catalog-allowed-attempt-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-allowed-attempt-tool-refs
      receipt))
    ('tool-catalog-unresolved-attempt-tool-refs
     (poo-flow-session-policy-validation-receipt-record-tool-catalog-unresolved-attempt-tool-refs
      receipt))
    ('memory-catalog-validation-id
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-validation-id
      receipt))
    ('memory-catalog-ref
     (poo-flow-session-policy-validation-receipt-memory-catalog-ref receipt))
    ('memory-catalog-valid?
     (poo-flow-session-policy-validation-receipt-memory-catalog-valid?
      receipt))
    ('memory-catalog-store-count
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-store-count
      receipt))
    ('memory-catalog-store-refs
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-store-refs
      receipt))
    ('memory-catalog-intent-count
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-intent-count
      receipt))
    ('memory-catalog-intent-store-refs
     (poo-flow-session-policy-validation-receipt-record-memory-catalog-intent-store-refs
      receipt))
    ('memory-catalog-resolved-store-refs
     (poo-flow-session-policy-validation-receipt-memory-catalog-resolved-store-refs
      receipt))
    ('memory-catalog-unresolved-store-refs
     (poo-flow-session-policy-validation-receipt-memory-catalog-unresolved-store-refs
      receipt))
    ('shared-resource-grants
     (poo-flow-session-policy-validation-receipt-record-shared-resource-grants
      receipt))
    ('diagnostic-count
     (poo-flow-session-policy-validation-receipt-diagnostic-count receipt))
    ('diagnostics
     (poo-flow-session-policy-validation-receipt-diagnostics receipt))
    ('runtime-owner
     (poo-flow-session-policy-validation-receipt-record-runtime-owner
      receipt))
    ('runtime-executed
     (poo-flow-session-policy-validation-receipt-runtime-executed?
      receipt))
    ('metadata
     (poo-flow-session-policy-validation-receipt-record-metadata receipt)))))

;; : (-> [PooSessionPolicyValidationReceipt] [Alist])
(def (poo-flow-session-policy-validation-receipts->alists receipts)
  (poo-flow-session-receipt-projection-batch
   receipts
   poo-flow-session-policy-validation-receipt->alist
   "session policy validation projection requires a list"))
