;;; -*- Gerbil -*-
;;; Boundary: POO object validation receipts for module object contracts.
;;; This module is intentionally report-oriented; it does not execute runtime
;;; backends and it keeps heavy source scanning in the harness.

(import :gerbil/gambit
        (only-in :gslph/src/extensions/facade
                 poo-object-field-contract-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        (only-in :std/sugar filter-map foldl)
        :poo-flow/src/module-system/object-core)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-field-contract-validation-kind
        poo-flow-module-object-validation-source-ref
        poo-flow-module-field-contract-validation-source-ref
        poo-flow-module-object-direct-field-identities
        poo-flow-module-object-resolved-field-identities
        poo-flow-module-object-inheritance-chain
        poo-flow-module-object-field-origin
        poo-flow-module-object-field-origins
        poo-flow-module-object-validation-phases
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

;; : (-> [PooModuleFieldContract] [Symbol])
(def (poo-flow-module-field-identities fields)
  (map poo-flow-module-field-contract-identity fields))

;; : (-> PooModuleObject [Symbol])
(def (poo-flow-module-object-direct-field-identities object)
  (poo-flow-module-field-identities
   (poo-flow-module-object-fields object)))

;; : (-> PooModuleObject [Symbol])
(def (poo-flow-module-object-resolved-field-identities object)
  (poo-flow-module-field-identities
   (poo-flow-module-object-resolved-fields object)))

;;; This is the declared ancestry closure. The field order in
;;; `resolved-field-identities` is the observed C3 result from gerbil-poo.
;; : (-> PooModuleObject [Symbol])
(def (poo-flow-module-object-inheritance-chain object)
  (poo-flow-module-object-inheritance-chain/onto object '()))

;; : (-> [PooModuleObject] [Symbol] [Symbol])
(def (poo-flow-module-object-inheritance-chains/onto objects tail)
  (if (null? objects)
    tail
    (poo-flow-module-object-inheritance-chain/onto
     (car objects)
     (poo-flow-module-object-inheritance-chains/onto
      (cdr objects)
      tail))))

;; : (-> PooModuleObject [Symbol] [Symbol])
(def (poo-flow-module-object-inheritance-chain/onto object tail)
  (cons
   (poo-flow-module-object-identity object)
   (poo-flow-module-object-inheritance-chains/onto
    (poo-flow-module-object-inherits object)
    tail)))

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-module-symbol-member? value values)
  (cond
   ((null? values) #f)
   ((eq? value (car values)) #t)
   (else
    (poo-flow-module-symbol-member? value (cdr values)))))

;; : (-> PooModuleObject Symbol MaybePooModuleObject)
(def (poo-flow-module-object-find-field-provider object field-identity)
  (if (poo-flow-module-symbol-member?
       field-identity
       (poo-flow-module-object-direct-field-identities object))
    object
    (let loop ((supers (poo-flow-module-object-inherits object)))
      (cond
       ((null? supers) #f)
       ((poo-flow-module-object-find-field-provider (car supers)
                                                    field-identity)
        => (lambda (provider) provider))
       (else
        (loop (cdr supers)))))))

;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-field-provider-index object)
  (let (providers (make-hash-table))
    (let visit ((provider object))
      (for-each
       (lambda (field)
         (let (field-identity
               (poo-flow-module-field-contract-identity field))
           (if (hash-key? providers field-identity)
             (void)
             (hash-put! providers field-identity provider))))
       (poo-flow-module-object-fields provider))
      (for-each visit (poo-flow-module-object-inherits provider)))
    providers))

;; : (-> PooModuleObject PooModuleFieldContract HashTable Alist)
(def (poo-flow-module-object-field-origin/index object field providers)
  (let* ((field-identity
          (poo-flow-module-field-contract-identity field))
         (provider
          (hash-get providers field-identity))
         (provider-identity
          (and provider (poo-flow-module-object-identity provider))))
    (list
     (cons 'field field-identity)
     (cons 'origin
           (if (eq? provider object) 'direct 'inherited))
     (cons 'provider provider-identity)
     (cons 'value-kind
           (poo-flow-module-field-contract-value-kind field))
     (cons 'merge
           (poo-flow-module-field-contract-merge field))
     (cons 'metadata
           (poo-flow-module-field-contract-metadata field)))))

;; : (-> PooModuleObject PooModuleFieldContract Alist)
(def (poo-flow-module-object-field-origin object field)
  (poo-flow-module-object-field-origin/index
   object
   field
   (poo-flow-module-object-field-provider-index object)))

;; : (-> PooModuleObject [Alist])
(def (poo-flow-module-object-field-origins object)
  (let (providers
        (poo-flow-module-object-field-provider-index object))
    (map (lambda (field)
           (poo-flow-module-object-field-origin/index
            object field providers))
         (poo-flow-module-object-resolved-fields object))))

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
  (let* ((inherits
          (poo-flow-module-object-inherits object))
         (direct-fields
          (poo-flow-module-object-fields object))
         (resolved-fields
          (poo-flow-module-object-resolved-fields object)))
    (poo-flow-module-object-validation-source-ref/identities
     object
     (map poo-flow-module-object-identity inherits)
     (poo-flow-module-field-identities direct-fields)
     (poo-flow-module-field-identities resolved-fields))))

;; : (-> PooModuleObject [Symbol] [Symbol] [Symbol] HashTable)
(def (poo-flow-module-object-validation-source-ref/identities
      object
      inherit-identities
      direct-field-identities
      resolved-field-identities)
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
   (cons 'inherits inherit-identities)
   (cons 'fields direct-field-identities)
   (cons 'resolvedFields resolved-field-identities)))

;;; Field-level source references preserve the concrete field identity while
;;; still citing the same upstream facade as the semantic validation owner.
;; : (-> PooModuleObject PooModuleFieldContract HashTable)
(def (poo-flow-module-field-contract-validation-source-ref object field)
  (poo-flow-module-field-contract-validation-source-ref/values
   object
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-kind field)
   (poo-flow-module-field-contract-merge field)))

;; : (-> PooModuleObject Symbol Value Value HashTable)
(def (poo-flow-module-field-contract-validation-source-ref/values object
                                                                  field
                                                                  value-kind
                                                                  merge)
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
   (cons 'field field)
   (cons 'valueKind value-kind)
   (cons 'merge merge)))

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
(def (object-diagnostics object)
  (object-diagnostics/resolved-fields
   object
   (poo-flow-module-object-resolved-fields object)))

;; : (-> PooModuleObject [PooModuleFieldContract] [HashTable])
(def (object-diagnostics/resolved-fields object resolved-fields)
  (object-diagnostics/resolved-identities
   object
   (map poo-flow-module-field-contract-identity resolved-fields)))

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
          (map poo-flow-module-field-contract->harness-field
               resolved-fields))
         (source-ref
          (poo-flow-module-object-validation-source-ref/identities
           object
           inherit-identities
           direct-field-identities
           resolved-field-identities))
         (harness-validation
          (poo-flow-module-object-harness-validation/harness-fields
           object
           harness-fields
           source-ref))
         (field-contract-validations
          (poo-flow-module-object-field-contract-validations/harness-fields
           object
           harness-fields))
         (local-diagnostics
          (object-diagnostics/resolved-identities
           object
           resolved-field-identities))
         (field-origins
          (let (providers
                (poo-flow-module-object-field-provider-index object))
            (map (lambda (field)
                   (poo-flow-module-object-field-origin/index
                    object field providers))
                 resolved-fields)))
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
          (cons 'inherits (hash-get validation 'inherits))
          (cons 'inheritance-chain
                (hash-get validation 'inheritance-chain))
          (cons 'inherit-count (hash-get validation 'inherit-count))
          (cons 'direct-field-count
                (hash-get validation 'direct-field-count))
          (cons 'direct-field-identities
                (hash-get validation 'direct-field-identities))
          (cons 'resolved-field-count
                (hash-get validation 'resolved-field-count))
          (cons 'resolved-field-identities
                (hash-get validation 'resolved-field-identities))
          (cons 'field-origins
                (hash-get validation 'field-origins))
          (cons 'metadata (hash-get validation 'metadata))
          (cons 'valid (hash-get validation 'valid))
          (cons 'diagnostics (hash-get validation 'diagnostics))
          (cons 'diagnostic-count
                (length (hash-get validation 'diagnostics)))
          (cons 'field-count (length field-validations))
          (cons 'invalid-fields
                (poo-flow-module-invalid-field-identities field-validations))
          (cons 'checked-signals (hash-get validation 'checkedSignals))
          (cons 'validation-phases
                (hash-get validation 'validationPhases))
          (cons 'field-validations
                (map poo-flow-module-field-contract-validation->alist
                     field-validations)))))

;;; Catalog validation stays a pure map so callers can decide whether to inspect
;;; receipts or escalate through the require! gates.
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

;; : (-> [HashTable] HashTable)
(def (poo-flow-module-objects-validation-summary validations)
  (let loop ((remaining validations)
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
             (invalid-count 0)
             (invalid-objects '()))
    (if (null? remaining)
      (receipt
       (cons 'kind "poo-flow-module-objects-validation-summary")
       (cons 'schema poo-flow-module-object-validation-schema)
       (cons 'object-count object-count)
       (cons 'object-identities (reverse object-identities))
       (cons 'inheritance-chains (reverse inheritance-chains))
       (cons 'direct-field-counts (reverse direct-field-counts))
       (cons 'direct-field-identities (reverse direct-field-identities))
       (cons 'resolved-field-counts (reverse resolved-field-counts))
       (cons 'resolved-field-identities (reverse resolved-field-identities))
       (cons 'field-origins (reverse field-origins))
       (cons 'inheritance-counts (reverse inheritance-counts))
       (cons 'validation-phases (reverse validation-phases))
       (cons 'invalid-count invalid-count)
       (cons 'invalid-objects (reverse invalid-objects))
       (cons 'valid (= invalid-count 0))
       (cons 'checkedSignals
             '(object-catalog-validation-contract
               object-catalog-debug-contract
               object-catalog-field-origin-contract
               object-catalog-inheritance-chain-contract
               object-catalog-phase-contract
               object-catalog-counts
               object-catalog-invalid-identities))
       (cons 'descriptor-realized? #f)
       (cons 'runtime-executed #f))
      (let* ((validation (car remaining))
             (valid?
              (poo-flow-module-object-validation-valid? validation))
             (object-identity (hash-get validation 'object)))
        (loop
         (cdr remaining)
         (+ object-count 1)
         (cons object-identity object-identities)
         (cons (hash-get validation 'inheritance-chain)
               inheritance-chains)
         (cons (hash-get validation 'direct-field-count)
               direct-field-counts)
         (cons (hash-get validation 'direct-field-identities)
               direct-field-identities)
         (cons (hash-get validation 'resolved-field-count)
               resolved-field-counts)
         (cons (hash-get validation 'resolved-field-identities)
               resolved-field-identities)
         (cons (hash-get validation 'field-origins)
               field-origins)
         (cons (hash-get validation 'inherit-count)
               inheritance-counts)
         (cons (hash-get validation 'validationPhases)
               validation-phases)
         (if valid? invalid-count (+ invalid-count 1))
         (if valid?
           invalid-objects
           (cons object-identity invalid-objects)))))))

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
