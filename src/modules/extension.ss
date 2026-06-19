;;; -*- Gerbil -*-
;;; Boundary: generic POO module extension graph and fixed-point convergence.

(import (only-in :clan/poo/object .o .ref object?))

(export poo-flow-module-extension-node-kind
        poo-flow-module-extension-operation-kind
        poo-flow-module-extension-contribution-kind
        poo-flow-module-extension-result-kind
        poo-flow-module-object-kind
        poo-flow-module-field-contract-kind
        poo-flow-module-field-contribution-kind
        poo-flow-module-config-merge-result-kind
        poo-flow-module-extension-node
        poo-flow-module-extension-node?
        poo-flow-module-extension-node-identity
        poo-flow-module-extension-node-slots
        poo-flow-module-extension-node-children
        poo-flow-module-extension-child-ref
        poo-flow-module-extension-slot-override
        poo-flow-module-extension-slot-append
        poo-flow-module-extension-slot-prepend
        poo-flow-module-extension-slot-remove
        poo-flow-module-extension-node-extend
        poo-flow-module-extension-node-remove
        poo-flow-module-extension-contribution
        poo-flow-module-extension-contribution?
        poo-flow-module-extension-contribution-target
        poo-flow-module-extension-contribution-operations
        poo-flow-module-extension-apply-contribution
        poo-flow-module-extension-apply-contributions
        poo-flow-module-extension-fixed-point
        poo-flow-module-extension-result?
        poo-flow-module-extension-result-root
        poo-flow-module-extension-result-iterations
        poo-flow-module-extension-result-stable?
        poo-flow-module-extension-node-snapshot
        poo-flow-module-object
        poo-flow-module-object?
        poo-flow-module-object-identity
        poo-flow-module-object-inherits
        poo-flow-module-object-fields
        poo-flow-module-object-metadata
        poo-flow-module-object-resolved-fields
        poo-flow-module-object-field
        poo-flow-module-object-default-slots
        poo-flow-module-object-node
        poo-flow-module-object-contributions
        poo-flow-module-objects-root-identity
        poo-flow-module-objects-node
        poo-flow-module-objects-ref
        poo-flow-module-objects-mk-merge
        poo-flow-module-field-contract
        poo-flow-module-field-contract?
        poo-flow-module-field-contract-identity
        poo-flow-module-field-contract-value-kind
        poo-flow-module-field-contract-merge
        poo-flow-module-field-contract-default
        poo-flow-module-field-contract-metadata
        poo-flow-module-field-contract-accepts?
        poo-flow-module-field-contribution
        poo-flow-module-field-contribution?
        poo-flow-module-field-contribution-target
        poo-flow-module-field-contribution-field
        poo-flow-module-field-contribution-value
        poo-flow-module-field-contribution->extension
        poo-flow-module-field-contributions->extensions
        poo-flow-module-config-mk-merge
        poo-flow-module-config-merge-result?
        poo-flow-module-config-merge-result-extension-result
        poo-flow-module-config-merge-result-contributions
        poo-flow-module-config-merge-result-root
        poo-flow-module-config-merge-result-iterations
        poo-flow-module-config-merge-result-stable?)

