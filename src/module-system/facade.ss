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
        :core/module-system/funs
        :poo-flow/src/module-system/loader/registry
        :poo-flow/src/module-system/loader/resolver
        :core/module-system/catalog/objects
        :core/module-system/loader/objects
        :poo-flow/src/module-system/loader/collection
        :poo-flow/src/module-system/loader/official-contributions
        :poo-flow/src/module-system/loader/selection
        :poo-flow/src/module-system/loader/tree
        :poo-flow/src/module-system/descriptor/syntax
        :poo-flow/src/module-system/projection/interface)

(export (import: :poo-flow/src/module-system/interface)
        (import: :poo-flow/src/module-system/loader/source)
        (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/module-system/descriptor/interface)
        (import: :core/module-system/funs)
        (import: :poo-flow/src/module-system/loader/registry)
        (import: :poo-flow/src/module-system/loader/resolver)
        (import: :core/module-system/catalog/objects)
        (import: :core/module-system/loader/objects)
        (import: :poo-flow/src/module-system/loader/collection)
        (import: :poo-flow/src/module-system/loader/official-contributions)
        (import: :poo-flow/src/module-system/loader/selection)
        (import: :poo-flow/src/module-system/loader/tree)
        (import: :poo-flow/src/module-system/descriptor/syntax)
        (import: :poo-flow/src/module-system/projection/interface))
