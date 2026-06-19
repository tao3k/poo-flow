;;; -*- Gerbil -*-
;;; Boundary: POO module object core contracts and object-aware wrappers.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?
                 make-object
                 $constant-slot-spec
                 $computed-slot-spec)
        :poo-flow/src/modules/extension)

(export poo-flow-module-object-kind
        poo-flow-module-field-contract-kind
        poo-flow-module-field-contribution-kind
        poo-flow-module-config-merge-result-kind
        poo-flow-module-objects-root-identity
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
        poo-flow-module-config-merge-result-stable?
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
        poo-flow-module-objects-node
        poo-flow-module-objects-ref
        poo-flow-module-objects-mk-merge)

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

;; : (-> PooModuleValueCandidate PooModuleKindId Boolean)
(def (poo-flow-module-object-kind? value kind)
  (and (object? value) (equal? (.ref value 'kind) kind)))

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
  (poo-flow-module-object-kind? value poo-flow-module-field-contribution-kind))

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
  (poo-flow-module-object-kind? value poo-flow-module-config-merge-result-kind))

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
    (make-object
     supers: inherits-value
     defaults: '((fields . ()))
     slots: (list
             (poo-flow-module-object-constant-slot
              'kind
              poo-flow-module-object-kind)
             (poo-flow-module-object-constant-slot
              'identity
              identity-value)
             (poo-flow-module-object-constant-slot
              'inherits
              inherits-value)
             (poo-flow-module-object-constant-slot
              'direct-fields
              fields-value)
             (poo-flow-module-object-fields-slot fields-value)
             (poo-flow-module-object-constant-slot
              'metadata
              metadata-value)))))

;; : (-> PooModuleObjectCandidate Boolean)
(def (poo-flow-module-object? value)
  (poo-flow-module-object-kind? value poo-flow-module-object-kind))

;; : (-> PooModuleObject Symbol)
(def (poo-flow-module-object-identity object) (.ref object 'identity))
;; : (-> PooModuleObject [PooModuleObject])
(def (poo-flow-module-object-inherits object) (.ref object 'inherits))
;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-fields object) (.ref object 'direct-fields))
;; : (-> PooModuleObject PooModuleObjectMetadata)
(def (poo-flow-module-object-metadata object) (.ref object 'metadata))

;; : (-> Symbol Value PooModuleObjectSlotSpec)
(def (poo-flow-module-object-constant-slot key value)
  (cons key ($constant-slot-spec value)))

;; : (-> [PooModuleFieldContract] PooModuleObjectSlotSpec)
(def (poo-flow-module-object-fields-slot fields)
  (cons 'fields
        ($computed-slot-spec
         (lambda (_self superfun)
           (poo-flow-module-object-fields-merge (superfun) fields)))))

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
  (if (null? inherits)
    '()
    (poo-flow-module-object-resolved-fields
     (poo-flow-module-object 'objects.inherited.fields inherits '() '()))))

;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-resolved-fields object)
  (.ref object 'fields))

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

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotMap)
(def (poo-flow-module-object-alist-set entries key value)
  (cond ((null? entries) (list (cons key value)))
        ((equal? (caar entries) key) (cons (cons key value) (cdr entries)))
        (else (cons (car entries)
                    (poo-flow-module-object-alist-set
                     (cdr entries)
                     key
                     value)))))

;; : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
(def (poo-flow-module-object-slots-merge base extra)
  (cond ((null? extra) base)
        (else
         (poo-flow-module-object-slots-merge
          (poo-flow-module-object-alist-set base (caar extra) (cdar extra))
          (cdr extra)))))

;;; Object nodes are extension nodes seeded with field defaults; downstream
;;; contributions only need to provide changed slots.
;; : (-> PooModuleObject PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-object-node object slots children)
  (poo-flow-module-extension-node
   (poo-flow-module-object-identity object)
   (poo-flow-module-object-slots-merge
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
