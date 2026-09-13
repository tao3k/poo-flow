;;; -*- Gerbil -*-
;;; Boundary: object-level diagnostics and validation receipts.

(import :gerbil/gambit
        (only-in :clan/poo/object object?)
        :poo-flow/src/module-system/object-core/interface
        :poo-flow/src/module-system/object-validation/support/facts
        :poo-flow/src/module-system/object-validation/support/harness
        :poo-flow/src/module-system/projection/syntax)

(export poo-flow-module-object-validation-phases
        object-diagnostics
        object-diagnostics/resolved-fields
        object-diagnostics/resolved-identities
        poo-flow-module-object-validation
        poo-flow-module-object-validation/field-cache
        poo-flow-module-object-validation/catalog-caches
        poo-flow-module-object-validation?
        poo-flow-module-object-validation-valid?
        poo-flow-module-object-validation-diagnostics
        poo-flow-module-invalid-field-identities
        poo-flow-module-object-validation->alist)

;;; Boundary: module object validation phases is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleObject POOObject [POOObject] [POOObject] [POOObject])
(def (poo-flow-module-object-validation-phases object
                                               harness-validation
                                               field-contract-validations
                                               local-diagnostics)
  (poo-flow-module-object-validation-phases/source-ref
   object
   (poo-flow-module-object-validation-source-ref object)
   harness-validation
   field-contract-validations
   local-diagnostics))

