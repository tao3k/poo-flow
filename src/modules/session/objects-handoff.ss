;;; -*- Gerbil -*-
;;; Boundary: fixed session handoff receipts for runtime owners.
;;; Invariant: handoff values are data receipts, not executable Scheme handlers.

(import :poo-flow/src/modules/session/objects-core)

(export make-poo-flow-session-handoff-receipt
        poo-flow-session-handoff-receipt?
        poo-flow-session-handoff-receipt-kind
        poo-flow-session-handoff-receipt-schema
        poo-flow-session-handoff-receipt-source
        poo-flow-session-handoff-receipt-session-id
        poo-flow-session-handoff-receipt-chunk-count
        poo-flow-session-handoff-receipt-placement-profile-ref
        poo-flow-session-handoff-receipt-placement-resolved?
        poo-flow-session-handoff-receipt-placement-diagnostics
        poo-flow-session-handoff-receipt-runtime-owner
        poo-flow-session-handoff-receipt-handoff-required
        poo-flow-session-handoff-receipt-runtime-executed
        poo-flow-session-handoff-receipt-runtime-parses-scheme-source
        poo-flow-session-handoff-receipt-scheme-manufactures-runtime-handlers
        poo-flow-session-handoff-receipt-metadata
        poo-flow-session-handoff
        poo-flow-session-handoff?
        poo-flow-session-handoff->alist)

;;; Fixed handoff receipts make the ABI boundary explicit: Scheme constructs
;;; typed receipt state, and only the ABI projection turns it into alist data.
;; : (-> Symbol Symbol Symbol Symbol Integer Symbol Boolean [Alist] String Boolean Boolean Boolean Boolean Alist PooSessionHandoffReceipt)
(defstruct poo-flow-session-handoff-receipt
  (kind
   schema
   source
   session-id
   chunk-count
   placement-profile-ref
   placement-resolved?
   placement-diagnostics
   runtime-owner
   handoff-required
   runtime-executed
   runtime-parses-scheme-source
   scheme-manufactures-runtime-handlers
   metadata)
  transparent: #t)

;;; Handoff receipts summarize the session for runtime owners. They keep the
;;; heavy execution boundary explicit and never claim Scheme executed work.
;; : (-> PooSession [Alist] PooSessionHandoff)
(def (poo-flow-session-handoff session . maybe-metadata)
  (poo-flow-session-require "session handoff requires a session"
                            (poo-flow-session? session)
                            session)
  (let (placement (poo-flow-session-value-placement session))
    (make-poo-flow-session-handoff-receipt
     'poo-flow.session.handoff
     'poo-flow.modules.session.handoff.v1
     'poo-flow-session-presentation
     (poo-flow-session-id session)
     (length (poo-flow-session-chunks session))
     (poo-flow-session-placement-profile-ref placement)
     (poo-flow-session-placement-resolved? placement)
     (poo-flow-session-placement-diagnostics placement)
     "marlin-agent-core"
     #t
     #f
     #f
     #f
     (if (null? maybe-metadata) '() (car maybe-metadata)))))

;; : (-> Value Boolean)
(def (poo-flow-session-handoff? value)
  (poo-flow-session-handoff-receipt? value))

;;; The ABI projection is the only place where handoff receipt state becomes an
;;; alist. Runtime language bindings consume this shape without seeing Gerbil
;;; structs or POO internals.
;; poo-flow-session-handoff->alist
;;   : (-> PooSessionHandoff Alist)
;;   | contract: project one fixed handoff receipt into ABI alist fields
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-session-handoff->alist handoff)
;;       ;; => ((kind . poo-flow.session.handoff) ...)
;;       ```
;;     %
(def (poo-flow-session-handoff->alist handoff)
  (list
   (cons 'kind (poo-flow-session-handoff-receipt-kind handoff))
   (cons 'schema (poo-flow-session-handoff-receipt-schema handoff))
   (cons 'source (poo-flow-session-handoff-receipt-source handoff))
   (cons 'session-id
         (poo-flow-session-handoff-receipt-session-id handoff))
   (cons 'chunk-count
         (poo-flow-session-handoff-receipt-chunk-count handoff))
   (cons 'placement-profile-ref
         (poo-flow-session-handoff-receipt-placement-profile-ref handoff))
   (cons 'placement-resolved?
         (poo-flow-session-handoff-receipt-placement-resolved? handoff))
   (cons 'placement-diagnostics
         (poo-flow-session-handoff-receipt-placement-diagnostics handoff))
   (cons 'runtime-owner
         (poo-flow-session-handoff-receipt-runtime-owner handoff))
   (cons 'handoff-required
         (poo-flow-session-handoff-receipt-handoff-required handoff))
   (cons 'runtime-executed
         (poo-flow-session-handoff-receipt-runtime-executed handoff))
   (cons 'runtime-parses-scheme-source
         (poo-flow-session-handoff-receipt-runtime-parses-scheme-source
          handoff))
   (cons 'scheme-manufactures-runtime-handlers
         (poo-flow-session-handoff-receipt-scheme-manufactures-runtime-handlers
          handoff))
   (cons 'metadata
         (poo-flow-session-handoff-receipt-metadata handoff))))
