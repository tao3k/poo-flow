;;; -*- Gerbil -*-
;;; Boundary: harness-backed field contract validation.

(import :gerbil/gambit
        (only-in :gslph/src/extensions/facade
                 poo-object-field-contract-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        (only-in :std/sugar filter-map foldl)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation-support/facts)

(export poo-flow-module-field-contract->harness-field
        poo-flow-module-object-harness-validation
        poo-flow-module-object-harness-validation/resolved-fields
        poo-flow-module-object-harness-validation/harness-fields
        poo-flow-module-field-contract-validation
        poo-flow-module-field-contract-validation/harness-field
        poo-flow-module-field-contract-validation-valid?
        poo-flow-module-type-validation->alist
        poo-flow-module-field-contract-validation->alist
        field-contract-validations-valid?
        poo-flow-module-object-field-contract-validations
        poo-flow-module-object-field-contract-validations/resolved-fields
        poo-flow-module-object-field-contract-validations/harness-fields
        duplicate-identities)

;; : (-> PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract->harness-field field)
  (let ((identity
         (poo-flow-module-field-contract-identity field))
        (value-kind
         (poo-flow-module-field-contract-value-kind field))
        (merge
         (poo-flow-module-field-contract-merge field))
        (default
         (poo-flow-module-field-contract-default field))
        (metadata
         (poo-flow-module-field-contract-metadata field)))
    (receipt
     (cons 'field identity)
     (cons 'identity identity)
     (cons 'valueKind value-kind)
     (cons 'value-kind value-kind)
     (cons 'merge merge)
     (cons 'default default)
     (cons 'metadata metadata))))

;;; Harness validation is report-only here. The Gerbil language-project harness
;;; owns field type/merge/default/metadata checks upstream; poo-flow supplies the
;;; object-aware source reference and keeps only module-domain catalog gates local.
;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-harness-validation object)
  (poo-flow-module-object-harness-validation/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)
   (poo-flow-module-object-validation-source-ref object)))

;; : (-> PooModuleObject [PooModuleFieldContract] HashTable HashTable)
(def (poo-flow-module-object-harness-validation/resolved-fields object
                                                               resolved-fields
                                                               source-ref)
  (poo-flow-module-object-harness-validation/harness-fields
   object
   (map poo-flow-module-field-contract->harness-field
        resolved-fields)
   source-ref))

;; : (-> PooModuleObject [HashTable] HashTable HashTable)
(def (poo-flow-module-object-harness-validation/harness-fields object
                                                              harness-fields
                                                              source-ref)
  (poo-object-contract-validation
   (poo-flow-module-object-identity object)
   harness-fields
   source-ref))

;; : (-> PooModuleObject PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract-validation object field)
  (poo-flow-module-field-contract-validation/harness-field
   object
   (poo-flow-module-field-contract->harness-field field)))

;; : (-> PooModuleObject HashTable HashTable)
(def (poo-flow-module-field-contract-validation/harness-field object
                                                             harness-field)
  (poo-object-field-contract-validation
   (poo-flow-module-object-identity object)
   harness-field
   (poo-flow-module-field-contract-validation-source-ref/values
    object
    (hash-get harness-field 'field)
    (hash-get harness-field 'valueKind)
    (hash-get harness-field 'merge))))

;; : (-> HashTable Boolean)
(def (poo-flow-module-field-contract-validation-valid? validation)
  (poo-object-validation-valid? validation))

;; : (-> HashTable Symbol Pair)
(def (poo-flow-module-validation-hash-field validation key)
  (cons key (hash-get validation key)))

;; : (-> HashTable [Symbol] Alist)
(def (poo-flow-module-validation-hash-fields validation keys)
  (map (lambda (key)
         (poo-flow-module-validation-hash-field validation key))
       keys))

;; : (-> HashTable Alist)
(def (poo-flow-module-type-validation->alist validation)
  (if (hash-table? validation)
    (poo-flow-module-validation-hash-fields
     validation
     '(kind schema valueKind typeDisplay valid diagnostics))
    '()))

;;; User-facing projection: preserve the upstream validation vocabulary while
;;; making field-level receipts easy for doctors and agents to scan.
;; : (-> HashTable Alist)
(def (poo-flow-module-field-contract-validation->alist validation)
  (append
   (poo-flow-module-validation-hash-fields
    validation
    '(kind schema object field valueKind merge valid diagnostics checkedSignals))
   (list
    (cons 'type-validation
          (poo-flow-module-type-validation->alist
           (hash-get validation 'typeValidation))))))

;; field-contract-validations-valid?
;;   : (-> (List HashTable) Boolean)
;;   | doc m%
;;       `field-contract-validations-valid?` reduces upstream field validation
;;       receipts without interpreting their diagnostics in poo-flow.
;;
;;       # Examples
;;
;;       ```scheme
;;       (field-contract-validations-valid? validations)
;;       ;; => #t
;;       ```
;;     %
(def (field-contract-validations-valid? validations)
  (andmap poo-flow-module-field-contract-validation-valid? validations))

;;; Higher-order boundary: each resolved C3 field is validated independently so
;;; upstream diagnostics keep the concrete field identity.
;; : (-> PooModuleObject [HashTable])
(def (poo-flow-module-object-field-contract-validations object)
  (poo-flow-module-object-field-contract-validations/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)))

;; : (-> PooModuleObject [PooModuleFieldContract] [HashTable])
(def (poo-flow-module-object-field-contract-validations/resolved-fields object
                                                                        resolved-fields)
  (poo-flow-module-object-field-contract-validations/harness-fields
   object
   (map poo-flow-module-field-contract->harness-field
        resolved-fields)))

;; : (-> PooModuleObject [HashTable] [HashTable])
(def (poo-flow-module-object-field-contract-validations/harness-fields object
                                                                      harness-fields)
  (map (lambda (harness-field)
         (poo-flow-module-field-contract-validation/harness-field
          object
          harness-field))
       harness-fields))

;; duplicate-identities
;;   : (-> (List Symbol) (List Symbol))
;;   | doc m%
;;       `duplicate-identities` finds duplicated resolved field identities after
;;       gerbil-poo C3 inheritance has projected the object field list.
;;
;;       # Examples
;;
;;       ```scheme
;;       (duplicate-identities '(a b a c b))
;;       ;; => (a b)
;;       ```
;;     %
(def (duplicate-identities identities)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (foldl (lambda (identity result)
              (if (hash-key? seen identity)
                (if (hash-key? duplicates identity)
                  result
                  (begin
                    (hash-put! duplicates identity #t)
                    (cons identity result)))
                (begin
                  (hash-put! seen identity #t)
                  result)))
            '()
            identities))))

;;; Object diagnostics stay intentionally narrow: only object-local metadata and
;;; C3-resolved identity collisions are checked here.
;; : (-> PooModuleObject [HashTable])
