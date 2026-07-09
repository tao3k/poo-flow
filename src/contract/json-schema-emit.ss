;;; -*- Gerbil -*-
;;; Contract: emit POO Flow object contracts from normalized JSON Schema IR.
;;; Optimization boundary: this module builds predicate closures once while
;;; emitting contracts; value validation reuses those closures without walking
;;; the normalized schema again.

(import (only-in :clan/poo/object
                 .alist)
        (only-in :std/pregexp
                 pregexp
                 pregexp-match)
        (only-in "../utilities/contracts.ss"
                 poo-flow-slot-contract-record
                 poo-flow-object-type-contract-record)
        (only-in "../utilities/functional.ss"
                 poo-flow-all?
                 poo-flow-find
                 poo-flow-predicate-and
                 poo-flow-predicate-or
                 poo-flow-predicate-exactly-one)
        (only-in "./json-schema-constraints.ss"
                 poo-flow-json-schema-apply-node-constraints)
        (only-in "./functional.ss"
                 poo-flow-contract-key->string
                 poo-flow-contract-all?
                 poo-flow-contract-json-object?
                 poo-flow-contract-member?
                 poo-flow-contract-project-list
                 poo-flow-contract-filter-map)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node?
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-node->alist
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-property-doc
                 poo-flow-json-schema-property-metadata
                 poo-flow-json-schema-property->alist
                 poo-flow-json-schema-object?
                 poo-flow-json-schema-object-properties
                 poo-flow-json-schema-object-additional-properties
                 poo-flow-json-schema-object-pattern-properties
                 poo-flow-json-schema-object-metadata
                 poo-flow-json-schema-pattern-property?
                 poo-flow-json-schema-pattern-property->alist))

(import (only-in :std/srfi/1 find every filter-map))

(export poo-flow-json-schema-any?
        poo-flow-json-schema-null?
        poo-flow-json-schema-json-object-value?
        poo-flow-json-schema-json-array-value?
        poo-flow-json-schema-integer-value?
        poo-flow-json-schema-symbol-string
        poo-flow-json-schema-contract-key
        poo-flow-json-schema-node-value-kind
        poo-flow-json-schema-node-predicate-key
        poo-flow-json-schema-node-predicate
        poo-flow-json-schema-property->slot-contract
        poo-flow-json-schema-object-node->object-type-contract
        poo-flow-json-schema-node->object-type-contract)

