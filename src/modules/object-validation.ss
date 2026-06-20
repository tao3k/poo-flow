;;; -*- Gerbil -*-
;;; Boundary: POO object validation receipts for module object contracts.
;;; This module is intentionally report-oriented; it does not execute runtime
;;; backends and it keeps heavy source scanning in the harness.

(import :gerbil/gambit
        (only-in :std/srfi/1 fold)
        (only-in :gslph/src/extensions/facade
                 poo-object-field-contract-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        :poo-flow/src/modules/object-core)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-field-contract-validation-kind
        poo-flow-module-object-validation-source-ref
        poo-flow-module-field-contract-validation-source-ref
        poo-flow-module-object-harness-validation
        poo-flow-module-field-contract-validation
        poo-flow-module-field-contract-validation-valid?
        poo-flow-module-field-contract-validation->alist
        poo-flow-module-object-field-contract-validations
        poo-flow-module-object-validation
        poo-flow-module-object-validation?
        poo-flow-module-object-validation-valid?
        poo-flow-module-object-validation-diagnostics
        poo-flow-module-object-validation->alist
        poo-flow-module-objects-validation
        poo-flow-module-objects-validation->alist
        poo-flow-module-objects-validation-summary
        poo-flow-require-module-object-validation!
        poo-flow-require-module-objects-validation!)

;; : PooFlowModuleObjectValidationKind
;; | PooFlowModuleObjectValidationKind = String
(def poo-flow-module-object-validation-kind
  "poo-flow-module-object-validation")

;; : PooFlowModuleObjectValidationSchema
;; | PooFlowModuleObjectValidationSchema = String
(def poo-flow-module-object-validation-schema
  "poo-flow-module-object-validation/v1")

;; : PooObjectFieldContractValidationKind
;; | PooObjectFieldContractValidationKind = String
(def poo-flow-module-field-contract-validation-kind
  "poo-object-field-contract-validation")

;;; Receipt helpers keep this module JSON-ish without importing an additional
;;; serialization layer; the upstream harness owns the validation vocabulary.
;; : (-> Pair... HashTable)
(def (receipt . entries)
  (let (table (make-hash-table))
    (for-each
     (lambda (entry)
       (hash-put! table (car entry) (cdr entry)))
     entries)
    table))

