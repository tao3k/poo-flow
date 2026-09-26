;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Owner: agent-sandbox request facade lives here.
;;; Boundary:
;;; - Field contracts, builders, validation, macro sugar, and task accessors
;;;   stay in separate request-specific owners.
;;; - This facade preserves the public import surface for extension users.
;;; Runtime contract:
;;; - Importing this module performs no request validation or backend work.
;;; Policy evidence:
;;; - Agent-sandbox descriptor, bridge, and profile tests import this facade.

(import :poo-flow/modules/agent-sandbox/request-field
        :poo-flow/modules/agent-sandbox/request-validation
        :poo-flow/modules/agent-sandbox/request-builder
        :poo-flow/modules/agent-sandbox/request-macro
        :poo-flow/modules/agent-sandbox/request-accessor)

(export (import: :poo-flow/modules/agent-sandbox/request-field)
        (import: :poo-flow/modules/agent-sandbox/request-validation)
        (import: :poo-flow/modules/agent-sandbox/request-builder)
        (import: :poo-flow/modules/agent-sandbox/request-macro)
        (import: :poo-flow/modules/agent-sandbox/request-accessor))
