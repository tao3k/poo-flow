;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: public facade for report-only session dataflow objects.
;;; Invariant: lower owners keep core values, handoff receipts, and graph views
;;; separate while this module preserves the historical import path.

(import :poo-flow/src/modules/session/objects-core
        :poo-flow/src/modules/session/objects-handoff
        :poo-flow/src/modules/session/objects-graph)

(export (import: :poo-flow/src/modules/session/objects-core)
        (import: :poo-flow/src/modules/session/objects-handoff)
        (import: :poo-flow/src/modules/session/objects-graph))