;; poo-flow-json-schema-any?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Accept any value for fallback schemas that are still proof-visible
;;       through metadata and diagnostics.
;;     %
(def (poo-flow-json-schema-any? _value)
  #t)

;; poo-flow-json-schema-null?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Recognize the null sentinels accepted by the JSON Schema bridge.
;;     %
(def (poo-flow-json-schema-null? value)
  (or (eq? value 'null)
      (eq? value 'json-null)
      (void? value)))

;; poo-flow-json-schema-json-object-value?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Delegate object recognition to the contract functional boundary.
;;     %
(def (poo-flow-json-schema-json-object-value? value)
  (poo-flow-contract-json-object? value))

;; poo-flow-json-schema-json-array-value?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Treat list values that are not JSON-like object alists as array values.
;;     %
(def (poo-flow-json-schema-json-array-value? value)
  (and (list? value)
       (not (poo-flow-contract-json-object? value))))

;; poo-flow-json-schema-integer-value?
;;   : (-> JsonSchemaDatum Boolean)
;;   | doc m%
;;       Keep integer predicate naming stable for generated contract metadata.
;;     %
(def (poo-flow-json-schema-integer-value? value)
  (integer? value))

;; poo-flow-json-schema-symbol-string
;;   : (-> JsonSchemaKey String)
;;   | doc m%
;;       Convert object keys and slots to stable path fragments.
;;     %
(def (poo-flow-json-schema-symbol-string value)
  (or (poo-flow-contract-key->string value)
      "json-schema"))

;; poo-flow-json-schema-contract-key
;;   : (-> Symbol Symbol Symbol)
;;   | doc m%
;;       Build the generated slot contract key from object and slot identity.
;;     %
(def (poo-flow-json-schema-contract-key object-key slot)
  (string->symbol
   (string-append
    (poo-flow-json-schema-symbol-string object-key)
    "/"
    (poo-flow-json-schema-symbol-string slot))))

;; poo-flow-json-schema-const-predicate
;;   : (-> JsonSchemaDatum JsonSchemaPredicate)
;;   | doc m%
;;       Build a reusable equality predicate for `const` schemas.
;;     %
(def (poo-flow-json-schema-const-predicate expected)
  (lambda (value)
    (equal? value expected)))

;; poo-flow-json-schema-enum-predicate
;;   : (-> [JsonSchemaDatum] JsonSchemaPredicate)
;;   | doc m%
;;       Build a reusable membership predicate for `enum` schemas.
;;     %
(def (poo-flow-json-schema-enum-predicate values)
  (lambda (value)
    (poo-flow-contract-member? value values)))

;; poo-flow-json-schema-nullable-predicate
;;   : (-> JsonSchemaPredicate JsonSchemaPredicate)
;;   | doc m%
;;       Build a nullable predicate without re-reading the normalized node.
;;     %
(def (poo-flow-json-schema-nullable-predicate predicate)
  (lambda (value)
    (or (poo-flow-json-schema-null? value)
        (predicate value))))

;; poo-flow-json-schema-array-predicate
;;   : (-> JsonSchemaPredicate JsonSchemaPredicate)
;;   | doc m%
;;       Build a homogeneous array predicate from the already-emitted item
;;       predicate. Runtime checks stay bounded to one list scan and do not
;;       interpret the normalized schema again.
;;     %
(def (poo-flow-json-schema-array-predicate item-predicate . maybe-metadata)
  (let* ((metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
         (min-items (poo-flow-json-schema-metadata-ref metadata 'min-items #f))
         (max-items (poo-flow-json-schema-metadata-ref metadata 'max-items #f)))
    (lambda (value)
      (and (poo-flow-json-schema-json-array-value? value)
           (or (not min-items) (>= (length value) min-items))
           (or (not max-items) (<= (length value) max-items))
           (poo-flow-contract-all? item-predicate value)))))

;; : (-> JsonSchemaMetadata Symbol JsonSchemaDatum JsonSchemaDatum)
(def (poo-flow-json-schema-metadata-ref metadata key default)
  (let ((found (assoc key metadata)))
    (if found (cdr found) default)))

;; poo-flow-json-schema-schema-ref
;;   : (-> JsonSchemaSource JsonSchemaKey JsonSchemaDatum JsonSchemaDatum)
;;   | doc m%
;;       Read one normalized schema entry by string-or-symbol key and return the
;;       caller supplied default when the entry is absent.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-schema-ref '((type . "object")) "type" #f)
;;       ;; => "object"
;;       ```
;;     %
;; Boundary: schema emission stays pure; specialized JSON Schema branches
;; use functional combinators instead of runtime mutation or ad hoc walkers.
(def (poo-flow-json-schema-schema-ref schema key default)
  (let ((found (and (list? schema)
                    (find
                     (lambda (entry)
                       (and (pair? entry)
                            (poo-flow-json-schema-schema-key=?
                             (car entry)
                             key)))
                     schema))))
    (if found
      (let ((value (cdr found)))
        (if (and (pair? value) (null? (cdr value)))
          (car value)
          value))
      default)))

;; : (-> JsonSchemaKey JsonSchemaKey Boolean)
(def (poo-flow-json-schema-schema-key=? left right)
  (cond
   ((equal? left right) #t)
   ((and (symbol? left) (string? right))
    (string=? (symbol->string left) right))
   ((and (string? left) (symbol? right))
    (string=? left (symbol->string right)))
   (else #f)))

;; : (-> JsonSchemaKey JsonSchemaKey)
(def (poo-flow-json-schema-schema-key->string key)
  (cond
   ((string? key) key)
   ((symbol? key) (symbol->string key))
   (else key)))

;; : (-> PooFlowJsonSchemaNode JsonSchemaPredicate)
(def (poo-flow-json-schema-string-predicate node)
  (let ((schema (poo-flow-json-schema-node-value node)))
    (lambda (value)
      (and (string? value)
           (let ((min-length
                  (poo-flow-json-schema-schema-ref schema "minLength" #f))
                 (max-length
                  (poo-flow-json-schema-schema-ref schema "maxLength" #f))
                 (pattern
                  (poo-flow-json-schema-schema-ref schema "pattern" #f)))
             (and (or (not min-length) (>= (string-length value) min-length))
                  (or (not max-length) (<= (string-length value) max-length))
                  (or (not pattern)
                      (poo-flow-json-schema-pattern-runtime-match?
                       pattern
                       value))))))))

;; : (-> JsonSchemaPattern String Boolean)
(def (poo-flow-json-schema-pattern-runtime-match? pattern value)
  (with-catch
   (lambda (_error) #f)
   (lambda ()
     (if (string? pattern)
       (if (pregexp-match (pregexp pattern) value) #t #f)
       #f))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaPredicate JsonSchemaPredicate)
(def (poo-flow-json-schema-number-predicate node base-predicate)
  (let ((schema (poo-flow-json-schema-node-value node)))
    (lambda (value)
      (and (base-predicate value)
           (let ((minimum (poo-flow-json-schema-schema-ref schema "minimum" #f))
                 (maximum (poo-flow-json-schema-schema-ref schema "maximum" #f))
                 (exclusive-minimum
                  (poo-flow-json-schema-schema-ref schema "exclusiveMinimum" #f))
                 (exclusive-maximum
                  (poo-flow-json-schema-schema-ref schema "exclusiveMaximum" #f)))
             (and (or (not minimum) (>= value minimum))
                  (or (not maximum) (<= value maximum))
                  (or (not exclusive-minimum) (> value exclusive-minimum))
                  (or (not exclusive-maximum) (< value exclusive-maximum))))))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaPredicate)
(def (poo-flow-json-schema-object-predicate node)
  (let ((schema (poo-flow-json-schema-node-value node))
        (metadata (poo-flow-json-schema-node-metadata node)))
    (lambda (value)
      (let* ((raw-rows (poo-flow-json-schema-object-runtime-rows value))
             (rows
              (poo-flow-json-schema-object-runtime-rows-for-schema
               schema
               raw-rows)))
        (and rows
             (poo-flow-json-schema-json-object-value? rows)
             (let ((min-properties
                    (poo-flow-json-schema-metadata-ref
                     metadata
                     'min-properties
                     #f))
                   (max-properties
                    (poo-flow-json-schema-metadata-ref
                     metadata
                     'max-properties
                     #f)))
               (and (or (not min-properties) (>= (length rows) min-properties))
                    (or (not max-properties) (<= (length rows) max-properties))))
             (poo-flow-json-schema-object-children-valid? schema rows))))))

;; : (-> JsonSchemaDatum JsonSchemaRuntimeObjectRows)
(def (poo-flow-json-schema-object-runtime-rows value)
  (cond
   ((list? value) value)
   (else
    (with-catch
     (lambda (_error) #f)
     (lambda () (.alist value))))))

;; : (-> JsonSchemaSource JsonSchemaRuntimeObjectRows JsonSchemaRuntimeObjectRows)
(def (poo-flow-json-schema-object-runtime-rows-for-schema schema rows)
  (if (and rows
           (poo-flow-json-schema-object? schema)
           (pair? rows)
           (null? (cdr rows))
           (pair? (car rows)))
    (let* ((entry (car rows))
           (key (car entry))
           (value (cdr entry))
           (properties (poo-flow-json-schema-object-properties schema))
           (patterns (poo-flow-json-schema-object-pattern-properties schema)))
      (if (and (not (poo-flow-json-schema-static-property-name? properties key))
               (null? (poo-flow-json-schema-matching-runtime-pattern-properties
                       patterns
                       key))
               (list? value))
        value
        rows))
    rows))

;; : (-> PooFlowJsonSchemaObject JsonSchemaRuntimeObjectRows Boolean)
(def (poo-flow-json-schema-object-children-valid? schema value)
  (if (poo-flow-json-schema-object? schema)
    (and (poo-flow-json-schema-object-properties-valid?
          (poo-flow-json-schema-object-properties schema)
          value)
         (poo-flow-json-schema-object-pattern-properties-valid?
          (poo-flow-json-schema-object-properties schema)
          (poo-flow-json-schema-object-pattern-properties schema)
          (poo-flow-json-schema-object-additional-properties schema)
          value))
    #t))

;; poo-flow-json-schema-object-properties-valid?
;;   : (-> [PooFlowJsonSchemaProperty] JsonSchemaRuntimeObjectRows Boolean)
;;   | doc m%
;;       Validate static object properties against the emitted property
;;       predicates while treating missing optional properties as valid.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-object-properties-valid? '() '())
;;       ;; => #t
;;       ```
;;     %
;; Invariants: object validation keeps property, pattern, and additional
;; property checks as composable predicates so policy facts stay inspectable.
(def (poo-flow-json-schema-object-properties-valid? properties value)
  (if (every
       (lambda (property)
         (let* ((name (poo-flow-json-schema-property-name property))
                (entry (poo-flow-json-schema-object-entry value name)))
           (if entry
             ((poo-flow-json-schema-node-predicate
               (poo-flow-json-schema-property-schema property))
              (cdr entry))
             (not (poo-flow-json-schema-property-required? property)))))
       properties)
    #t
    #f))

;; poo-flow-json-schema-object-pattern-properties-valid?
;;   : (-> [PooFlowJsonSchemaProperty] [PooFlowJsonSchemaPatternProperty] JsonSchemaAdditionalProperties JsonSchemaRuntimeObjectRows Boolean)
;;   | doc m%
;;       Validate dynamic object entries against pattern properties, falling
;;       back to the additional-properties policy only when no pattern matches.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-object-pattern-properties-valid? '() '() #t '())
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-json-schema-object-pattern-properties-valid?
      properties pattern-properties additional-properties value)
  (if (every
       (lambda (entry)
         (let* ((key (car entry))
                (matches
                 (poo-flow-json-schema-matching-runtime-pattern-properties
                  pattern-properties
                  key)))
           (if (null? matches)
             (or (poo-flow-json-schema-static-property-name? properties key)
                 (poo-flow-json-schema-additional-runtime-valid?
                  additional-properties
                  (cdr entry)))
             (poo-flow-json-schema-pattern-runtime-valid?
              matches
              (cdr entry)))))
       value)
    #t
    #f))

;; : (-> [PooFlowJsonSchemaPatternProperty] JsonSchemaKey [PooFlowJsonSchemaPatternProperty])
(def (poo-flow-json-schema-matching-runtime-pattern-properties pattern-properties key)
  (let ((runtime-key (poo-flow-json-schema-schema-key->string key)))
    (filter-map
     (lambda (pattern-property)
       (and (poo-flow-json-schema-pattern-runtime-match?
             (poo-flow-json-schema-pattern-property-pattern pattern-property)
             runtime-key)
            pattern-property))
     pattern-properties)))

;; poo-flow-json-schema-pattern-runtime-valid?
;;   : (-> [PooFlowJsonSchemaPatternProperty] JsonSchemaDatum Boolean)
;;   | doc m%
;;       Apply every matched pattern-property predicate to the runtime value and
;;       preserve conjunctive JSON Schema semantics.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-pattern-runtime-valid? '() "value")
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-json-schema-pattern-runtime-valid? pattern-properties value)
  (if (every
       (lambda (pattern-property)
         ((poo-flow-json-schema-node-predicate
           (poo-flow-json-schema-pattern-property-schema pattern-property))
          value))
       pattern-properties)
    #t
    #f))

;; : (-> JsonSchemaAdditionalProperties JsonSchemaDatum Boolean)
(def (poo-flow-json-schema-additional-runtime-valid? additional-properties value)
  (cond
   ((eq? additional-properties #t) #t)
   ((eq? additional-properties #f) #f)
   ((poo-flow-json-schema-node? additional-properties)
    ((poo-flow-json-schema-node-predicate additional-properties) value))
   (else #t)))

;; poo-flow-json-schema-static-property-name?
;;   : (-> [PooFlowJsonSchemaProperty] JsonSchemaKey Boolean)
;;   | doc m%
;;       Detect whether a runtime object key is already covered by a static
;;       property definition before pattern/additional handling runs.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-static-property-name? '() 'missing)
;;       ;; => #f
;;       ```
;;     %
(def (poo-flow-json-schema-static-property-name? properties key)
  (if (find
       (lambda (property)
         (poo-flow-json-schema-schema-key=?
          (poo-flow-json-schema-property-name property)
          key))
       properties)
    #t
    #f))

;; poo-flow-json-schema-object-entry
;;   : (-> JsonSchemaRuntimeObjectRows JsonSchemaKey JsonSchemaObjectEntry)
;;   | doc m%
;;       Return the runtime object entry whose key matches a schema key under
;;       the string-or-symbol normalization rule.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-json-schema-object-entry '((name . "p")) "name")
;;       ;; => (name . "p")
;;       ```
;;     %
(def (poo-flow-json-schema-object-entry value key)
  (find
   (lambda (entry)
     (and (pair? entry)
          (poo-flow-json-schema-schema-key=? (car entry) key)))
   value))

;; poo-flow-json-schema-node-constraints
;;   : (-> PooFlowJsonSchemaNode Alist)
;;   | doc m%
;;       Read normalized constraint metadata from one schema node.
;;     %
;; poo-flow-json-schema-node-predicate-list
;;   : (-> [PooFlowJsonSchemaNode] [JsonSchemaPredicate])
;;   | doc m%
;;       Project child schema nodes into predicate closures through the contract
;;       SRFI-backed list helper.
;;     %
(def (poo-flow-json-schema-node-predicate-list nodes)
  (poo-flow-contract-project-list
   poo-flow-json-schema-node-predicate
   nodes))

;; poo-flow-json-schema-property-slot-projector
;;   : (-> Symbol Symbol Procedure)
;;   | doc m%
;;       Build the property-to-slot mapper for one emitted object contract.
;;     %
(def (poo-flow-json-schema-property-slot-projector object-key object-kind)
  (lambda (property)
    (poo-flow-json-schema-property->slot-contract
     property
     object-key
     object-kind)))

;; poo-flow-json-schema-node-value-kind
;;   : (-> PooFlowJsonSchemaNode Symbol)
;;   | doc m%
;;       Map normalized schema node kinds to generated contract value kinds.
;;     %
(def (poo-flow-json-schema-node-value-kind node)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((eq? kind 'always) 'PooFlowJsonValue)
     ((eq? kind 'never) 'PooFlowJsonNever)
     ((eq? kind 'string) 'String)
     ((eq? kind 'number) 'Number)
     ((eq? kind 'integer) 'Integer)
     ((eq? kind 'boolean) 'Boolean)
     ((eq? kind 'null) 'PooFlowJsonNull)
     ((eq? kind 'object) 'PooFlowJsonObject)
     ((eq? kind 'array) 'List)
     ((eq? kind 'nullable) 'PooFlowJsonNullable)
     ((eq? kind 'enum) 'PooFlowJsonEnum)
     ((eq? kind 'const) 'PooFlowJsonConst)
     ((eq? kind 'one-of) 'PooFlowJsonOneOf)
     (else 'PooFlowJsonValue))))

;; poo-flow-json-schema-node-predicate-key
;;   : (-> PooFlowJsonSchemaNode Symbol)
;;   | doc m%
;;       Map normalized schema node kinds to generated predicate metadata keys.
;;     %
(def (poo-flow-json-schema-node-predicate-key node)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((eq? kind 'always) 'poo-flow-json-schema-any?)
     ((eq? kind 'never) 'poo-flow-json-schema-never?)
     ((eq? kind 'string) 'string?)
     ((eq? kind 'number) 'number?)
     ((eq? kind 'integer) 'poo-flow-json-schema-integer-value?)
     ((eq? kind 'boolean) 'boolean?)
     ((eq? kind 'null) 'poo-flow-json-schema-null?)
     ((eq? kind 'object) 'poo-flow-json-schema-json-object-value?)
     ((eq? kind 'array) 'poo-flow-json-schema-json-array-value?)
     ((eq? kind 'nullable) 'poo-flow-json-schema-nullable-generated?)
     ((eq? kind 'enum) 'poo-flow-json-schema-enum-generated?)
     ((eq? kind 'const) 'poo-flow-json-schema-const-generated?)
     ((eq? kind 'any-of) 'poo-flow-json-schema-any-of-generated?)
     ((eq? kind 'all-of) 'poo-flow-json-schema-all-of-generated?)
     ((eq? kind 'one-of) 'poo-flow-json-schema-one-of-generated?)
     (else 'poo-flow-json-schema-any?))))

;; poo-flow-json-schema-node-predicate
;;   : (-> PooFlowJsonSchemaNode JsonSchemaPredicate)
;;   | result: runtime predicate used by generated slot contracts
;;   | doc m%
;;       Predicate generation is the only runtime-testing boundary in the JSON
;;       Schema bridge; contract metadata still carries the normalized IR.
;;       # Examples
;;       ```scheme
;;       ((poo-flow-json-schema-node-predicate node) value)
;;       ;; => boolean
;;       ```
;;     %
(def (poo-flow-json-schema-node-predicate node)
  (let (kind (poo-flow-json-schema-node-kind node))
    (poo-flow-json-schema-apply-node-constraints
     node
     (cond
      ((eq? kind 'always) poo-flow-json-schema-any?)
      ((eq? kind 'never) (lambda (_value) #f))
     ((eq? kind 'string) (poo-flow-json-schema-string-predicate node))
     ((eq? kind 'number) (poo-flow-json-schema-number-predicate node number?))
     ((eq? kind 'integer)
      (poo-flow-json-schema-number-predicate
       node
       poo-flow-json-schema-integer-value?))
      ((eq? kind 'boolean) boolean?)
      ((eq? kind 'null) poo-flow-json-schema-null?)
     ((eq? kind 'object) (poo-flow-json-schema-object-predicate node))
      ((eq? kind 'array)
      (poo-flow-json-schema-array-predicate
       (poo-flow-json-schema-node-predicate
        (poo-flow-json-schema-node-value node))
       (poo-flow-json-schema-node-metadata node)))
      ((eq? kind 'const)
       (poo-flow-json-schema-const-predicate
        (poo-flow-json-schema-node-value node)))
      ((eq? kind 'enum)
       (poo-flow-json-schema-enum-predicate
        (poo-flow-json-schema-node-value node)))
      ((eq? kind 'nullable)
       (poo-flow-json-schema-nullable-predicate
        (poo-flow-json-schema-node-predicate
         (poo-flow-json-schema-node-value node))))
      ((eq? kind 'any-of)
       (poo-flow-predicate-or
        (poo-flow-json-schema-node-predicate-list
         (poo-flow-json-schema-node-value node))))
      ((eq? kind 'all-of)
       (poo-flow-predicate-and
        (poo-flow-json-schema-node-predicate-list
         (poo-flow-json-schema-node-value node))))
      ((eq? kind 'one-of)
       (poo-flow-predicate-exactly-one
        (poo-flow-json-schema-node-predicate-list
         (poo-flow-json-schema-node-value node))))
      (else poo-flow-json-schema-any?))
     poo-flow-json-schema-json-array-value?)))

;; : (-> JsonSchemaDatum JsonSchemaDatum)
(def (poo-flow-json-schema-map-value-schema->alist value)
  (cond
   ((poo-flow-json-schema-node? value)
    (poo-flow-json-schema-node->alist value))
   ((poo-flow-json-schema-pattern-property? value)
    (poo-flow-json-schema-pattern-property->alist value))
   ((pair? value)
    (cons (poo-flow-json-schema-map-value-schema->alist (car value))
          (poo-flow-json-schema-map-value-schema->alist (cdr value))))
   (else value)))

;; poo-flow-json-schema-property->slot-contract
;;   : (-> PooFlowJsonSchemaProperty Symbol Symbol PooFlowSlotContract)
;;   | doc m%
;;       Emit one property contract while preserving normalized schema and source
;;       property metadata for later facts and receipts.
;;     %
(def (poo-flow-json-schema-property->slot-contract property object-key object-kind)
  (let* ((slot (poo-flow-json-schema-property-name property))
         (schema (poo-flow-json-schema-property-schema property))
         (metadata
          (append
           (list
            (cons 'source 'json-schema)
            (cons 'doc (poo-flow-json-schema-property-doc property))
            (cons 'schema (poo-flow-json-schema-node->alist schema))
            (cons 'property
                  (poo-flow-json-schema-property->alist property)))
           (poo-flow-json-schema-property-metadata property))))
    (poo-flow-slot-contract-record
     (poo-flow-json-schema-contract-key object-key slot)
     object-kind
     slot
     (poo-flow-json-schema-node-value-kind schema)
     (poo-flow-json-schema-node-predicate-key schema)
     (poo-flow-json-schema-node-predicate schema)
     (poo-flow-json-schema-property-required? property)
     metadata)))

;; poo-flow-json-schema-object-node->object-type-contract
;;   : (-> PooFlowJsonSchemaNode Symbol Symbol Symbol PooFlowObjectTypeContract)
;;   | doc m%
;;       Emit a structural object contract from a normalized object node.
;;     %
(def (poo-flow-json-schema-object-node->object-type-contract node owner object-kind
                                                             object-key)
  (let* ((object (poo-flow-json-schema-node-value node))
         (properties
          (if (poo-flow-json-schema-object? object)
            (poo-flow-json-schema-object-properties object)
            '()))
         (slots
          (poo-flow-contract-project-list
           (poo-flow-json-schema-property-slot-projector object-key object-kind)
           properties))
         (metadata
          (append
           (list
            (cons 'source 'json-schema)
            (cons 'schema-kind 'object)
            (cons 'additional-properties
                  (poo-flow-json-schema-map-value-schema->alist
                   (poo-flow-json-schema-object-additional-properties object)))
            (cons 'pattern-properties
                  (poo-flow-json-schema-map-value-schema->alist
                   (poo-flow-json-schema-object-pattern-properties object)))
            (cons 'normalized-schema
                  (poo-flow-json-schema-node->alist node)))
           (poo-flow-json-schema-object-metadata object)
           (poo-flow-json-schema-node-metadata node))))
    (poo-flow-object-type-contract-record
     object-key
     owner
     object-kind
     slots
     metadata)))

;; poo-flow-json-schema-node->object-type-contract
;;   : (-> PooFlowJsonSchemaNode Symbol Symbol Symbol PooFlowObjectTypeContract)
;;   | doc m%
;;       Emit an object contract for structural schemas and a single `value`
;;       slot contract for scalar or fallback schemas.
;;     %
(def (poo-flow-json-schema-node->object-type-contract node owner object-kind
                                                      object-key)
  (if (and (poo-flow-json-schema-node? node)
           (eq? (poo-flow-json-schema-node-kind node) 'object))
    (poo-flow-json-schema-object-node->object-type-contract
     node
     owner
     object-kind
     object-key)
    (poo-flow-object-type-contract-record
     object-key
     owner
     object-kind
     (list
      (poo-flow-slot-contract-record
       (poo-flow-json-schema-contract-key object-key 'value)
       object-kind
       'value
       (poo-flow-json-schema-node-value-kind node)
       (poo-flow-json-schema-node-predicate-key node)
       (poo-flow-json-schema-node-predicate node)
       #t
       (list
        (cons 'source 'json-schema)
        (cons 'schema (poo-flow-json-schema-node->alist node)))))
     (list
      (cons 'source 'json-schema)
      (cons 'schema-kind (poo-flow-json-schema-node-kind node))
      (cons 'normalized-schema (poo-flow-json-schema-node->alist node))))))
(import (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-pattern-property-schema
                 poo-flow-json-schema-pattern-property-pattern
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-object?
                 poo-flow-json-schema-node?))
