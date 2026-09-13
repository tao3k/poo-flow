;;; -*- Gerbil -*-
;;; Boundary: harness-backed field contract validation.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/extensions/poo-object-validation
                 poo-object-field-contract-validation
                 poo-object-contract-validation)
        :poo-flow/src/module-system/object-core/interface
        :poo-flow/src/module-system/object-validation/support/facts
        :poo-flow/src/module-system/projection/syntax)

(export poo-flow-module-field-contract->harness-field
        poo-flow-module-object-harness-validation
        poo-flow-module-object-harness-validation/resolved-fields
        poo-flow-module-object-harness-validation/harness-fields
        poo-flow-module-object-harness-validation/resolved-fields/cache
        poo-flow-module-field-contract-validation
        poo-flow-module-field-contract-validation/harness-field
        poo-flow-module-field-contract-validation/cached
        poo-flow-module-field-contract-validation-valid?
        poo-flow-module-type-validation->alist
        poo-flow-module-field-contract-validation->alist
        field-contract-validations-valid?
        poo-flow-module-object-field-contract-validations
        poo-flow-module-object-field-contract-validations/resolved-fields
        poo-flow-module-object-field-contract-validations/resolved-fields/cache
        poo-flow-module-object-field-contract-validations/harness-fields
        duplicate-identities)

