;;; -*- Gerbil -*-
;;; Contract: shared helpers for JSON Schema value validation.
;;; Invariant: this owner has no receipt structs and no public validation API;
;;; it only normalizes candidate access, paths, shape checks, and regex rows.

(import (only-in :clan/poo/object
                 .all-slots
                 .ref
                 .slot?
                 object?)
        (only-in "./functional.ss"
                 poo-flow-contract-any?
                 poo-flow-contract-key->string
                 poo-flow-contract-key->symbol
                 poo-flow-contract-json-object?
                 poo-flow-contract-object-ref
                 poo-flow-contract-project-list
                 poo-flow-contract-filter-map)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-pattern-property-compiled)
        (only-in :std/srfi/13
                 string-join)
        (only-in :std/pregexp
                 pregexp
                 pregexp-match))

(export +poo-flow-json-schema-validation-missing+
        poo-flow-json-schema-candidate-slot
        poo-flow-json-schema-candidate-rows
        poo-flow-json-schema-candidate-row-slot
        poo-flow-json-schema-path->symbol
        poo-flow-json-schema-path-append
        poo-flow-json-schema-schema-guided-array?
        poo-flow-json-schema-schema-guided-array-values
        poo-flow-json-schema-schema-guided-object?
        poo-flow-json-schema-validation-node-constraints
        poo-flow-json-schema-array-constraint-valid?
        poo-flow-json-schema-object-constraint-valid?
        poo-flow-json-schema-array-node-shape-valid?
        poo-flow-json-schema-object-node-shape-valid?
        poo-flow-json-schema-object-node-rows-shape-valid?
        poo-flow-json-schema-row-key-symbol
        poo-flow-json-schema-row-key-string
        poo-flow-json-schema-pattern-property-matches?
        poo-flow-json-schema-compiled-pattern
        poo-flow-json-schema-matching-pattern-properties)

;; : JsonSchemaValidationMissing
(def +poo-flow-json-schema-validation-missing+
  (list 'poo-flow-json-schema-validation-missing))

;; : [(Pair String CompiledPattern)]
(def +poo-flow-json-schema-compiled-pattern-cache+
  '())

;; : (-> JsonSchemaCandidateObject Symbol JsonSchemaCandidateSlotValue)
(def (poo-flow-json-schema-candidate-slot candidate slot)
  (cond
   ((poo-flow-contract-json-object? candidate)
    (poo-flow-contract-object-ref
     candidate
     slot
     +poo-flow-json-schema-validation-missing+))
   ((and (object? candidate)
         (.slot? candidate slot))
    (.ref candidate slot))
   (else +poo-flow-json-schema-validation-missing+)))

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
;; : (forall (k v) (-> [(Pair k v)] k v))
;; : (-> JsonObjectRows JsonObjectSlot JsonObjectValue)
;; | doc Returns the normalized JSON object row value for a requested slot, or
;; | doc the validation missing sentinel when the candidate does not provide it.
;; # Examples
;; (poo-flow-json-schema-candidate-row-slot '(("jobs" . jobs)) 'jobs) => jobs
;; result: Any | +poo-flow-json-schema-validation-missing+
;;
;; Optimization boundary: JSON Schema object keys commonly arrive as strings,
;; while generated contracts address slots as symbols.  This is intentionally a
;; single-pass normalized lookup so recursive map-value validation does not pay
;; an assq miss plus generic object-ref fallback for every row.
(def (poo-flow-json-schema-candidate-row-slot rows slot)
  (let* ((slot-symbol (poo-flow-contract-key->symbol slot))
         (slot-string (poo-flow-contract-key->string slot)))
    (let loop ((rest rows))
      (cond
       ((null? rest)
        (poo-flow-contract-object-ref
         rows
         slot
         +poo-flow-json-schema-validation-missing+))
       (else
        (let* ((row (car rest))
               (key (car row))
               (key-symbol (poo-flow-contract-key->symbol key)))
          (if (or (eq? key-symbol slot-symbol)
                  (and slot-string
                       (equal? (poo-flow-contract-key->string key)
                               slot-string)))
            (cdr row)
            (loop (cdr rest)))))))))

;; : (-> JsonSchemaPathPart String)
(def (poo-flow-json-schema-path-part->string part)
  (cond
   ((string? part) part)
   ((symbol? part) (symbol->string part))
   ((number? part) (number->string part))
   (else "value")))

;; : (-> JsonSchemaValidationPath String)
(def (poo-flow-json-schema-path->string path)
  (cond
   ((null? path) "root")
   (else
    (string-join
     (poo-flow-contract-project-list
      poo-flow-json-schema-path-part->string
      path)
     "/"))))

;; : (-> JsonSchemaValidationPath Symbol)
(def (poo-flow-json-schema-path->symbol path)
  (string->symbol
   (poo-flow-json-schema-path->string path)))

;; : (-> JsonSchemaValidationPath JsonSchemaPathPart JsonSchemaValidationPath)
(def (poo-flow-json-schema-path-append path part)
  (append path (list part)))

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

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue Boolean)
(def (poo-flow-json-schema-object-node-shape-valid? node value)
  (and (poo-flow-json-schema-schema-guided-object? value)
       (poo-flow-json-schema-object-node-rows-shape-valid?
        node
        (poo-flow-json-schema-candidate-rows value))))

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

;; : (-> [PooFlowJsonSchemaPatternProperty] JsonObjectKey [PooFlowJsonSchemaPatternProperty])
(def (poo-flow-json-schema-matching-pattern-properties pattern-properties key)
  (poo-flow-contract-filter-map
   (lambda (pattern-property)
     (and (poo-flow-json-schema-pattern-property-matches?
           pattern-property
           key)
          pattern-property))
   pattern-properties))
