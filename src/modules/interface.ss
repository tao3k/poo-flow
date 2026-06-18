;;; -*- Gerbil -*-
;;; Boundary: Marlin-style module interface and config helpers.
;;; Invariant: interface values are schemas and metadata, not loaders.

(import (only-in :clan/poo/object .all-slots .o .ref object?))

(export poo-modules-kind
        poo-module-workflow-kind
        poo-module-value-catalog-kind
        poo-eval-modules-result-kind
        poo-module-system-presentation-kind
        poo-module-interface-kind
        poo-module-import-kind
        poo-module-import-source-ref-kind
        poo-module-import-local-source-kind
        poo-module-interface-prototype
        poo-module-interface
        poo-module-interface?
        poo-module-interface-id
        poo-module-interface-schemas
        poo-module-interface-metadata
        poo-string-required
        poo-string-constant
        poo-string-default
        poo-string-optional
        poo-option-merge
        poo-option-append
        poo-option-override
        poo-option-conflict
        poo-module-kind=?
        poo-module-object-has-slot?
        poo-module-object-ref/default
        poo-module-object->alist)

;;; Boundary: stable ids are receipt vocabulary only; they do not choose a loader.
;; ModuleKindId <- Unit
(def poo-modules-kind
  "poo.modules.v1")

;; ModuleKindId <- Unit
(def poo-module-workflow-kind
  "poo.modules.workflow.v1")

;; ModuleKindId <- Unit
(def poo-module-value-catalog-kind
  "poo.modules.value-catalog.v1")

;; ModuleKindId <- Unit
(def poo-eval-modules-result-kind
  "poo.modules.eval-result.v1")

;; ModuleKindId <- Unit
(def poo-module-system-presentation-kind
  "poo.modules.system-presentation.v1")

;; ModuleKindId <- Unit
(def poo-module-interface-kind
  "poo.modules.interface.v1")

;; ModuleKindId <- Unit
(def poo-module-import-kind
  "poo.modules.import.v1")

;; ModuleKindId <- Unit
(def poo-module-import-source-ref-kind
  "poo.modules.import.source-ref.v1")

;; ModuleKindId <- Unit
(def poo-module-import-local-source-kind
  "poo.modules.import.local-source.v1")

;;; Boundary: interface prototype defaults are sparse so configs can override.
;; PooModuleInterfacePrototype <- Unit
(def poo-module-interface-prototype
  (.o kind: poo-module-interface-kind
      id: "anonymous-poo-module-interface"
      schemas: (.o)
      metadata: '()))

;; Boolean <- ModuleKind ModuleKind
(def (poo-module-kind=? value expected)
  (cond
   ((and (string? value) (string? expected))
    (string=? value expected))
   (else
    (equal? value expected))))

;;; Boundary: config lookup stays record-like and avoids list-shape parsing.
;; Boolean <- POOConfigRecord Symbol
(def (poo-module-object-has-slot? object slot-name)
  (and (object? object)
       (member slot-name (.all-slots object))))

;; ConfigSlotValue <- POOConfigRecord Symbol ConfigSlotValue
(def (poo-module-object-ref/default object slot-name default-value)
  (if (poo-module-object-has-slot? object slot-name)
    (.ref object slot-name)
    default-value))

;;; Boundary: alist projection happens only at activation/config edges.
;; ModuleOptionAlist <- POOConfigRecordOrAlist
(def (poo-module-object->alist value)
  (cond
   ((object? value)
    (map (lambda (slot-name)
           (cons slot-name (.ref value slot-name)))
         (.all-slots value)))
   ((list? value) value)
   (else '())))

;;; Boundary: schemas live on the interface, user values live in config objects.
;; PooModuleInterface <- InterfaceId InterfaceSchemaObject InterfaceMetadata
(def (poo-module-interface interface-id-value schema-object metadata-value)
  (.o (:: @ (list poo-module-interface-prototype))
      id: interface-id-value
      schemas: schema-object
      metadata: metadata-value))

;;; Boundary: interface detection uses kind slots, not constructor identity.
;; Boolean <- PooModuleInterfaceCandidate
(def (poo-module-interface? value)
  (and (object? value)
       (poo-module-object-has-slot? value 'kind)
       (poo-module-kind=? (.ref value 'kind) poo-module-interface-kind)))

;; InterfaceId <- PooModuleInterface
(def (poo-module-interface-id interface)
  (.ref interface 'id))

;; InterfaceSchemaObject <- PooModuleInterface
(def (poo-module-interface-schemas interface)
  (.ref interface 'schemas))

;; InterfaceMetadata <- PooModuleInterface
(def (poo-module-interface-metadata interface)
  (.ref interface 'metadata))

;;; Boundary: schema helper records are intentionally plain POO values.
;; InterfaceSchemaSpec <- Unit
(def (poo-string-required)
  (.o type: 'String))

;; InterfaceSchemaSpec <- String
(def (poo-string-constant constant-value)
  (.o type: 'String
      constant: constant-value))

;; InterfaceSchemaSpec <- String
(def (poo-string-default default-value)
  (.o type: 'String
      default: default-value))

;; InterfaceSchemaSpec <- Unit
(def (poo-string-optional)
  (.o type: 'String
      optional?: #t))

;;; Boundary: merge helpers declare option semantics without reading configs.
;; InterfaceSchemaSpec <- OptionValueType OptionMergeRule Value Alist
(def (poo-option-merge value-type merge-rule default-value metadata-value)
  (.o type: value-type
      merge: merge-rule
      default: default-value
      metadata: metadata-value))

;; InterfaceSchemaSpec <- OptionValueType Value
(def (poo-option-append value-type default-value)
  (poo-option-merge value-type 'append default-value '()))

;; InterfaceSchemaSpec <- OptionValueType Value
(def (poo-option-override value-type default-value)
  (poo-option-merge value-type 'override default-value '()))

;; InterfaceSchemaSpec <- OptionValueType
(def (poo-option-conflict value-type)
  (.o type: value-type
      merge: 'conflict))