;; : (-> PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract->harness-field field)
  (let ((identity
         (poo-flow-module-field-contract-identity field))
        (value-kind
         (poo-flow-module-value-type-kind
          (poo-flow-module-field-contract-value-type field)))
        (merge
         (poo-flow-module-field-contract-merge field))
        (default
         (poo-flow-module-field-contract-default field))
        (metadata
         (poo-flow-module-field-contract-metadata field)))
    (harness-receipt
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
;; : (-> PooModuleObject POOObject)
(def (poo-flow-module-object-harness-validation object)
  (let* ((resolved-fields
          (poo-flow-module-object-resolved-fields object))
         (direct-fields
          (poo-flow-module-object-fields object)))
    (poo-flow-module-object-harness-validation/resolved-fields
     object
     resolved-fields
     (poo-flow-module-object-validation-source-ref/identities
      object
      (map poo-flow-module-object-identity
           (poo-flow-module-object-inherits object))
      (poo-flow-module-field-identities direct-fields)
      (poo-flow-module-field-identities resolved-fields)))))

;;; Boundary: module object harness validation resolved fields is the policy-
;;; visible edge for module-system, object behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> [PooModuleFieldContract] [PooObjectHarnessField] [PooObjectHarnessField])
(def (poo-flow-module-object-harness-fields/rev resolved-fields fields-rev)
  (if (null? resolved-fields)
    fields-rev
    (poo-flow-module-object-harness-fields/rev
     (cdr resolved-fields)
     (cons (poo-flow-module-field-contract->harness-field
            (car resolved-fields))
           fields-rev))))

;; : (-> [PooModuleFieldContract] [PooObjectHarnessField])
(def (poo-flow-module-object-harness-fields resolved-fields)
  (reverse
   (poo-flow-module-object-harness-fields/rev resolved-fields '())))

;; : (-> PooModuleObject [PooModuleFieldContract] HashTable POOObject)
(def (poo-flow-module-object-harness-validation/resolved-fields object
                                                               resolved-fields
                                                               source-ref)
  (poo-flow-module-object-harness-validation/harness-fields
   object
   (poo-flow-module-object-harness-fields resolved-fields)
   source-ref))

;; : (-> PooModuleObject [HashTable] HashTable POOObject)
(def (poo-flow-module-object-harness-validation/harness-fields object
                                                              harness-fields
                                                              source-ref)
  (poo-flow-validation-value->native
   (poo-object-contract-validation
    (poo-flow-module-object-identity object)
    harness-fields
    source-ref)))

;; : (-> PooModuleObject POOObject POOObject)
(def (poo-flow-module-object-harness-validation-cache-receipt object cached)
  (receipt
   (poo-flow-module-validation-hash-field cached 'kind)
   (poo-flow-module-validation-hash-field cached 'schema)
   (cons 'object (poo-flow-module-object-identity object))
   (poo-flow-module-validation-hash-field cached 'valid)
   (poo-flow-module-validation-hash-field cached 'diagnostics)
   (poo-flow-module-validation-hash-field cached 'checkedSignals)))

;;; Boundary: module object harness validation resolved fields cache is the
;;; policy-visible edge for module-system, object behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> PooModuleObject [PooModuleFieldContract] [HashTable] HashTable HashTable POOObject)
(def (poo-flow-module-object-harness-validation/resolved-fields/cache
      object
      cache-key
      harness-fields
      source-ref
      cache)
  (cond ((hash-get cache cache-key)
         => (lambda (cached)
              (poo-flow-module-object-harness-validation-cache-receipt
               object
               cached)))
        (else
         (let (validation
               (poo-flow-module-object-harness-validation/harness-fields
                object
                harness-fields
                source-ref))
           (if (poo-flow-module-field-contract-validation-valid? validation)
             (hash-put! cache cache-key validation))
           validation))))

;; : (-> PooModuleObject PooModuleFieldContract POOObject)
(def (poo-flow-module-field-contract-validation object field)
  (poo-flow-module-field-contract-validation/harness-field
   object
   (poo-flow-module-field-contract->harness-field field)))

;; : (-> PooModuleObject HashTable POOObject)
(def (poo-flow-module-field-contract-validation/harness-field object
                                                             harness-field)
  (poo-flow-validation-value->native
   (poo-object-field-contract-validation
    (poo-flow-module-object-identity object)
    harness-field
    (poo-flow-module-field-contract-validation-source-ref/values
     object
     (hash-get harness-field 'field)
     (hash-get harness-field 'valueKind)
     (hash-get harness-field 'merge)))))

;; : (-> PooModuleObject PooModuleFieldContract POOObject POOObject)
(def (poo-flow-module-field-contract-validation-cache-receipt object
                                                              field
                                                              cached)
  (receipt
   (poo-flow-module-validation-hash-field cached 'kind)
   (poo-flow-module-validation-hash-field cached 'schema)
   (cons 'object (poo-flow-module-object-identity object))
   (cons 'field (poo-flow-module-field-contract-identity field))
   (cons 'valueKind
         (poo-flow-module-value-type-kind
          (poo-flow-module-field-contract-value-type field)))
   (cons 'merge (poo-flow-module-field-contract-merge field))
   (poo-flow-module-validation-hash-field cached 'valid)
   (poo-flow-module-validation-hash-field cached 'diagnostics)
   (poo-flow-module-validation-hash-field cached 'checkedSignals)
   (poo-flow-module-validation-hash-field cached 'typeValidation)))

;;; Boundary: module field contract validation cached is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject PooModuleFieldContract HashTable POOObject)
(def (poo-flow-module-field-contract-validation/cached object field cache)
  (cond ((hash-get cache field)
         => (lambda (cached)
              (poo-flow-module-field-contract-validation-cache-receipt
               object
               field
               cached)))
        (else
         (let (validation (poo-flow-module-field-contract-validation
                           object
                           field))
           (if (poo-flow-module-field-contract-validation-valid? validation)
             (hash-put! cache field validation))
           validation))))

;; : (-> POOObject Boolean)
(def (poo-flow-module-field-contract-validation-valid? validation)
  (poo-flow-validation-ref validation 'valid))

;; : (-> ValidationValue Symbol Pair)
(def (poo-flow-module-validation-hash-field validation key)
  (cons key (poo-flow-validation-ref validation key)))

;;; Boundary: module type validation to alist is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> POOObject Alist)
(defpoo-module-final-projection
  poo-flow-module-type-validation->alist (validation)
  (bindings ())
  (fields ((kind (poo-flow-validation-ref validation 'kind))
           (schema (poo-flow-validation-ref validation 'schema))
           (valueKind (poo-flow-validation-ref validation 'valueKind))
           (typeDisplay (poo-flow-validation-ref validation 'typeDisplay))
           (valid (poo-flow-validation-ref validation 'valid))
           (diagnostics
            (poo-flow-validation-ref validation 'diagnostics)))))

;;; User-facing projection: preserve the upstream validation vocabulary while
;;; making field-level receipts easy for doctors and agents to scan.
;; : (-> POOObject Alist)
(defpoo-module-final-projection
  poo-flow-module-field-contract-validation->alist (validation)
  (bindings ((type-validation
               (poo-flow-module-type-validation->alist
               (poo-flow-validation-ref validation 'typeValidation)))))
  (fields ((kind (poo-flow-validation-ref validation 'kind))
           (schema (poo-flow-validation-ref validation 'schema))
           (object (poo-flow-validation-ref validation 'object))
           (field (poo-flow-validation-ref validation 'field))
           (valueKind (poo-flow-validation-ref validation 'valueKind))
           (merge (poo-flow-validation-ref validation 'merge))
           (valid (poo-flow-validation-ref validation 'valid))
           (diagnostics
            (poo-flow-validation-ref validation 'diagnostics))
           (checkedSignals
            (poo-flow-validation-ref validation 'checkedSignals))
           (type-validation type-validation))))

;; field-contract-validations-valid?
;;   : (-> (List POOObject) Boolean)
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
;; : (-> PooModuleObject [POOObject])
(def (poo-flow-module-object-field-contract-validations object)
  (poo-flow-module-object-field-contract-validations/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)))

;;; Boundary: module object field contract validations harness fields is the
;;; policy-visible edge for module-system, object behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> PooModuleObject [PooModuleFieldContract] [POOObject])
(def (poo-flow-module-object-field-contract-validations/resolved-fields object
                                                                        resolved-fields)
  (poo-flow-module-object-field-contract-validations/harness-fields
   object
   (poo-flow-module-object-harness-fields resolved-fields)))

;;; Boundary: module object field contract validations resolved fields cache is
;;; the policy-visible edge for module-system, object behavior, keeping
;;; validation, lookup, or projection responsibilities centralized for callers.
;; : (-> PooModuleObject [PooModuleFieldContract] HashTable [POOObject] [POOObject])
(def (poo-flow-module-object-field-contract-validations/resolved-fields/cache/rev
      object
      resolved-fields
      cache
      validations-rev)
  (if (null? resolved-fields)
    validations-rev
    (poo-flow-module-object-field-contract-validations/resolved-fields/cache/rev
     object
     (cdr resolved-fields)
     cache
     (cons (poo-flow-module-field-contract-validation/cached
            object
            (car resolved-fields)
            cache)
           validations-rev))))

;; : (-> PooModuleObject [PooModuleFieldContract] HashTable [POOObject])
(def (poo-flow-module-object-field-contract-validations/resolved-fields/cache
      object
      resolved-fields
      cache)
  (reverse
   (poo-flow-module-object-field-contract-validations/resolved-fields/cache/rev
    object
    resolved-fields
    cache
    '())))

;;; Boundary: module object field contract validations harness fields is the
;;; policy-visible edge for module-system, object behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> PooModuleObject [HashTable] [POOObject] [POOObject])
(def (poo-flow-module-object-field-contract-validations/harness-fields/rev
      object
      harness-fields
      validations-rev)
  (if (null? harness-fields)
    validations-rev
    (poo-flow-module-object-field-contract-validations/harness-fields/rev
     object
     (cdr harness-fields)
     (cons (poo-flow-module-field-contract-validation/harness-field
            object
            (car harness-fields))
           validations-rev))))

;; : (-> PooModuleObject [HashTable] [POOObject])
(def (poo-flow-module-object-field-contract-validations/harness-fields object
                                                                      harness-fields)
  (reverse
   (poo-flow-module-object-field-contract-validations/harness-fields/rev
    object
    harness-fields
    '())))

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
(def (duplicate-identities/rev identities seen duplicates result-rev)
  (cond
   ((null? identities) result-rev)
   ((hash-key? seen (car identities))
    (if (hash-key? duplicates (car identities))
      (duplicate-identities/rev (cdr identities) seen duplicates result-rev)
      (begin
        (hash-put! duplicates (car identities) #t)
        (duplicate-identities/rev
         (cdr identities)
         seen
         duplicates
         (cons (car identities) result-rev)))))
   (else
    (hash-put! seen (car identities) #t)
    (duplicate-identities/rev (cdr identities) seen duplicates result-rev))))

;; : (-> [Symbol] [Symbol])
(def (duplicate-identities identities)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (duplicate-identities/rev identities seen duplicates '()))))

;;; Object diagnostics stay intentionally narrow: only object-local metadata and
;;; C3-resolved identity collisions are checked here.
;; : (-> PooModuleObject [POOObject])