;; : (-> PooModuleObject HashTable POOObject [POOObject] [POOObject] [POOObject])
(def (poo-flow-module-object-validation-phases/source-ref object
                                                          source-ref
                                                          harness-validation
                                                          field-contract-validations
                                                          local-diagnostics)
  (list
   (receipt
    (cons 'phase 'source-reference)
    (cons 'status 'ok)
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'detail (poo-flow-validation-value->native source-ref)))
   (receipt
    (cons 'phase 'harness-object-contract)
    (cons 'status
          (if (poo-flow-validation-ref harness-validation 'valid) 'ok 'invalid))
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'diagnostic-count
          (length (poo-flow-validation-ref harness-validation 'diagnostics))))
   (receipt
    (cons 'phase 'field-contracts)
    (cons 'status
          (if (field-contract-validations-valid?
               field-contract-validations)
            'ok
            'invalid))
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'field-count (length field-contract-validations))
    (cons 'invalid-fields
          (poo-flow-module-invalid-field-identities
           field-contract-validations)))
   (receipt
    (cons 'phase 'local-object-diagnostics)
    (cons 'status (if (null? local-diagnostics) 'ok 'invalid))
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'diagnostic-count (length local-diagnostics)))))

;;; Boundary: object diagnostics resolved fields is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleObject [POOObject])
(def (object-diagnostics object)
  (object-diagnostics/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)))

;;; Boundary: object diagnostics resolved identities is the policy-visible edge
;;; for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject [PooModuleFieldContract] [POOObject])
(def (object-diagnostics/resolved-fields object resolved-fields)
  (object-diagnostics/resolved-identities
   object
   (poo-flow-module-field-identities resolved-fields)))

;;; Boundary: object diagnostics resolved identities is the policy-visible edge
;;; for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject [Symbol] [POOObject])
(def (object-diagnostics/resolved-identities object resolved-identities)
  (let (duplicates (duplicate-identities resolved-identities))
    (append
     (if (metadata-list? (poo-flow-module-object-metadata object))
       '()
       (list
        (diagnostic
         'object-metadata-not-list
         "module object metadata must be an association list"
         (poo-flow-module-object-identity object)
         (poo-flow-module-object-metadata object))))
     (if (null? duplicates)
       '()
       (list
        (diagnostic
         'duplicate-resolved-field
         "module object resolved fields contain duplicate identities"
         (poo-flow-module-object-identity object)
         duplicates))))))

;;; The public receipt joins upstream harness diagnostics with the few
;;; downstream catalog gates that the generic harness cannot know about.
;; : (-> PooModuleObject POOObject)
(def (poo-flow-module-object-validation object)
  (poo-flow-module-object-validation/field-cache object #f))

;;; Boundary: module object validation catalog caches is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject MaybeHashTable POOObject)
(def (poo-flow-module-object-validation/field-cache object field-cache)
  (poo-flow-module-object-validation/catalog-caches object
                                                    field-cache
                                                    #f
                                                    #f
                                                    #f))

;; : (-> HashTable Value (-> Value) Value)
(def (poo-flow-module-object-validation-cache-ref cache key thunk)
  (cond ((and cache (hash-get cache key)) => values)
        (else
         (let (value (thunk))
           (if cache
             (hash-put! cache key value)
             (void))
           value))))

;; : (-> PooModuleObject [PooModuleFieldContract] [POOObject])
(def (poo-flow-module-object-validation-field-origins/rev
      object
      resolved-fields
      providers
      origins-rev)
  (if (null? resolved-fields)
    origins-rev
    (poo-flow-module-object-validation-field-origins/rev
     object
     (cdr resolved-fields)
     providers
     (cons (poo-flow-module-object-field-origin/index
            object
            (car resolved-fields)
            providers)
           origins-rev))))

;; : (-> PooModuleObject [PooModuleFieldContract] [POOObject])
(def (poo-flow-module-object-validation-field-origins object resolved-fields)
  (let (providers
        (poo-flow-module-object-field-provider-index object))
    (reverse
     (poo-flow-module-object-validation-field-origins/rev
      object
      resolved-fields
      providers
      '()))))

;; : (-> PooModuleObject [Symbol] [Symbol] [Symbol] [PooModuleFieldContract] MaybeHashTable [POOObject])
(def (poo-flow-module-object-validation-field-origins/cache object
                                                            inherit-identities
                                                            direct-field-identities
                                                            resolved-field-identities
                                                            resolved-fields
                                                            cache)
  (let (cache-key
         (and cache
              (null? direct-field-identities)
              (list inherit-identities resolved-field-identities)))
    (if cache-key
      (poo-flow-module-object-validation-cache-ref
       cache
       cache-key
       (lambda ()
         (poo-flow-module-object-validation-field-origins
          object
          resolved-fields)))
      (poo-flow-module-object-validation-field-origins
       object
       resolved-fields))))

;;; Boundary: module object validation catalog caches is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject MaybeHashTable MaybeHashTable MaybeHashTable MaybeHashTable POOObject)
(def (poo-flow-module-object-validation/catalog-caches object
                                                       field-cache
                                                       harness-cache
                                                       harness-fields-cache
                                                       field-origins-cache)
  (let* ((inherits
          (poo-flow-module-object-inherits object))
         (direct-fields
          (poo-flow-module-object-fields object))
         (resolved-fields
          (poo-flow-module-object-resolved-fields object))
         (inherit-identities
          (map poo-flow-module-object-identity inherits))
         (direct-field-identities
          (poo-flow-module-field-identities direct-fields))
         (resolved-field-identities
          (poo-flow-module-field-identities resolved-fields))
         (harness-fields
          (poo-flow-module-object-validation-cache-ref
           harness-fields-cache
           resolved-field-identities
           (lambda ()
             (map poo-flow-module-field-contract->harness-field
                  resolved-fields))))
         (source-ref
          (poo-flow-module-object-validation-source-ref/identities
           object
           inherit-identities
           direct-field-identities
           resolved-field-identities))
         (harness-validation
         (if harness-cache
            (poo-flow-module-object-harness-validation/resolved-fields/cache
             object
             resolved-field-identities
             harness-fields
             source-ref
             harness-cache)
            (poo-flow-module-object-harness-validation/harness-fields
             object
             harness-fields
             source-ref)))
         (field-contract-validations
          (if field-cache
            (poo-flow-module-object-field-contract-validations/resolved-fields/cache
             object
             resolved-fields
             field-cache)
            (poo-flow-module-object-field-contract-validations/harness-fields
             object
             harness-fields)))
         (local-diagnostics
          (object-diagnostics/resolved-identities
           object
           resolved-field-identities))
         (field-origins
          (poo-flow-module-object-validation-field-origins/cache
           object
           inherit-identities
           direct-field-identities
           resolved-field-identities
           resolved-fields
           field-origins-cache))
         (diagnostics
          (append local-diagnostics
                  (poo-flow-validation-ref harness-validation 'diagnostics)))
         (validation-phases
          (poo-flow-module-object-validation-phases/source-ref
           object
           source-ref
           harness-validation
           field-contract-validations
           local-diagnostics))
         (valid? (and (null? diagnostics)
                      (poo-flow-validation-ref harness-validation 'valid)
                      (field-contract-validations-valid?
                       field-contract-validations))))
    (receipt
     (cons 'kind poo-flow-module-object-validation-kind)
     (cons 'schema poo-flow-module-object-validation-schema)
     (cons 'object (poo-flow-module-object-identity object))
     (cons 'inherits inherit-identities)
     (cons 'inheritance-chain
           (poo-flow-module-object-inheritance-chain object))
     (cons 'inherit-count
           (length inherits))
     (cons 'direct-field-count
           (length direct-fields))
     (cons 'direct-field-identities
           direct-field-identities)
     (cons 'resolved-field-count
           (length resolved-fields))
     (cons 'resolved-field-identities
           resolved-field-identities)
     (cons 'field-origins
           field-origins)
     (cons 'metadata (poo-flow-module-object-metadata object))
     (cons 'sourceRef (poo-flow-validation-value->native source-ref))
     (cons 'harnessValidation harness-validation)
     (cons 'fieldContractValidations field-contract-validations)
     (cons 'validationPhases validation-phases)
     (cons 'valid valid?)
     (cons 'diagnostics diagnostics)
     (cons 'checkedSignals
           '(upstream-poo-object-contract-validation
             upstream-poo-object-field-contract-validation
             object-metadata-shape
             resolved-field-identity
             object-contract-debug-receipt
             object-field-origin-contract
             object-inheritance-chain-contract
             object-validation-phase-contract)))))

;; : (-> PooFlowModuleObjectValidationReceipt Boolean)
(def (poo-flow-module-object-validation? value)
  (and (object? value)
       (equal? (poo-flow-validation-ref value 'kind)
               poo-flow-module-object-validation-kind)
       (equal? (poo-flow-validation-ref value 'schema)
               poo-flow-module-object-validation-schema)))

;; : (-> POOObject Boolean)
(def (poo-flow-module-object-validation-valid? validation)
  (poo-flow-validation-ref validation 'valid))

;; : (-> POOObject [POOObject])
(def (poo-flow-module-object-validation-diagnostics validation)
  (poo-flow-validation-ref validation 'diagnostics))

;;; Boundary: module invalid field identities is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [POOObject] [Symbol] [Symbol])
(def (poo-flow-module-invalid-field-identities/rev field-validations
                                                   identities-rev)
  (cond
   ((null? field-validations) identities-rev)
   ((poo-flow-module-field-contract-validation-valid?
     (car field-validations))
    (poo-flow-module-invalid-field-identities/rev
     (cdr field-validations)
     identities-rev))
   (else
    (let (identity
          (poo-flow-validation-ref (car field-validations) 'field))
      (poo-flow-module-invalid-field-identities/rev
       (cdr field-validations)
       (if identity
         (cons identity identities-rev)
         identities-rev))))))

;; : (-> [POOObject] [Symbol])
(def (poo-flow-module-invalid-field-identities field-validations)
  (reverse
   (poo-flow-module-invalid-field-identities/rev
    field-validations
    '())))

;;; Public projection boundary: callers get stable alists without depending on
;;; hash-table nesting or harness-private source receipt shapes.
;; : (-> POOObject Alist)
(defpoo-module-final-projection
  poo-flow-module-object-validation->alist (validation)
  (bindings ((field-validations
              (poo-flow-validation-ref validation 'fieldContractValidations))))
  (fields ((kind (poo-flow-validation-ref validation 'kind))
           (schema (poo-flow-validation-ref validation 'schema))
           (object (poo-flow-validation-ref validation 'object))
           (inherits (poo-flow-validation-ref validation 'inherits))
           (inheritance-chain
            (poo-flow-validation-ref validation 'inheritance-chain))
           (inherit-count (poo-flow-validation-ref validation 'inherit-count))
           (direct-field-count
            (poo-flow-validation-ref validation 'direct-field-count))
           (direct-field-identities
            (poo-flow-validation-ref validation 'direct-field-identities))
           (resolved-field-count
            (poo-flow-validation-ref validation 'resolved-field-count))
           (resolved-field-identities
            (poo-flow-validation-ref validation 'resolved-field-identities))
           (field-origins (poo-flow-validation-ref validation 'field-origins))
           (metadata (poo-flow-validation-ref validation 'metadata))
           (valid (poo-flow-validation-ref validation 'valid))
           (diagnostics (poo-flow-validation-ref validation 'diagnostics))
           (checkedSignals
            (poo-flow-validation-ref validation 'checkedSignals))
           (validationPhases
            (poo-flow-validation-ref validation 'validationPhases))
           (diagnostic-count
            (length (poo-flow-validation-ref validation 'diagnostics)))
           (field-count (length field-validations))
           (invalid-fields
            (poo-flow-module-invalid-field-identities field-validations))
           (field-validations
            (map poo-flow-module-field-contract-validation->alist
                 field-validations)))))

;;; Catalog validation stays a pure map so callers can decide whether to inspect
;;; receipts or escalate through the require! gates.
;; : (-> [PooModuleObject] [POOObject])
