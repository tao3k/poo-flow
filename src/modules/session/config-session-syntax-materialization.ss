;;; Boundary: materialization syntax lowers session authoring forms into
;;; runtime receipt builders without starting durable execution.
;;; Invariant: generated materialization objects must keep checkpoint and
;;; recovery ids explicit.
(import :poo-flow/src/modules/session/config-session-runtime
        :poo-flow/src/modules/session/config-session-syntax-core)

(export session-materialization)

;; session-materialization
;;   : (-> Syntax PooSessionMaterializationReceipt)
;;   | doc m%
;;       Materialization rows record runtime handoff state only; they do not
;;       await futures or open sandboxes.
;;     %
;; session-materialization
;; : (-> SessionMaterializationSyntax SessionMaterializationExpansionSyntax)
;; | doc m%
;;   Expands user-facing session materialization clauses into a runtime
;;   materialization receipt value.
;;   # Examples
;;   ```scheme
;;   (session-materialization request (project p) ...)
;;   ;; => #<poo-flow-session-materialization>
;;   ```
(defrules session-materialization
  (project root session parents state pending-runtime sandbox-handle tokens error metadata)
  ((_ request-id
      (project project-id)
      (root root-session-ref)
      (session session-ref)
      (parents parent-session-ref ...)
      (state materialization-state)
      (pending-runtime pending-runtime-ref)
      (sandbox-handle sandbox-handle-ref)
      (tokens token-summary-entry ...)
      (error error-summary)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-materialization
    'request-id
    'project-id
    'root-session-ref
    'session-ref
    '(parent-session-ref ...)
    'materialization-state
    'pending-runtime-ref
    'sandbox-handle-ref
    '(token-summary-entry ...)
    'error-summary
    '(metadata-entry ...)))
  ((_ request-id
      (project project-id)
      (root root-session-ref)
      (session session-ref)
      (parents parent-session-ref ...)
      (state materialization-state)
      (pending-runtime pending-runtime-ref)
      (sandbox-handle sandbox-handle-ref)
      (tokens token-summary-entry ...)
      (error error-summary))
   (poo-flow-session-syntax-materialization
    'request-id
    'project-id
    'root-session-ref
    'session-ref
    '(parent-session-ref ...)
    'materialization-state
    'pending-runtime-ref
    'sandbox-handle-ref
    '(token-summary-entry ...)
    'error-summary)))

;; : (-> PooSessionMaterializationReceipt Alist)
