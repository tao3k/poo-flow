;;; -*- Gerbil -*-
;;; Boundary: report-only session communication receipts.
;;; Invariant: communication receipts describe routing intent only; Scheme does
;;; not deliver messages or mutate source/target sessions.

(import :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/objects)

(export +poo-flow-session-communication-receipt-kind+
        +poo-flow-session-communication-receipt-schema+
        +poo-flow-session-communication-ledger-ref/default+
        make-poo-flow-session-communication-receipt-record
        poo-flow-session-communication-receipt-record?
        poo-flow-session-communication-receipt
        poo-flow-session-communication-receipt?
        poo-flow-session-communication-receipt-project-id
        poo-flow-session-communication-receipt-relation-kind
        poo-flow-session-communication-receipt-source-root-session-id
        poo-flow-session-communication-receipt-target-root-session-id
        poo-flow-session-communication-receipt-source-agent-id
        poo-flow-session-communication-receipt-target-agent-id
        poo-flow-session-communication-receipt-channel-id
        poo-flow-session-communication-receipt-source-session-id
        poo-flow-session-communication-receipt-target-session-id
        poo-flow-session-communication-receipt-message-kind
        poo-flow-session-communication-receipt-payload-summary
        poo-flow-session-communication-receipt-delivery-policy
        poo-flow-session-communication-receipt-communication-ledger-ref
        poo-flow-session-communication-receipt-durable-policy-ref
        poo-flow-session-communication-receipt-valid?
        poo-flow-session-communication-receipt-diagnostics
        poo-flow-session-communication-receipt-metadata
        poo-flow-session-communication-receipt->alist
        poo-flow-session-communication-receipts->alists)

