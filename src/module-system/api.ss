;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public Module System facade.
;;; Invariant: each subsystem owns its interface; this file only composes the
;;; public import closure consumed by users and the ASP build API.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/authoring/interface
        :poo-flow/src/module-system/composition/interface
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/descriptor/interface
        :poo-flow/src/module-system/diagnostics/interface
        :core/extension-graph/interface
        :poo-flow/src/module-system/loader/interface
        :core/module-schema/interface
        :core/object-family/interface
        :poo-flow/src/module-system/object-validation/interface
        :poo-flow/src/module-system/observability/interface
        :poo-flow/src/module-system/profile-composition/interface
        :core/poo-clos/interface
        :poo-flow/src/module-system/projection/interface
        :poo-flow/src/module-system/semantic-module/interface)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/authoring/interface)
        (import: :poo-flow/src/module-system/composition/interface)
        (import: :poo-flow/src/module-system/contribution/interface)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :poo-flow/src/module-system/diagnostics/interface)
        (import: :core/extension-graph/interface)
        (import: :poo-flow/src/module-system/loader/interface)
        (import: :core/module-schema/interface)
        (import: :core/object-family/interface)
        (import: :poo-flow/src/module-system/object-validation/interface)
        (import: :poo-flow/src/module-system/observability/interface)
        (import: :poo-flow/src/module-system/profile-composition/interface)
        (import: :core/poo-clos/interface)
        (import: :poo-flow/src/module-system/projection/interface)
        (import: :poo-flow/src/module-system/semantic-module/interface))
