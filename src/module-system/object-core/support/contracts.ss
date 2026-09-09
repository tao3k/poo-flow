;;; -*- Gerbil -*-
;;; Boundary: field, contribution, and transformer contracts for module objects.

(import :gerbil/gambit
        (only-in :clan/poo/object
                 .cc
                 .mix
                 .o
                 .ref
                 .slot?
                 object?
                 make-object
                 $constant-slot-spec
                 $computed-slot-spec)
        (only-in :clan/poo/mop
                 .defgeneric Any Bool Object Type element? raise-type-error)
        (only-in :clan/poo/type List String Symbol)
        (only-in "../../types.ss" poo-flow-predicate-type)
        :poo-flow/src/module-system/extension/interface)

(export poo-flow-module-object-kind
        poo-flow-module-field-contract-kind
        poo-flow-module-field-contribution-kind
        poo-flow-module-transformer-contract-kind
        poo-flow-module-config-merge-result-kind
        poo-flow-module-objects-root-identity
        poo-flow-module-object-kind?
        poo-flow-module-alist?
        PooFlowModuleAnyType
        PooFlowModuleListType
        PooFlowModuleMapType
        PooFlowModuleAlistType
        PooFlowModuleSymbolType
        PooFlowModuleStringType
        PooFlowModuleBooleanType
        PooFlowModuleObjectType
        PooFlowModuleNodeType
        poo-flow-module-list-type
        poo-flow-module-value-type?
        poo-flow-module-value-type-kind
        poo-flow-module-value-type-accepts?
        poo-flow-module-field-contract
        poo-flow-module-field-contract?
        poo-flow-module-field-contract-identity
        poo-flow-module-field-contract-value-type
        poo-flow-module-field-contract-merge
        poo-flow-module-field-contract-default
        poo-flow-module-field-contract-metadata
        poo-flow-module-field-contract-accepts?
        poo-flow-module-field-contract-with-merge
        poo-flow-module-field-contribution-prototype
        poo-flow-module-field-contribution
        poo-flow-module-field-contribution?
        poo-flow-module-field-contribution-target
        poo-flow-module-field-contribution-field
        poo-flow-module-field-contribution-value
        poo-flow-module-field-contribution-field-contract?
        poo-flow-module-field-contribution-field-value-type
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
        poo-flow-module-transformer-contract-input-type
        poo-flow-module-transformer-contract-argument-type
        poo-flow-module-transformer-contract-output-type
        poo-flow-module-transformer-contract-idempotent?
        poo-flow-module-transformer-contract-identity-key
        poo-flow-module-transformer-contract-metadata
        poo-flow-module-transformer-list-append-contract
        poo-flow-module-transformer-list-remove-contract
        poo-flow-module-transformer-map-set-contract
        poo-flow-module-transformer-type-compatible?
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

;;; Module field types are native gerbil-poo Type descriptors.  The symbol in
;;; `module-value-kind` is a report-only projection for the upstream harness;
;;; it never participates in semantic dispatch.
(def (poo-flow-module-value-type base-type kind)
  (.cc base-type
       'module-value-kind kind
       'sexp kind))

(def PooFlowModuleAnyType
  (poo-flow-module-value-type Any 'Any))
(def (poo-flow-module-list-type element-type)
  (poo-flow-module-value-type (List element-type) 'List))
(def PooFlowModuleListType
  (poo-flow-module-list-type Any))
(def PooFlowModuleMapType
  (poo-flow-module-value-type
   (poo-flow-predicate-type 'PooFlowModuleMap poo-flow-module-alist?)
   'Map))
(def PooFlowModuleAlistType
  (poo-flow-module-value-type
   (poo-flow-predicate-type 'PooFlowModuleAlist poo-flow-module-alist?)
   'Alist))
(def PooFlowModuleSymbolType
  (poo-flow-module-value-type Symbol 'Symbol))
(def PooFlowModuleStringType
  (poo-flow-module-value-type String 'String))
(def PooFlowModuleBooleanType
  (poo-flow-module-value-type Bool 'Boolean))
(def PooFlowModuleObjectType
  (poo-flow-module-value-type Object 'Object))
(def PooFlowModuleNodeType
  (poo-flow-module-value-type
   (poo-flow-predicate-type 'PooFlowModuleNode
                            poo-flow-module-extension-node?)
   'Node))

(def (poo-flow-module-value-type? value-type)
  (and (element? Type value-type)
       (.slot? value-type 'module-value-kind)
       (symbol? (.ref value-type 'module-value-kind))))

(def (poo-flow-module-value-type-kind value-type)
  (unless (poo-flow-module-value-type? value-type)
    (raise-type-error Type value-type))
  (.ref value-type 'module-value-kind))

(def (poo-flow-module-value-type-accepts? value-type value)
  (and (poo-flow-module-value-type? value-type)
       (element? value-type value)))

;;; Field contracts translate object-level C3 inheritance into merge operations
;;; without hardcoding backend-specific fields in the module system.
;; : (-> Symbol Symbol Symbol PooModuleFieldDefault PooModuleFieldMetadata PooModuleFieldContract)
(def (poo-flow-module-field-contract identity value-type merge default metadata)
  (unless (poo-flow-module-value-type? value-type)
    (raise-type-error Type value-type))
  (let ((identity-value identity)
        (value-type-value value-type)
        (merge-value merge)
        (default-value default)
        (metadata-value metadata))
    (.o kind: poo-flow-module-field-contract-kind
        identity: identity-value
        value-type: value-type-value
        merge: merge-value
        default: default-value
        metadata: metadata-value)))

;; : (-> PooModuleFieldContractCandidate Boolean)
(def (poo-flow-module-field-contract? value)
  (poo-flow-module-object-kind? value poo-flow-module-field-contract-kind))

;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-identity field) (.ref field 'identity))
;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-value-type field) (.ref field 'value-type))
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
  (poo-flow-module-value-type-accepts?
   (poo-flow-module-field-contract-value-type field)
   value))

;; : (-> PooModuleFieldContract Symbol PooModuleFieldContract)
(def (poo-flow-module-field-contract-with-merge field merge)
  (poo-flow-module-field-contract
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-type field)
   merge
   (poo-flow-module-field-contract-default field)
   (poo-flow-module-field-contract-metadata field)))

;;; The contribution prototype owns derived extension behavior.  Concrete
;;; contributions refine this native POO value with constant defaults; no
;;; positional record or compatibility representation participates in dispatch.
(def poo-flow-module-field-contribution-prototype
  (.o (:: self)
      kind: poo-flow-module-field-contribution-kind
      (.operation
       (poo-flow-module-field-operation
        (.ref self 'field-identity)
        (.ref self 'field-merge)
        (.ref self 'value)))))

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
         (field-value-type-value
          (if field-contract?
            (poo-flow-module-field-contract-value-type field-value)
            PooFlowModuleAnyType)))
    (.mix poo-flow-module-field-contribution-prototype
      defaults: (list
                 (cons 'target target-value)
                 (cons 'field field-value)
                 (cons 'value value-value)
                 (cons 'field-identity field-identity-value)
                 (cons 'field-merge field-merge-value)
                 (cons 'field-value-type field-value-type-value)
                 (cons 'field-contract? field-contract?)))))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution? value)
  (poo-flow-module-object-kind? value poo-flow-module-field-contribution-kind))

;;; Boundary: module field contribution target is the policy-visible edge for
;;; module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-target contribution)
  (.ref contribution 'target))
;;; Boundary: module field contribution field is the policy-visible edge for
;;; module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution PooModuleFieldContract)
(def (poo-flow-module-field-contribution-field contribution)
  (.ref contribution 'field))
;;; Boundary: module field contribution value is the policy-visible edge for
;;; module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution PooModuleFieldValue)
(def (poo-flow-module-field-contribution-value contribution)
  (.ref contribution 'value))
;;; Boundary: module field contribution field contract predicate is the policy-
;;; visible edge for module-system, object, core behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-field-contract? contribution)
  (.ref contribution 'field-contract?))
;;; Boundary: module field contribution field value kind is the policy-visible
;;; edge for module-system, object, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-value-type contribution)
  (.ref contribution 'field-value-type))

;;; Boundary: module field contribution field identity is the policy-visible
;;; edge for module-system, object, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-identity contribution)
  (.ref contribution 'field-identity))

;;; Boundary: module field contribution merge is the policy-visible edge for
;;; module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-merge contribution)
  (.ref contribution 'field-merge))

;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-valid? contribution)
  (or (not (poo-flow-module-field-contribution-field-contract? contribution))
      (poo-flow-module-value-type-accepts?
       (poo-flow-module-field-contribution-field-value-type contribution)
       (poo-flow-module-field-contribution-value contribution))))

;;; Field merge names are interpreted once behind the prototype method.  The
;;; contribution-to-extension path dispatches through native POO slots.
;; : (-> Symbol Symbol PooModuleFieldValue PooModuleExtensionOperation)
(def (poo-flow-module-field-operation field-identity merge value)
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
    (poo-flow-module-extension-slot-override field-identity value))))

;;; Native generic dispatch lets refined contribution prototypes replace the
;;; projection without extending this owner with another representation case.
;; : (-> PooModuleFieldContribution PooModuleExtensionOperation)
(.defgeneric (poo-flow-module-field-contribution-operation contribution)
  slot: .operation)

;;; Boundary: module field contribution to extension is the policy-visible edge
;;; for module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooModuleFieldContribution PooModuleExtensionContribution)
(def (poo-flow-module-field-contribution->extension contribution)
  (if (poo-flow-module-field-contribution-valid? contribution)
    (poo-flow-module-extension-contribution
     (poo-flow-module-field-contribution-target contribution)
     (list (poo-flow-module-field-contribution-operation contribution)))
      (error "poo-flow module field contribution violates its POO contract"
             contribution)))

;;; Field contribution projection is a map because validation happens at each
;;; contribution boundary before the generic extension graph sees operations.
;; : (-> [PooModuleFieldContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-field-contributions->extensions contributions)
  (map poo-flow-module-field-contribution->extension contributions))

;;; Transformer contracts are object-owned wrappers around standard
;;; list/map-shaped operations. They validate user or agent repair payloads
;;; before those payloads become ordinary field contributions.
;; : (forall (m) (-> Symbol Symbol Symbol Symbol Symbol Boolean MaybeSymbol m PooModuleTransformerContract))
;; : (-> Symbol Symbol Symbol Symbol Symbol Boolean MaybeSymbol Alist PooModuleTransformerContract)
(def (poo-flow-module-transformer-contract identity
                                           merge
                                           input-type
                                           argument-type
                                           output-type
                                           idempotent?
                                           identity-key
                                           metadata)
  (for-each
   (lambda (value-type)
     (unless (poo-flow-module-value-type? value-type)
       (raise-type-error Type value-type)))
   (list input-type argument-type output-type))
  (let ((identity-value identity)
        (merge-value merge)
        (input-type-value input-type)
        (argument-type-value argument-type)
        (output-type-value output-type)
        (idempotent-value idempotent?)
        (identity-key-value identity-key)
        (metadata-value metadata))
    (.o kind: poo-flow-module-transformer-contract-kind
        identity: identity-value
        merge: merge-value
        input-type: input-type-value
        argument-type: argument-type-value
        output-type: output-type-value
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
(def (poo-flow-module-transformer-contract-input-type transformer)
  (.ref transformer 'input-type))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-argument-type transformer)
  (.ref transformer 'argument-type))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-output-type transformer)
  (.ref transformer 'output-type))
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
   PooFlowModuleListType
   PooFlowModuleListType
   PooFlowModuleListType
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.append))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-list-remove-contract
  (poo-flow-module-transformer-contract
   'list.remove
   'remove
   PooFlowModuleListType
   PooFlowModuleListType
   PooFlowModuleListType
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.remove))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-map-set-contract
  (poo-flow-module-transformer-contract
   'map.set
   'override
   PooFlowModuleMapType
   PooFlowModuleMapType
   PooFlowModuleMapType
   #t
   #f
   '((scope . object-core) (standard-library-shape . map.set))))

;; : (-> Symbol Symbol Boolean)
(def (poo-flow-module-transformer-type-compatible? expected actual)
  (or (eq? expected PooFlowModuleAnyType)
      (eq? actual PooFlowModuleAnyType)
      (eq? expected actual)
      (and (eq? expected PooFlowModuleMapType)
           (eq? actual PooFlowModuleAlistType))
      (and (eq? expected PooFlowModuleAlistType)
           (eq? actual PooFlowModuleMapType))))

;; : (-> Symbol PooModuleTransformerContract String)
(def (poo-flow-module-transformer-diagnostic code transformer)
  (string-append
   "transformer:"
   (symbol->string (poo-flow-module-transformer-contract-identity transformer))
   ":"
   (symbol->string code)))

;;; Boundary: module transformer contract diagnostics is the policy-visible
;;; edge for module-system, object, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooModuleTransformerContract PooModuleFieldContract PooModuleFieldValue [String])
(def (poo-flow-module-transformer-contract-diagnostics transformer field value)
  (append
   (if (poo-flow-module-transformer-type-compatible?
        (poo-flow-module-transformer-contract-input-type transformer)
        (poo-flow-module-field-contract-value-type field))
     '()
     (list (poo-flow-module-transformer-diagnostic
            'field-kind-mismatch
            transformer)))
   (if (poo-flow-module-value-type-accepts?
        (poo-flow-module-transformer-contract-argument-type transformer)
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

;;; Boundary: module transformer field contribution is the policy-visible edge
;;; for module-system, object, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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
