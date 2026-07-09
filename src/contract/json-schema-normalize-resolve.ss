;;; -*- Gerbil -*-
;;; Contract: normalize JSON-like schema values into POO Flow JSON Schema IR.
;;; Invariant: this module performs pure import-boundary normalization only.
;;; It does not fetch schemas, execute validators, or emit runtime payloads.

(import (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node?
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-node-record
                 poo-flow-json-schema-object?
                 poo-flow-json-schema-object-properties
                 poo-flow-json-schema-object-additional-properties
                 poo-flow-json-schema-object-pattern-properties
                 poo-flow-json-schema-object-metadata
                 poo-flow-json-schema-object-record
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-property-doc
                 poo-flow-json-schema-property-metadata
                 poo-flow-json-schema-property-record
                 poo-flow-json-schema-pattern-property-pattern
                 poo-flow-json-schema-pattern-property-compiled
                 poo-flow-json-schema-pattern-property-schema
                 poo-flow-json-schema-pattern-property-record
                 poo-flow-json-schema-diagnostic-record)
        (only-in "./functional.ss"
                 poo-flow-contract-object-ref
                 poo-flow-contract-member?
                 poo-flow-contract-map-pair-with-diagnostics)
        (only-in "./json-schema-normalize-core.ss"
                 poo-flow-json-schema-local-definition-name))

