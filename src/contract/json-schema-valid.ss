;;; -*- Gerbil -*-
;;; Contract: boolean fast path for normalized JSON Schema value validation.
;;; Invariant: this owner returns booleans only. Diagnostics and receipts stay
;;; in json-schema-validate.ss so the hot path avoids allocation.

(import (only-in :clan/poo/object
                 .all-slots
                 .ref
                 object?)
        (only-in "./functional.ss"
                 poo-flow-contract-all?
                 poo-flow-contract-any?
                 poo-flow-contract-member?
                 poo-flow-contract-key->string
                 poo-flow-contract-key->symbol
                 poo-flow-contract-json-object?
                 poo-flow-contract-object-ref
                 poo-flow-contract-project-list)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node?
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-object-properties
                 poo-flow-json-schema-object-additional-properties
                 poo-flow-json-schema-object-pattern-properties
                 poo-flow-json-schema-pattern-property-compiled
                 poo-flow-json-schema-pattern-property-schema
                 poo-flow-json-schema-normalization-schema)
        (only-in "./json-schema-emit.ss"
                 poo-flow-json-schema-null?)
        (only-in "./json-schema-receipt.ss"
                 poo-flow-json-schema-contract-artifact-normalization)
        (only-in :std/srfi/1
                 fold)
        (only-in :std/pregexp
                 pregexp
                 pregexp-match))

(export poo-flow-json-schema-node-valid?
        poo-flow-json-schema-contract-artifact-value-valid?)

