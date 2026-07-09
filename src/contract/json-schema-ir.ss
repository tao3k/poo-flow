;;; -*- Gerbil -*-
;;; Contract: JSON Schema normalized IR for contract generation.
;;; Invariant: this file owns data shape only; parsing and emission live in
;;; neighboring owners.

(export make-poo-flow-json-schema-node
        poo-flow-json-schema-node?
        poo-flow-json-schema-node-kind
        poo-flow-json-schema-node-value
        poo-flow-json-schema-node-metadata
        poo-flow-json-schema-node-record
        poo-flow-json-schema-node->alist
        make-poo-flow-json-schema-property
        poo-flow-json-schema-property?
        poo-flow-json-schema-property-name
        poo-flow-json-schema-property-schema
        poo-flow-json-schema-property-required?
        poo-flow-json-schema-property-doc
        poo-flow-json-schema-property-metadata
        poo-flow-json-schema-property-record
        poo-flow-json-schema-property->alist
        make-poo-flow-json-schema-object
        poo-flow-json-schema-object?
        poo-flow-json-schema-object-properties
        poo-flow-json-schema-object-additional-properties
        poo-flow-json-schema-object-pattern-properties
        poo-flow-json-schema-object-metadata
        poo-flow-json-schema-object-record
        poo-flow-json-schema-object->alist
        make-poo-flow-json-schema-pattern-property
        poo-flow-json-schema-pattern-property?
        poo-flow-json-schema-pattern-property-pattern
        poo-flow-json-schema-pattern-property-compiled
        poo-flow-json-schema-pattern-property-schema
        poo-flow-json-schema-pattern-property-record
        poo-flow-json-schema-pattern-property->alist
        make-poo-flow-json-schema-diagnostic
        poo-flow-json-schema-diagnostic?
        poo-flow-json-schema-diagnostic-severity
        poo-flow-json-schema-diagnostic-reason
        poo-flow-json-schema-diagnostic-message
        poo-flow-json-schema-diagnostic-value
        poo-flow-json-schema-diagnostic-metadata
        poo-flow-json-schema-diagnostic-record
        poo-flow-json-schema-diagnostic->alist
        make-poo-flow-json-schema-normalization
        poo-flow-json-schema-normalization?
        poo-flow-json-schema-normalization-schema
        poo-flow-json-schema-normalization-references
        poo-flow-json-schema-normalization-diagnostics
        poo-flow-json-schema-normalization-record
        poo-flow-json-schema-normalization->alist
        +poo-flow-json-schema-supported-keywords+)

;; : [String]
(def +poo-flow-json-schema-supported-keywords+
  '("$schema"
    "$comment"
    "$ref"
    "$defs"
    "title"
    "description"
    "default"
    "examples"
    "format"
    "type"
    "required"
    "properties"
    "additionalProperties"
    "patternProperties"
    "enum"
    "const"
    "anyOf"
    "allOf"
    "oneOf"
    "items"
    "minLength"
    "maxLength"
    "pattern"
    "minimum"
    "maximum"
    "exclusiveMinimum"
    "exclusiveMaximum"
    "minItems"
    "maxItems"
    "minProperties"
    "maxProperties"
    "definitions"))

