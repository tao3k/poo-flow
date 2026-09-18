;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Narrow public module-source facade used by builds and downstream loaders.

(import :poo-flow/src/module-system/loader/collection
        :poo-flow/src/module-system/loader/contribution-registry
        :poo-flow/src/module-system/loader/selection)

(export (except-out
         (import: :poo-flow/src/module-system/loader/collection)
         poo-flow-module-source-collection-role-entrypoints)
        (import: :poo-flow/src/module-system/loader/contribution-registry)
        (import: :poo-flow/src/module-system/loader/selection))
