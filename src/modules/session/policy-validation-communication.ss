;;; -*- Gerbil -*-
;;; Boundary: communication receipt normalization and grant checks.

(import (only-in :poo-flow/src/modules/session/communication
                 poo-flow-session-communication-channel-receipt?
                 poo-flow-session-communication-channel-receipt->alist
                 poo-flow-session-communication-receipt?
                 poo-flow-session-communication-receipt->alist)
        :poo-flow/src/modules/session/policy-validation-support)

(export poo-flow-session-policy-communication-receipts
        poo-flow-session-policy-communication-channel-receipts
        poo-flow-session-policy-communication-channel-receipt-row
        poo-flow-session-policy-communication-channel-receipt-rows
        poo-flow-session-policy-communication-receipt-row
        poo-flow-session-policy-communication-receipt-rows
        poo-flow-session-policy-communication-receipt-channel
        poo-flow-session-policy-communication-channel-receipt-channel
        poo-flow-session-policy-communication-receipt-target
        poo-flow-session-policy-communication-channel-receipt-target
        poo-flow-session-policy-communication-receipt-channel-allowed?
        poo-flow-session-policy-communication-channel-receipt-channel-allowed?
        poo-flow-session-policy-communication-receipt-target-allowed?
        poo-flow-session-policy-communication-channel-receipt-target-allowed?
        poo-flow-session-policy-communication-receipt-allowed?
        poo-flow-session-policy-communication-channel-receipt-allowed?)

;; : (-> Alist [PooSessionCommunicationReceiptOrRow])
(def (poo-flow-session-policy-communication-receipts metadata)
  (poo-flow-session-validation-alist-ref metadata 'communication-receipts '()))

;; : (-> Alist [PooSessionCommunicationChannelReceiptOrRow])
(def (poo-flow-session-policy-communication-channel-receipts metadata)
  (poo-flow-session-validation-alist-ref
   metadata
   'communication-channel-receipts
   '()))

;; : (-> PooSessionCommunicationChannelReceiptOrRow Alist)
(def (poo-flow-session-policy-communication-channel-receipt-row receipt)
  (cond
   ((poo-flow-session-communication-channel-receipt? receipt)
    (poo-flow-session-communication-channel-receipt->alist receipt))
   ((list? receipt) receipt)
   (else
    (list (cons 'kind 'poo-flow.session.communication-channel-receipt.invalid)
          (cons 'value receipt)))))

;; : (-> [PooSessionCommunicationChannelReceiptOrRow] [Alist])
(def (poo-flow-session-policy-communication-channel-receipt-rows receipts)
  (map poo-flow-session-policy-communication-channel-receipt-row receipts))

;; : (-> PooSessionCommunicationReceiptOrRow Alist)
(def (poo-flow-session-policy-communication-receipt-row receipt)
  (cond
   ((poo-flow-session-communication-receipt? receipt)
    (poo-flow-session-communication-receipt->alist receipt))
   ((list? receipt) receipt)
   (else
    (list (cons 'kind 'poo-flow.session.communication-receipt.invalid)
          (cons 'value receipt)))))

;; : (-> [PooSessionCommunicationReceiptOrRow] [Alist])
(def (poo-flow-session-policy-communication-receipt-rows receipts)
  (map poo-flow-session-policy-communication-receipt-row receipts))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-receipt-channel row)
  (poo-flow-session-validation-row-ref row 'channel-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-channel-receipt-channel row)
  (poo-flow-session-validation-row-ref row 'channel-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-receipt-target row)
  (poo-flow-session-validation-row-ref row 'target-session-id #f))

;; : (-> Alist Symbol)
(def (poo-flow-session-policy-communication-channel-receipt-target row)
  (poo-flow-session-validation-row-ref row 'target-session-id #f))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-channel-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-receipt-channel row)
   (poo-flow-session-policy-channel-allowed policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-channel-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-channel-receipt-channel row)
   (poo-flow-session-policy-channel-allowed policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-target-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-receipt-target row)
   (poo-flow-session-policy-communication-targets policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-target-allowed?
      policy
      row)
  (poo-flow-session-validation-granted?
   (poo-flow-session-policy-communication-channel-receipt-target row)
   (poo-flow-session-policy-communication-targets policy)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-receipt-allowed? policy row)
  (and (poo-flow-session-policy-communication-receipt-channel-allowed?
        policy
        row)
       (poo-flow-session-policy-communication-receipt-target-allowed?
        policy
        row)))

;; : (-> PooSessionPolicy Alist Boolean)
(def (poo-flow-session-policy-communication-channel-receipt-allowed?
      policy
      row)
  (and (poo-flow-session-policy-communication-channel-receipt-channel-allowed?
        policy
        row)
       (poo-flow-session-policy-communication-channel-receipt-target-allowed?
        policy
        row)))
