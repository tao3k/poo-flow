;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public facade for module loader source declarations.
;;; Invariant: backend receipts and tree/catalog declarations live in leaf owners.

(import :poo-flow/src/module-system/loader/backend
        :poo-flow/src/module-system/loader/collection
        :poo-flow/src/module-system/loader/official-contributions
        :poo-flow/src/module-system/loader/selection
        :poo-flow/src/module-system/loader/tree)

(export poo-flow-module-source-collection-prototype
        make-poo-flow-module-source-collection
        poo-flow-module-source-collection?
        poo-flow-module-source-collection-identity
        poo-flow-module-source-collection-owner
        poo-flow-module-source-collection-source-root
        poo-flow-module-source-collection-modules-directory
        poo-flow-module-source-collection-modules-root
        poo-flow-module-source-collection-locate
        poo-flow-module-style-policy-prototype
        poo-flow-default-module-style-policy
        poo-flow-module-required-role-files
        poo-flow-module-allowed-entrypoint-roles
        poo-flow-module-source-collection-validate!
        poo-flow-load-modules
        poo-flow-module-load-path-prototype
        make-poo-flow-module-load-path
        extend-poo-flow-module-load-path
        poo-flow-module-load-path?
        poo-flow-module-load-path-identity
        poo-flow-module-load-path-collections
        poo-flow-module-load-path-locate
        make-poo-flow-contribution-module-source
        make-poo-flow-contribution-module-load-path
        make-poo-flow-user-interface-module-source
        make-poo-flow-user-interface-module-load-path
        poo-flow-maintained-module-source
        poo-flow-default-module-load-path
        (import: :poo-flow/src/module-system/loader/official-contributions)
        poo-flow-module-loader-entry-prototype
        make-poo-flow-module-loader-entry
        poo-flow-module-loader-entry?
        poo-flow-module-loader-entry-source
        poo-flow-module-loader-entry-module
        poo-flow-module-loader-backend-prototype
        make-poo-flow-module-loader-backend
        poo-flow-module-loader-backend?
        poo-flow-module-loader-backend-name
        poo-flow-module-loader-backend-source-kind
        poo-flow-module-loader-backend-load
        poo-flow-module-loader-backend-metadata
        poo-flow-lazy-load-plan-prototype
        make-poo-flow-lazy-load-plan
        poo-flow-lazy-load-plan?
        poo-flow-lazy-load-plan-source
        poo-flow-lazy-load-plan-backends
        poo-flow-lazy-load-plan-forced?
        poo-flow-lazy-load-plan-receipt
        poo-flow-lazy-load-plan-metadata
        poo-flow-module-load-receipt-prototype
        make-poo-flow-module-load-receipt
        poo-flow-module-load-receipt?
        poo-flow-module-load-receipt-source
        poo-flow-module-load-receipt-module
        poo-flow-module-load-receipt-backend-name
        poo-flow-module-load-receipt-loaded?
        poo-flow-module-load-receipt-code
        poo-flow-module-load-receipt-messages
        poo-flow-module-load-receipt-metadata
        poo-flow-module-static-loader
        poo-flow-module-loader-backend-supports?
        poo-flow-lazy-load-source-receipt
        poo-flow-make-lazy-load-plan
        poo-flow-force-lazy-load-source-receipt
        poo-flow-force-lazy-load-plan
        poo-flow-module-load-source-receipt
        poo-flow-module-load-source-receipts
        poo-flow-module-load-receipt->alist
        poo-flow-module-tree-source-refs
        poo-flow-module-tree-lazy-load-plans
        poo-flow-src-modules-root
        poo-flow-module-system-source
        poo-flow-module-system-source-refs
        poo-flow-src-modules-source-refs
        poo-flow-src-modules-lazy-load-plans
        poo-flow-module-auto-import-root-identity
        poo-flow-module-auto-import-entry-node
        poo-flow-module-auto-imports-node
        poo-flow-module-auto-imports-mk-merge
        poo-flow-module-auto-imports-result-source-refs
        poo-flow-user-tree-source
        poo-flow-user-tree-entrypoint-policy
        poo-flow-user-tree-source-allowed-responsibilities
        poo-flow-user-tree-source-denied-responsibilities
        poo-flow-user-tree-source-allows?
        poo-flow-user-tree-source-policy-violations
        poo-flow-user-tree-source-valid?
        poo-flow-user-tree-init-source
        poo-flow-user-tree-config-source
        poo-flow-user-tree-source-refs
        poo-flow-user-tree-config-authoring-validate!
        poo-flow-user-tree-lazy-load-plans
        poo-flow-module-selection-source-refs
        poo-flow-module-bundles-source-refs
        poo-flow-module-selection-lazy-load-plans
        poo-flow-module-bundles-lazy-load-plans
        poo-flow-module-load-source
        poo-flow-module-load-sources
        poo-flow-module-load-catalog)
