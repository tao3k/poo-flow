;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: stable downstream POO Flow user-interface mechanics.
;;; Invariant: concrete module APIs are selected through their own interface.ss
;;; entrypoints and never widen this facade as the module catalog grows.

(import :poo-flow/src/module-system/facade
        :poo-flow/src/user-interface/entrypoints
        :poo-flow/src/user-interface/presentation
        :poo-flow/src/module-system/observability/module-presentation)

(export (import: :poo-flow/src/module-system/facade)
        (import: :poo-flow/src/user-interface/entrypoints)
        (import: :poo-flow/src/user-interface/presentation)
        (import: :poo-flow/src/module-system/observability/module-presentation))