;; : PooModuleExtensionNodeKindId
;; | PooModuleExtensionNodeKindId = String
(def poo-flow-module-extension-node-kind "poo-flow.modules.extension.node.v1")
;; : PooModuleExtensionOperationKindId
;; | PooModuleExtensionOperationKindId = String
(def poo-flow-module-extension-operation-kind "poo-flow.modules.extension.operation.v1")
;; : PooModuleExtensionContributionKindId
;; | PooModuleExtensionContributionKindId = String
(def poo-flow-module-extension-contribution-kind "poo-flow.modules.extension.contribution.v1")
;; : PooModuleExtensionResultKindId
;; | PooModuleExtensionResultKindId = String
(def poo-flow-module-extension-result-kind "poo-flow.modules.extension.result.v1")
;; : PooModuleObjectKindId
;; | PooModuleObjectKindId = String
(def poo-flow-module-object-kind "poo-flow.modules.object.v1")
;; : PooModuleFieldContractKindId
;; | PooModuleFieldContractKindId = String
(def poo-flow-module-field-contract-kind "poo-flow.modules.field-contract.v1")
;; : PooModuleFieldContributionKindId
;; | PooModuleFieldContributionKindId = String
(def poo-flow-module-field-contribution-kind "poo-flow.modules.field-contribution.v1")
;; : PooModuleConfigMergeResultKindId
;; | PooModuleConfigMergeResultKindId = String
(def poo-flow-module-config-merge-result-kind "poo-flow.modules.config-merge-result.v1")
;; : PooModuleObjectsRootIdentity
;; | PooModuleObjectsRootIdentity = Symbol
(def poo-flow-module-objects-root-identity 'objects)

;;; Kind checks are slot-based so POO extension objects can evolve without
;;; exposing constructor identity to downstream module configs.
;; : (-> PooModuleValueCandidate PooModuleKindId Boolean)
(def (poo-flow-module-extension-kind? value kind)
  (and (object? value) (equal? (.ref value 'kind) kind)))

;;; Nodes are inert POO graph data; extension operations transform this graph
;;; before any loader or runtime code sees module configuration.
;; : (-> Symbol Alist [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-extension-node identity slots children)
  (let ((identity-value identity) (slots-value slots) (children-value children))
    (.o kind: poo-flow-module-extension-node-kind
        identity: identity-value
        slots: slots-value
        children: children-value)))

;; : (-> PooModuleExtensionNodeCandidate Boolean)
(def (poo-flow-module-extension-node? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-node-kind))

;; : (-> PooModuleExtensionNode Symbol)
(def (poo-flow-module-extension-node-identity node) (.ref node 'identity))
;; : (-> PooModuleExtensionNode PooModuleSlotMap)
(def (poo-flow-module-extension-node-slots node) (.ref node 'slots))
;; : (-> PooModuleExtensionNode [PooModuleExtensionNode])
(def (poo-flow-module-extension-node-children node) (.ref node 'children))

;;; Operations are normalized to one POO value so module objects, field
;;; contracts, and direct graph edits share a single merge path.
;; : (-> Symbol MaybeSymbol PooModuleSlotValue MaybePooModuleExtensionNode MaybeSymbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-operation action slot value node target)
  (let ((action-value action)
        (slot-value slot)
        (value-value value)
        (node-value node)
        (target-value target))
    (.o kind: poo-flow-module-extension-operation-kind
        action: action-value
        slot: slot-value
        value: value-value
        node: node-value
        target: target-value)))

;; : (-> PooModuleExtensionOperation Symbol)
(def (poo-flow-module-extension-operation-action operation) (.ref operation 'action))
;; : (-> PooModuleExtensionOperation MaybeSymbol)
(def (poo-flow-module-extension-operation-slot operation) (.ref operation 'slot))
;; : (-> PooModuleExtensionOperation PooModuleSlotValue)
(def (poo-flow-module-extension-operation-value operation) (.ref operation 'value))
;; : (-> PooModuleExtensionOperation MaybePooModuleExtensionNode)
(def (poo-flow-module-extension-operation-node operation) (.ref operation 'node))
;; : (-> PooModuleExtensionOperation MaybeSymbol)
(def (poo-flow-module-extension-operation-target operation) (.ref operation 'target))

;; : (-> Symbol PooModuleSlotValue PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-override slot value)
  (poo-flow-module-extension-operation 'slot-override slot value #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-append slot values)
  (poo-flow-module-extension-operation 'slot-append slot values #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-prepend slot values)
  (poo-flow-module-extension-operation 'slot-prepend slot values #f #f))
;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-remove slot values)
  (poo-flow-module-extension-operation 'slot-remove slot values #f #f))
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-extend node)
  (poo-flow-module-extension-operation 'node-extend #f #f node #f))
;; : (-> Symbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-remove target)
  (poo-flow-module-extension-operation 'node-remove #f #f #f target))

;;; Contributions keep the target identity outside individual operations so a
;;; profile can patch one node with several ordered edits.
;; : (-> Symbol [PooModuleExtensionOperation] PooModuleExtensionContribution)
(def (poo-flow-module-extension-contribution target operations)
  (let ((target-value target) (operations-value operations))
    (.o kind: poo-flow-module-extension-contribution-kind
        target: target-value
        operations: operations-value)))

;; : (-> PooModuleExtensionContributionCandidate Boolean)
(def (poo-flow-module-extension-contribution? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-contribution-kind))
;; : (-> PooModuleExtensionContribution Symbol)
(def (poo-flow-module-extension-contribution-target contribution) (.ref contribution 'target))
;; : (-> PooModuleExtensionContribution [PooModuleExtensionOperation])
(def (poo-flow-module-extension-contribution-operations contribution) (.ref contribution 'operations))

;;; Fixed-point results report convergence explicitly; unstable results are
;;; evidence for the doctor path instead of hidden runtime failures.
;; : (-> PooModuleExtensionNode Integer Boolean PooModuleExtensionResult)
(def (poo-flow-module-extension-result root iterations stable?)
  (let ((root-value root) (iterations-value iterations) (stable-value stable?))
    (.o kind: poo-flow-module-extension-result-kind
        root: root-value
        iterations: iterations-value
        stable?: stable-value)))

;; : (-> PooModuleResultCandidate Boolean)
(def (poo-flow-module-extension-result? value)
  (poo-flow-module-extension-kind? value poo-flow-module-extension-result-kind))
;; : (-> PooModuleExtensionResult PooModuleExtensionNode)
(def (poo-flow-module-extension-result-root result) (.ref result 'root))
;; : (-> PooModuleExtensionResult Integer)
(def (poo-flow-module-extension-result-iterations result) (.ref result 'iterations))
;; : (-> PooModuleExtensionResult Boolean)
(def (poo-flow-module-extension-result-stable? result) (.ref result 'stable?))

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
  (poo-flow-module-extension-kind? value poo-flow-module-field-contract-kind))

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

;;; Value-kind checks are intentionally shallow; runtime-specific validation
;;; remains owned by sandbox/workflow adapters after config projection.
;; : (-> PooModuleFieldContract PooModuleFieldValueCandidate Boolean)
(def (poo-flow-module-field-contract-accepts? field value)
  (let (value-kind (poo-flow-module-field-contract-value-kind field))
    (cond ((eq? value-kind 'Any) #t)
          ((eq? value-kind 'List) (list? value))
          ((eq? value-kind 'Symbol) (symbol? value))
          ((eq? value-kind 'String) (string? value))
          ((eq? value-kind 'Boolean) (boolean? value))
          ((eq? value-kind 'Object) (object? value))
          ((eq? value-kind 'Node) (poo-flow-module-extension-node? value))
          (else #t))))

;;; Field contributions are object-aware extension requests: the field decides
;;; merge behavior while the contribution carries target and value.
;; : (-> Symbol PooModuleFieldContract PooModuleFieldValue PooModuleFieldContribution)
(def (poo-flow-module-field-contribution target field value)
  (let ((target-value target)
        (field-value field)
        (value-value value))
    (.o kind: poo-flow-module-field-contribution-kind
        target: target-value
        field: field-value
        value: value-value)))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution? value)
  (poo-flow-module-extension-kind? value poo-flow-module-field-contribution-kind))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-target contribution)
  (.ref contribution 'target))
;; : (-> PooModuleFieldContribution PooModuleFieldContract)
(def (poo-flow-module-field-contribution-field contribution)
  (.ref contribution 'field))
;; : (-> PooModuleFieldContribution PooModuleFieldValue)
(def (poo-flow-module-field-contribution-value contribution)
  (.ref contribution 'value))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-identity contribution)
  (let (field (poo-flow-module-field-contribution-field contribution))
    (if (poo-flow-module-field-contract? field)
      (poo-flow-module-field-contract-identity field)
      field)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-merge contribution)
  (let (field (poo-flow-module-field-contribution-field contribution))
    (if (poo-flow-module-field-contract? field)
      (poo-flow-module-field-contract-merge field)
      'override)))

;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-valid? contribution)
  (let (field (poo-flow-module-field-contribution-field contribution))
    (or (not (poo-flow-module-field-contract? field))
        (poo-flow-module-field-contract-accepts?
         field
         (poo-flow-module-field-contribution-value contribution)))))

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
  (if (poo-flow-module-field-contribution-valid? contribution)
    (poo-flow-module-extension-contribution
     (poo-flow-module-field-contribution-target contribution)
     (list (poo-flow-module-field-contribution-operation contribution)))
    (error "poo-flow module field contribution violates its POO contract"
           contribution)))

;; : (-> [PooModuleFieldContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-field-contributions->extensions contributions)
  (map poo-flow-module-field-contribution->extension contributions))

;;; Config merge results preserve the original contributions so diagnostics can
;;; explain both the final graph and the inputs that produced it.
;; : (-> PooModuleExtensionResult [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-config-merge-result extension-result contributions)
  (let ((extension-result-value extension-result)
        (contributions-value contributions))
    (.o kind: poo-flow-module-config-merge-result-kind
        extension-result: extension-result-value
        contributions: contributions-value)))

;; : (-> PooModuleConfigMergeResultCandidate Boolean)
(def (poo-flow-module-config-merge-result? value)
  (poo-flow-module-extension-kind? value poo-flow-module-config-merge-result-kind))

;; : (-> PooModuleConfigMergeResult PooModuleExtensionResult)
(def (poo-flow-module-config-merge-result-extension-result result)
  (.ref result 'extension-result))
;; : (-> PooModuleConfigMergeResult [PooModuleFieldContribution])
(def (poo-flow-module-config-merge-result-contributions result)
  (.ref result 'contributions))
;; : (-> PooModuleConfigMergeResult PooModuleExtensionNode)
(def (poo-flow-module-config-merge-result-root result)
  (poo-flow-module-extension-result-root
   (poo-flow-module-config-merge-result-extension-result result)))
;; : (-> PooModuleConfigMergeResult Integer)
(def (poo-flow-module-config-merge-result-iterations result)
  (poo-flow-module-extension-result-iterations
   (poo-flow-module-config-merge-result-extension-result result)))
;; : (-> PooModuleConfigMergeResult Boolean)
(def (poo-flow-module-config-merge-result-stable? result)
  (poo-flow-module-extension-result-stable?
   (poo-flow-module-config-merge-result-extension-result result)))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-config-mk-merge base contributions)
  (poo-flow-module-config-merge-result
   (poo-flow-module-extension-fixed-point
    base
    (poo-flow-module-field-contributions->extensions contributions))
   contributions))

;;; Module objects are POO-side schemas. They can inherit fields, but they do
;;; not instantiate modules or evaluate user config.
;; : (-> Symbol [PooModuleObject] [PooModuleFieldContract] PooModuleObjectMetadata PooModuleObject)
(def (poo-flow-module-object identity inherits fields metadata)
  (let ((identity-value identity)
        (inherits-value inherits)
        (fields-value fields)
        (metadata-value metadata))
    (.o kind: poo-flow-module-object-kind
        identity: identity-value
        inherits: inherits-value
        fields: fields-value
        metadata: metadata-value)))

;; : (-> PooModuleObjectCandidate Boolean)
(def (poo-flow-module-object? value)
  (poo-flow-module-extension-kind? value poo-flow-module-object-kind))

;; : (-> PooModuleObject Symbol)
(def (poo-flow-module-object-identity object) (.ref object 'identity))
;; : (-> PooModuleObject [PooModuleObject])
(def (poo-flow-module-object-inherits object) (.ref object 'inherits))
;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-fields object) (.ref object 'fields))
;; : (-> PooModuleObject PooModuleObjectMetadata)
(def (poo-flow-module-object-metadata object) (.ref object 'metadata))

;; : (-> (U PooModuleFieldContract Symbol) Symbol)
(def (poo-flow-module-object-field-identity field)
  (if (poo-flow-module-field-contract? field)
    (poo-flow-module-field-contract-identity field)
    field))

;; : (-> [PooModuleFieldContract] PooModuleFieldContract [PooModuleFieldContract])
(def (poo-flow-module-object-field-set fields field)
  (let (field-identity (poo-flow-module-object-field-identity field))
    (cond ((null? fields) (list field))
          ((equal? (poo-flow-module-object-field-identity (car fields))
                   field-identity)
           (cons field (cdr fields)))
          (else
           (cons (car fields)
                 (poo-flow-module-object-field-set (cdr fields) field))))))

;; : (-> [PooModuleFieldContract] [PooModuleFieldContract] [PooModuleFieldContract])
(def (poo-flow-module-object-fields-merge base extra)
  (cond ((null? extra) base)
        (else
         (poo-flow-module-object-fields-merge
          (poo-flow-module-object-field-set base (car extra))
          (cdr extra)))))

;; : (-> [PooModuleObject] [PooModuleFieldContract])
(def (poo-flow-module-object-inherited-fields inherits)
  (cond ((null? inherits) '())
        (else
         (poo-flow-module-object-fields-merge
          (poo-flow-module-object-resolved-fields (car inherits))
          (poo-flow-module-object-inherited-fields (cdr inherits))))))

;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-resolved-fields object)
  (poo-flow-module-object-fields-merge
   (poo-flow-module-object-inherited-fields
    (poo-flow-module-object-inherits object))
   (poo-flow-module-object-fields object)))

;; poo-flow-module-object-field
;;   : (-> PooModuleObject Symbol MaybePooModuleFieldContract)
;;   | contract: resolves inherited fields before selecting by identity
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-object-field object 'backend)
;;       ;; => field contract or #f
;;       ```
;;     %
(def (poo-flow-module-object-field object identity)
  (let field-ref ((fields (poo-flow-module-object-resolved-fields object)))
    (cond ((null? fields) #f)
          ((equal? (poo-flow-module-object-field-identity (car fields))
                   identity)
           (car fields))
          (else (field-ref (cdr fields))))))

;; : (-> PooModuleObject PooModuleSlotMap)
(def (poo-flow-module-object-default-slots object)
  (map (lambda (field)
         (cons (poo-flow-module-field-contract-identity field)
               (poo-flow-module-field-contract-default field)))
       (poo-flow-module-object-resolved-fields object)))

;;; Object nodes are extension nodes seeded with field defaults; downstream
;;; contributions only need to provide changed slots.
;; : (-> PooModuleObject PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-object-node object slots children)
  (poo-flow-module-extension-node
   (poo-flow-module-object-identity object)
   (poo-flow-module-extension-slots-merge
    (poo-flow-module-object-default-slots object)
    slots)
   children))

;; : (-> PooModuleObject Pair PooModuleFieldContribution)
(def (poo-flow-module-object-contribution object entry)
  (let (field (poo-flow-module-object-field object (car entry)))
    (if field
      (poo-flow-module-field-contribution
       (poo-flow-module-object-identity object)
       field
       (cdr entry))
      (error "unknown poo-flow module object field"
             (poo-flow-module-object-identity object)
             (car entry)))))

;; : (-> PooModuleObject PooModuleObjectContributionEntries [PooModuleFieldContribution])
(def (poo-flow-module-object-contributions object entries)
  (map (lambda (entry)
         (poo-flow-module-object-contribution object entry))
       entries))

;;; The object namespace is a regular extension graph root, so object removal
;;; and extension use the same fixed-point merge path as runtime modules.
;; : (-> [PooModuleObject] PooModuleExtensionNode)
(def (poo-flow-module-objects-node objects)
  (poo-flow-module-extension-node
   poo-flow-module-objects-root-identity
   '((namespace . objects))
   (map (lambda (object)
          (poo-flow-module-object-node object '() '()))
        objects)))

;; : (-> PooModuleExtensionNode Symbol MaybePooModuleExtensionNode)
(def (poo-flow-module-objects-ref objects-node identity)
  (poo-flow-module-extension-child-ref
   (poo-flow-module-extension-node-children objects-node)
   identity))

;; : (-> [PooModuleObject] [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-objects-mk-merge objects contributions)
  (poo-flow-module-config-mk-merge
   (poo-flow-module-objects-node objects)
   contributions))

;; : (-> PooModuleSlotValue [PooModuleSlotValue] Boolean)
(def (poo-flow-module-extension-member? value values)
  (and (member value values) #t))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-append-distinct base extra)
  (append
   base
   (filter (lambda (value)
             (not (poo-flow-module-extension-member? value base)))
           extra)))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-remove-elements values removed)
  (filter (lambda (value)
            (not (poo-flow-module-extension-member? value removed)))
          values))

;; : (-> PooModuleSlotValue [PooModuleSlotValue])
(def (poo-flow-module-extension-list-value value)
  (cond ((null? value) '())
        ((list? value) value)
        (else (list value))))

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotMap)
(def (poo-flow-module-extension-alist-set entries key value)
  (cond ((null? entries) (list (cons key value)))
        ((equal? (caar entries) key) (cons (cons key value) (cdr entries)))
        (else (cons (car entries)
                    (poo-flow-module-extension-alist-set (cdr entries) key value)))))

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotValue)
(def (poo-flow-module-extension-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> PooModuleExtensionNode PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-extension-replace-node node slots children)
  (poo-flow-module-extension-node
   (poo-flow-module-extension-node-identity node)
   slots
   children))

;; : (-> [PooModuleExtensionNode] Symbol MaybePooModuleExtensionNode)
(def (poo-flow-module-extension-child-ref children identity)
  (cond ((null? children) #f)
        ((equal? (poo-flow-module-extension-node-identity (car children)) identity)
         (car children))
        (else (poo-flow-module-extension-child-ref (cdr children) identity))))

;; : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
(def (poo-flow-module-extension-slots-merge base extra)
  (cond ((null? extra) base)
        (else
         (poo-flow-module-extension-slots-merge
          (poo-flow-module-extension-alist-set base (caar extra) (cdar extra))
          (cdr extra)))))

;; : (-> PooModuleExtensionNode PooModuleExtensionNode PooModuleExtensionNode)
(def (poo-flow-module-extension-node-merge base extra)
  (poo-flow-module-extension-node
   (poo-flow-module-extension-node-identity base)
   (poo-flow-module-extension-slots-merge
    (poo-flow-module-extension-node-slots base)
    (poo-flow-module-extension-node-slots extra))
   (poo-flow-module-extension-children-merge
    (poo-flow-module-extension-node-children base)
    (poo-flow-module-extension-node-children extra))))

;; : (-> [PooModuleExtensionNode] PooModuleExtensionNode [PooModuleExtensionNode])
(def (poo-flow-module-extension-children-merge-one children extra-child)
  (cond ((null? children) (list extra-child))
        ((equal? (poo-flow-module-extension-node-identity (car children))
                 (poo-flow-module-extension-node-identity extra-child))
         (cons (poo-flow-module-extension-node-merge (car children) extra-child)
               (cdr children)))
        (else
         (cons (car children)
               (poo-flow-module-extension-children-merge-one (cdr children)
                                                             extra-child)))))

;; : (-> [PooModuleExtensionNode] [PooModuleExtensionNode] [PooModuleExtensionNode])
(def (poo-flow-module-extension-children-merge children extra-children)
  (cond ((null? extra-children) children)
        (else
         (poo-flow-module-extension-children-merge
          (poo-flow-module-extension-children-merge-one children (car extra-children))
          (cdr extra-children)))))

;; : (-> [PooModuleExtensionNode] Symbol [PooModuleExtensionNode])
(def (poo-flow-module-extension-children-remove children identity)
  (cond ((null? children) '())
        ((equal? (poo-flow-module-extension-node-identity (car children)) identity)
         (poo-flow-module-extension-children-remove (cdr children) identity))
        (else
         (cons (car children)
               (poo-flow-module-extension-children-remove (cdr children) identity)))))

;;; List slot operations normalize scalar input before merge, so user-facing
;;; feature rows can pass either one value or a list value consistently.
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation Boolean PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-slot-list-op node operation append?)
  (let* ((slot (poo-flow-module-extension-operation-slot operation))
         (current (poo-flow-module-extension-list-value
                   (poo-flow-module-extension-alist-ref/default
                    (poo-flow-module-extension-node-slots node) slot '())))
         (extra (poo-flow-module-extension-list-value
                 (poo-flow-module-extension-operation-value operation)))
         (next (if append?
                 (poo-flow-module-extension-append-distinct current extra)
                 (poo-flow-module-extension-append-distinct extra current))))
    (poo-flow-module-extension-replace-node
     node
     (poo-flow-module-extension-alist-set
      (poo-flow-module-extension-node-slots node) slot next)
     (poo-flow-module-extension-node-children node))))

;;; Operation application is deliberately total: unknown operation names leave
;;; the node unchanged so extension doctors can report policy mistakes later.
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operation node operation)
  (let (action (poo-flow-module-extension-operation-action operation))
    (cond
     ((eq? action 'slot-override)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-alist-set
        (poo-flow-module-extension-node-slots node)
        (poo-flow-module-extension-operation-slot operation)
        (poo-flow-module-extension-operation-value operation))
       (poo-flow-module-extension-node-children node)))
     ((eq? action 'slot-append)
      (poo-flow-module-extension-apply-slot-list-op node operation #t))
     ((eq? action 'slot-prepend)
      (poo-flow-module-extension-apply-slot-list-op node operation #f))
     ((eq? action 'slot-remove)
      (let* ((slot (poo-flow-module-extension-operation-slot operation))
             (current (poo-flow-module-extension-list-value
                       (poo-flow-module-extension-alist-ref/default
                        (poo-flow-module-extension-node-slots node) slot '())))
             (removed (poo-flow-module-extension-list-value
                       (poo-flow-module-extension-operation-value operation))))
        (poo-flow-module-extension-replace-node
         node
         (poo-flow-module-extension-alist-set
          (poo-flow-module-extension-node-slots node)
          slot
          (poo-flow-module-extension-remove-elements current removed))
         (poo-flow-module-extension-node-children node))))
     ((eq? action 'node-extend)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (poo-flow-module-extension-children-merge-one
        (poo-flow-module-extension-node-children node)
        (poo-flow-module-extension-operation-node operation))))
     ((eq? action 'node-remove)
      (poo-flow-module-extension-replace-node
       node
       (poo-flow-module-extension-node-slots node)
       (poo-flow-module-extension-children-remove
        (poo-flow-module-extension-node-children node)
        (poo-flow-module-extension-operation-target operation))))
     (else node))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionOperation] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operations node operations)
  (cond ((null? operations) node)
        (else
         (poo-flow-module-extension-apply-operations
          (poo-flow-module-extension-apply-operation node (car operations))
          (cdr operations)))))

;;; Contribution application recurses through children after the current target
;;; has been patched, which keeps parent and child updates in one graph walk.
;; : (-> PooModuleExtensionNode PooModuleExtensionContribution PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contribution node contribution)
  (let* ((target (poo-flow-module-extension-contribution-target contribution))
         (current
          (if (equal? target (poo-flow-module-extension-node-identity node))
            (poo-flow-module-extension-apply-operations
             node
             (poo-flow-module-extension-contribution-operations contribution))
            node)))
    (poo-flow-module-extension-replace-node
     current
     (poo-flow-module-extension-node-slots current)
     (map (lambda (child)
            (poo-flow-module-extension-apply-contribution child contribution))
          (poo-flow-module-extension-node-children current)))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions node contributions)
  (cond ((null? contributions) node)
        (else
         (poo-flow-module-extension-apply-contributions
          (poo-flow-module-extension-apply-contribution node (car contributions))
          (cdr contributions)))))

;;; Snapshot comparison keeps fixed-point convergence structural and independent
;;; of POO object identity or lazy slot internals.
;; : (-> PooModuleExtensionNode PooModuleExtensionSnapshot)
;; | PooModuleExtensionSnapshot = List
(def (poo-flow-module-extension-node-snapshot node)
  (list (poo-flow-module-extension-node-identity node)
        (poo-flow-module-extension-node-slots node)
        (map poo-flow-module-extension-node-snapshot
             (poo-flow-module-extension-node-children node))))

;;; Fixed-point stepping is isolated so policy can see bounded recursion without
;;; mistaking it for a general-purpose list transform.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] Integer PooModuleExtensionResult)
(def (poo-flow-module-extension-fixed-point-step current contributions iteration)
  (let (next (poo-flow-module-extension-apply-contributions current contributions))
    (cond
     ((equal? (poo-flow-module-extension-node-snapshot current)
              (poo-flow-module-extension-node-snapshot next))
      (poo-flow-module-extension-result next iteration #t))
     ((>= iteration 16)
      (poo-flow-module-extension-result next iteration #f))
     (else
      (poo-flow-module-extension-fixed-point-step
       next
       contributions
       (+ iteration 1))))))

;; poo-flow-module-extension-fixed-point
;;   : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionResult)
;;   | contract: applies extension contributions until the graph snapshot is stable
;;   | warning: stops after 16 iterations and marks the result unstable
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-extension-fixed-point root contributions)
;;       ;; => extension result with root, iteration count, and stable? flag
;;       ```
;;     %
(def (poo-flow-module-extension-fixed-point base contributions)
  (poo-flow-module-extension-fixed-point-step base contributions 0))
