;;; Boundary: config-session agent syntax maps user authoring forms into
;;; session-core POO objects without crossing runtime execution boundaries.
;;; Invariant: generated agent objects must retain stable ids for parent and
;;; child session policy checks.
(import :poo-flow/src/modules/session/config-session-syntax-materialization
        :poo-flow/src/modules/session/config-session-syntax-agent-node)

(export (import: :poo-flow/src/modules/session/config-session-syntax-materialization)
        (import: :poo-flow/src/modules/session/config-session-syntax-agent-node))
