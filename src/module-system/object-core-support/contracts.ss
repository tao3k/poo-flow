;;; -*- Gerbil -*-
;;; Boundary: field, contribution, and transformer contracts for module objects.

(import :gerbil/gambit
        (only-in :clan/poo/object
                 .o
                 .ref
                 object?
                 make-object
                 $constant-slot-spec
                 $computed-slot-spec)
        (only-in :std/sugar foldl)
        :poo-flow/src/module-system/extension)

(export poo-flow-module-object-kind
        poo-flow-module-field-contract-kind
        poo-flow-module-field-contribution-kind
        poo-flow-module-transformer-contract-kind
        poo-flow-module-config-merge-result-kind
        poo-flow-module-objects-root-identity
        poo-flow-module-object-kind?
        poo-flow-module-alist?
        poo-flow-module-value-kind-accepts?
        poo-flow-module-field-contract
        poo-flow-module-field-contract?
        poo-flow-module-field-contract-identity
        poo-flow-module-field-contract-value-kind
        poo-flow-module-field-contract-merge
        poo-flow-module-field-contract-default
        poo-flow-module-field-contract-metadata
        poo-flow-module-field-contract-accepts?
        poo-flow-module-field-contract-with-merge
        poo-flow-module-field-contribution
        poo-flow-module-field-contribution-vector?
        poo-flow-module-field-contribution?
        poo-flow-module-field-contribution-target
        poo-flow-module-field-contribution-field
        poo-flow-module-field-contribution-value
        poo-flow-module-field-contribution-field-contract?
        poo-flow-module-field-contribution-field-value-kind
        poo-flow-module-field-contribution-field-identity
        poo-flow-module-field-contribution-merge
        poo-flow-module-field-contribution-valid?
        poo-flow-module-field-contribution-operation
        poo-flow-module-field-contribution->extension
        poo-flow-module-field-contributions->extensions
        poo-flow-module-transformer-contract
        poo-flow-module-transformer-contract?
        poo-flow-module-transformer-contract-identity
        poo-flow-module-transformer-contract-merge
        poo-flow-module-transformer-contract-input-kind
        poo-flow-module-transformer-contract-argument-kind
        poo-flow-module-transformer-contract-output-kind
        poo-flow-module-transformer-contract-idempotent?
        poo-flow-module-transformer-contract-identity-key
        poo-flow-module-transformer-contract-metadata
        poo-flow-module-transformer-list-append-contract
        poo-flow-module-transformer-list-remove-contract
        poo-flow-module-transformer-map-set-contract
        poo-flow-module-transformer-kind-compatible?
        poo-flow-module-transformer-diagnostic
        poo-flow-module-transformer-contract-diagnostics
        poo-flow-module-transformer-contract-valid?
        poo-flow-module-transformer-field-contribution)

