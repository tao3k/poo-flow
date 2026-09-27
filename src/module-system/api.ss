;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public Module System facade.
;;; Invariant: each subsystem owns its interface; this file only composes the
;;; public import closure consumed by users and the ASP build API.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/authoring/contracts
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/descriptor/interface
        :core/module-system/loader/objects
        :poo-flow/src/module-system/loader/collection
        :poo-flow/src/module-system/loader/official-contributions
        :poo-flow/src/module-system/loader/selection
        :poo-flow/src/module-system/loader/tree
        :poo-flow/src/module-system/profile-composition/binding-syntax
        :poo-flow/src/module-system/profile-composition/profile-bundle
        :poo-flow/src/module-system/profile-composition/bindings
        :poo-flow/src/scenario/case
        :poo-flow/src/scenario/accessors
        :poo-flow/src/scenario/workload
        :poo-flow/src/scenario/plan-projection
        :poo-flow/src/module-system/projection/interface
        :core/module-system/types
        :poo-flow/src/module-system/semantic-module/objects)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/authoring/contracts)
        (import: :poo-flow/src/module-system/contribution/interface)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :core/module-system/loader/objects)
        (import: :poo-flow/src/module-system/loader/collection)
        (import: :poo-flow/src/module-system/loader/official-contributions)
        (import: :poo-flow/src/module-system/loader/selection)
        (import: :poo-flow/src/module-system/loader/tree)
        (import: :poo-flow/src/module-system/profile-composition/binding-syntax)
        (import: :poo-flow/src/module-system/profile-composition/profile-bundle)
        (import: :poo-flow/src/module-system/profile-composition/bindings)
        (import: :poo-flow/src/scenario/case)
        (import: :poo-flow/src/scenario/accessors)
        (import: :poo-flow/src/scenario/workload)
        (import: :poo-flow/src/scenario/plan-projection)
        (import: :poo-flow/src/module-system/projection/interface)
        (import: :core/module-system/types)
        (import: :poo-flow/src/module-system/semantic-module/objects))
