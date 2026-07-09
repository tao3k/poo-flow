;;; -*- Gerbil -*-
;;; Contract: JSON Schema validation keyword constraints.
;;; Invariant: this owner stores small constraint metadata and compiles it into
;;; predicates; it does not parse full schemas or emit object contracts.

(import (only-in "../utilities/functional.ss"
                 poo-flow-predicate-and)
        (only-in "./functional.ss"
                 poo-flow-contract-json-object?
                 poo-flow-contract-object-ref
                 poo-flow-contract-project-list
                 poo-flow-contract-map-pair-with-diagnostics)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-node-record
                 poo-flow-json-schema-diagnostic-record)
        (only-in :std/pregexp
                 pregexp
                 pregexp-match)
        (only-in :std/srfi/1
                 filter-map))

(export +poo-flow-json-schema-constraint-keywords+
        poo-flow-json-schema-parse-result-with-constraints
        poo-flow-json-schema-apply-node-constraints)

;; +poo-flow-json-schema-constraint-keywords+
;;   : [Symbol]
;;   | doc m%
;;       Supported validation keywords carried as normalized node metadata.
;;     %
(def +poo-flow-json-schema-constraint-keywords+
  '(minLength
    maxLength
    minimum
    maximum
    exclusiveMinimum
    exclusiveMaximum
    minItems
    maxItems
    minProperties
    maxProperties
    pattern))

;; poo-flow-json-schema-non-negative-integer?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Recognize JSON Schema length/count bounds.
;;     %
(def (poo-flow-json-schema-non-negative-integer? value)
  (and (integer? value)
       (>= value 0)))