;; | PooModuleObjectKindId = String
(def poo-flow-module-object-kind "poo-flow.modules.object.v1")
;; : PooModuleFieldContractKindId
;; | PooModuleFieldContractKindId = String
(def poo-flow-module-field-contract-kind "poo-flow.modules.field-contract.v1")
;; : PooModuleFieldContributionKindId
;; | PooModuleFieldContributionKindId = String
(def poo-flow-module-field-contribution-kind "poo-flow.modules.field-contribution.v1")
;; : PooModuleTransformerContractKindId
;; | PooModuleTransformerContractKindId = String
(def poo-flow-module-transformer-contract-kind "poo-flow.modules.transformer-contract.v1")
;; : PooModuleConfigMergeResultKindId
;; | PooModuleConfigMergeResultKindId = String
(def poo-flow-module-config-merge-result-kind "poo-flow.modules.config-merge-result.v1")
;; : PooModuleObjectsRootIdentity
;; | PooModuleObjectsRootIdentity = Symbol
(def poo-flow-module-objects-root-identity 'objects)

;; : (-> PooModuleValueCandidate PooModuleKindId Boolean)
(def (poo-flow-module-object-kind? value kind)
  (and (object? value) (equal? (.ref value 'kind) kind)))

;; | PooModuleAlistCandidate = (U Null Pair)
;; : (-> PooModuleAlistCandidate Boolean)
(def (poo-flow-module-alist? value)
  (cond ((null? value) #t)
        ((and (pair? value) (pair? (car value)))
         (poo-flow-module-alist? (cdr value)))
        (else #f)))

;; : (-> PooModuleKindId PooModuleFieldValueCandidate Boolean)
(def (poo-flow-module-value-kind-accepts? value-kind value)
  (cond ((eq? value-kind 'Any) #t)
        ((eq? value-kind 'List) (list? value))
        ((eq? value-kind 'Map) (poo-flow-module-alist? value))
        ((eq? value-kind 'Alist) (poo-flow-module-alist? value))
        ((eq? value-kind 'Symbol) (symbol? value))
        ((eq? value-kind 'String) (string? value))
        ((eq? value-kind 'Boolean) (boolean? value))
        ((eq? value-kind 'Object) (object? value))
        ((eq? value-kind 'Node) (poo-flow-module-extension-node? value))
        (else #t)))

;;; Field contracts translate object-level C3 inheritance into merge operations
;;; without hardcoding backend-specific fields in the module system.
;; : (-> Symbol Symbol Symbol PooModuleFieldDefault PooModuleFieldMetadata PooModuleFieldContract)
(def (poo-flow-module-field-contract identity value-kind merge default metadata)
  (let ((identity-value identity)
        (value-kind-value value-kind)
        (merge-value merge)
        (default-value default)
        (metadata-value metadata))
    (.o kind: poo-flow-module-field-contract-kind
        identity: identity-value
        value-kind: value-kind-value
        merge: merge-value
        default: default-value
        metadata: metadata-value)))

;; : (-> PooModuleFieldContractCandidate Boolean)
(def (poo-flow-module-field-contract? value)
  (poo-flow-module-object-kind? value poo-flow-module-field-contract-kind))

;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-identity field) (.ref field 'identity))
;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-value-kind field) (.ref field 'value-kind))
;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-merge field) (.ref field 'merge))
;; : (-> PooModuleFieldContract PooModuleFieldDefault)
(def (poo-flow-module-field-contract-default field) (.ref field 'default))
;; : (-> PooModuleFieldContract PooModuleFieldMetadata)
(def (poo-flow-module-field-contract-metadata field) (.ref field 'metadata))

;;; Value-kind checks are intentionally shallow; object-specific transformer
;;; contracts can refine this before an extension operation is projected.
;; : (-> PooModuleFieldContract PooModuleFieldValueCandidate Boolean)
(def (poo-flow-module-field-contract-accepts? field value)
  (poo-flow-module-value-kind-accepts?
   (poo-flow-module-field-contract-value-kind field)
   value))

;; : (-> PooModuleFieldContract Symbol PooModuleFieldContract)
(def (poo-flow-module-field-contract-with-merge field merge)
  (poo-flow-module-field-contract
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-kind field)
   merge
   (poo-flow-module-field-contract-default field)
   (poo-flow-module-field-contract-metadata field)))

;;; Field contributions are object-aware extension requests: the field decides
;;; merge behavior while the contribution carries target and value.
;; : (-> Symbol PooModuleFieldContract PooModuleFieldValue PooModuleFieldContribution)
(def (poo-flow-module-field-contribution target field value)
  (let* ((target-value target)
         (field-value field)
         (value-value value)
         (field-contract? (poo-flow-module-field-contract? field-value))
         (field-identity-value
          (if field-contract?
            (poo-flow-module-field-contract-identity field-value)
            field-value))
         (field-merge-value
          (if field-contract?
            (poo-flow-module-field-contract-merge field-value)
            'override))
         (field-value-kind-value
          (if field-contract?
            (poo-flow-module-field-contract-value-kind field-value)
            'Any)))
    (vector poo-flow-module-field-contribution-kind
            target-value
            field-value
            value-value
            field-identity-value
            field-merge-value
            field-value-kind-value
            field-contract?)))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution-vector? value)
  (and (vector? value)
       (= (vector-length value) 8)
       (equal? (vector-ref value 0)
               poo-flow-module-field-contribution-kind)))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution? value)
  (or (poo-flow-module-field-contribution-vector? value)
      (poo-flow-module-object-kind? value poo-flow-module-field-contribution-kind)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-target contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 1)
    (.ref contribution 'target)))
;; : (-> PooModuleFieldContribution PooModuleFieldContract)
(def (poo-flow-module-field-contribution-field contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 2)
    (.ref contribution 'field)))
;; : (-> PooModuleFieldContribution PooModuleFieldValue)
(def (poo-flow-module-field-contribution-value contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 3)
    (.ref contribution 'value)))
;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-field-contract? contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 7)
    (.ref contribution 'field-contract-p)))
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-value-kind contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 6)
    (.ref contribution 'field-value-kind)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-identity contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 4)
    (.ref contribution 'field-identity)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-merge contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 5)
    (.ref contribution 'field-merge)))

;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-valid? contribution)
  (or (not (poo-flow-module-field-contribution-field-contract? contribution))
      (poo-flow-module-value-kind-accepts?
       (poo-flow-module-field-contribution-field-value-kind contribution)
       (poo-flow-module-field-contribution-value contribution))))

;;; Contribution conversion is the only place field merge names become graph
;;; operations, keeping custom objects independent from merge internals.
;; : (-> PooModuleFieldContribution PooModuleExtensionOperation)
(def (poo-flow-module-field-contribution-operation contribution)
  (let* ((field-identity
          (poo-flow-module-field-contribution-field-identity contribution))
         (value
          (poo-flow-module-field-contribution-value contribution))
         (merge
          (poo-flow-module-field-contribution-merge contribution)))
    (cond
     ((eq? merge 'override)
      (poo-flow-module-extension-slot-override field-identity value))
     ((eq? merge 'append)
      (poo-flow-module-extension-slot-append field-identity value))
     ((eq? merge 'prepend)
      (poo-flow-module-extension-slot-prepend field-identity value))
     ((eq? merge 'remove)
      (poo-flow-module-extension-slot-remove field-identity value))
     ((eq? merge 'node-extend)
      (poo-flow-module-extension-node-extend value))
     ((eq? merge 'node-remove)
      (poo-flow-module-extension-node-remove value))
     (else
      (poo-flow-module-extension-slot-override field-identity value)))))

;; : (-> PooModuleFieldContribution PooModuleExtensionContribution)
(def (poo-flow-module-field-contribution->extension contribution)
  (let* ((target
          (poo-flow-module-field-contribution-target contribution))
         (value
          (poo-flow-module-field-contribution-value contribution))
         (field-contract?
          (poo-flow-module-field-contribution-field-contract? contribution))
         (valid?
          (or (not field-contract?)
              (poo-flow-module-value-kind-accepts?
               (poo-flow-module-field-contribution-field-value-kind
                contribution)
               value)))
         (field-identity
          (poo-flow-module-field-contribution-field-identity contribution))
         (merge
          (poo-flow-module-field-contribution-merge contribution))
         (operation
          (cond
           ((eq? merge 'override)
            (poo-flow-module-extension-slot-override field-identity value))
           ((eq? merge 'append)
            (poo-flow-module-extension-slot-append field-identity value))
           ((eq? merge 'prepend)
            (poo-flow-module-extension-slot-prepend field-identity value))
           ((eq? merge 'remove)
            (poo-flow-module-extension-slot-remove field-identity value))
           ((eq? merge 'node-extend)
            (poo-flow-module-extension-node-extend value))
           ((eq? merge 'node-remove)
            (poo-flow-module-extension-node-remove value))
           (else
            (poo-flow-module-extension-slot-override field-identity value)))))
    (if valid?
      (poo-flow-module-extension-contribution target (list operation))
      (error "poo-flow module field contribution violates its POO contract"
             contribution))))

;;; Field contribution projection is a map because validation happens at each
;;; contribution boundary before the generic extension graph sees operations.
;; : (-> [PooModuleFieldContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-field-contributions->extensions contributions)
  (map poo-flow-module-field-contribution->extension contributions))

;;; Transformer contracts are object-owned wrappers around standard
;;; list/map-shaped operations. They validate user or agent repair payloads
;;; before those payloads become ordinary field contributions.
;; : (-> Symbol Symbol Symbol Symbol Symbol Boolean MaybeSymbol Alist PooModuleTransformerContract)
(def (poo-flow-module-transformer-contract identity
                                           merge
                                           input-kind
                                           argument-kind
                                           output-kind
                                           idempotent?
                                           identity-key
                                           metadata)
  (let ((identity-value identity)
        (merge-value merge)
        (input-kind-value input-kind)
        (argument-kind-value argument-kind)
        (output-kind-value output-kind)
        (idempotent-value idempotent?)
        (identity-key-value identity-key)
        (metadata-value metadata))
    (.o kind: poo-flow-module-transformer-contract-kind
        identity: identity-value
        merge: merge-value
        input-kind: input-kind-value
        argument-kind: argument-kind-value
        output-kind: output-kind-value
        idempotent?: idempotent-value
        identity-key: identity-key-value
        metadata: metadata-value)))

;; : (-> PooModuleTransformerContractCandidate Boolean)
(def (poo-flow-module-transformer-contract? value)
  (poo-flow-module-object-kind? value poo-flow-module-transformer-contract-kind))

;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-identity transformer)
  (.ref transformer 'identity))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-merge transformer)
  (.ref transformer 'merge))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-input-kind transformer)
  (.ref transformer 'input-kind))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-argument-kind transformer)
  (.ref transformer 'argument-kind))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-output-kind transformer)
  (.ref transformer 'output-kind))
;; : (-> PooModuleTransformerContract Boolean)
(def (poo-flow-module-transformer-contract-idempotent? transformer)
  (.ref transformer 'idempotent?))
;; : (-> PooModuleTransformerContract MaybeSymbol)
(def (poo-flow-module-transformer-contract-identity-key transformer)
  (.ref transformer 'identity-key))
;; : (-> PooModuleTransformerContract Alist)
(def (poo-flow-module-transformer-contract-metadata transformer)
  (.ref transformer 'metadata))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-list-append-contract
  (poo-flow-module-transformer-contract
   'list.append
   'append
   'List
   'List
   'List
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.append))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-list-remove-contract
  (poo-flow-module-transformer-contract
   'list.remove
   'remove
   'List
   'List
   'List
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.remove))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-map-set-contract
  (poo-flow-module-transformer-contract
   'map.set
   'override
   'Map
   'Map
   'Map
   #t
   #f
   '((scope . object-core) (standard-library-shape . map.set))))

;; : (-> Symbol Symbol Boolean)
(def (poo-flow-module-transformer-kind-compatible? expected actual)
  (or (eq? expected 'Any)
      (eq? actual 'Any)
      (eq? expected actual)
      (and (eq? expected 'Map) (eq? actual 'Alist))
      (and (eq? expected 'Alist) (eq? actual 'Map))))

;; : (-> Symbol PooModuleTransformerContract String)
(def (poo-flow-module-transformer-diagnostic code transformer)
  (string-append
   "transformer:"
   (symbol->string (poo-flow-module-transformer-contract-identity transformer))
   ":"
   (symbol->string code)))

;; : (-> PooModuleTransformerContract PooModuleFieldContract PooModuleFieldValue [String])
(def (poo-flow-module-transformer-contract-diagnostics transformer field value)
  (append
   (if (poo-flow-module-transformer-kind-compatible?
        (poo-flow-module-transformer-contract-input-kind transformer)
        (poo-flow-module-field-contract-value-kind field))
     '()
     (list (poo-flow-module-transformer-diagnostic
            'field-kind-mismatch
            transformer)))
   (if (poo-flow-module-value-kind-accepts?
        (poo-flow-module-transformer-contract-argument-kind transformer)
        value)
     '()
     (list (poo-flow-module-transformer-diagnostic
            'argument-kind-mismatch
            transformer)))))

;; : (-> PooModuleTransformerContract PooModuleFieldContract PooModuleFieldValue Boolean)
(def (poo-flow-module-transformer-contract-valid? transformer field value)
  (null? (poo-flow-module-transformer-contract-diagnostics
          transformer
          field
          value)))

;; : (-> Symbol PooModuleFieldContract PooModuleTransformerContract PooModuleFieldValue PooModuleFieldContribution)
(def (poo-flow-module-transformer-field-contribution target field transformer value)
  (if (poo-flow-module-transformer-contract-valid? transformer field value)
    (poo-flow-module-field-contribution
     target
     (poo-flow-module-field-contract-with-merge
      field
      (poo-flow-module-transformer-contract-merge transformer))
     value)
    (error "poo-flow module transformer violates its POO contract"
           (poo-flow-module-transformer-contract-diagnostics
            transformer
            field
            value))))
