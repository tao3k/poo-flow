;;; -*- Gerbil -*-
;;; Boundary: public facade for effective session policy validation receipts.
;;; Implementation lives in policy-validation-* modules so catalog, transport,
;;; and receipt projection checks remain independently auditable.

(import :poo-flow/src/modules/session/policy-validation-support
        :poo-flow/src/modules/session/policy-validation-receipt)

(export poo-flow-session-policy-tool-attempt
        poo-flow-session-policy-tool-attempt?
        poo-flow-session-policy-tool-attempt-id
        poo-flow-session-policy-tool-attempt-trigger-ref
        poo-flow-session-policy-tool-attempt-tool-ref
        poo-flow-session-policy-tool-attempt-action
        poo-flow-session-policy-validation-receipt
        poo-flow-session-policy-validation-receipt?
        poo-flow-session-policy-validation-receipt-validation-id
        poo-flow-session-policy-validation-receipt-effective-model-ref
        poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
        poo-flow-session-policy-validation-receipt-effective-prompt-chunk-refs
        poo-flow-session-policy-validation-receipt-effective-isolation-mode
        poo-flow-session-policy-validation-receipt-effective-sandbox-profile-ref
        poo-flow-session-policy-validation-receipt-tool-catalog-ref
        poo-flow-session-policy-validation-receipt-tool-catalog-valid?
        poo-flow-session-policy-validation-receipt-tool-catalog-policy-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-resolved-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-allowed-attempt-tool-refs
        poo-flow-session-policy-validation-receipt-tool-catalog-unresolved-attempt-tool-refs
        poo-flow-session-policy-validation-receipt-memory-catalog-ref
        poo-flow-session-policy-validation-receipt-memory-catalog-valid?
        poo-flow-session-policy-validation-receipt-memory-catalog-resolved-store-refs
        poo-flow-session-policy-validation-receipt-memory-catalog-unresolved-store-refs
        poo-flow-session-policy-validation-receipt-allowed-communication-channel-receipts
        poo-flow-session-policy-validation-receipt-denied-communication-channel-receipts
        poo-flow-session-policy-validation-receipt-allowed-communication-receipts
        poo-flow-session-policy-validation-receipt-denied-communication-receipts
        poo-flow-session-policy-validation-receipt-valid?
        poo-flow-session-policy-validation-receipt-diagnostic-count
        poo-flow-session-policy-validation-receipt-diagnostics
        poo-flow-session-policy-validation-receipt-runtime-executed?
        poo-flow-session-policy-validation-receipt->alist
        poo-flow-session-policy-validation-receipts->alists)