;; poo-flow-json-schema-valid-constraint-value?
;;   : (-> Symbol JsonSchemaDatum Boolean)
;;   | doc m%
;;       Validate the small P0 constraint value shapes before adding them to IR.
;;     %
(def (poo-flow-json-schema-valid-constraint-value? key value)
  (cond
   ((or (eq? key 'minLength)
        (eq? key 'maxLength)
        (eq? key 'minItems)
        (eq? key 'maxItems)
        (eq? key 'minProperties)
        (eq? key 'maxProperties))
    (poo-flow-json-schema-non-negative-integer? value))
   ((or (eq? key 'minimum)
        (eq? key 'maximum)
        (eq? key 'exclusiveMinimum)
        (eq? key 'exclusiveMaximum))
    (number? value))
   ((eq? key 'pattern)
    (and (string? value)
         (with-catch
          (lambda (_failure) #f)
          (lambda ()
            (pregexp value)
            #t))))
   (else #f)))

;; poo-flow-json-schema-constraint-diagnostic
;;   : (-> Symbol JsonSchemaDatum Symbol PooFlowJsonSchemaDiagnostic)
;;   | doc m%
;;       Emit a warning when a supported constraint key has an invalid value
;;       shape. The bridge keeps generation alive with a safe fallback.
;;     %
(def (poo-flow-json-schema-constraint-diagnostic key value context)
  (poo-flow-json-schema-diagnostic-record
   'warning
   'invalid-constraint-value
   "JSON Schema constraint has an invalid value shape"
   value
   `((context . ,context)
     (keyword . ,key)
     (owner . json-schema-constraints))))

;; poo-flow-json-schema-parse-constraint
;;   : (-> JsonSchemaObjectRows Symbol Symbol JsonSchemaMissingSentinel Pair)
;;   | result: maybe constraint row paired with diagnostics
;;   | doc m%
;;       Parse one optional constraint keyword from a schema object.
;;     %
(def (poo-flow-json-schema-parse-constraint schema key context missing)
  (let (value
        (poo-flow-contract-object-ref schema key missing))
    (cond
     ((eq? value missing)
      (cons #f '()))
     ((poo-flow-json-schema-valid-constraint-value? key value)
      (cons (cons key value) '()))
     (else
      (cons
       #f
       (list
        (poo-flow-json-schema-constraint-diagnostic
         key
         value
         context)))))))

;; poo-flow-json-schema-parse-constraints
;;   : (-> JsonSchemaObjectRows Symbol JsonSchemaMissingSentinel Pair)
;;   | result: constraint alist paired with diagnostics
;;   | doc m%
;;       Collect supported validation keywords into bounded metadata rows.
;;     %
(def (poo-flow-json-schema-parse-constraints schema context missing)
  (let* ((parsed
          (poo-flow-contract-map-pair-with-diagnostics
           (lambda (key)
             (poo-flow-json-schema-parse-constraint
              schema
              key
              context
              missing))
           +poo-flow-json-schema-constraint-keywords+
           '()))
         (constraints
          (filter-map
           (lambda (constraint)
             constraint)
           (car parsed))))
    (cons constraints (cdr parsed))))

;; poo-flow-json-schema-node-with-constraints
;;   : (-> PooFlowJsonSchemaNode Alist PooFlowJsonSchemaNode)
;;   | doc m%
;;       Attach parsed constraints to node metadata without changing the node
;;       family. The emitter owns executable predicate composition.
;;     %
(def (poo-flow-json-schema-node-with-constraints node constraints)
  (if (null? constraints)
    node
    (poo-flow-json-schema-node-record
     (poo-flow-json-schema-node-kind node)
     (poo-flow-json-schema-node-value node)
     (append
      (poo-flow-json-schema-node-metadata node)
      (list (cons 'constraints constraints))))))

;; poo-flow-json-schema-parse-result-with-constraints
;;   : (-> JsonSchemaObjectRows Symbol JsonSchemaMissingSentinel JsonSchemaParseResult JsonSchemaParseResult)
;;   | doc m%
;;       Merge validation-keyword metadata into an already parsed schema node.
;;     %
(def (poo-flow-json-schema-parse-result-with-constraints schema context missing
                                                         parsed)
  (let (constraints
        (poo-flow-json-schema-parse-constraints schema context missing))
    (cons
     (poo-flow-json-schema-node-with-constraints
      (car parsed)
      (car constraints))
     (append (cdr parsed) (cdr constraints)))))

;; poo-flow-json-schema-node-constraints
;;   : (-> PooFlowJsonSchemaNode Alist)
;;   | doc m%
;;       Read normalized constraint metadata from one schema node.
;;     %
(def (poo-flow-json-schema-node-constraints node)
  (poo-flow-contract-object-ref
   (poo-flow-json-schema-node-metadata node)
   'constraints
   '()))

;; poo-flow-json-schema-constraint-predicate
;;   : (-> Procedure Pair JsonSchemaPredicate)
;;   | doc m%
;;       Compile one normalized validation keyword into a predicate. JSON Schema
;;       type-specific constraints pass non-applicable values.
;;     %
(def (poo-flow-json-schema-constraint-predicate array-value? constraint)
  (let ((key (car constraint))
        (bound (cdr constraint)))
    (cond
     ((eq? key 'minLength)
      (lambda (value)
        (or (not (string? value))
            (>= (string-length value) bound))))
     ((eq? key 'maxLength)
      (lambda (value)
        (or (not (string? value))
            (<= (string-length value) bound))))
     ((eq? key 'minimum)
      (lambda (value)
        (or (not (number? value))
            (>= value bound))))
     ((eq? key 'maximum)
      (lambda (value)
        (or (not (number? value))
            (<= value bound))))
     ((eq? key 'exclusiveMinimum)
      (lambda (value)
        (or (not (number? value))
            (> value bound))))
     ((eq? key 'exclusiveMaximum)
      (lambda (value)
        (or (not (number? value))
            (< value bound))))
     ((eq? key 'minItems)
      (lambda (value)
        (or (not (array-value? value))
            (>= (length value) bound))))
     ((eq? key 'maxItems)
      (lambda (value)
        (or (not (array-value? value))
            (<= (length value) bound))))
     ((eq? key 'minProperties)
      (lambda (value)
        (or (not (poo-flow-contract-json-object? value))
            (>= (length value) bound))))
     ((eq? key 'maxProperties)
      (lambda (value)
        (or (not (poo-flow-contract-json-object? value))
            (<= (length value) bound))))
     ((eq? key 'pattern)
      (let (compiled-pattern (pregexp bound))
        (lambda (value)
          (or (not (string? value))
              (if (pregexp-match compiled-pattern value) #t #f)))))
     (else
      (lambda (_value) #t)))))

;; poo-flow-json-schema-constraints-predicate
;;   : (-> Procedure Alist JsonSchemaPredicate)
;;   | doc m%
;;       Combine normalized constraints into one predicate closure.
;;     %
(def (poo-flow-json-schema-constraints-predicate array-value? constraints)
  (poo-flow-predicate-and
   (poo-flow-contract-project-list
    (lambda (constraint)
      (poo-flow-json-schema-constraint-predicate array-value? constraint))
    constraints)))

;; poo-flow-json-schema-apply-node-constraints
;;   : (-> PooFlowJsonSchemaNode JsonSchemaPredicate Procedure JsonSchemaPredicate)
;;   | doc m%
;;       Add metadata-owned constraints to a node's base predicate once during
;;       contract emission.
;;     %
(def (poo-flow-json-schema-apply-node-constraints node base-predicate
                                                  array-value?)
  (let (constraints
        (poo-flow-json-schema-node-constraints node))
    (if (null? constraints)
      base-predicate
      (poo-flow-predicate-and
       (list
        base-predicate
        (poo-flow-json-schema-constraints-predicate
         array-value?
         constraints))))))
