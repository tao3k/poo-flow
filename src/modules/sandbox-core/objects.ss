;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: sandbox-core object aggregate.
;;; Invariant: sandbox-core is a developer-owned object namespace, not a module row.

(import :poo-flow/src/modules/sandbox-core/profile)

(export (import: :poo-flow/src/modules/sandbox-core/profile)
        poo-flow-sandbox-core-module-objects)

;; : [PooModuleObject]
(def poo-flow-sandbox-core-module-objects
  (list poo-flow-sandbox-core-profile-object))