;; : (-> Symbol String Value Value HashTable)
(def (diagnostic code message subject evidence)
  (receipt (cons 'code code)
           (cons 'message message)
           (cons 'subject subject)
           (cons 'evidence evidence)))

;;; Local object metadata is the only metadata gate that stays in poo-flow;
;;; field metadata shape is validated by the upstream object facade.
;; : (-> ModuleObjectMetadataCandidate Boolean)
(def (metadata-list? value)
  (or (null? value)
      (and (list? value) (andmap pair? value))))

;;; Source references deliberately point at the upstream facade, not at this
;;; adapter, so failing receipts send framework authors to the contract owner.
;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-validation-source-ref object)
  (receipt
   (cons 'kind "dependency")
   (cons 'manager "gerbil.pkg")
   (cons 'dependency "github.com/tao3k/gerbil-scheme-language-project-harness")
   (cons 'repository "github.com/tao3k/agent-semantic-protocols")
   (cons 'localSource "languages/gerbil-scheme-language-project-harness")
   (cons 'repositorySource "src/extensions/facade.ss")
   (cons 'indexHint "gslph-extensions-facade")
   (cons 'pathPolicy "package-dependency")
   (cons 'selectorScheme "gerbil-poo")
   (cons 'object (poo-flow-module-object-identity object))
   (cons 'inherits
         (map poo-flow-module-object-identity
              (poo-flow-module-object-inherits object)))
   (cons 'fields
         (map poo-flow-module-field-contract-identity
              (poo-flow-module-object-fields object)))
   (cons 'resolvedFields
         (map poo-flow-module-field-contract-identity
              (poo-flow-module-object-resolved-fields object)))))

;;; Field-level source references preserve the concrete field identity while
;;; still citing the same upstream facade as the semantic validation owner.
;; : (-> PooModuleObject PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract-validation-source-ref object field)
  (receipt
   (cons 'kind "dependency")
   (cons 'manager "gerbil.pkg")
   (cons 'dependency "github.com/tao3k/gerbil-scheme-language-project-harness")
   (cons 'repository "github.com/tao3k/agent-semantic-protocols")
   (cons 'localSource "languages/gerbil-scheme-language-project-harness")
   (cons 'repositorySource "src/extensions/facade.ss")
   (cons 'indexHint "gslph-extensions-facade")
   (cons 'pathPolicy "package-dependency")
   (cons 'selectorScheme "gerbil-poo")
   (cons 'object (poo-flow-module-object-identity object))
   (cons 'field (poo-flow-module-field-contract-identity field))
   (cons 'valueKind (poo-flow-module-field-contract-value-kind field))
   (cons 'merge (poo-flow-module-field-contract-merge field))))

;;; This is the only conversion seam: downstream POO objects become the plain
;;; field-contract hash shape accepted by the harness facade.
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
  (poo-object-contract-validation
   (poo-flow-module-object-identity object)
   (map poo-flow-module-field-contract->harness-field
        (poo-flow-module-object-resolved-fields object))
   (poo-flow-module-object-validation-source-ref object)))

;; : (-> PooModuleObject PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract-validation object field)
  (poo-object-field-contract-validation
   (poo-flow-module-object-identity object)
   (poo-flow-module-field-contract->harness-field field)
   (poo-flow-module-field-contract-validation-source-ref object field)))

;; : (-> HashTable Boolean)
(def (poo-flow-module-field-contract-validation-valid? validation)
  (poo-object-validation-valid? validation))

;; : (-> HashTable Alist)
(def (poo-flow-module-type-validation->alist validation)
  (if (hash-table? validation)
    (list (cons 'kind (hash-get validation 'kind))
          (cons 'schema (hash-get validation 'schema))
          (cons 'value-kind (hash-get validation 'valueKind))
          (cons 'type-display (hash-get validation 'typeDisplay))
          (cons 'valid (hash-get validation 'valid))
          (cons 'diagnostics (hash-get validation 'diagnostics)))
    '()))

;;; User-facing projection: preserve the upstream validation vocabulary while
;;; making field-level receipts easy for doctors and agents to scan.
;; : (-> HashTable Alist)
(def (poo-flow-module-field-contract-validation->alist validation)
  (list (cons 'kind (hash-get validation 'kind))
        (cons 'schema (hash-get validation 'schema))
        (cons 'object (hash-get validation 'object))
        (cons 'field (hash-get validation 'field))
        (cons 'value-kind (hash-get validation 'valueKind))
        (cons 'merge (hash-get validation 'merge))
        (cons 'valid (hash-get validation 'valid))
        (cons 'diagnostics (hash-get validation 'diagnostics))
        (cons 'checked-signals (hash-get validation 'checkedSignals))
        (cons 'type-validation
              (poo-flow-module-type-validation->alist
               (hash-get validation 'typeValidation)))))

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
  (map (lambda (field)
         (poo-flow-module-field-contract-validation object field))
       (poo-flow-module-object-resolved-fields object)))

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
  (let (state
        (fold
         (lambda (identity state)
           (let ((seen (car state))
                 (dupes (cdr state)))
             (if (memq identity seen)
               (cons seen
                     (if (memq identity dupes)
                       dupes
                       (cons identity dupes)))
               (cons (cons identity seen) dupes))))
         (cons '() '())
         identities))
    (reverse (cdr state))))

;;; Object diagnostics stay intentionally narrow: only object-local metadata and
;;; C3-resolved identity collisions are checked here.
;; : (-> PooModuleObject [HashTable])
(def (object-diagnostics object)
  (let* ((resolved-fields (poo-flow-module-object-resolved-fields object))
         (resolved-identities
          (map poo-flow-module-field-contract-identity resolved-fields))
         (duplicates (duplicate-identities resolved-identities)))
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
  (let* ((harness-validation
          (poo-flow-module-object-harness-validation object))
         (source-ref
          (poo-flow-module-object-validation-source-ref object))
         (field-contract-validations
          (poo-flow-module-object-field-contract-validations object))
         (local-diagnostics
          (object-diagnostics object))
         (diagnostics
          (append local-diagnostics
                  (hash-get harness-validation 'diagnostics)))
         (valid? (and (null? diagnostics)
                      (poo-object-validation-valid? harness-validation)
                      (field-contract-validations-valid?
                       field-contract-validations))))
    (receipt
     (cons 'kind poo-flow-module-object-validation-kind)
     (cons 'schema poo-flow-module-object-validation-schema)
     (cons 'object (poo-flow-module-object-identity object))
     (cons 'sourceRef source-ref)
     (cons 'harnessValidation harness-validation)
     (cons 'fieldContractValidations field-contract-validations)
     (cons 'valid valid?)
     (cons 'diagnostics diagnostics)
     (cons 'checkedSignals
           '(upstream-poo-object-contract-validation
             upstream-poo-object-field-contract-validation
             object-metadata-shape
             resolved-field-identity)))))

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

;; : (-> [HashTable] [Symbol])
(def (poo-flow-module-invalid-field-identities field-validations)
  (cond
   ((null? field-validations) '())
   ((poo-flow-module-field-contract-validation-valid? (car field-validations))
    (poo-flow-module-invalid-field-identities (cdr field-validations)))
   (else
    (cons (hash-get (car field-validations) 'field)
          (poo-flow-module-invalid-field-identities (cdr field-validations))))))

;;; Public projection boundary: callers get stable alists without depending on
;;; hash-table nesting or harness-private source receipt shapes.
;; : (-> HashTable Alist)
(def (poo-flow-module-object-validation->alist validation)
  (let (field-validations
        (hash-get validation 'fieldContractValidations))
    (list (cons 'kind (hash-get validation 'kind))
          (cons 'schema (hash-get validation 'schema))
          (cons 'object (hash-get validation 'object))
          (cons 'valid (hash-get validation 'valid))
          (cons 'diagnostics (hash-get validation 'diagnostics))
          (cons 'diagnostic-count
                (length (hash-get validation 'diagnostics)))
          (cons 'field-count (length field-validations))
          (cons 'invalid-fields
                (poo-flow-module-invalid-field-identities field-validations))
          (cons 'checked-signals (hash-get validation 'checkedSignals))
          (cons 'field-validations
                (map poo-flow-module-field-contract-validation->alist
                     field-validations)))))

;;; Catalog validation stays a pure map so callers can decide whether to inspect
;;; receipts or escalate through the require! gates.
;; : (-> [PooModuleObject] [HashTable])
(def (poo-flow-module-objects-validation objects)
  (map poo-flow-module-object-validation objects))

;; : (-> [HashTable] [Alist])
(def (poo-flow-module-objects-validation->alist validations)
  (map poo-flow-module-object-validation->alist validations))

;; : (-> [HashTable] [Symbol])
(def (poo-flow-module-invalid-object-identities validations)
  (cond
   ((null? validations) '())
   ((poo-flow-module-object-validation-valid? (car validations))
    (poo-flow-module-invalid-object-identities (cdr validations)))
   (else
    (cons (hash-get (car validations) 'object)
          (poo-flow-module-invalid-object-identities (cdr validations))))))

;; : (-> [HashTable] HashTable)
(def (poo-flow-module-objects-validation-summary validations)
  (let (invalid-objects
        (poo-flow-module-invalid-object-identities validations))
    (receipt
     (cons 'kind "poo-flow-module-objects-validation-summary")
     (cons 'schema poo-flow-module-object-validation-schema)
     (cons 'object-count (length validations))
     (cons 'invalid-count (length invalid-objects))
     (cons 'invalid-objects invalid-objects)
     (cons 'valid (null? invalid-objects)))))

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
