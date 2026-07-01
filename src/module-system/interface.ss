;;; -*- Gerbil -*-
;;; Boundary: Marlin-style module interface and config helpers.
;;; Invariant: interface values are schemas and metadata, not loaders.

(import (only-in :clan/poo/object .all-slots .o .ref object?))

(export poo-flow-modules-kind
        poo-flow-brand-name
        poo-flow-brand-group
        poo-flow-scheme-owner
        poo-flow-module-system-owner
        poo-flow-module-workflow-kind
        poo-flow-module-value-catalog-kind
        poo-flow-eval-modules-result-kind
        poo-flow-module-system-presentation-kind
        poo-flow-module-interface-kind
        poo-flow-module-import-kind
        poo-flow-module-import-source-ref-kind
        poo-flow-module-import-local-source-kind
        poo-flow-module-interface-prototype
        poo-flow-module-interface
        poo-flow-module-interface?
        poo-flow-module-interface-id
        poo-flow-module-interface-schemas
        poo-flow-module-interface-metadata
        poo-flow-string-required
        poo-flow-string-constant
        poo-flow-string-default
        poo-flow-string-optional
        poo-flow-option-policy
        poo-flow-option-append
        poo-flow-option-override
        poo-flow-option-conflict
        poo-flow-module-kind=?
        poo-flow-module-object-has-slot?
        poo-flow-module-object-ref/default
        poo-flow-module-object->alist)

;;; Boundary: poo-flow is the product/module-system brand, not the bare POO prefix.
;; : (-> Unit String)
(def poo-flow-brand-name
  "poo-flow")

;;; Boundary: default module group uses the brand identity.
;; : (-> Unit Symbol)
(def poo-flow-brand-group
  'poo-flow)

;;; Boundary: Scheme-side ownership is branded but still Gerbil-hosted.
;; : (-> Unit String)
(def poo-flow-scheme-owner
  "poo-flow.scheme")

;;; Boundary: module-system ownership is distinct from runtime execution.
;; : (-> Unit String)
(def poo-flow-module-system-owner
  "poo-flow.modules")

;;; Boundary: stable ids are receipt vocabulary only; they do not choose a loader.
;; : (-> Unit ModuleKindId)
(def poo-flow-modules-kind
  "poo-flow.modules.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-workflow-kind
  "poo-flow.modules.workflow.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-value-catalog-kind
  "poo-flow.modules.value-catalog.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-eval-modules-result-kind
  "poo-flow.modules.eval-result.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-system-presentation-kind
  "poo-flow.modules.system-presentation.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-interface-kind
  "poo-flow.modules.interface.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-import-kind
  "poo-flow.modules.import.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-import-source-ref-kind
  "poo-flow.modules.import.source-ref.v1")

;; : (-> Unit ModuleKindId)
(def poo-flow-module-import-local-source-kind
  "poo-flow.modules.import.local-source.v1")

;;; Boundary: interface prototype defaults are sparse so configs can override.
;; : (-> Unit PooModuleInterfacePrototype)
(def poo-flow-module-interface-prototype
  (.o kind: poo-flow-module-interface-kind
      id: "anonymous-poo-module-interface"
      brand-name: poo-flow-brand-name
      schemas: (.o)
      metadata: '()))

;;; Boundary: module kind= predicate is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> ModuleKind ModuleKind Boolean)
(def (poo-flow-module-kind=? value expected)
  (cond
   ((and (string? value) (string? expected))
    (string=? value expected))
   (else
    (equal? value expected))))

;;; Boundary: config lookup stays POO slot-based and avoids list-shape parsing.
;; : (-> POOConfigRecord Symbol Boolean)
(def (poo-flow-module-object-has-slot? object slot-name)
  (and (object? object)
       (member slot-name (.all-slots object))))

;;; Boundary: module object ref default is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> POOConfigRecord Symbol ConfigSlotValue ConfigSlotValue)
(def (poo-flow-module-object-ref/default object slot-name default-value)
  (if (poo-flow-module-object-has-slot? object slot-name)
    (.ref object slot-name)
    default-value))

;;; Boundary: alist projection happens only at activation/config edges.
;; : (-> POOConfigRecord [Symbol] ModuleOptionAlist ModuleOptionAlist)
(def (poo-flow-module-object->alist/rev object slot-names rows-rev)
  (if (null? slot-names)
    rows-rev
    (poo-flow-module-object->alist/rev
     object
     (cdr slot-names)
     (cons (cons (car slot-names) (.ref object (car slot-names)))
           rows-rev))))

;; : (-> POOConfigRecordOrAlist ModuleOptionAlist)
(def (poo-flow-module-object->alist value)
  (cond
   ((object? value)
    (reverse
     (poo-flow-module-object->alist/rev value (.all-slots value) '())))
   ((list? value) value)
   (else '())))

;;; Boundary: schemas live on the interface, user values live in config objects.
;; : (-> InterfaceId InterfaceSchemaObject InterfaceMetadata PooModuleInterface)
(def (poo-flow-module-interface interface-id-value schema-object metadata-value)
  (.o (:: @ (list poo-flow-module-interface-prototype))
      id: interface-id-value
      schemas: schema-object
      metadata: metadata-value))

;;; Boundary: interface detection uses kind slots, not constructor identity.
;; : (-> PooModuleInterfaceCandidate Boolean)
(def (poo-flow-module-interface? value)
  (and (object? value)
       (poo-flow-module-object-has-slot? value 'kind)
       (poo-flow-module-kind=? (.ref value 'kind) poo-flow-module-interface-kind)))

;; : (-> PooModuleInterface InterfaceId)
(def (poo-flow-module-interface-id interface)
  (.ref interface 'id))

;; : (-> PooModuleInterface InterfaceSchemaObject)
(def (poo-flow-module-interface-schemas interface)
  (.ref interface 'schemas))

;; : (-> PooModuleInterface InterfaceMetadata)
(def (poo-flow-module-interface-metadata interface)
  (.ref interface 'metadata))

;;; Boundary: schema helper records are intentionally plain POO values.
;; : (-> Unit InterfaceSchemaSpec)
(def (poo-flow-string-required)
  (.o type: 'String))

;; : (-> String InterfaceSchemaSpec)
(def (poo-flow-string-constant constant-value)
  (.o type: 'String
      constant: constant-value))

;; : (-> String InterfaceSchemaSpec)
(def (poo-flow-string-default default-value)
  (.o type: 'String
      default: default-value))

;; : (-> Unit InterfaceSchemaSpec)
(def (poo-flow-string-optional)
  (.o type: 'String
      optional?: #t))

;;; Boundary: policy helpers declare option semantics without reading configs.
;; : (-> OptionValueType OptionPolicyRule Value Alist InterfaceSchemaSpec)
(def (poo-flow-option-policy value-type policy-rule default-value metadata-value)
  (.o type: value-type
      policy: policy-rule
      default: default-value
      metadata: metadata-value))

;; : (-> OptionValueType Value InterfaceSchemaSpec)
(def (poo-flow-option-append value-type default-value)
  (poo-flow-option-policy value-type 'append default-value '()))

;; : (-> OptionValueType Value InterfaceSchemaSpec)
(def (poo-flow-option-override value-type default-value)
  (poo-flow-option-policy value-type 'override default-value '()))

;; : (-> OptionValueType InterfaceSchemaSpec)
(def (poo-flow-option-conflict value-type)
  (.o type: value-type
      policy: 'conflict))
