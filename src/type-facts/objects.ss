;;; -*- Gerbil -*-
;;; Boundary: structured type facts for POO Flow validation layers.
;;; Invariant: facts are Scheme control-plane data; Lean and runtime payloads
;;; are final projections, not semantic owners.

(import (only-in "../utilities/contracts.ss"
                 poo-flow-slot-contract-key
                 poo-flow-slot-contract-slot
                 poo-flow-slot-contract-value-kind
                 poo-flow-slot-contract-predicate-key
                 poo-flow-slot-contract-required?
                 poo-flow-slot-contract-metadata
                 poo-flow-object-type-contract-key
                 poo-flow-object-type-contract-owner
                 poo-flow-object-type-contract-object-kind
                 poo-flow-object-type-contract-slots
                 poo-flow-object-type-contract-metadata))

(export make-poo-flow-type-fact-contract
        poo-flow-type-fact-contract?
        poo-flow-type-fact-contract-key
        poo-flow-type-fact-contract-kind
        poo-flow-type-fact-contract-owner
        poo-flow-type-fact-contract-name
        poo-flow-type-fact-contract-source-slot
        poo-flow-type-fact-contract-value-kind
        poo-flow-type-fact-contract-polarity
        poo-flow-type-fact-contract-metadata
        poo-flow-type-fact
        poo-flow-type-fact-contract->alist
        make-poo-flow-lean-fact-contract
        poo-flow-lean-fact-contract?
        poo-flow-lean-fact-contract-key
        poo-flow-lean-fact-contract-kind
        poo-flow-lean-fact-contract-lean-owner
        poo-flow-lean-fact-contract-lean-name
        poo-flow-lean-fact-contract-source-slot
        poo-flow-lean-fact-contract-polarity
        poo-flow-lean-fact-contract-metadata
        poo-flow-lean-fact
        poo-flow-lean-fact-contract->alist
        poo-flow-contract-required-polarity
        poo-flow-contract-slot-fact-metadata
        poo-flow-contract-slot->type-fact
        poo-flow-object-type-contract->type-facts
        poo-flow-contract-slot->lean-fact-contract
        poo-flow-object-type-contract->lean-fact-contracts
        make-poo-flow-type-validation-receipt
        poo-flow-type-validation-receipt?
        poo-flow-type-validation-receipt-kind
        poo-flow-type-validation-receipt-schema
        poo-flow-type-validation-receipt-object
        poo-flow-type-validation-receipt-valid
        poo-flow-type-validation-receipt-source-ref
        poo-flow-type-validation-receipt-harness-validation
        poo-flow-type-validation-receipt-diagnostics
        poo-flow-type-validation-receipt-checked-signals
        poo-flow-type-validation-receipt-type-facts
        poo-flow-type-validation-receipt-lean-fact-contracts
        poo-flow-type-validation-receipt-runtime-executed
        poo-flow-type-validation-receipt-valid?
        poo-flow-type-validation-receipt->alist)

