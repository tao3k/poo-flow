;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public owner for Session policy validation receipts.
;;; Construction and ABI projection close through focused dependency owners.
(import :poo-flow/modules/session/policy-validation-receipt-core
        :poo-flow/modules/session/policy-validation-receipt-projection)

(export poo-flow-session-policy-validation-receipt
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
