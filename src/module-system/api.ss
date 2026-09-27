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
        :poo-flow/src/module-system/loader/interface
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/module-system/projection/interface
        :core/module-system/types
        :poo-flow/src/module-system/semantic-module/objects)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/authoring/contracts)
        (import: :poo-flow/src/module-system/contribution/interface)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :poo-flow/src/module-system/loader/interface)
        (import: :poo-flow/src/module-system/profile-composition/interface)
        (import: :poo-flow/src/module-system/projection/interface)
        (import: :core/module-system/types)
        (import: :poo-flow/src/module-system/semantic-module/objects))
