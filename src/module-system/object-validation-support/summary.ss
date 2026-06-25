;;; -*- Gerbil -*-
;;; Boundary: object validation catalog summaries and require gates.

(import :gerbil/gambit
        (only-in :gslph/src/extensions/facade
                 poo-object-field-contract-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        (only-in :std/sugar filter-map foldl)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation-support/facts
        :poo-flow/src/module-system/object-validation-support/harness
        :poo-flow/src/module-system/object-validation-support/object)

(export poo-flow-module-objects-validation
        poo-flow-module-objects-validation->alist
        poo-flow-module-invalid-object-identities
        poo-flow-module-validation-values
        poo-flow-module-objects-validation-summary
        poo-flow-require-module-object-validation!
        poo-flow-require-module-objects-validation!)

;; : (-> [PooModuleObject] [HashTable])
(def (poo-flow-module-objects-validation objects)
  (map poo-flow-module-object-validation objects))

;;; Validation receipts stay list-shaped for callers that serialize reports;
;;; the hash-table detail remains private to each object validation pass.
;; : (-> [HashTable] [Alist])
(def (poo-flow-module-objects-validation->alist validations)
  (map poo-flow-module-object-validation->alist validations))

;; : (-> [HashTable] [Symbol])
(def (poo-flow-module-invalid-object-identities validations)
  (filter-map
   (lambda (validation)
     (and (not (poo-flow-module-object-validation-valid? validation))
          (hash-get validation 'object)))
   validations))

;; : (-> [HashTable] Symbol [Value])
(def (poo-flow-module-validation-values validations key)
  (map (lambda (validation) (hash-get validation key)) validations))

;; poo-flow-module-objects-validation-summary
;;   : (-> [HashTable] HashTable)
;;   | doc m%
;;       `poo-flow-module-objects-validation-summary` projects catalog-level
;;       validation facts without rewalking module objects or executing runtime
;;       descriptors.
;;     %
(def (poo-flow-module-objects-validation-summary validations)
  (let ((invalid-objects
         (poo-flow-module-invalid-object-identities validations)))
    (receipt
     (cons 'kind "poo-flow-module-objects-validation-summary")
     (cons 'schema poo-flow-module-object-validation-schema)
     (cons 'object-count (length validations))
     (cons 'object-identities
           (poo-flow-module-validation-values validations 'object))
     (cons 'inheritance-chains
           (poo-flow-module-validation-values validations 'inheritance-chain))
     (cons 'direct-field-counts
           (poo-flow-module-validation-values validations 'direct-field-count))
     (cons 'direct-field-identities
           (poo-flow-module-validation-values validations 'direct-field-identities))
     (cons 'resolved-field-counts
           (poo-flow-module-validation-values validations 'resolved-field-count))
     (cons 'resolved-field-identities
           (poo-flow-module-validation-values validations 'resolved-field-identities))
     (cons 'field-origins
           (poo-flow-module-validation-values validations 'field-origins))
     (cons 'inheritance-counts
           (poo-flow-module-validation-values validations 'inherit-count))
     (cons 'validation-phases
           (poo-flow-module-validation-values validations 'validationPhases))
     (cons 'invalid-count (length invalid-objects))
     (cons 'invalid-objects invalid-objects)
     (cons 'valid (null? invalid-objects))
     (cons 'checkedSignals
           '(object-catalog-validation-contract
             object-catalog-debug-contract
             object-catalog-field-origin-contract
             object-catalog-inheritance-chain-contract
             object-catalog-phase-contract
             object-catalog-counts
             object-catalog-invalid-identities))
     (cons 'descriptor-realized? #f)
     (cons 'runtime-executed #f))))

;;; Catalog loading calls this gate so invalid module objects fail before a
;;; user-facing declarative configuration is projected.
;; : (-> PooModuleObject PooModuleObject)
(def (poo-flow-require-module-object-validation! object)
  (let (validation (poo-flow-module-object-validation object))
    (if (poo-flow-module-object-validation-valid? validation)
      object
      (error "poo-flow module object failed upstream harness validation"
             validation))))

;; : (-> [PooModuleObject] [PooModuleObject])
(def (poo-flow-require-module-objects-validation! objects)
  (for-each poo-flow-require-module-object-validation! objects)
  objects)
