;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: stable downstream POO Flow user-interface presentation mechanics.
;;; Invariant: Module System and concrete module APIs are imported through their
;;; own owner interfaces; they never widen this User Interface facade.

(import :poo-flow/src/user-interface/entrypoints
        :poo-flow/src/user-interface/presentation
        :poo-flow/src/module-system/observability/module-presentation)

(export (import: :poo-flow/src/user-interface/entrypoints)
        (import: :poo-flow/src/user-interface/presentation)
        (import: :poo-flow/src/module-system/observability/module-presentation))
