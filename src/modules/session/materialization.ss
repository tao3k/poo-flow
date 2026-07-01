;;; -*- Gerbil -*-
;;; Boundary: runtime materialization receipts for session handoff.
;;; Invariant: receipts describe runtime state and handoff identity only;
;;; Scheme never waits on runtime futures, opens sandbox handles, or replays IO.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/receipt-syntax)

(export +poo-flow-session-materialization-states+
        poo-flow-session-materialization-state?
        make-poo-flow-session-materialization-receipt
        poo-flow-session-materialization-receipt?
        poo-flow-session-materialization-receipt-request-id
        poo-flow-session-materialization-receipt-project-id
        poo-flow-session-materialization-receipt-root-session-ref
        poo-flow-session-materialization-receipt-session-ref
        poo-flow-session-materialization-receipt-parent-session-refs
        poo-flow-session-materialization-receipt-state
        poo-flow-session-materialization-receipt-pending-runtime-ref
        poo-flow-session-materialization-receipt-sandbox-handle-ref
        poo-flow-session-materialization-receipt-token-usage-summary
        poo-flow-session-materialization-receipt-error-summary
        poo-flow-session-materialization-receipt-runtime-owner
        poo-flow-session-materialization-receipt-runtime-executed?
        poo-flow-session-runtime-materialization-receipt
        poo-flow-session-materialization-receipt->alist)

;; : [Symbol]
(def +poo-flow-session-materialization-states+
  '(pending materialized failed dropped))

;; : (-> Symbol Boolean)
(def (poo-flow-session-materialization-state? value)
  (and (symbol? value)
       (if (member value +poo-flow-session-materialization-states+)
         #t
         #f)))

;; : (-> RequestId ProjectId RootSessionRef SessionRef ParentSessionRefs State PendingRuntimeRef SandboxHandleRef TokenUsageSummary ErrorSummary RuntimeOwner RuntimeExecuted Metadata PooSessionMaterializationReceipt)
(defstruct poo-flow-session-materialization-receipt
  (request-id
   project-id
   root-session-ref
   session-ref
   parent-session-refs
   state
   pending-runtime-ref
   sandbox-handle-ref
   token-usage-summary
   error-summary
   runtime-owner
   runtime-executed?
   metadata)
  transparent: #t)

;; : (-> Symbol Symbol Symbol Symbol [Symbol] Symbol Symbol MaybeSymbol Alist MaybeAlist [Alist] PooSessionMaterializationReceipt)
(def (poo-flow-session-runtime-materialization-receipt request-id
                                                       project-id
                                                       root-session-ref
                                                       session-ref
                                                       parent-session-refs
                                                       state
                                                       pending-runtime-ref
                                                       sandbox-handle-ref
                                                       token-usage-summary
                                                       error-summary
                                                       . maybe-metadata)
  (poo-flow-session-require "session materialization request id must be a symbol"
                            (symbol? request-id)
                            request-id)
  (poo-flow-session-require "session materialization project id must be a symbol"
                            (symbol? project-id)
                            project-id)
  (poo-flow-session-require "session materialization root ref must be a symbol"
                            (symbol? root-session-ref)
                            root-session-ref)
  (poo-flow-session-require "session materialization session ref must be a symbol"
                            (symbol? session-ref)
                            session-ref)
  (poo-flow-session-require
   "session materialization parent refs must be symbols"
   (poo-flow-session-every? symbol? parent-session-refs)
   parent-session-refs)
  (poo-flow-session-require
   "session materialization state must be pending, materialized, failed, or dropped"
   (poo-flow-session-materialization-state? state)
   state)
  (poo-flow-session-require
   "session materialization pending runtime ref must be a symbol"
   (symbol? pending-runtime-ref)
   pending-runtime-ref)
  (poo-flow-session-require
   "session materialization sandbox handle ref must be a symbol or #f"
   (or (symbol? sandbox-handle-ref) (not sandbox-handle-ref))
   sandbox-handle-ref)
  (poo-flow-session-require
   "session materialization token usage summary must be an alist"
   (list? token-usage-summary)
   token-usage-summary)
  (poo-flow-session-require
   "session materialization error summary must be an alist or #f"
   (or (list? error-summary) (not error-summary))
   error-summary)
  (make-poo-flow-session-materialization-receipt
   request-id
   project-id
   root-session-ref
   session-ref
   parent-session-refs
   state
   pending-runtime-ref
   sandbox-handle-ref
   token-usage-summary
   error-summary
   "marlin-agent-core"
   #f
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> PooSessionMaterializationReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-materialization-receipt->alist
  (receipt)
  (require poo-flow-session-require
           "session materialization projection requires a receipt"
           (poo-flow-session-materialization-receipt? receipt)
           receipt)
  (bindings ())
  (fields
   (('kind 'poo-flow.session.materialization-receipt)
    ('schema 'poo-flow.modules.session.materialization-receipt.v1)
    ('request-id
     (poo-flow-session-materialization-receipt-request-id receipt))
    ('project-id
     (poo-flow-session-materialization-receipt-project-id receipt))
    ('root-session-ref
     (poo-flow-session-materialization-receipt-root-session-ref receipt))
    ('session-ref
     (poo-flow-session-materialization-receipt-session-ref receipt))
    ('parent-session-refs
     (poo-flow-session-materialization-receipt-parent-session-refs
      receipt))
    ('materialization-state
     (poo-flow-session-materialization-receipt-state receipt))
    ('pending-runtime-ref
     (poo-flow-session-materialization-receipt-pending-runtime-ref
      receipt))
    ('sandbox-handle-ref
     (poo-flow-session-materialization-receipt-sandbox-handle-ref
      receipt))
    ('token-usage-summary
     (poo-flow-session-materialization-receipt-token-usage-summary
      receipt))
    ('error-summary
     (poo-flow-session-materialization-receipt-error-summary receipt))
    ('runtime-owner
     (poo-flow-session-materialization-receipt-runtime-owner receipt))
    ('runtime-executed
     (poo-flow-session-materialization-receipt-runtime-executed?
      receipt))
    ('handoff-required #t)
    ('metadata
     (poo-flow-session-materialization-receipt-metadata receipt)))))