;; poo-flow-type-fact-contract
;;   : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol Alist PooFlowTypeFactContract)
;;   | doc m%
;;       Fixed Scheme-side type fact row. The generated constructor and accessors
;;       stay internal to the validation layer; runtime and Lean consumers receive
;;       only the explicit alist projection.
;;     %
(defstruct poo-flow-type-fact-contract
  (key
   kind
   owner
   name
   source-slot
   value-kind
   polarity
   metadata)
  transparent: #t)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooFlowTypeFactContract)
(def (poo-flow-type-fact key kind owner name source-slot value-kind polarity
                         . maybe-metadata)
  (make-poo-flow-type-fact-contract
   key
   kind
   owner
   name
   source-slot
   value-kind
   polarity
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> PooFlowTypeFactContract Alist)
(def (poo-flow-type-fact-contract->alist fact)
  (list
   (cons 'key (poo-flow-type-fact-contract-key fact))
   (cons 'kind (poo-flow-type-fact-contract-kind fact))
   (cons 'owner (poo-flow-type-fact-contract-owner fact))
   (cons 'name (poo-flow-type-fact-contract-name fact))
   (cons 'source-slot (poo-flow-type-fact-contract-source-slot fact))
   (cons 'value-kind (poo-flow-type-fact-contract-value-kind fact))
   (cons 'polarity (poo-flow-type-fact-contract-polarity fact))
   (cons 'metadata (poo-flow-type-fact-contract-metadata fact))))

;; poo-flow-lean-fact-contract
;;   : (-> Symbol Symbol Symbol Symbol Symbol Symbol Alist PooFlowLeanFactContract)
;;   | doc m%
;;       Fixed Lean fact contract row. It records the Lean owner/name separately
;;       from the Scheme source slot so projection can remain explicit.
;;     %
(defstruct poo-flow-lean-fact-contract
  (key
   kind
   lean-owner
   lean-name
   source-slot
   polarity
   metadata)
  transparent: #t)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol [Alist] PooFlowLeanFactContract)
(def (poo-flow-lean-fact key kind lean-owner lean-name source-slot polarity
                         . maybe-metadata)
  (make-poo-flow-lean-fact-contract
   key
   kind
   lean-owner
   lean-name
   source-slot
   polarity
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> PooFlowLeanFactContract Alist)
(def (poo-flow-lean-fact-contract->alist fact)
  (list
   (cons 'key (poo-flow-lean-fact-contract-key fact))
   (cons 'kind (poo-flow-lean-fact-contract-kind fact))
   (cons 'lean-owner (poo-flow-lean-fact-contract-lean-owner fact))
   (cons 'lean-name (poo-flow-lean-fact-contract-lean-name fact))
   (cons 'source-slot (poo-flow-lean-fact-contract-source-slot fact))
   (cons 'polarity (poo-flow-lean-fact-contract-polarity fact))
   (cons 'metadata (poo-flow-lean-fact-contract-metadata fact))))

;; poo-flow-contract-required-polarity
;;   : (-> Boolean Symbol)
;;   | doc m%
;;       Convert a slot contract required flag into the polarity used by
;;       type-fact and Lean-fact projections.
;;       # Examples
;;       (poo-flow-contract-required-polarity #t)
;;       # Result
;;       'positive
;;     %
(def (poo-flow-contract-required-polarity required?)
  (if required? 'positive 'optional))

;; poo-flow-contract-slot-fact-metadata
;;   : (-> PooFlowObjectTypeContract PooFlowSlotContract Alist)
;;   | doc m%
;;       Preserve the executable contract identity as projection metadata while
;;       keeping the projected fact itself non-executable.
;;       # Examples
;;       (poo-flow-contract-slot-fact-metadata object-contract slot-contract)
;;       # Result
;;       An alist containing object contract, owner, predicate, and slot metadata.
;;     %
(def (poo-flow-contract-slot-fact-metadata object-contract slot-contract)
  (append
   (list
    (cons 'object-contract
          (poo-flow-object-type-contract-key object-contract))
    (cons 'contract-owner
          (poo-flow-object-type-contract-owner object-contract))
    (cons 'object-metadata
          (poo-flow-object-type-contract-metadata object-contract))
    (cons 'predicate
          (poo-flow-slot-contract-predicate-key slot-contract))
    (cons 'required?
          (poo-flow-slot-contract-required? slot-contract)))
   (poo-flow-slot-contract-metadata slot-contract)))

;; poo-flow-contract-slot->type-fact
;;   : (-> PooFlowObjectTypeContract PooFlowSlotContract PooFlowTypeFactContract)
;;   | doc m%
;;       Project one structured slot contract into a type fact row. The fact
;;       records the POO object kind, source slot, value kind, and polarity.
;;       # Examples
;;       (poo-flow-contract-slot->type-fact object-contract slot-contract)
;;       # Result
;;       A non-executable type fact contract row.
;;     %
(def (poo-flow-contract-slot->type-fact object-contract slot-contract)
  (poo-flow-type-fact
   (poo-flow-slot-contract-key slot-contract)
   'slot-contract
   (poo-flow-object-type-contract-object-kind object-contract)
   (poo-flow-slot-contract-slot slot-contract)
   (poo-flow-slot-contract-slot slot-contract)
   (poo-flow-slot-contract-value-kind slot-contract)
   (poo-flow-contract-required-polarity
    (poo-flow-slot-contract-required? slot-contract))
   (poo-flow-contract-slot-fact-metadata object-contract slot-contract)))

;; poo-flow-object-type-contract->type-facts
;;   : (-> PooFlowObjectTypeContract [PooFlowTypeFactContract])
;;   | doc m%
;;       Project every slot contract in an object contract into stable type
;;       facts. This is the default bridge from defcontract-family declarations
;;       into proof-addressable validation data.
;;       # Examples
;;       (poo-flow-object-type-contract->type-facts receipt-contract)
;;       # Result
;;       A list of type fact contract rows.
;;     %
(def (poo-flow-object-type-contract->type-facts object-contract)
  (map (lambda (slot-contract)
         (poo-flow-contract-slot->type-fact object-contract slot-contract))
       (poo-flow-object-type-contract-slots object-contract)))

;; poo-flow-contract-slot->lean-fact-contract
;;   : (-> PooFlowObjectTypeContract PooFlowSlotContract PooFlowLeanFactContract)
;;   | doc m%
;;       Project one slot contract into a Lean fact contract request. Scheme
;;       names the proof address; Lean remains an external verification target.
;;       # Examples
;;       (poo-flow-contract-slot->lean-fact-contract object-contract slot-contract)
;;       # Result
;;       A non-executable Lean fact contract row.
;;     %
(def (poo-flow-contract-slot->lean-fact-contract object-contract slot-contract)
  (poo-flow-lean-fact
   (poo-flow-slot-contract-key slot-contract)
   'slot-contract
   (poo-flow-object-type-contract-object-kind object-contract)
   (poo-flow-slot-contract-slot slot-contract)
   (poo-flow-slot-contract-slot slot-contract)
   (poo-flow-contract-required-polarity
    (poo-flow-slot-contract-required? slot-contract))
   (poo-flow-contract-slot-fact-metadata object-contract slot-contract)))

;; poo-flow-object-type-contract->lean-fact-contracts
;;   : (-> PooFlowObjectTypeContract [PooFlowLeanFactContract])
;;   | doc m%
;;       Project every slot contract in an object contract into Lean fact
;;       contract requests. The output is data for proof tooling, not execution.
;;       # Examples
;;       (poo-flow-object-type-contract->lean-fact-contracts receipt-contract)
;;       # Result
;;       A list of Lean fact contract rows.
;;     %
(def (poo-flow-object-type-contract->lean-fact-contracts object-contract)
  (map (lambda (slot-contract)
         (poo-flow-contract-slot->lean-fact-contract object-contract
                                                     slot-contract))
       (poo-flow-object-type-contract-slots object-contract)))

;; poo-flow-type-validation-receipt
;;   : (-> Symbol String Symbol Boolean PooFlowSourceRef PooFlowHarnessValidation [Alist] [Symbol] [PooFlowTypeFactContract] [PooFlowLeanFactContract] Boolean PooFlowTypeValidationReceipt)
;;   | doc m%
;;       Fixed validation receipt row for type-fact checks. It keeps runtime
;;       execution evidence as a field, but exposes external shape only through
;;       `poo-flow-type-validation-receipt->alist`.
;;     %
(defstruct poo-flow-type-validation-receipt
  (kind
   schema
   object
   valid
   source-ref
   harness-validation
   diagnostics
   checked-signals
   type-facts
   lean-fact-contracts
   runtime-executed)
  transparent: #t)

;; : (-> PooFlowTypeValidationReceipt Boolean)
(def (poo-flow-type-validation-receipt-valid? receipt)
  (and (poo-flow-type-validation-receipt? receipt)
       (poo-flow-type-validation-receipt-valid receipt)))

;; : (-> (-> PooFlowFactContract Alist) [PooFlowFactContract] [Alist])
(def (poo-flow-type-facts->alists projector facts)
  (map projector facts))

;; : (-> PooFlowTypeValidationReceipt Alist)
(def (poo-flow-type-validation-receipt->alist receipt)
  (list
   (cons 'kind (poo-flow-type-validation-receipt-kind receipt))
   (cons 'schema (poo-flow-type-validation-receipt-schema receipt))
   (cons 'object (poo-flow-type-validation-receipt-object receipt))
   (cons 'valid (poo-flow-type-validation-receipt-valid receipt))
   (cons 'source-ref (poo-flow-type-validation-receipt-source-ref receipt))
   (cons 'harness-validation
         (poo-flow-type-validation-receipt-harness-validation receipt))
   (cons 'diagnostics
         (poo-flow-type-validation-receipt-diagnostics receipt))
   (cons 'diagnostic-count
         (length (poo-flow-type-validation-receipt-diagnostics receipt)))
   (cons 'checked-signals
         (poo-flow-type-validation-receipt-checked-signals receipt))
   (cons 'type-facts
         (poo-flow-type-facts->alists
          poo-flow-type-fact-contract->alist
          (poo-flow-type-validation-receipt-type-facts receipt)))
   (cons 'lean-fact-contracts
         (poo-flow-type-facts->alists
          poo-flow-lean-fact-contract->alist
          (poo-flow-type-validation-receipt-lean-fact-contracts receipt)))
   (cons 'runtime-executed
         (poo-flow-type-validation-receipt-runtime-executed receipt))))