;; poo-flow-json-schema-node
;;   : (-> Symbol JsonSchemaDatum Alist PooFlowJsonSchemaNode)
;;   | doc m%
;;       Fixed normalized schema node. KIND is an internal tag such as
;;       `object`, `string`, `nullable`, `enum`, or `predicate-fallback`.
;;     %
(defstruct poo-flow-json-schema-node
  (kind value metadata)
  transparent: #t)

;; : (-> Symbol JsonSchemaDatum [Alist] PooFlowJsonSchemaNode)
(def (poo-flow-json-schema-node-record kind value . maybe-metadata)
  (make-poo-flow-json-schema-node
   kind
   value
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-json-schema-property
;;   : (-> Symbol PooFlowJsonSchemaNode Boolean MaybeString Alist PooFlowJsonSchemaProperty)
;;   | doc m%
;;       Object property row after `required` has been merged into per-field
;;       optionality.
;;     %
(defstruct poo-flow-json-schema-property
  (name schema required? doc metadata)
  transparent: #t)

;; : (-> Symbol PooFlowJsonSchemaNode Boolean MaybeString [Alist] PooFlowJsonSchemaProperty)
(def (poo-flow-json-schema-property-record name schema required? doc
                                           . maybe-metadata)
  (make-poo-flow-json-schema-property
   name
   schema
   required?
   doc
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-json-schema-object
;;   : (-> [PooFlowJsonSchemaProperty] JsonSchemaMapValueSchema [PooFlowJsonSchemaPatternProperty] Alist PooFlowJsonSchemaObject)
;;   | doc m%
;;       Object schema payload. Map-value schemas are normalized IR nodes, so
;;       validators can recurse into dynamic object keys without reparsing raw
;;       JSON Schema rows.
;;     %
(defstruct poo-flow-json-schema-object
  (properties additional-properties pattern-properties metadata)
  transparent: #t)

;; : (-> [PooFlowJsonSchemaProperty] JsonSchemaMapValueSchema [PooFlowJsonSchemaPatternProperty] [Alist] PooFlowJsonSchemaObject)
(def (poo-flow-json-schema-object-record properties additional-properties
                                         pattern-properties . maybe-metadata)
  (make-poo-flow-json-schema-object
   properties
   additional-properties
   pattern-properties
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-json-schema-pattern-property
;;   : (-> String CompiledPattern PooFlowJsonSchemaNode PooFlowJsonSchemaPatternProperty)
;;   | doc m%
;;       Dynamic object key row for `patternProperties`. The compiled pattern
;;       is runtime-only; public projections keep the source pattern string and
;;       normalized child schema.
;;     %
(defstruct poo-flow-json-schema-pattern-property
  (pattern compiled schema)
  transparent: #t)

;; : (-> String Object PooFlowJsonSchemaNode PooFlowJsonSchemaPatternProperty)
(def (poo-flow-json-schema-pattern-property-record pattern compiled schema)
  (make-poo-flow-json-schema-pattern-property pattern compiled schema))

;; poo-flow-json-schema-diagnostic
;;   : (-> Symbol Symbol String JsonSchemaDatum Alist PooFlowJsonSchemaDiagnostic)
;;   | doc m%
;;       Normalizer/emitter diagnostic row before observability wrapping.
;;     %
(defstruct poo-flow-json-schema-diagnostic
  (severity reason message value metadata)
  transparent: #t)

;; : (-> Symbol Symbol String JsonSchemaDatum [Alist] PooFlowJsonSchemaDiagnostic)
(def (poo-flow-json-schema-diagnostic-record severity reason message value
                                             . maybe-metadata)
  (make-poo-flow-json-schema-diagnostic
   severity
   reason
   message
   value
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; poo-flow-json-schema-normalization
;;   : (-> PooFlowJsonSchemaNode Alist [PooFlowJsonSchemaDiagnostic] PooFlowJsonSchemaNormalization)
;;   | doc m%
;;       Pure normalization receipt. Final public receipts are built by
;;       json-schema-receipt.ss.
;;     %
(defstruct poo-flow-json-schema-normalization
  (schema references diagnostics)
  transparent: #t)

;; : (-> PooFlowJsonSchemaNode Alist [PooFlowJsonSchemaDiagnostic] PooFlowJsonSchemaNormalization)
(def (poo-flow-json-schema-normalization-record schema references diagnostics)
  (make-poo-flow-json-schema-normalization schema references diagnostics))

;; : (-> JsonSchemaDatum JsonSchemaDatum)
(def (poo-flow-json-schema-project value)
  (cond
   ((poo-flow-json-schema-node? value)
    (poo-flow-json-schema-node->alist value))
   ((poo-flow-json-schema-property? value)
    (poo-flow-json-schema-property->alist value))
   ((poo-flow-json-schema-object? value)
    (poo-flow-json-schema-object->alist value))
   ((poo-flow-json-schema-pattern-property? value)
    (poo-flow-json-schema-pattern-property->alist value))
   ((poo-flow-json-schema-diagnostic? value)
    (poo-flow-json-schema-diagnostic->alist value))
   ((pair? value)
    (cons (poo-flow-json-schema-project (car value))
          (poo-flow-json-schema-project (cdr value))))
   (else value)))

;; : (-> PooFlowJsonSchemaNode Alist)
(def (poo-flow-json-schema-node->alist node)
  (list
   (cons 'kind (poo-flow-json-schema-node-kind node))
   (cons 'value
         (poo-flow-json-schema-project
          (poo-flow-json-schema-node-value node)))
   (cons 'metadata (poo-flow-json-schema-node-metadata node))))

;; : (-> PooFlowJsonSchemaProperty Alist)
(def (poo-flow-json-schema-property->alist property)
  (list
   (cons 'name (poo-flow-json-schema-property-name property))
   (cons 'schema
         (poo-flow-json-schema-node->alist
          (poo-flow-json-schema-property-schema property)))
   (cons 'required? (poo-flow-json-schema-property-required? property))
   (cons 'doc (poo-flow-json-schema-property-doc property))
   (cons 'metadata (poo-flow-json-schema-property-metadata property))))

;; : (-> PooFlowJsonSchemaPatternProperty Alist)
(def (poo-flow-json-schema-pattern-property->alist pattern-property)
  (cons
   (poo-flow-json-schema-pattern-property-pattern pattern-property)
   (poo-flow-json-schema-node->alist
    (poo-flow-json-schema-pattern-property-schema pattern-property))))

;; : (-> PooFlowJsonSchemaObject Alist)
(def (poo-flow-json-schema-object->alist object)
  (list
   (cons 'properties
         (map poo-flow-json-schema-property->alist
              (poo-flow-json-schema-object-properties object)))
   (cons 'additional-properties
         (poo-flow-json-schema-project
          (poo-flow-json-schema-object-additional-properties object)))
   (cons 'pattern-properties
         (poo-flow-json-schema-project
          (poo-flow-json-schema-object-pattern-properties object)))
   (cons 'metadata (poo-flow-json-schema-object-metadata object))))

;; : (-> PooFlowJsonSchemaDiagnostic Alist)
(def (poo-flow-json-schema-diagnostic->alist diagnostic)
  (list
   (cons 'severity
         (poo-flow-json-schema-diagnostic-severity diagnostic))
   (cons 'reason
         (poo-flow-json-schema-diagnostic-reason diagnostic))
   (cons 'message
         (poo-flow-json-schema-diagnostic-message diagnostic))
   (cons 'value
         (poo-flow-json-schema-diagnostic-value diagnostic))
   (cons 'metadata
         (poo-flow-json-schema-diagnostic-metadata diagnostic))))

;; : (-> PooFlowJsonSchemaNormalization Alist)
(def (poo-flow-json-schema-normalization->alist normalization)
  (list
   (cons 'schema
         (poo-flow-json-schema-node->alist
          (poo-flow-json-schema-normalization-schema normalization)))
   (cons 'references
         (map (lambda (entry)
                (cons (car entry)
                      (poo-flow-json-schema-node->alist (cdr entry))))
              (poo-flow-json-schema-normalization-references normalization)))
   (cons 'diagnostics
         (map poo-flow-json-schema-diagnostic->alist
              (poo-flow-json-schema-normalization-diagnostics normalization)))))