(export #t)

;; poo-flow-json-schema-ref-lookup
;;   : (-> String JsonSchemaReferenceRows MaybePooFlowJsonSchemaNode)
;;   | result: referenced normalized node or #f
;;   | doc m%
;;       Reference lookup stays on normalized definition rows; external and
;;       missing references are handled by the caller as explicit diagnostics.
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-ref-lookup "User" references)
;;       ;; => maybe-node
;;       ```
;;     %
(def (poo-flow-json-schema-ref-lookup ref-name references)
  (poo-flow-contract-object-ref references ref-name #f))

;; poo-flow-json-schema-resolve-node
;;   : (-> PooFlowJsonSchemaNode JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | doc m%
;;       Resolve references inside a parsed node while carrying the reference
;;       stack used to detect cycles.
;;     %
(def (poo-flow-json-schema-resolve-node node references seen)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((eq? kind 'ref)
      (poo-flow-json-schema-resolve-ref node references seen))
     ((eq? kind 'object)
      (poo-flow-json-schema-resolve-object node references seen))
     ((eq? kind 'array)
      (poo-flow-json-schema-resolve-array node references seen))
     ((or (eq? kind 'nullable)
          (eq? kind 'any-of)
          (eq? kind 'all-of)
          (eq? kind 'one-of))
      (poo-flow-json-schema-resolve-sequence node references seen))
     (else
      (cons node '())))))

;; poo-flow-json-schema-resolve-ref
;;   : (-> PooFlowJsonSchemaNode JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | doc m%
;;       Resolve a local definition reference or return a diagnostic fallback
;;       for external, cyclic, and missing references.
;;     %
(def (poo-flow-json-schema-resolve-ref node references seen)
  (let* ((ref (poo-flow-json-schema-node-value node))
         (name (poo-flow-json-schema-local-definition-name ref)))
    ;; Reference resolution must remain bounded: P0 only follows local
    ;; definition names, and the `seen` set prevents recursive schemas from
    ;; creating an unbounded normalized object graph.
    (cond
     ((not name)
      (cons
       (poo-flow-json-schema-node-record
        'predicate-fallback
        'any
        `((ref . ,ref) (fallback . external-reference)))
       (list
        (poo-flow-json-schema-diagnostic-record
         'warning
         'unsupported-reference
         "Only local #/definitions/<name> and #/$defs/<name> references are supported in P0"
         ref
         '((owner . json-schema-normalize))))))
     ((poo-flow-contract-member? name seen)
      (cons
       (poo-flow-json-schema-node-record
        'predicate-fallback
        'any
        `((ref . ,ref) (fallback . cyclic-reference)))
       (list
        (poo-flow-json-schema-diagnostic-record
         'warning
         'cyclic-reference
         "Cyclic JSON Schema references fall back to an opaque predicate"
         ref
         '((owner . json-schema-normalize))))))
     (else
      (let (target (poo-flow-json-schema-ref-lookup name references))
        (if target
          (let (resolved
                (poo-flow-json-schema-resolve-node
                 target
                 references
                 (cons name seen)))
            (cons
             (poo-flow-json-schema-node-record
              (poo-flow-json-schema-node-kind (car resolved))
              (poo-flow-json-schema-node-value (car resolved))
              (cons (cons 'resolved-ref ref)
                    (poo-flow-json-schema-node-metadata (car resolved))))
             (cdr resolved)))
          (cons
           (poo-flow-json-schema-node-record
            'predicate-fallback
            'any
            `((ref . ,ref) (fallback . unresolved-reference)))
           (list
            (poo-flow-json-schema-diagnostic-record
             'warning
             'unresolved-reference
             "Local JSON Schema reference could not be resolved"
             ref
             '((owner . json-schema-normalize)))))))))))

;; poo-flow-json-schema-resolve-object
;;   : (-> PooFlowJsonSchemaNode JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | doc m%
;;       Resolve each property schema inside an object node while preserving the
;;       object's own metadata and additionalProperties value.
;;     %
(def (poo-flow-json-schema-resolve-object node references seen)
  (let* ((object (poo-flow-json-schema-node-value node))
         (resolved
          (poo-flow-json-schema-resolve-properties
           (poo-flow-json-schema-object-properties object)
           references
           seen))
         (resolved-additional
          (poo-flow-json-schema-resolve-additional-properties
           (poo-flow-json-schema-object-additional-properties object)
           references
           seen))
         (resolved-patterns
          (poo-flow-json-schema-resolve-pattern-properties
           (poo-flow-json-schema-object-pattern-properties object)
           references
           seen)))
    (cons
     (poo-flow-json-schema-node-record
      'object
      (poo-flow-json-schema-object-record
       (car resolved)
       (car resolved-additional)
       (car resolved-patterns)
       (poo-flow-json-schema-object-metadata object))
      (poo-flow-json-schema-node-metadata node))
     (append (cdr resolved)
             (cdr resolved-additional)
             (cdr resolved-patterns)))))

;; poo-flow-json-schema-resolve-additional-properties
;;   : (-> JsonSchemaMapValueSchema JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | doc m%
;;       Resolve references inside the normalized additionalProperties schema.
;;     %
(def (poo-flow-json-schema-resolve-additional-properties additional references seen)
  (if (poo-flow-json-schema-node? additional)
    (poo-flow-json-schema-resolve-node additional references seen)
    (cons additional '())))

;; poo-flow-json-schema-resolve-pattern-properties
;;   : (-> [Pair] JsonSchemaReferenceRows [String] JsonSchemaPatternResolveResult)
;;   | doc m%
;;       Resolve references inside every normalized patternProperties value.
;;     %
(def (poo-flow-json-schema-resolve-pattern-properties pattern-properties
                                                     references
                                                     seen)
  (poo-flow-contract-map-pair-with-diagnostics
   (lambda (row)
     (let (resolved
           (poo-flow-json-schema-resolve-node
            (poo-flow-json-schema-pattern-property-schema row)
            references
            seen))
       (cons (poo-flow-json-schema-pattern-property-record
              (poo-flow-json-schema-pattern-property-pattern row)
              (poo-flow-json-schema-pattern-property-compiled row)
              (car resolved))
             (cdr resolved))))
   pattern-properties
   '()))

;; poo-flow-json-schema-resolve-array
;;   : (-> PooFlowJsonSchemaNode JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | result: array node with resolved item schema and diagnostics
;;   | doc m%
;;       Resolve references inside the parsed homogeneous item schema while
;;       preserving array node metadata.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-resolve-array node references seen)
;;       ;; => (resolved-array-node . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-resolve-array node references seen)
  (let* ((value (poo-flow-json-schema-node-value node))
         (resolved
          (if (list? value)
            (let (children
                  (map (lambda (child)
                         (poo-flow-json-schema-resolve-node
                          child
                          references
                          seen))
                       value))
              (cons (map car children)
                    (if (null? children)
                      []
                      (apply append (map cdr children)))))
            (poo-flow-json-schema-resolve-node value references seen))))
    (cons
     (poo-flow-json-schema-node-record
      'array
      (car resolved)
      (poo-flow-json-schema-node-metadata node))
     (cdr resolved))))

;; poo-flow-json-schema-resolve-properties
;;   : (-> [PooFlowJsonSchemaProperty] JsonSchemaReferenceRows [String] JsonSchemaPropertyResolveResult)
;;   | result: resolved properties paired with reference diagnostics
;;   | doc m%
;;       Property resolution walks already-parsed property objects and preserves
;;       property metadata while replacing nested schema nodes with resolved IR.
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-resolve-properties properties references '())
;;       ;; => (properties . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-resolve-properties properties references seen)
  (poo-flow-contract-map-pair-with-diagnostics
   (lambda (property)
     (let (resolved
           (poo-flow-json-schema-resolve-node
            (poo-flow-json-schema-property-schema property)
            references
            seen))
       (cons
        (poo-flow-json-schema-property-record
         (poo-flow-json-schema-property-name property)
         (car resolved)
         (poo-flow-json-schema-property-required? property)
         (poo-flow-json-schema-property-doc property)
         (poo-flow-json-schema-property-metadata property))
        (cdr resolved))))
   properties
   '()))

;; poo-flow-json-schema-resolve-sequence
;;   : (-> PooFlowJsonSchemaNode JsonSchemaReferenceRows [String] JsonSchemaResolveResult)
;;   | result: resolved logical/nullable sequence node with diagnostics
;;   | doc m%
;;       Sequence resolution handles `nullable`, `any-of`, `all-of`, and `one-of`
;;       nodes without changing their public normalized IR shape.
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-resolve-sequence node references '())
;;       ;; => (node . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-resolve-sequence node references seen)
  (let* ((parsed
          (poo-flow-contract-map-pair-with-diagnostics
           (lambda (item)
             (poo-flow-json-schema-resolve-node item references seen))
           (if (list? (poo-flow-json-schema-node-value node))
             (poo-flow-json-schema-node-value node)
             (list (poo-flow-json-schema-node-value node)))
           '()))
         (value (car parsed)))
    (cons
     (poo-flow-json-schema-node-record
      (poo-flow-json-schema-node-kind node)
      (if (eq? (poo-flow-json-schema-node-kind node) 'nullable)
        (car value)
        value)
      (poo-flow-json-schema-node-metadata node))
     (cdr parsed))))