;; : JsonSchemaValidationMissing
(def +poo-flow-json-schema-validation-missing+
  (list 'poo-flow-json-schema-validation-missing))

;; : [(Pair String CompiledPattern)]
(def +poo-flow-json-schema-compiled-pattern-cache+
  '())

;; : (-> JsonSchemaCandidateObject JsonSchemaCandidateRows)
(def (poo-flow-json-schema-candidate-rows candidate)
  (cond
   ((poo-flow-contract-json-object? candidate)
    candidate)
   ((object? candidate)
    (poo-flow-contract-project-list
     (lambda (slot)
       (cons slot (.ref candidate slot)))
     (.all-slots candidate)))
   (else '())))

;; : (-> JsonSchemaCandidateRows Symbol JsonSchemaCandidateSlotValue)
(def (poo-flow-json-schema-row-value row)
  (let (tail (cdr row))
    (if (and (pair? tail)
             (null? (cdr tail))
             (not (poo-flow-contract-json-object? tail))
             (poo-flow-contract-json-object? (car tail)))
      (car tail)
      tail)))

(def (poo-flow-json-schema-candidate-row-slot rows slot)
  (let (row (assq slot rows))
    (if row
      (poo-flow-json-schema-row-value row)
      (poo-flow-contract-object-ref
       rows
       slot
       +poo-flow-json-schema-validation-missing+))))

;; : (-> JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-schema-guided-array? value)
  (or (list? value)
      (vector? value)))

;; : (-> JsonSchemaCandidateSlotValue [JsonSchemaCandidateSlotValue])
(def (poo-flow-json-schema-schema-guided-array-values value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else '())))

;; : (-> JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-schema-guided-object? value)
  (or (poo-flow-contract-json-object? value)
      (object? value)))

;; : (-> PooFlowJsonSchemaNode Alist)
(def (poo-flow-json-schema-validation-node-constraints node)
  (poo-flow-contract-object-ref
   (poo-flow-json-schema-node-metadata node)
   'constraints
   '()))

;; : (-> JsonSchemaConstraint Integer Boolean)
(def (poo-flow-json-schema-object-constraint-valid? constraint size)
  (let ((key (car constraint))
        (bound (cdr constraint)))
    (cond
     ((eq? key 'minProperties) (>= size bound))
     ((eq? key 'maxProperties) (<= size bound))
     (else #t))))

;; : (-> JsonSchemaConstraint Integer Boolean)
(def (poo-flow-json-schema-array-constraint-valid? constraint size)
  (let ((key (car constraint))
        (bound (cdr constraint)))
    (cond
     ((eq? key 'minItems) (>= size bound))
     ((eq? key 'maxItems) (<= size bound))
     (else #t))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-array-node-shape-valid? node value)
  (and (poo-flow-json-schema-schema-guided-array? value)
       (let (constraints
             (poo-flow-json-schema-validation-node-constraints node))
         (if (null? constraints)
           #t
           (let (size
                 (length
                  (poo-flow-json-schema-schema-guided-array-values value)))
             (not
              (poo-flow-contract-any?
               (lambda (constraint)
                 (not
                  (poo-flow-json-schema-array-constraint-valid?
                   constraint
                   size)))
               constraints)))))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateRows Boolean)
(def (poo-flow-json-schema-object-node-rows-shape-valid? node rows)
  (let (constraints
        (poo-flow-json-schema-validation-node-constraints node))
    (if (null? constraints)
      #t
      (let (size (length rows))
        (not
         (poo-flow-contract-any?
          (lambda (constraint)
            (not
             (poo-flow-json-schema-object-constraint-valid?
              constraint
              size)))
          constraints))))))

;; : (-> JsonSchemaObjectRow Symbol)
(def (poo-flow-json-schema-row-key-symbol row)
  (poo-flow-contract-key->symbol (car row)))

;; : (-> JsonSchemaObjectRow String)
(def (poo-flow-json-schema-row-key-string row)
  (or (poo-flow-contract-key->string (car row))
      (symbol->string (poo-flow-json-schema-row-key-symbol row))))

;; : (-> PooFlowJsonSchemaPatternProperty JsonObjectKey Boolean)
(def (poo-flow-json-schema-pattern-property-matches? pattern-property key)
  (let (compiled-pattern
       (or (poo-flow-json-schema-pattern-property-compiled pattern-property)
           #f))
    (and compiled-pattern
         (if (pregexp-match compiled-pattern key) #t #f))))

;; : (-> RegexSource CompiledPattern)
(def (poo-flow-json-schema-compiled-pattern pattern)
  (let (entry (assoc pattern +poo-flow-json-schema-compiled-pattern-cache+))
    (if entry
      (cdr entry)
      (let (compiled-pattern
            (with-catch
             (lambda (_failure) #f)
             (lambda ()
               (pregexp pattern))))
        (when compiled-pattern
          (set! +poo-flow-json-schema-compiled-pattern-cache+
                (cons (cons pattern compiled-pattern)
                      +poo-flow-json-schema-compiled-pattern-cache+)))
        compiled-pattern))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-node-valid? node value)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((eq? kind 'array)
      (poo-flow-json-schema-array-node-valid? node value))
     ((eq? kind 'object)
      (poo-flow-json-schema-object-node-valid? node value))
     ((and (eq? kind 'nullable)
           (not (poo-flow-json-schema-null? value)))
      (poo-flow-json-schema-node-valid?
       (poo-flow-json-schema-node-value node)
       value))
     (else
      (poo-flow-json-schema-node-shallow-valid? node value)))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-node-shallow-valid? node value)
  (and (poo-flow-json-schema-node-kind-valid? node value)
       (poo-flow-json-schema-node-constraints-valid? node value)))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-node-kind-valid? node value)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((eq? kind 'always) #t)
     ((eq? kind 'never) #f)
     ((eq? kind 'string) (string? value))
     ((eq? kind 'number) (number? value))
     ((eq? kind 'integer) (integer? value))
     ((eq? kind 'boolean) (boolean? value))
     ((eq? kind 'null) (poo-flow-json-schema-null? value))
     ((eq? kind 'const)
      (equal? value (poo-flow-json-schema-node-value node)))
     ((eq? kind 'enum)
      (poo-flow-contract-member?
       value
       (poo-flow-json-schema-node-value node)))
     ((eq? kind 'any-of)
      (poo-flow-contract-any?
       (lambda (child)
         (poo-flow-json-schema-node-valid? child value))
       (poo-flow-json-schema-node-value node)))
     ((eq? kind 'all-of)
      (poo-flow-contract-all?
       (lambda (child)
         (poo-flow-json-schema-node-valid? child value))
       (poo-flow-json-schema-node-value node)))
     ((eq? kind 'one-of)
      (= (fold
          (lambda (child count)
            (if (poo-flow-json-schema-node-valid? child value)
              (+ count 1)
              count))
          0
          (poo-flow-json-schema-node-value node))
         1))
     (else #t))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-node-constraints-valid? node value)
  (not
   (poo-flow-contract-any?
    (lambda (constraint)
      (not
       (poo-flow-json-schema-node-constraint-valid?
        constraint
        value)))
    (poo-flow-json-schema-validation-node-constraints node))))

;; : (-> JsonSchemaConstraint JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-node-constraint-valid? constraint value)
  (let ((key (car constraint))
        (bound (cdr constraint)))
    (cond
     ((eq? key 'minLength)
      (poo-flow-json-schema-min-length-valid? bound value))
     ((eq? key 'maxLength)
      (poo-flow-json-schema-max-length-valid? bound value))
     ((eq? key 'minimum)
      (poo-flow-json-schema-minimum-valid? bound value))
     ((eq? key 'maximum)
      (poo-flow-json-schema-maximum-valid? bound value))
     ((eq? key 'exclusiveMinimum)
      (poo-flow-json-schema-exclusive-minimum-valid? bound value))
     ((eq? key 'exclusiveMaximum)
      (poo-flow-json-schema-exclusive-maximum-valid? bound value))
     ((or (eq? key 'minItems)
          (eq? key 'maxItems))
      (poo-flow-json-schema-array-value-constraint-valid? constraint value))
     ((or (eq? key 'minProperties)
          (eq? key 'maxProperties))
      (poo-flow-json-schema-object-value-constraint-valid? constraint value))
     ((eq? key 'pattern)
      (poo-flow-json-schema-pattern-constraint-valid? bound value))
     (else #t))))

;; : (-> Integer JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-min-length-valid? bound value)
  (or (not (string? value))
      (>= (string-length value) bound)))

;; : (-> Integer JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-max-length-valid? bound value)
  (or (not (string? value))
      (<= (string-length value) bound)))

;; : (-> Number JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-minimum-valid? bound value)
  (or (not (number? value))
      (>= value bound)))

;; : (-> Number JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-maximum-valid? bound value)
  (or (not (number? value))
      (<= value bound)))

;; : (-> Number JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-exclusive-minimum-valid? bound value)
  (or (not (number? value))
      (> value bound)))

;; : (-> Number JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-exclusive-maximum-valid? bound value)
  (or (not (number? value))
      (< value bound)))

;; : (-> JsonSchemaConstraint JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-array-value-constraint-valid? constraint value)
  (or (not (poo-flow-json-schema-schema-guided-array? value))
      (poo-flow-json-schema-array-constraint-valid?
       constraint
       (length (poo-flow-json-schema-schema-guided-array-values value)))))

;; : (-> JsonSchemaConstraint JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-object-value-constraint-valid? constraint value)
  (or (not (poo-flow-json-schema-schema-guided-object? value))
      (poo-flow-json-schema-object-constraint-valid?
       constraint
       (length (poo-flow-json-schema-candidate-rows value)))))

;; : (-> RegexSource JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-pattern-constraint-valid? bound value)
  (or (not (string? value))
      (let (compiled-pattern
            (poo-flow-json-schema-compiled-pattern bound))
        (and compiled-pattern
             (if (pregexp-match compiled-pattern value) #t #f)))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaArrayCandidate Boolean)
(def (poo-flow-json-schema-array-node-valid? node value)
  (and (poo-flow-json-schema-array-node-shape-valid? node value)
       (let ((item-node (poo-flow-json-schema-node-value node))
             (items (poo-flow-json-schema-schema-guided-array-values value)))
         (poo-flow-contract-all?
          (lambda (item)
            (poo-flow-json-schema-node-valid? item-node item))
          items))))

;; : (-> PooFlowJsonSchemaProperty JsonSchemaCandidateRows Boolean)
(def (poo-flow-json-schema-property-valid/rows? property rows)
  (let (value
        (poo-flow-json-schema-candidate-row-slot
         rows
         (poo-flow-json-schema-property-name property)))
    (if (eq? value +poo-flow-json-schema-validation-missing+)
      (not (poo-flow-json-schema-property-required? property))
      (poo-flow-json-schema-node-valid?
       (poo-flow-json-schema-property-schema property)
       value))))

;; : (-> PooFlowJsonSchemaPatternProperty JsonSchemaObjectRow Boolean)
(def (poo-flow-json-schema-pattern-row-valid? pattern-property object-row)
  (poo-flow-json-schema-node-valid?
   (poo-flow-json-schema-pattern-property-schema pattern-property)
   (poo-flow-json-schema-row-value object-row)))

;; : (-> JsonSchemaMapValueSchema JsonSchemaObjectRow Boolean)
(def (poo-flow-json-schema-additional-property-valid? additional object-row)
  (cond
   ((eq? additional 'unspecified) #t)
   ((and (poo-flow-json-schema-node? additional)
         (eq? (poo-flow-json-schema-node-kind additional) 'never))
    #f)
   ((poo-flow-json-schema-node? additional)
    (poo-flow-json-schema-node-valid?
     additional
     (poo-flow-json-schema-row-value object-row)))
     (else #f)))

;; : (-> PooFlowJsonSchemaObject JsonSchemaObjectRow [Symbol] Boolean)
(def (poo-flow-json-schema-object-row-valid? object object-row declared)
  (let* ((row-key
          (poo-flow-json-schema-row-key-symbol object-row))
         (row-key-string
          (poo-flow-json-schema-row-key-string object-row))
         (pattern-state
          (poo-flow-json-schema-pattern-row-state
           (poo-flow-json-schema-object-pattern-properties object)
           row-key-string
           object-row)))
    (and
     (not (eq? pattern-state 'invalid))
     (or (poo-flow-contract-member? row-key declared)
         (eq? pattern-state 'matched)
         (poo-flow-json-schema-additional-property-valid?
          (poo-flow-json-schema-object-additional-properties object)
          object-row)))))

;; : (-> [PooFlowJsonSchemaPatternProperty] JsonObjectKey JsonSchemaObjectRow Symbol)
(def (poo-flow-json-schema-pattern-row-state pattern-properties key object-row)
  (fold
   (lambda (pattern-property state)
     (cond
      ((eq? state 'invalid) 'invalid)
      ((poo-flow-json-schema-pattern-property-matches?
        pattern-property
        key)
       (if (poo-flow-json-schema-pattern-row-valid?
            pattern-property
            object-row)
         'matched
         'invalid))
      (else state)))
   'unmatched
   pattern-properties))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateObject Boolean)
(def (poo-flow-json-schema-object-node-valid? node candidate)
  (and (poo-flow-json-schema-schema-guided-object? candidate)
       (let* ((rows
               (poo-flow-json-schema-candidate-rows candidate))
              (object
               (poo-flow-json-schema-node-value node))
              (properties
               (poo-flow-json-schema-object-properties object))
              (declared
               (poo-flow-contract-project-list
                poo-flow-json-schema-property-name
                properties)))
         (and
          (poo-flow-json-schema-object-node-rows-shape-valid? node rows)
          (poo-flow-contract-all?
           (lambda (property)
             (poo-flow-json-schema-property-valid/rows? property rows))
           properties)
          (poo-flow-contract-all?
           (lambda (row)
             (poo-flow-json-schema-object-row-valid?
              object
              row
              declared))
           rows)))))

;; : (-> PooFlowJsonSchemaContractArtifact JsonSchemaCandidateObject Boolean)
(def (poo-flow-json-schema-contract-artifact-value-valid? artifact candidate)
  (and (or (poo-flow-contract-json-object? candidate)
           (object? candidate))
       (poo-flow-json-schema-node-valid?
        (poo-flow-json-schema-normalization-schema
         (poo-flow-json-schema-contract-artifact-normalization artifact))
        candidate)))
