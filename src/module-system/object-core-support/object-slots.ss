;;; Boundary: constant-slot lookup and field indexing for POO object support;
;;; inheritance resolution remains owned by object.ss.
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
;; : (-> Symbol Object ConstantSlotSpec)
(def (poo-flow-module-object-constant-slot key value)
  (let (spec ($constant-slot-spec value))
    `(,key . ,spec)))

;; : MissingSlotSentinel
(def +poo-flow-module-object-slot-missing+
  (list 'poo-flow-module-object-slot-missing))

;; poo-flow-module-object-constant-slot-ref/default
;;   : (-> POOObject Symbol Object Object)
;;   | doc m%
;;       Read a constant POO slot without forcing dynamic slot fallback.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-object-constant-slot-ref/default object 'name #f)
;;       ;; => the constant value, or #f
;;       ```
;;     %
(def (poo-flow-module-object-constant-slot-ref/default object key default)
  (match (assq key (object-slots object))
    (#f default)
    ([_ . spec]
     (if ($constant-slot-spec? spec)
       ($constant-slot-spec-value spec)
       default))))

;; : (-> POOObject Symbol Object)
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

;; : (-> HashTable Symbol Object)
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
