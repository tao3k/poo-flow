;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO Flow contribution admission and verification boundary.
(import :clan/poo/object
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/utilities/functional
        "objects.ss"
        "verification.ss")
(export .o .ref .mix .extend .slot? object?
        use-module user-composition poo-flow-scenario-case-profiles
        poo-flow-map poo-flow-append-map poo-flow-all? poo-flow-any?
        (import: "objects.ss")
        (import: "verification.ss"))
