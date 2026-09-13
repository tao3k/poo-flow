;;; -*- Gerbil -*-
;;; Boundary: reusable POO-native slot schemas for PooFlow Type/Contract owners.
;;; Invariant: schemas are ordinary POO values; alists exist only as receipts.

(import (only-in :clan/poo/object .cc .o .ref)
        (only-in :clan/poo/mop element? raise-type-error)
        (only-in :std/srfi/1 filter-map)
        (only-in "../types.ss"
                 poo-flow-predicate-contract
                 poo-flow-predicate-type))

(export poo-flow-contract-value-type
        poo-flow-contract-slot
        poo-flow-contract-slot-key
        poo-flow-contract-slot-name
        poo-flow-contract-slot-type
        poo-flow-contract-slot-report-kind
        poo-flow-contract-slot-predicate-key
        poo-flow-contract-slot-required?
        poo-flow-contract-slot-metadata
        poo-flow-native-contract
        poo-flow-native-contract-key
        poo-flow-native-contract-owner
        poo-flow-native-contract-object-kind
        poo-flow-native-contract-slots
        poo-flow-native-contract-metadata
        poo-flow-contract-slot->alist
        poo-flow-native-contract->alist
        poo-flow-contract-check-slot!)

;; report-kind is receipt metadata only.  Runtime admission always dispatches
;; through the native Type protocol and never through this symbolic label.
(def (poo-flow-contract-value-type identity predicate report-kind
                                   . maybe-predicate-key)
  (.cc (poo-flow-predicate-type identity predicate)
       'report-kind report-kind
       'predicate-key
       (if (null? maybe-predicate-key) identity (car maybe-predicate-key))))

(def (poo-flow-contract-slot key-value slot-value value-type-value
                             required-value metadata-value)
  (.o kind: 'poo-flow.contract.slot-schema
      key: key-value
      slot: slot-value
      value-type: value-type-value
      required?: (if required-value #t #f)
      metadata: metadata-value))

(def (poo-flow-contract-slot-name slot-contract)
  (.ref slot-contract 'slot))

(def (poo-flow-contract-slot-key slot-contract)
  (.ref slot-contract 'key))

(def (poo-flow-contract-slot-type slot-contract)
  (.ref slot-contract 'value-type))

(def (poo-flow-contract-slot-report-kind slot-contract)
  (.ref (poo-flow-contract-slot-type slot-contract) 'report-kind))

(def (poo-flow-contract-slot-predicate-key slot-contract)
  (.ref (poo-flow-contract-slot-type slot-contract) 'predicate-key))

(def (poo-flow-contract-slot-required? slot-contract)
  (.ref slot-contract 'required?))

(def (poo-flow-contract-slot-metadata slot-contract)
  (.ref slot-contract 'metadata))

(def (poo-flow-contract-obligations slots slot-present? slot-ref)
  (lambda (candidate _context)
    (let (slot-failure
          (lambda (slot-name reason-value)
            (.o kind: 'poo-flow.contract.slot-failure
                slot: slot-name
                reason: reason-value)))
      (filter-map
       (lambda (slot-contract)
         (let* ((slot-name (poo-flow-contract-slot-name slot-contract))
                (required? (poo-flow-contract-slot-required? slot-contract))
                (present? (slot-present? candidate slot-name)))
           (cond
            ((and required? (not present?))
             (slot-failure slot-name 'required-slot-absent))
            ((and present?
                  (not (element? (poo-flow-contract-slot-type slot-contract)
                                 (slot-ref candidate slot-name))))
             (slot-failure slot-name 'slot-type-rejected))
            (else #f))))
       slots))))

(def (poo-flow-native-contract identity owner object-kind predicate
                               slots slot-present? slot-ref metadata)
  (.cc (poo-flow-predicate-contract
        identity
        predicate
        (poo-flow-contract-obligations slots slot-present? slot-ref))
       'owner owner
       'object-kind object-kind
       'slots slots
       'metadata metadata))

(def (poo-flow-native-contract-key contract)
  (.ref contract 'identity))

(def (poo-flow-native-contract-owner contract)
  (.ref contract 'owner))

(def (poo-flow-native-contract-object-kind contract)
  (.ref contract 'object-kind))

(def (poo-flow-native-contract-slots contract)
  (.ref contract 'slots))

(def (poo-flow-native-contract-metadata contract)
  (.ref contract 'metadata))

(def (poo-flow-contract-slot->alist slot-contract)
  (list (cons 'key (poo-flow-contract-slot-key slot-contract))
        (cons 'slot (poo-flow-contract-slot-name slot-contract))
        (cons 'value-kind
              (poo-flow-contract-slot-report-kind slot-contract))
        (cons 'predicate (poo-flow-contract-slot-predicate-key slot-contract))
        (cons 'required? (poo-flow-contract-slot-required? slot-contract))
        (cons 'metadata (poo-flow-contract-slot-metadata slot-contract))))

(def (poo-flow-native-contract->alist contract)
  (list (cons 'key (poo-flow-native-contract-key contract))
        (cons 'owner (poo-flow-native-contract-owner contract))
        (cons 'object-kind (poo-flow-native-contract-object-kind contract))
        (cons 'slots
              (map poo-flow-contract-slot->alist
                   (poo-flow-native-contract-slots contract)))
        (cons 'metadata (poo-flow-native-contract-metadata contract))))

(def (poo-flow-contract-check-slot! slot-contract value)
  (if (element? (poo-flow-contract-slot-type slot-contract) value)
    value
    (raise-type-error (poo-flow-contract-slot-type slot-contract) value)))
