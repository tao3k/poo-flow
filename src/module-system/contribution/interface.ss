;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO Flow contribution verification and Profile composition boundary.
(import :clan/poo/object
        (only-in :core/profile-composition/selection-syntax use-module)
        (only-in :poo-flow/src/scenario/composition-syntax user-composition)
        (only-in :poo-flow/src/scenario/accessors
                 poo-flow-scenario-case-profiles)
        :poo-flow/src/utilities/functional
        :core/contribution/verification)
(export .o .ref .mix .extend .slot? object?
        use-module user-composition poo-flow-scenario-case-profiles
        poo-flow-map poo-flow-append-map poo-flow-all? poo-flow-any?
        (import: :core/contribution/verification))
