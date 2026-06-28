;;; -*- Gerbil -*-
;;; Boundary: object-level diagnostics and validation receipts.

(import :gerbil/gambit
        (only-in :gslph/src/extensions/facade
                 poo-object-field-contract-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        (only-in :std/sugar filter-map foldl)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation-support/facts
        :poo-flow/src/module-system/object-validation-support/harness)

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
;; : (-> PooModuleObject HashTable [HashTable] [HashTable] [HashTable])
(def (poo-flow-module-object-validation-phases object
                                               harness-validation
                                               field-contract-validations
                                               local-diagnostics)
  (list
   (receipt
    (cons 'phase 'source-reference)
    (cons 'status 'ok)
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'detail
          (poo-flow-module-object-validation-source-ref object)))
   (receipt
    (cons 'phase 'harness-object-contract)
    (cons 'status
          (if (poo-object-validation-valid? harness-validation) 'ok 'invalid))
    (cons 'owner (poo-flow-module-object-identity object))
    (cons 'diagnostic-count
          (length (hash-get harness-validation 'diagnostics))))
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
;; : (-> PooModuleObject [HashTable])
(def (object-diagnostics object)
  (object-diagnostics/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)))

;;; Boundary: object diagnostics resolved identities is the policy-visible edge
;;; for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject [PooModuleFieldContract] [HashTable])
(def (object-diagnostics/resolved-fields object resolved-fields)
  (object-diagnostics/resolved-identities
   object
   (map poo-flow-module-field-contract-identity resolved-fields)))

;;; Boundary: object diagnostics resolved identities is the policy-visible edge
;;; for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject [Symbol] [HashTable])
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
;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-validation object)
  (poo-flow-module-object-validation/field-cache object #f))

;;; Boundary: module object validation catalog caches is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject MaybeHashTable HashTable)
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

;; : (-> PooModuleObject [Symbol] [Symbol] [Symbol] [PooModuleFieldContract] MaybeHashTable [Alist])
(def (poo-flow-module-object-validation-field-origins/cache object
                                                            inherit-identities
                                                            direct-field-identities
                                                            resolved-field-identities
                                                            resolved-fields
                                                            cache)
  (let ((providers
         (poo-flow-module-object-field-provider-index object))
        (cache-key
         (and cache
              (null? direct-field-identities)
              (list inherit-identities resolved-field-identities))))
    (poo-flow-module-object-validation-cache-ref
     cache
     cache-key
     (lambda ()
       (map (lambda (field)
              (poo-flow-module-object-field-origin/index
               object field providers))
            resolved-fields)))))

;;; Boundary: module object validation catalog caches is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleObject MaybeHashTable MaybeHashTable MaybeHashTable MaybeHashTable HashTable)
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
                  (hash-get harness-validation 'diagnostics)))
         (validation-phases
          (poo-flow-module-object-validation-phases
           object
           harness-validation
           field-contract-validations
           local-diagnostics))
         (valid? (and (null? diagnostics)
                      (poo-object-validation-valid? harness-validation)
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
     (cons 'sourceRef source-ref)
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
  (and (hash-table? value)
       (equal? (hash-get value 'kind)
               poo-flow-module-object-validation-kind)
       (equal? (hash-get value 'schema)
               poo-flow-module-object-validation-schema)))

;; : (-> HashTable Boolean)
(def (poo-flow-module-object-validation-valid? validation)
  (hash-get validation 'valid))

;; : (-> HashTable [HashTable])
(def (poo-flow-module-object-validation-diagnostics validation)
  (hash-get validation 'diagnostics))

;;; Boundary: module invalid field identities is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [HashTable] [Symbol])
(def (poo-flow-module-invalid-field-identities field-validations)
  (filter-map
   (lambda (validation)
     (and (not (poo-flow-module-field-contract-validation-valid? validation))
          (hash-get validation 'field)))
   field-validations))

;; : (-> HashTable Symbol Pair)
(def (poo-flow-module-object-validation-field validation key)
  (cons key (hash-get validation key)))

;;; Boundary: module object validation fields is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> HashTable [Symbol] Alist)
(def (poo-flow-module-object-validation-fields validation keys)
  (map (lambda (key)
         (poo-flow-module-object-validation-field validation key))
       keys))

;;; Public projection boundary: callers get stable alists without depending on
;;; hash-table nesting or harness-private source receipt shapes.
;; : (-> HashTable Alist)
(def (poo-flow-module-object-validation->alist validation)
  (let (field-validations
        (hash-get validation 'fieldContractValidations))
    (append
     (poo-flow-module-object-validation-fields
      validation
      '(kind schema object inherits inheritance-chain inherit-count
             direct-field-count direct-field-identities
             resolved-field-count resolved-field-identities field-origins
             metadata valid diagnostics checkedSignals validationPhases))
     (list
      (cons 'diagnostic-count
            (length (hash-get validation 'diagnostics)))
      (cons 'field-count (length field-validations))
      (cons 'invalid-fields
            (poo-flow-module-invalid-field-identities field-validations))
      (cons 'field-validations
            (map poo-flow-module-field-contract-validation->alist
                 field-validations))))))

;;; Catalog validation stays a pure map so callers can decide whether to inspect
;;; receipts or escalate through the require! gates.
;; : (-> [PooModuleObject] [HashTable])
