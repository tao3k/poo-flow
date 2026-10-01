;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Owner: public facade for nono-sandbox C binding contract projection.
;;; Boundary: C binding belongs to the sandbox/nono-sandbox module category.
;;; Runtime contract: manifest owners emit data; native.ss owns gated FFI probes.

(import :poo-flow/modules/nono-sandbox/c-binding-build
        :poo-flow/modules/nono-sandbox/c-binding-descriptor
        :poo-flow/modules/nono-sandbox/c-binding-runtime
        :poo-flow/modules/nono-sandbox/native)

(export (import: :poo-flow/modules/nono-sandbox/c-binding-build)
        (import: :poo-flow/modules/nono-sandbox/c-binding-descriptor)
        (import: :poo-flow/modules/nono-sandbox/c-binding-runtime)
        (import: :poo-flow/modules/nono-sandbox/native))
