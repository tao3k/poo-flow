;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public facade for the POO Flow Loader mechanism.
;;; Invariant: maintained modules and user-interface projections never flow
;;; backward through this mechanism-only facade.

(import :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/loader/source
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/descriptor/interface
        :poo-flow/src/module-system/loader/context
        :poo-flow/src/module-system/diagnostics/interface
        :poo-flow/src/module-system/loader/registry
        :poo-flow/src/module-system/loader/resolver
        :poo-flow/src/module-system/loader/interface
        :poo-flow/src/module-system/descriptor/syntax
        :poo-flow/src/module-system/projection/interface
        :poo-flow/src/module-system/observability/interface)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/loader/source)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :poo-flow/src/module-system/loader/context)
        (import: :poo-flow/src/module-system/diagnostics/interface)
        (import: :poo-flow/src/module-system/loader/registry)
        (import: :poo-flow/src/module-system/loader/resolver)
        (import: :poo-flow/src/module-system/loader/interface)
        (import: :poo-flow/src/module-system/descriptor/syntax)
        (import: :poo-flow/src/module-system/projection/interface)
        (import: :poo-flow/src/module-system/observability/interface))
