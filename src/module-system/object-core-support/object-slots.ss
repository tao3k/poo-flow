(import :gerbil/gambit
        (only-in :clan/poo/object
                 $constant-slot-spec
                 $constant-slot-spec-value
                 $constant-slot-spec?
                 .ref
                 object-slots)
        :poo-flow/src/module-system/object-core-support/contracts)

(export poo-flow-module-object-constant-slot
        +poo-flow-module-object-slot-missing+
        poo-flow-module-object-constant-slot-ref/default
        poo-flow-module-object-constant-slot-ref
        poo-flow-module-object-field-identity
        poo-flow-module-object-field-index
        poo-flow-module-object-identity-hash-ref
        poo-flow-module-object-field-set)

;; Boundary: slot lookup and field indexing helpers stay independent from
;; object inheritance resolution, which remains in object.ss.
;; : (-> Symbol Any ConstantSlotSpec)
(def (poo-flow-module-object-constant-slot key value)
  (cons key ($constant-slot-spec value)))

;; : MissingSlotSentinel
(def +poo-flow-module-object-slot-missing+
  (list 'poo-flow-module-object-slot-missing))

;; : (-> POOObject Symbol Any Any)
;; | doc Reads a constant POO slot without forcing dynamic slot fallback.
;; # Examples
;; (poo-flow-module-object-constant-slot-ref/default object 'name #f) => value
;; result: Any
(def (poo-flow-module-object-constant-slot-ref/default object key default)
  (let loop ((slots (object-slots object)))
    (cond
     ((null? slots) default)
     ((eq? (caar slots) key)
      (let (spec (cdar slots))
        (if ($constant-slot-spec? spec)
          ($constant-slot-spec-value spec)
          default)))
     (else (loop (cdr slots))))))

;; : (-> POOObject Symbol Any)
(def (poo-flow-module-object-constant-slot-ref object key)
  (let (value (poo-flow-module-object-constant-slot-ref/default
               object
               key
               +poo-flow-module-object-slot-missing+))
    (if (eq? value +poo-flow-module-object-slot-missing+)
      (.ref object key)
      value)))

;; : (-> FieldContractLike Symbol)
(def (poo-flow-module-object-field-identity field)
  (if (poo-flow-module-field-contract? field)
    (poo-flow-module-field-contract-identity field)
    field))

;; : (-> [FieldContractLike] HashTable)
(def (poo-flow-module-object-field-index fields)
  (let (index (make-hash-table))
    (for-each
     (lambda (field)
       (let (identity (poo-flow-module-object-field-identity field))
         (if (poo-flow-module-object-identity-hash-ref index identity)
           index
           (hash-put! index identity field))))
     fields)
    index))

;; : (-> HashTable Symbol Any)
(def (poo-flow-module-object-identity-hash-ref table identity)
  (hash-get table identity))

;; : (-> [FieldContractLike] FieldContractLike [FieldContractLike])
(def (poo-flow-module-object-field-set fields field)
  (let (field-identity (poo-flow-module-object-field-identity field))
    (cond ((null? fields) (list field))
          ((equal? (poo-flow-module-object-field-identity (car fields))
                   field-identity)
           (cons field (cdr fields)))
          (else
           (cons (car fields)
                 (poo-flow-module-object-field-set (cdr fields) field))))))
