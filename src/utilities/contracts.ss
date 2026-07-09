;;; -*- Gerbil -*-
;;; Utilities: reusable structured contracts for POO Flow control-plane objects.

(export make-poo-flow-slot-contract
        poo-flow-slot-contract?
        poo-flow-slot-contract-key
        poo-flow-slot-contract-owner
        poo-flow-slot-contract-slot
        poo-flow-slot-contract-value-kind
        poo-flow-slot-contract-predicate-key
        poo-flow-slot-contract-predicate
        poo-flow-slot-contract-required?
        poo-flow-slot-contract-metadata
        poo-flow-slot-contract-record
        poo-flow-slot-contract->alist
        make-poo-flow-object-type-contract
        poo-flow-object-type-contract?
        poo-flow-object-type-contract-key
        poo-flow-object-type-contract-owner
        poo-flow-object-type-contract-object-kind
        poo-flow-object-type-contract-slots
        poo-flow-object-type-contract-metadata
        poo-flow-object-type-contract-record
        poo-flow-object-type-contract->alist
        poo-flow-contract-alist?
        poo-flow-contract-list-of?
        poo-flow-contract-require!
        poo-flow-contract-check-slot!)

;; poo-flow-slot-contract
;;   : (-> Symbol Symbol Symbol Symbol Symbol Procedure Boolean Alist PooFlowSlotContract)
;;   | doc m%
;;       Generic slot-level contract record. The predicate is executable, while
;;       predicate-key and metadata make the contract projectable.
;;       # Examples
;;       (make-poo-flow-slot-contract
;;        'receipt/schema 'Receipt 'schema 'String 'string? string? #t '())
;;       # Result
;;       A fixed contract record with generated accessors.
;;     %
(defstruct poo-flow-slot-contract
  (key
   owner
   slot
   value-kind
   predicate-key
   predicate
   required?
   metadata)
  transparent: #t)

;; poo-flow-slot-contract-record
;;   : (-> Symbol Symbol Symbol Symbol Symbol Procedure Boolean [Alist] PooFlowSlotContract)
;;   | doc m%
;;       Construct one reusable slot contract. Module-specific types wrap this
;;       function instead of redefining the contract record shape.
;;       # Examples
;;       (poo-flow-slot-contract-record
;;        'receipt/schema 'Receipt 'schema 'String 'string? string? #t)
;;       # Result
;;       A structured slot contract record.
;;     %
(def (poo-flow-slot-contract-record key owner slot value-kind predicate-key predicate required? . maybe-metadata)
  (make-poo-flow-slot-contract
   key
   owner
   slot
   value-kind
   predicate-key
   predicate
   required?
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-slot-contract->alist
;;   : (-> PooFlowSlotContract Alist)
;;   | doc m%
;;       Project a slot contract without exposing its executable predicate.
;;       # Examples
;;       (poo-flow-slot-contract->alist contract)
;;       # Result
;;       An alist with key, owner, slot, value kind, predicate key, and metadata.
;;     %
(def (poo-flow-slot-contract->alist contract)
  (list
   (cons 'key (poo-flow-slot-contract-key contract))
   (cons 'owner (poo-flow-slot-contract-owner contract))
   (cons 'slot (poo-flow-slot-contract-slot contract))
   (cons 'value-kind (poo-flow-slot-contract-value-kind contract))
   (cons 'predicate (poo-flow-slot-contract-predicate-key contract))
   (cons 'required? (poo-flow-slot-contract-required? contract))
   (cons 'metadata (poo-flow-slot-contract-metadata contract))))

;; poo-flow-object-type-contract
;;   : (-> Symbol Symbol Symbol [PooFlowSlotContract] Alist PooFlowObjectTypeContract)
;;   | doc m%
;;       Generic object-level type contract. It groups slot contracts so checks,
;;       reports, type facts, and proof projections share the same data.
;;       # Examples
;;       (make-poo-flow-object-type-contract
;;        'observability/receipt 'observability 'Receipt slot-contracts '())
;;       # Result
;;       A fixed object type contract record with generated accessors.
;;     %
(defstruct poo-flow-object-type-contract
  (key
   owner
   object-kind
   slots
   metadata)
  transparent: #t)

;; poo-flow-object-type-contract-record
;;   : (-> Symbol Symbol Symbol [PooFlowSlotContract] [Alist] PooFlowObjectTypeContract)
;;   | doc m%
;;       Construct an object-level contract from slot contracts.
;;       # Examples
;;       (poo-flow-object-type-contract-record
;;        'observability/receipt 'observability 'Receipt slot-contracts)
;;       # Result
;;       A structured object contract that can be checked and projected.
;;     %
(def (poo-flow-object-type-contract-record key owner object-kind slots . maybe-metadata)
  (make-poo-flow-object-type-contract
   key
   owner
   object-kind
   slots
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-object-type-contract->alist
;;   : (-> PooFlowObjectTypeContract Alist)
;;   | doc m%
;;       Project an object contract and its slot contracts.
;;       # Examples
;;       (poo-flow-object-type-contract->alist object-contract)
;;       # Result
;;       An alist with key, owner, object kind, slots, and metadata.
;;     %
(def (poo-flow-object-type-contract->alist contract)
  (list
   (cons 'key (poo-flow-object-type-contract-key contract))
   (cons 'owner (poo-flow-object-type-contract-owner contract))
   (cons 'object-kind (poo-flow-object-type-contract-object-kind contract))
   (cons 'slots
         (map poo-flow-slot-contract->alist
              (poo-flow-object-type-contract-slots contract)))
   (cons 'metadata (poo-flow-object-type-contract-metadata contract))))

;; poo-flow-contract-alist?
;;   : (-> PooFlowValue Boolean)
;;   | doc m%
;;       Recognize proper association lists used by projection metadata.
;;       # Examples
;;       (poo-flow-contract-alist? '((kind . graph) (valid? . #t)))
;;       # Result
;;       #t for proper association lists; #f otherwise.
;;     %
(def (poo-flow-contract-alist? value)
  (and (list? value)
       (andmap pair? value)))

;; poo-flow-contract-list-of?
;;   : (-> (-> PooFlowValue Boolean) [PooFlowValue] Boolean)
;;   | doc m%
;;       Recognize proper lists whose elements satisfy a predicate.
;;       # Examples
;;       (poo-flow-contract-list-of? symbol? '(a b c))
;;       # Result
;;       #t when the input is a proper list and every item passes.
;;     %
(def (poo-flow-contract-list-of? predicate values)
  (and (list? values)
       (andmap predicate values)))

;; poo-flow-contract-require!
;;   : (-> Symbol (-> PooFlowValue Boolean) PooFlowValue PooFlowValue)
;;   | doc m%
;;       Enforce a predicate and return the original value.
;;       # Examples
;;       (poo-flow-contract-require! 'receipt.schema string? schema)
;;       # Result
;;       The original value when valid; raises an error when invalid.
;;     %
(def (poo-flow-contract-require! label predicate value)
  (if (predicate value)
    value
    (error "poo-flow contract failed" label value)))

;; poo-flow-contract-check-slot!
;;   : (-> PooFlowSlotContract PooFlowValue PooFlowValue)
;;   | doc m%
;;       Execute one structured slot contract against a candidate value.
;;       # Examples
;;       (poo-flow-contract-check-slot! schema-slot-contract schema)
;;       # Result
;;       The original value when valid; raises with the slot contract key when invalid.
;;     %
(def (poo-flow-contract-check-slot! contract value)
  (poo-flow-contract-require!
   (poo-flow-slot-contract-key contract)
   (poo-flow-slot-contract-predicate contract)
   value))
