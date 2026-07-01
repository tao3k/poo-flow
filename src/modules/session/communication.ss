;;; -*- Gerbil -*-
;;; Boundary: report-only session communication receipts.
;;; Invariant: communication receipts describe routing intent only; Scheme does
;;; not deliver messages or mutate source/target sessions.

(import :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/receipt-syntax)

(export +poo-flow-session-communication-receipt-kind+
        +poo-flow-session-communication-receipt-schema+
        +poo-flow-session-communication-channel-receipt-kind+
        +poo-flow-session-communication-channel-receipt-schema+
        +poo-flow-session-communication-ledger-ref/default+
        make-poo-flow-session-communication-channel-receipt-record
        poo-flow-session-communication-channel-receipt-record?
        poo-flow-session-communication-channel-receipt
        poo-flow-session-communication-channel-receipt?
        poo-flow-session-communication-channel-receipt-project-id
        poo-flow-session-communication-channel-receipt-channel-id
        poo-flow-session-communication-channel-receipt-relation-kind
        poo-flow-session-communication-channel-receipt-source-session-id
        poo-flow-session-communication-channel-receipt-target-session-id
        poo-flow-session-communication-channel-receipt-source-agent-id
        poo-flow-session-communication-channel-receipt-target-agent-id
        poo-flow-session-communication-channel-receipt-allowed-message-kinds
        poo-flow-session-communication-channel-receipt-delivery-policies
        poo-flow-session-communication-channel-receipt-communication-ledger-ref
        poo-flow-session-communication-channel-receipt-durable-policy-ref
        poo-flow-session-communication-channel-receipt-valid?
        poo-flow-session-communication-channel-receipt-diagnostics
        poo-flow-session-communication-channel-receipt-metadata
        poo-flow-session-communication-channel-receipt->alist
        poo-flow-session-communication-channel-receipts->alists
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

(def +poo-flow-session-communication-channel-receipt-kind+
  'poo-flow.session.communication-channel-receipt)

(def +poo-flow-session-communication-channel-receipt-schema+
  'poo-flow.modules.session.communication-channel-receipt.v1)

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

;; : (-> [Any] Boolean)
(def (poo-flow-session-communication-symbol-list? values)
  (and (list? values)
       (poo-flow-session-every? symbol? values)))

;; : (-> [Alist] MaybeSymbol)
(def (poo-flow-session-communication-durable-policy-ref metadata)
  (let (durable-policy
        (poo-flow-session-communication-option metadata 'durable-policy #f))
    (cond
     ((poo-flow-durable-policy? durable-policy)
      (poo-flow-durable-policy-receipt-policy-id
       (poo-flow-durable-policy->receipt durable-policy)))
     (else
      (poo-flow-session-communication-option metadata
                                             'durable-policy-ref
                                             #f)))))

;; : PooSessionCommunicationChannelReceiptRecord
(defstruct poo-flow-session-communication-channel-receipt-record
  (project-id
   channel-id
   relation-kind
   source-session-id
   target-session-id
   source-agent-id
   target-agent-id
   allowed-message-kinds
   delivery-policies
   communication-ledger-ref
   durable-policy-ref
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   open?
   runtime-executed)
  transparent: #t)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Symbol] [Symbol] [Alist] PooSessionCommunicationChannelReceipt)
(def (poo-flow-session-communication-channel-receipt project-id
                                                     channel-id
                                                     relation-kind
                                                     source-session-id
                                                     target-session-id
                                                     source-agent-id
                                                     target-agent-id
                                                     allowed-message-kinds
                                                     delivery-policies
                                                     . maybe-metadata)
  (let* ((metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
         (communication-ledger-ref
          (poo-flow-session-communication-option
           metadata
           'communication-ledger-ref
           +poo-flow-session-communication-ledger-ref/default+))
         (durable-policy-ref
          (poo-flow-session-communication-durable-policy-ref metadata)))
    (poo-flow-session-require "session communication channel project id must be a symbol"
                              (symbol? project-id)
                              project-id)
    (poo-flow-session-require "session communication channel id must be a symbol"
                              (symbol? channel-id)
                              channel-id)
    (poo-flow-session-require
     "session communication channel relation kind must be parent-child, child-parent, sibling, or cross-root"
     (poo-flow-session-communication-relation-kind? relation-kind)
     relation-kind)
    (poo-flow-session-require "session communication channel source session must be a symbol"
                              (symbol? source-session-id)
                              source-session-id)
    (poo-flow-session-require "session communication channel target session must be a symbol"
                              (symbol? target-session-id)
                              target-session-id)
    (poo-flow-session-require "session communication channel source agent must be a symbol"
                              (symbol? source-agent-id)
                              source-agent-id)
    (poo-flow-session-require "session communication channel target agent must be a symbol"
                              (symbol? target-agent-id)
                              target-agent-id)
    (poo-flow-session-require "session communication channel message kinds must be symbols"
                              (poo-flow-session-communication-symbol-list?
                               allowed-message-kinds)
                              allowed-message-kinds)
    (poo-flow-session-require "session communication channel delivery policies must be symbols"
                              (poo-flow-session-communication-symbol-list?
                               delivery-policies)
                              delivery-policies)
    (poo-flow-session-require "session communication channel ledger ref must be a symbol"
                              (symbol? communication-ledger-ref)
                              communication-ledger-ref)
    (make-poo-flow-session-communication-channel-receipt-record
     project-id
     channel-id
     relation-kind
     source-session-id
     target-session-id
     source-agent-id
     target-agent-id
     allowed-message-kinds
     delivery-policies
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
(def (poo-flow-session-communication-channel-receipt? value)
  (poo-flow-session-communication-channel-receipt-record? value))

;; Public accessors are ordinary generated wrappers over the record slots.
(defpoo-session-record-accessors
  (poo-flow-session-communication-channel-receipt-project-id
   poo-flow-session-communication-channel-receipt-record-project-id)
  (poo-flow-session-communication-channel-receipt-channel-id
   poo-flow-session-communication-channel-receipt-record-channel-id)
  (poo-flow-session-communication-channel-receipt-relation-kind
   poo-flow-session-communication-channel-receipt-record-relation-kind)
  (poo-flow-session-communication-channel-receipt-source-session-id
   poo-flow-session-communication-channel-receipt-record-source-session-id)
  (poo-flow-session-communication-channel-receipt-target-session-id
   poo-flow-session-communication-channel-receipt-record-target-session-id)
  (poo-flow-session-communication-channel-receipt-source-agent-id
   poo-flow-session-communication-channel-receipt-record-source-agent-id)
  (poo-flow-session-communication-channel-receipt-target-agent-id
   poo-flow-session-communication-channel-receipt-record-target-agent-id)
  (poo-flow-session-communication-channel-receipt-allowed-message-kinds
   poo-flow-session-communication-channel-receipt-record-allowed-message-kinds)
  (poo-flow-session-communication-channel-receipt-delivery-policies
   poo-flow-session-communication-channel-receipt-record-delivery-policies)
  (poo-flow-session-communication-channel-receipt-communication-ledger-ref
   poo-flow-session-communication-channel-receipt-record-communication-ledger-ref)
  (poo-flow-session-communication-channel-receipt-durable-policy-ref
   poo-flow-session-communication-channel-receipt-record-durable-policy-ref)
  (poo-flow-session-communication-channel-receipt-valid?
   poo-flow-session-communication-channel-receipt-record-valid?)
  (poo-flow-session-communication-channel-receipt-diagnostics
   poo-flow-session-communication-channel-receipt-record-diagnostics)
  (poo-flow-session-communication-channel-receipt-metadata
   poo-flow-session-communication-channel-receipt-record-metadata))

;; : (-> PooSessionCommunicationChannelReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-communication-channel-receipt->alist
  (receipt)
  (bindings
   ((diagnostics
     (poo-flow-session-communication-channel-receipt-diagnostics receipt))))
  (fields
   (('kind +poo-flow-session-communication-channel-receipt-kind+)
    ('schema +poo-flow-session-communication-channel-receipt-schema+)
    ('project-id
     (poo-flow-session-communication-channel-receipt-project-id receipt))
    ('channel-id
     (poo-flow-session-communication-channel-receipt-channel-id receipt))
    ('relation-kind
     (poo-flow-session-communication-channel-receipt-relation-kind receipt))
    ('source-session-id
     (poo-flow-session-communication-channel-receipt-source-session-id
      receipt))
    ('target-session-id
     (poo-flow-session-communication-channel-receipt-target-session-id
      receipt))
    ('source-agent-id
     (poo-flow-session-communication-channel-receipt-source-agent-id receipt))
    ('target-agent-id
     (poo-flow-session-communication-channel-receipt-target-agent-id receipt))
    ('allowed-message-kinds
     (poo-flow-session-communication-channel-receipt-allowed-message-kinds
      receipt))
    ('delivery-policies
     (poo-flow-session-communication-channel-receipt-delivery-policies
      receipt))
    ('communication-ledger-ref
     (poo-flow-session-communication-channel-receipt-communication-ledger-ref
      receipt))
    ('durable-policy-ref
     (poo-flow-session-communication-channel-receipt-durable-policy-ref
      receipt))
    ('valid?
     (poo-flow-session-communication-channel-receipt-valid? receipt))
    ('diagnostics diagnostics)
    ('diagnostic-count (length diagnostics))
    ('metadata
     (poo-flow-session-communication-channel-receipt-metadata receipt))
    ('runtime-owner
     (poo-flow-session-communication-channel-receipt-record-runtime-owner
      receipt))
    ('handoff-required
     (poo-flow-session-communication-channel-receipt-record-handoff-required
      receipt))
    ('open?
     (poo-flow-session-communication-channel-receipt-record-open? receipt))
    ('runtime-executed
     (poo-flow-session-communication-channel-receipt-record-runtime-executed
      receipt)))))

;; : (-> [PooSessionCommunicationChannelReceipt] [Alist])
(defpoo-session-receipt-projection-batch
  poo-flow-session-communication-channel-receipts->alists (receipts)
  (projector poo-flow-session-communication-channel-receipt->alist)
  (error-message "session communication channel serialization requires a list"))

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
         (durable-policy-ref
          (poo-flow-session-communication-durable-policy-ref metadata)))
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

;; Public accessors are ordinary generated wrappers over the record slots.
(defpoo-session-record-accessors
  (poo-flow-session-communication-receipt-project-id
   poo-flow-session-communication-receipt-record-project-id)
  (poo-flow-session-communication-receipt-relation-kind
   poo-flow-session-communication-receipt-record-relation-kind)
  (poo-flow-session-communication-receipt-source-root-session-id
   poo-flow-session-communication-receipt-record-source-root-session-id)
  (poo-flow-session-communication-receipt-target-root-session-id
   poo-flow-session-communication-receipt-record-target-root-session-id)
  (poo-flow-session-communication-receipt-channel-id
   poo-flow-session-communication-receipt-record-channel-id)
  (poo-flow-session-communication-receipt-source-session-id
   poo-flow-session-communication-receipt-record-source-session-id)
  (poo-flow-session-communication-receipt-target-session-id
   poo-flow-session-communication-receipt-record-target-session-id)
  (poo-flow-session-communication-receipt-source-agent-id
   poo-flow-session-communication-receipt-record-source-agent-id)
  (poo-flow-session-communication-receipt-target-agent-id
   poo-flow-session-communication-receipt-record-target-agent-id)
  (poo-flow-session-communication-receipt-message-kind
   poo-flow-session-communication-receipt-record-message-kind)
  (poo-flow-session-communication-receipt-payload-summary
   poo-flow-session-communication-receipt-record-payload-summary)
  (poo-flow-session-communication-receipt-delivery-policy
   poo-flow-session-communication-receipt-record-delivery-policy)
  (poo-flow-session-communication-receipt-communication-ledger-ref
   poo-flow-session-communication-receipt-record-communication-ledger-ref)
  (poo-flow-session-communication-receipt-durable-policy-ref
   poo-flow-session-communication-receipt-record-durable-policy-ref)
  (poo-flow-session-communication-receipt-valid?
   poo-flow-session-communication-receipt-record-valid?)
  (poo-flow-session-communication-receipt-diagnostics
   poo-flow-session-communication-receipt-record-diagnostics)
  (poo-flow-session-communication-receipt-metadata
   poo-flow-session-communication-receipt-record-metadata))

;; : (-> PooSessionCommunicationReceipt Alist)
(defpoo-session-receipt-projection
  poo-flow-session-communication-receipt->alist
  (receipt)
  (bindings
   ((diagnostics
     (poo-flow-session-communication-receipt-diagnostics receipt))))
  (fields
   (('kind +poo-flow-session-communication-receipt-kind+)
    ('schema +poo-flow-session-communication-receipt-schema+)
    ('project-id
     (poo-flow-session-communication-receipt-project-id receipt))
    ('relation-kind
     (poo-flow-session-communication-receipt-relation-kind receipt))
    ('source-root-session-id
     (poo-flow-session-communication-receipt-source-root-session-id
      receipt))
    ('target-root-session-id
     (poo-flow-session-communication-receipt-target-root-session-id
      receipt))
    ('source-session-id
     (poo-flow-session-communication-receipt-source-session-id receipt))
    ('target-session-id
     (poo-flow-session-communication-receipt-target-session-id receipt))
    ('source-agent-id
     (poo-flow-session-communication-receipt-source-agent-id receipt))
    ('target-agent-id
     (poo-flow-session-communication-receipt-target-agent-id receipt))
    ('channel-id
     (poo-flow-session-communication-receipt-channel-id receipt))
    ('message-kind
     (poo-flow-session-communication-receipt-message-kind receipt))
    ('payload-summary
     (poo-flow-session-communication-receipt-payload-summary receipt))
    ('delivery-policy
     (poo-flow-session-communication-receipt-delivery-policy receipt))
    ('communication-ledger-ref
     (poo-flow-session-communication-receipt-communication-ledger-ref
      receipt))
    ('durable-policy-ref
     (poo-flow-session-communication-receipt-durable-policy-ref receipt))
    ('valid?
     (poo-flow-session-communication-receipt-valid? receipt))
    ('diagnostics diagnostics)
    ('diagnostic-count (length diagnostics))
    ('metadata
     (poo-flow-session-communication-receipt-metadata receipt))
    ('runtime-owner
     (poo-flow-session-communication-receipt-record-runtime-owner receipt))
    ('handoff-required
     (poo-flow-session-communication-receipt-record-handoff-required
      receipt))
    ('delivered?
     (poo-flow-session-communication-receipt-record-delivered? receipt))
    ('runtime-executed
     (poo-flow-session-communication-receipt-record-runtime-executed
      receipt)))))

;; : (-> [PooSessionCommunicationReceipt] [Alist])
(defpoo-session-receipt-projection-batch
  poo-flow-session-communication-receipts->alists (receipts)
  (projector poo-flow-session-communication-receipt->alist)
  (error-message "session communication receipt serialization requires a list"))
