;;; -*- Gerbil -*-
;;; Owner: agent-sandbox request facade lives here.
;;; Boundary:
;;; - Field contracts, builders, validation, macro sugar, and task accessors
;;;   stay in separate request-specific owners.
;;; - This facade preserves the public import surface for extension users.
;;; Runtime contract:
;;; - Importing this module performs no request validation or backend work.
;;; Policy evidence:
;;; - Agent-sandbox descriptor, bridge, and profile tests import this facade.

(import :modules/agent-sandbox/request-field
        :modules/agent-sandbox/request-validation
        :modules/agent-sandbox/request-builder
        :modules/agent-sandbox/request-macro
        :modules/agent-sandbox/request-accessor)

(export (import: :modules/agent-sandbox/request-field)
        (import: :modules/agent-sandbox/request-validation)
        (import: :modules/agent-sandbox/request-builder)
        (import: :modules/agent-sandbox/request-macro)
        (import: :modules/agent-sandbox/request-accessor))
