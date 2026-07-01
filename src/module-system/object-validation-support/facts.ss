;;; -*- Gerbil -*-
;;; Boundary: module object validation facts, origins, and source refs.

(import :gerbil/gambit
        :poo-flow/src/module-system/object-core)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-field-contract-validation-kind
        receipt
        diagnostic
        poo-flow-module-field-identities
        poo-flow-module-object-direct-field-identities
        poo-flow-module-object-resolved-field-identities
        poo-flow-module-object-inheritance-chain
        poo-flow-module-object-inheritance-chains/onto
        poo-flow-module-object-inheritance-chain/onto
        poo-flow-module-symbol-member?
        poo-flow-module-object-find-field-provider
        poo-flow-module-object-field-provider-index
        poo-flow-module-object-field-origin/index
        poo-flow-module-object-field-origin
        poo-flow-module-object-field-origins
        metadata-list?
        poo-flow-module-object-validation-source-ref
        poo-flow-module-object-validation-source-ref/identities
        poo-flow-module-field-contract-validation-source-ref
        poo-flow-module-field-contract-validation-source-ref/values)


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

;;; Boundary: module field identities is the policy-visible edge for module-
;;; system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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
  (let (cache (poo-flow-module-object-inheritance-chain-cache object))
    (if (vector-ref cache 0)
      (vector-ref cache 1)
      (let (chain (poo-flow-module-object-inheritance-chain/onto object '()))
        (vector-set! cache 0 #t)
        (vector-set! cache 1 chain)
        chain))))

;;; Boundary: module object inheritance chains onto is the policy-visible edge
;;; for module-system, object behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: module symbol member predicate is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-module-symbol-member? value values)
  (cond
   ((null? values) #f)
   ((eq? value (car values)) #t)
   (else
    (poo-flow-module-symbol-member? value (cdr values)))))

;;; Boundary: module object find field provider is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; poo-flow-module-object-find-field-provider
;;   : (-> PooModuleObject Symbol MaybePooModuleObject)
;;   | doc m%
;;       `poo-flow-module-object-find-field-provider` documents the module-
;;       system, object boundary that the Gerbil policy harness treats as
;;       agent-facing behavior. The example keeps the call shape visible
;;       without duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-object-find-field-provider ...)
;;       ;; => policy-visible result
;;       ```
;;     %
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

;;; Boundary: module object field provider index is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; poo-flow-module-object-field-provider-index
;;   : (-> PooModuleObject HashTable)
;;   | doc m%
;;       `poo-flow-module-object-field-provider-index` documents the module-
;;       system, object boundary that the Gerbil policy harness treats as
;;       agent-facing behavior. The example keeps the call shape visible
;;       without duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-object-field-provider-index ...)
;;       ;; => policy-visible result
;;       ```
;;     %
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

;;; Boundary: module object field origin index is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: module object field origins is the policy-visible edge for
;;; module-system, object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleObject [Alist])
(def (poo-flow-module-object-field-origins object)
  (let (providers
        (poo-flow-module-object-field-provider-index object))
    (map (lambda (field)
           (poo-flow-module-object-field-origin/index
            object field providers))
         (poo-flow-module-object-resolved-fields object))))


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
