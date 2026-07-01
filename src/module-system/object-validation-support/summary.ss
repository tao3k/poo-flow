;;; -*- Gerbil -*-
;;; Boundary: object validation catalog summaries and require gates.

(import :gerbil/gambit
        (only-in :std/sugar filter-map)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation-support/facts
        :poo-flow/src/module-system/object-validation-support/harness
        :poo-flow/src/module-system/object-validation-support/object
        :poo-flow/src/module-system/projection-syntax)

(export poo-flow-module-objects-validation
        poo-flow-module-objects-validation->alists
        poo-flow-module-invalid-object-identities
        poo-flow-module-validation-values
        poo-flow-module-objects-validation-summary
        poo-flow-require-module-object-validation!
        poo-flow-require-module-objects-validation!)

;;; Boundary: module objects validation is the policy-visible edge for module-
;;; system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooModuleObject] [HashTable])
(def (poo-flow-module-objects-validation objects)
  (let ((field-cache (make-hash-table))
        (harness-cache (make-hash-table))
        (harness-fields-cache (make-hash-table))
        (field-origins-cache (make-hash-table)))
    (map (lambda (object)
           (poo-flow-module-object-validation/catalog-caches object
                                                            field-cache
                                                            harness-cache
                                                            harness-fields-cache
                                                            field-origins-cache))
         objects)))

;;; Validation receipts stay list-shaped for callers that serialize reports;
;;; the hash-table detail remains private to each object validation pass.
;; : (-> [HashTable] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-module-objects-validation->alists (validations)
  (projector poo-flow-module-object-validation->alist)
  (error-message "module object validation serialization requires a list"))

;;; Boundary: module invalid object identities is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [HashTable] [Symbol])
(def (poo-flow-module-invalid-object-identities validations)
  (filter-map
   (lambda (validation)
     (and (not (poo-flow-module-object-validation-valid? validation))
          (hash-get validation 'object)))
   validations))

;;; Boundary: module validation values is the policy-visible edge for module-
;;; system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [HashTable] Symbol [Value])
(def (poo-flow-module-validation-values validations key)
  (map (lambda (validation) (hash-get validation key)) validations))

;;; Boundary: module objects validation summary collect is the policy-visible
;;; edge for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; poo-flow-module-objects-validation-summary/collect
;;   : (-> [HashTable] Values)
;;   | doc m%
;;       `poo-flow-module-objects-validation-summary/collect` documents the
;;       module-system, object boundary that the Gerbil policy harness treats
;;       as agent-facing behavior. The example keeps the call shape visible
;;       without duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-objects-validation-summary/collect ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(def (poo-flow-module-objects-validation-summary/collect validations)
  (let loop ((rest validations)
             (object-count 0)
             (object-identities '())
             (inheritance-chains '())
             (direct-field-counts '())
             (direct-field-identities '())
             (resolved-field-counts '())
             (resolved-field-identities '())
             (field-origins '())
             (inheritance-counts '())
             (validation-phases '())
             (invalid-objects '()))
    (if (null? rest)
      (values object-count
              (reverse object-identities)
              (reverse inheritance-chains)
              (reverse direct-field-counts)
              (reverse direct-field-identities)
              (reverse resolved-field-counts)
              (reverse resolved-field-identities)
              (reverse field-origins)
              (reverse inheritance-counts)
              (reverse validation-phases)
              (reverse invalid-objects))
      (let* ((validation (car rest))
             (object (hash-get validation 'object))
             (invalid? (not (poo-flow-module-object-validation-valid? validation))))
        (loop (cdr rest)
              (+ object-count 1)
              (cons object object-identities)
              (cons (hash-get validation 'inheritance-chain) inheritance-chains)
              (cons (hash-get validation 'direct-field-count) direct-field-counts)
              (cons (hash-get validation 'direct-field-identities)
                    direct-field-identities)
              (cons (hash-get validation 'resolved-field-count)
                    resolved-field-counts)
              (cons (hash-get validation 'resolved-field-identities)
                    resolved-field-identities)
              (cons (hash-get validation 'field-origins) field-origins)
              (cons (hash-get validation 'inherit-count) inheritance-counts)
              (cons (hash-get validation 'validationPhases) validation-phases)
              (if invalid?
                (cons object invalid-objects)
                invalid-objects))))))

;; poo-flow-module-objects-validation-summary
;;   : (-> [HashTable] HashTable)
;;   | doc m%
;;       `poo-flow-module-objects-validation-summary` projects catalog-level
;;       validation facts without rewalking module objects or executing runtime
;;       descriptors.
;;     %
(def (poo-flow-module-objects-validation-summary validations)
  (call-with-values
    (lambda ()
      (poo-flow-module-objects-validation-summary/collect validations))
    (lambda (object-count
             object-identities
             inheritance-chains
             direct-field-counts
             direct-field-identities
             resolved-field-counts
             resolved-field-identities
             field-origins
             inheritance-counts
             validation-phases
             invalid-objects)
      (receipt
       (cons 'kind "poo-flow-module-objects-validation-summary")
       (cons 'schema poo-flow-module-object-validation-schema)
       (cons 'object-count object-count)
       (cons 'object-identities object-identities)
       (cons 'inheritance-chains inheritance-chains)
       (cons 'direct-field-counts direct-field-counts)
       (cons 'direct-field-identities direct-field-identities)
       (cons 'resolved-field-counts resolved-field-counts)
       (cons 'resolved-field-identities resolved-field-identities)
       (cons 'field-origins field-origins)
       (cons 'inheritance-counts inheritance-counts)
       (cons 'validation-phases validation-phases)
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
       (cons 'runtime-executed #f)))))

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