(def +poo-flow-session-communication-receipt-kind+
  'poo-flow.session.communication-receipt)

(def +poo-flow-session-communication-receipt-schema+
  'poo-flow.modules.session.communication-receipt.v1)

(def +poo-flow-session-communication-ledger-ref/default+
  'runtime/communication-ledger)

;; : [Symbol]
(def +poo-flow-session-communication-relation-kinds+
  '(parent-child child-parent sibling cross-root))

;; : (-> Symbol Boolean)
(def (poo-flow-session-communication-relation-kind? value)
  (and (symbol? value)
       (if (member value +poo-flow-session-communication-relation-kinds+)
         #t
         #f)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-communication-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;; : PooSessionCommunicationReceiptRecord
(defstruct poo-flow-session-communication-receipt-record
  (project-id
   relation-kind
   source-root-session-id
   target-root-session-id
   source-session-id
   target-session-id
   source-agent-id
   target-agent-id
   channel-id
   message-kind
   payload-summary
   delivery-policy
   communication-ledger-ref
   durable-policy-ref
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   delivered?
   runtime-executed)
  transparent: #t)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Symbol Any Symbol [Alist] PooSessionCommunicationReceipt)
(def (poo-flow-session-communication-receipt project-id
                                             relation-kind
                                             source-root-session-id
                                             target-root-session-id
                                             source-session-id
                                             target-session-id
                                             source-agent-id
                                             target-agent-id
                                             channel-id
                                             message-kind
                                             payload-summary
                                             delivery-policy
                                             . maybe-metadata)
  (let* ((metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
         (communication-ledger-ref
          (poo-flow-session-communication-option
           metadata
           'communication-ledger-ref
           +poo-flow-session-communication-ledger-ref/default+))
         (durable-policy
          (poo-flow-session-communication-option metadata
                                                 'durable-policy
                                                 #f))
         (durable-policy-ref
          (cond
           ((poo-flow-durable-policy? durable-policy)
            (poo-flow-durable-policy-receipt-policy-id
             (poo-flow-durable-policy->receipt durable-policy)))
           (else
            (poo-flow-session-communication-option metadata
                                                   'durable-policy-ref
                                                   #f)))))
    (poo-flow-session-require "session communication project id must be a symbol"
                              (symbol? project-id)
                              project-id)
    (poo-flow-session-require
     "session communication relation kind must be parent-child, child-parent, sibling, or cross-root"
     (poo-flow-session-communication-relation-kind? relation-kind)
     relation-kind)
    (poo-flow-session-require "session communication source root must be a symbol"
                              (symbol? source-root-session-id)
                              source-root-session-id)
    (poo-flow-session-require "session communication target root must be a symbol"
                              (symbol? target-root-session-id)
                              target-root-session-id)
    (poo-flow-session-require "session communication source session must be a symbol"
                              (symbol? source-session-id)
                              source-session-id)
    (poo-flow-session-require "session communication target session must be a symbol"
                              (symbol? target-session-id)
                              target-session-id)
    (poo-flow-session-require "session communication source agent must be a symbol"
                              (symbol? source-agent-id)
                              source-agent-id)
    (poo-flow-session-require "session communication target agent must be a symbol"
                              (symbol? target-agent-id)
                              target-agent-id)
    (poo-flow-session-require "session communication channel must be a symbol"
                              (symbol? channel-id)
                              channel-id)
    (poo-flow-session-require "session communication message kind must be a symbol"
                              (symbol? message-kind)
                              message-kind)
    (poo-flow-session-require "session communication delivery policy must be a symbol"
                              (symbol? delivery-policy)
                              delivery-policy)
    (poo-flow-session-require "session communication ledger ref must be a symbol"
                              (symbol? communication-ledger-ref)
                              communication-ledger-ref)
    (make-poo-flow-session-communication-receipt-record
     project-id
     relation-kind
     source-root-session-id
     target-root-session-id
     source-session-id
     target-session-id
     source-agent-id
     target-agent-id
     channel-id
     message-kind
     payload-summary
     delivery-policy
     communication-ledger-ref
     durable-policy-ref
     #t
     '()
     metadata
     "marlin-agent-core"
     #t
     #f
     #f)))

;; : (-> Any Boolean)
(def (poo-flow-session-communication-receipt? value)
  (poo-flow-session-communication-receipt-record? value))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-project-id receipt)
  (poo-flow-session-communication-receipt-record-project-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-relation-kind receipt)
  (poo-flow-session-communication-receipt-record-relation-kind receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-source-root-session-id receipt)
  (poo-flow-session-communication-receipt-record-source-root-session-id
   receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-target-root-session-id receipt)
  (poo-flow-session-communication-receipt-record-target-root-session-id
   receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-channel-id receipt)
  (poo-flow-session-communication-receipt-record-channel-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-source-session-id receipt)
  (poo-flow-session-communication-receipt-record-source-session-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-target-session-id receipt)
  (poo-flow-session-communication-receipt-record-target-session-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-source-agent-id receipt)
  (poo-flow-session-communication-receipt-record-source-agent-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-target-agent-id receipt)
  (poo-flow-session-communication-receipt-record-target-agent-id receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-message-kind receipt)
  (poo-flow-session-communication-receipt-record-message-kind receipt))

;; : (-> PooSessionCommunicationReceipt Any)
(def (poo-flow-session-communication-receipt-payload-summary receipt)
  (poo-flow-session-communication-receipt-record-payload-summary receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-delivery-policy receipt)
  (poo-flow-session-communication-receipt-record-delivery-policy receipt))

;; : (-> PooSessionCommunicationReceipt Symbol)
(def (poo-flow-session-communication-receipt-communication-ledger-ref receipt)
  (poo-flow-session-communication-receipt-record-communication-ledger-ref
   receipt))

;; : (-> PooSessionCommunicationReceipt MaybeSymbol)
(def (poo-flow-session-communication-receipt-durable-policy-ref receipt)
  (poo-flow-session-communication-receipt-record-durable-policy-ref receipt))

;; : (-> PooSessionCommunicationReceipt Boolean)
(def (poo-flow-session-communication-receipt-valid? receipt)
  (poo-flow-session-communication-receipt-record-valid? receipt))

;; : (-> PooSessionCommunicationReceipt [Alist])
(def (poo-flow-session-communication-receipt-diagnostics receipt)
  (poo-flow-session-communication-receipt-record-diagnostics receipt))

;; : (-> PooSessionCommunicationReceipt Alist)
(def (poo-flow-session-communication-receipt-metadata receipt)
  (poo-flow-session-communication-receipt-record-metadata receipt))

;; : (-> PooSessionCommunicationReceipt Alist)
(def (poo-flow-session-communication-receipt->alist receipt)
  (list
   (cons 'kind +poo-flow-session-communication-receipt-kind+)
   (cons 'schema +poo-flow-session-communication-receipt-schema+)
   (cons 'project-id
         (poo-flow-session-communication-receipt-project-id receipt))
   (cons 'relation-kind
         (poo-flow-session-communication-receipt-relation-kind receipt))
   (cons 'source-root-session-id
         (poo-flow-session-communication-receipt-source-root-session-id
          receipt))
   (cons 'target-root-session-id
         (poo-flow-session-communication-receipt-target-root-session-id
          receipt))
   (cons 'source-session-id
         (poo-flow-session-communication-receipt-source-session-id receipt))
   (cons 'target-session-id
         (poo-flow-session-communication-receipt-target-session-id receipt))
   (cons 'source-agent-id
         (poo-flow-session-communication-receipt-source-agent-id receipt))
   (cons 'target-agent-id
         (poo-flow-session-communication-receipt-target-agent-id receipt))
   (cons 'channel-id
         (poo-flow-session-communication-receipt-channel-id receipt))
   (cons 'message-kind
         (poo-flow-session-communication-receipt-message-kind receipt))
   (cons 'payload-summary
         (poo-flow-session-communication-receipt-payload-summary receipt))
   (cons 'delivery-policy
         (poo-flow-session-communication-receipt-delivery-policy receipt))
   (cons 'communication-ledger-ref
         (poo-flow-session-communication-receipt-communication-ledger-ref
          receipt))
   (cons 'durable-policy-ref
         (poo-flow-session-communication-receipt-durable-policy-ref receipt))
   (cons 'valid?
         (poo-flow-session-communication-receipt-valid? receipt))
   (cons 'diagnostics
         (poo-flow-session-communication-receipt-diagnostics receipt))
   (cons 'diagnostic-count
         (length
          (poo-flow-session-communication-receipt-diagnostics receipt)))
   (cons 'metadata
         (poo-flow-session-communication-receipt-metadata receipt))
   (cons 'runtime-owner
         (poo-flow-session-communication-receipt-record-runtime-owner receipt))
   (cons 'handoff-required
         (poo-flow-session-communication-receipt-record-handoff-required
          receipt))
   (cons 'delivered?
         (poo-flow-session-communication-receipt-record-delivered? receipt))
   (cons 'runtime-executed
         (poo-flow-session-communication-receipt-record-runtime-executed
          receipt))))

;; : (-> [PooSessionCommunicationReceipt] [Alist])
(def (poo-flow-session-communication-receipts->alists receipts)
  (cond
   ((null? receipts) '())
   ((pair? receipts)
    (cons (poo-flow-session-communication-receipt->alist (car receipts))
          (poo-flow-session-communication-receipts->alists (cdr receipts))))
   (else
    (error "session communication receipt serialization requires a list"
           receipts))))
