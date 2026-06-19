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

(import :poo-flow/src/modules/agent-sandbox/request-field
        :poo-flow/src/modules/agent-sandbox/request-validation
        :poo-flow/src/modules/agent-sandbox/request-builder
        :poo-flow/src/modules/agent-sandbox/request-macro
        :poo-flow/src/modules/agent-sandbox/request-accessor)

(export (import: :poo-flow/src/modules/agent-sandbox/request-field)
        (import: :poo-flow/src/modules/agent-sandbox/request-validation)
        (import: :poo-flow/src/modules/agent-sandbox/request-builder)
        (import: :poo-flow/src/modules/agent-sandbox/request-macro)
        (import: :poo-flow/src/modules/agent-sandbox/request-accessor))
