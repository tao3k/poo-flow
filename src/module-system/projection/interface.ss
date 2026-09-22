;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public projection facade for module option and runtime receipts.
;;; Invariant: implementation logic stays in focused projection leaf owners.

(import :poo-flow/src/module-system/projection/catalog
        :poo-flow/src/module-system/projection/options
        :poo-flow/src/module-system/projection/runtime)

(export (import: :poo-flow/src/module-system/projection/catalog)
        (import: :poo-flow/src/module-system/projection/options)
        (import: :poo-flow/src/module-system/projection/runtime))
