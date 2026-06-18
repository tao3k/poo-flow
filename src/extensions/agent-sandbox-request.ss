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

(import :extensions/agent-sandbox-request-field
        :extensions/agent-sandbox-request-validation
        :extensions/agent-sandbox-request-builder
        :extensions/agent-sandbox-request-macro
        :extensions/agent-sandbox-request-accessor)

(export (import: :extensions/agent-sandbox-request-field)
        (import: :extensions/agent-sandbox-request-validation)
        (import: :extensions/agent-sandbox-request-builder)
        (import: :extensions/agent-sandbox-request-macro)
        (import: :extensions/agent-sandbox-request-accessor))
