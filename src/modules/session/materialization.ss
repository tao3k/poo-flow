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
        poo-flow-session-materialization-receipt-declaration-checked?
        poo-flow-session-materialization-receipt-declared-session-refs
        poo-flow-session-materialization-receipt-declared-parent-session-refs
        poo-flow-session-materialization-receipt-declared-sandbox-handle-refs
        poo-flow-session-materialization-receipt-root-session-declared?
        poo-flow-session-materialization-receipt-session-declared?
        poo-flow-session-materialization-receipt-undeclared-session-refs
        poo-flow-session-materialization-receipt-undeclared-parent-session-refs
        poo-flow-session-materialization-receipt-sandbox-handle-declared?
        poo-flow-session-materialization-receipt-valid?
        poo-flow-session-materialization-receipt-diagnostic-count
        poo-flow-session-materialization-receipt-diagnostics
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

;; : (-> Alist Symbol MaybeValue)
(def (poo-flow-session-materialization-metadata-ref metadata key)
  (poo-flow-session-alist-ref metadata key #f))

;; : (-> MaybeSymbolList Boolean)
(def (poo-flow-session-materialization-maybe-symbol-list? value)
  (or (not value)
      (poo-flow-session-every? symbol? value)))

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-session-materialization-member? value declared-refs)
  (if (member value declared-refs) #t #f))

;; : (-> List List List)
(def (poo-flow-session-materialization-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

(defrules poo-flow-session-materialization-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; : (-> [Symbol] MaybeSymbolList [Symbol])
(def (poo-flow-session-materialization-undeclared-refs refs declared-refs)
  (if declared-refs
    (let loop ((remaining-refs refs)
               (undeclared-refs-rev '()))
      (cond
       ((null? remaining-refs) (reverse undeclared-refs-rev))
       ((poo-flow-session-materialization-member? (car remaining-refs)
                                                  declared-refs)
        (loop (cdr remaining-refs) undeclared-refs-rev))
       (else
        (loop (cdr remaining-refs)
              (cons (car remaining-refs) undeclared-refs-rev)))))
    '()))

;; : (-> Symbol Symbol Alist)
(def (poo-flow-session-materialization-diagnostic code request-id detail)
  (poo-flow-session-materialization-field-rows
   (kind 'poo-flow.session.materialization.diagnostic)
   (schema 'poo-flow.modules.session.materialization.diagnostic.v1)
   (code code)
   (request-id request-id)
   (detail detail)
   (severity 'error)
   (runtime-executed #f)))

;; : (-> Symbol Symbol [Symbol] [Alist] [Alist])
(def (poo-flow-session-materialization-session-diagnostics/rev request-id
                                                               code
                                                               session-refs
                                                               diagnostics-rev)
  (if (null? session-refs)
    diagnostics-rev
    (poo-flow-session-materialization-session-diagnostics/rev
     request-id
     code
     (cdr session-refs)
     (cons (poo-flow-session-materialization-diagnostic
            code
            request-id
            (poo-flow-session-materialization-field-rows
             (session-ref (car session-refs))))
           diagnostics-rev))))

;; : (-> Symbol Symbol [Symbol] [Alist])
(def (poo-flow-session-materialization-session-diagnostics request-id
                                                           code
                                                           session-refs)
  (reverse
   (poo-flow-session-materialization-session-diagnostics/rev
    request-id
    code
    session-refs
    '())))

;; : (-> Symbol Symbol MaybeSymbolList [Alist])
(def (poo-flow-session-materialization-sandbox-diagnostics request-id
                                                           sandbox-handle-ref
                                                           declared-refs)
  (if (and declared-refs
           sandbox-handle-ref
           (not (poo-flow-session-materialization-member?
                 sandbox-handle-ref
                 declared-refs)))
    (list
     (poo-flow-session-materialization-diagnostic
      'materialization-sandbox-handle-not-declared
      request-id
      (poo-flow-session-materialization-field-rows
       (sandbox-handle-ref sandbox-handle-ref))))
    '()))

;; : (-> Symbol Symbol MaybeSymbol [Alist])
(def (poo-flow-session-materialization-state-diagnostics request-id
                                                         state
                                                         sandbox-handle-ref
                                                         error-summary)
  (poo-flow-session-materialization-rows/tail
   (if (and (or (eq? state 'pending)
                (eq? state 'materialized))
            (not sandbox-handle-ref))
     (list
      (poo-flow-session-materialization-diagnostic
       'materialization-sandbox-handle-required
       request-id
       (poo-flow-session-materialization-field-rows
        (state state))))
     '())
   (if (and (eq? state 'failed)
            (not error-summary))
     (list
      (poo-flow-session-materialization-diagnostic
       'materialization-failed-missing-error-summary
       request-id
       '()))
     '())))

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
   declaration-checked?
   declared-session-refs
   declared-parent-session-refs
   declared-sandbox-handle-refs
   root-session-declared?
   session-declared?
   undeclared-session-refs
   undeclared-parent-session-refs
   sandbox-handle-declared?
   valid?
   diagnostic-count
   diagnostics
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
  (let* ((metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
         (declared-session-refs
          (poo-flow-session-materialization-metadata-ref
           metadata
           'declared-session-refs))
         (declared-parent-session-refs0
          (poo-flow-session-materialization-metadata-ref
           metadata
           'declared-parent-session-refs))
         (declared-parent-session-refs
          (if declared-parent-session-refs0
            declared-parent-session-refs0
            declared-session-refs))
         (declared-sandbox-handle-refs
          (poo-flow-session-materialization-metadata-ref
           metadata
           'declared-sandbox-handle-refs)))
    (poo-flow-session-require
     "session materialization declared session refs must be symbols"
     (poo-flow-session-materialization-maybe-symbol-list?
      declared-session-refs)
     declared-session-refs)
    (poo-flow-session-require
     "session materialization declared parent refs must be symbols"
     (poo-flow-session-materialization-maybe-symbol-list?
      declared-parent-session-refs)
     declared-parent-session-refs)
    (poo-flow-session-require
     "session materialization declared sandbox handle refs must be symbols"
     (poo-flow-session-materialization-maybe-symbol-list?
      declared-sandbox-handle-refs)
     declared-sandbox-handle-refs)
    (let* ((declaration-checked? (if declared-session-refs #t #f))
           (root-session-declared?
            (or (not declared-session-refs)
                (poo-flow-session-materialization-member?
                 root-session-ref
                 declared-session-refs)))
           (session-declared?
            (or (not declared-session-refs)
                (poo-flow-session-materialization-member?
                 session-ref
                 declared-session-refs)))
           (undeclared-session-refs
            (poo-flow-session-materialization-undeclared-refs
             (list root-session-ref session-ref)
             declared-session-refs))
           (undeclared-parent-session-refs
            (poo-flow-session-materialization-undeclared-refs
             parent-session-refs
             declared-parent-session-refs))
           (sandbox-handle-declared?
            (or (not declared-sandbox-handle-refs)
                (not sandbox-handle-ref)
                (poo-flow-session-materialization-member?
                 sandbox-handle-ref
                 declared-sandbox-handle-refs)))
           (diagnostics
            (poo-flow-session-materialization-rows/tail
             (poo-flow-session-materialization-session-diagnostics
              request-id
              'materialization-session-not-declared
              undeclared-session-refs)
             (poo-flow-session-materialization-rows/tail
              (poo-flow-session-materialization-session-diagnostics
               request-id
               'materialization-parent-session-not-declared
               undeclared-parent-session-refs)
              (poo-flow-session-materialization-rows/tail
               (poo-flow-session-materialization-sandbox-diagnostics
                request-id
                sandbox-handle-ref
                declared-sandbox-handle-refs)
               (poo-flow-session-materialization-state-diagnostics
                request-id
                state
                sandbox-handle-ref
                error-summary))))))
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
       declaration-checked?
       (if declared-session-refs declared-session-refs '())
       (if declared-parent-session-refs declared-parent-session-refs '())
       (if declared-sandbox-handle-refs declared-sandbox-handle-refs '())
       root-session-declared?
       session-declared?
       undeclared-session-refs
       undeclared-parent-session-refs
       sandbox-handle-declared?
       (null? diagnostics)
       (length diagnostics)
       diagnostics
       "marlin-agent-core"
       #f
       metadata))))

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
    ('declaration-checked?
     (poo-flow-session-materialization-receipt-declaration-checked?
      receipt))
    ('declared-session-refs
     (poo-flow-session-materialization-receipt-declared-session-refs
      receipt))
    ('declared-parent-session-refs
     (poo-flow-session-materialization-receipt-declared-parent-session-refs
      receipt))
    ('declared-sandbox-handle-refs
     (poo-flow-session-materialization-receipt-declared-sandbox-handle-refs
      receipt))
    ('root-session-declared?
     (poo-flow-session-materialization-receipt-root-session-declared?
      receipt))
    ('session-declared?
     (poo-flow-session-materialization-receipt-session-declared?
      receipt))
    ('undeclared-session-refs
     (poo-flow-session-materialization-receipt-undeclared-session-refs
      receipt))
    ('undeclared-parent-session-refs
     (poo-flow-session-materialization-receipt-undeclared-parent-session-refs
      receipt))
    ('sandbox-handle-declared?
     (poo-flow-session-materialization-receipt-sandbox-handle-declared?
      receipt))
    ('valid?
     (poo-flow-session-materialization-receipt-valid? receipt))
    ('diagnostic-count
     (poo-flow-session-materialization-receipt-diagnostic-count receipt))
    ('diagnostics
     (poo-flow-session-materialization-receipt-diagnostics receipt))
    ('runtime-owner
     (poo-flow-session-materialization-receipt-runtime-owner receipt))
    ('runtime-executed
     (poo-flow-session-materialization-receipt-runtime-executed?
      receipt))
    ('handoff-required #t)
    ('metadata
     (poo-flow-session-materialization-receipt-metadata receipt)))))
