;;; -*- Gerbil -*-
;;; Boundary: stable facade for POO-native tool specs, catalogs, and receipts.

(import :poo-flow/src/modules/tool-core/objects-core
        :poo-flow/src/modules/tool-core/objects-builtin)

(export +poo-flow-tool-core-spec-kind+
        +poo-flow-tool-core-catalog-kind+
        +poo-flow-tool-core-handoff-manifest-kind+
        +poo-flow-tool-core-policy-validation-receipt-kind+
        poo-flow-tool-spec
        poo-flow-tool-spec?
        poo-flow-tool-spec-ref
        poo-flow-tool-spec-tool-kind
        poo-flow-tool-spec-actions
        poo-flow-tool-spec-sandbox-required?
        poo-flow-tool-spec-sandbox-profile-ref
        poo-flow-tool-spec->alist
        poo-flow-tool-handoff-manifest
        poo-flow-tool-handoff-manifest?
        poo-flow-tool-handoff-manifest->alist
        poo-flow-tool-catalog
        poo-flow-tool-catalog?
        poo-flow-tool-catalog-ref
        poo-flow-tool-catalog-tool-refs
        poo-flow-tool-catalog-tool-count
        poo-flow-tool-catalog-find
        poo-flow-tool-catalog->alist
        poo-flow-tool-policy-catalog-validation-receipt
        poo-flow-tool-policy-catalog-validation-receipt?
        poo-flow-tool-policy-catalog-validation-receipt-valid?
        poo-flow-tool-policy-catalog-validation-receipt-diagnostics
        poo-flow-tool-policy-catalog-validation-receipt->alist
        poo-flow-tool-core-builtin-read-workspace-file
        poo-flow-tool-core-builtin-write-workspace-file
        poo-flow-tool-core-builtin-run-shell-command
        poo-flow-tool-core-mcp-tool
        poo-flow-tool-core-default-catalog)
