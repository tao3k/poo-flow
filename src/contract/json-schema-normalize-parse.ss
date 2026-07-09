;;; Boundary: owns object/property/pattern-property parsing for normalized JSON
;;; Schema IR and delegates shared registry behavior to normalize-core.
;;; Invariant: parser-owned facts from this owner describe schema shape and
;;; diagnostics only; reference resolution and runtime predicate emission live
;;; in sibling modules.

(import (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node-record
                 poo-flow-json-schema-object-record
                 poo-flow-json-schema-property-record
                 poo-flow-json-schema-pattern-property-record
                 poo-flow-json-schema-diagnostic-record)
        (only-in :std/srfi/1
                 every
                 iota
                 map)
        (only-in "./functional.ss"
                 poo-flow-contract-json-object?
                 poo-flow-contract-json-array->list
                 poo-flow-contract-key->string
                 poo-flow-contract-key->symbol
                 poo-flow-contract-object-ref
                 poo-flow-contract-filter-map
                 poo-flow-contract-member?
                 poo-flow-contract-map-pair-with-diagnostics)
        (only-in "./json-schema-normalize-core.ss"
                 +poo-flow-json-schema-missing+
                 poo-flow-json-schema-parse/context
                 poo-flow-json-schema-register-object-parsers!))

(export poo-flow-json-schema-parse-array-schema
        poo-flow-json-schema-parse-object-schema
        poo-flow-json-schema-parse-definitions)

;; Engineering boundary: this owner parses object/array specializations after
;; the core dispatcher has selected the branch. Keep tuple, property, and
;; definition walks on shared contract mappers so contributed schemas produce
;; deterministic nodes and diagnostics.

;; : (-> Object Diagnostics Pair)
(def (poo-flow-json-schema-result node diagnostics) (cons node diagnostics))

;; : (-> Symbol Symbol String Object Alist JsonSchemaDiagnostic)
(def (poo-flow-json-schema-diagnostic severity reason message value context)
  (poo-flow-json-schema-diagnostic-record severity reason message value context))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-array-schema schema context)
  (let ((items (poo-flow-contract-object-ref schema "items" +poo-flow-json-schema-missing+)))
    (cond
     ((eq? items +poo-flow-json-schema-missing+)
      (poo-flow-json-schema-result
       (poo-flow-json-schema-node-record
        'array
        (poo-flow-json-schema-node-record 'any '() (list (cons 'implicit #t)))
        (poo-flow-json-schema-array-metadata schema context))
       '()))
     ((and (not (poo-flow-json-schema-json-object?
                 (poo-flow-json-schema-array-value items)))
           (list? (poo-flow-json-schema-array-value items)))
      (poo-flow-json-schema-parse-tuple-schema schema items context))
     (else
      (let ((parsed (poo-flow-json-schema-parse/context
                     items
                     (cons (cons 'slot 'items) context))))
        (poo-flow-json-schema-result
         (poo-flow-json-schema-node-record
          'array
          (car parsed)
          (poo-flow-json-schema-array-metadata schema context))
         (cdr parsed)))))))

;; Boundary: tuple schemas are parsed as indexed item projections, not generic
;; array validation; diagnostics stay tied to each tuple position.
;; poo-flow-json-schema-parse-tuple-schema
;;   : (-> JsonObject JsonArray Alist Pair)
;;   | doc m%
;;       Parse tuple-style `items` schemas with the shared diagnostic mapper.
;;       The indexed projection is a pure value transform and keeps tuple node
;;       order stable for generated facts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-parse-tuple-schema schema items '())
;;       ;; => (array-node . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-parse-tuple-schema schema items context)
  (let* ((item-list (poo-flow-json-schema-array-value items))
         (indexed-items (map cons item-list (iota (length item-list))))
         (parsed-items
          (poo-flow-contract-map-pair-with-diagnostics
           (lambda (entry)
             (let ((parsed (poo-flow-json-schema-parse/context
                            (car entry)
                            (list (cons 'slot 'items)
                                  (cons 'index (cdr entry))))))
               (cons (car parsed) (cdr parsed))))
           indexed-items
           '())))
    (poo-flow-json-schema-result
     (poo-flow-json-schema-node-record
      'array
      (car parsed-items)
      (poo-flow-json-schema-array-metadata schema context))
     (cdr parsed-items))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-object-schema schema context)
  (let* ((required (poo-flow-json-schema-required-symbols schema))
         (properties-result
          (poo-flow-json-schema-parse-properties schema required context))
         (additional-result
          (poo-flow-json-schema-parse-additional-properties schema context))
         (patterns-result
          (poo-flow-json-schema-parse-pattern-properties schema context))
         (metadata (poo-flow-json-schema-object-metadata schema context)))
    (poo-flow-json-schema-result
     (poo-flow-json-schema-node-record
      'object
      (poo-flow-json-schema-object-record
       (car properties-result)
       (if (pair? additional-result) (car additional-result) additional-result)
       (car patterns-result)
       metadata)
      metadata)
     (append (cdr properties-result)
             (if (pair? additional-result) (cdr additional-result) '())
             (cdr patterns-result)))))

;; Boundary: this helper projects required names only; malformed required
;; entries are left for validation diagnostics instead of parse-time failure.
;; poo-flow-json-schema-required-symbols
;;   : (-> JsonObject [Symbol])
;;   | doc m%
;;       Project the JSON Schema `required` array into symbols. Non-string
;;       entries are ignored here because diagnostics are emitted by the schema
;;       validation layer.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-required-symbols schema)
;;       ;; => (name email)
;;       ```
;;     %
(def (poo-flow-json-schema-required-symbols schema)
  (let ((required (poo-flow-contract-object-ref schema "required" +poo-flow-json-schema-missing+)))
    (if (list? (poo-flow-json-schema-array-value required))
      (poo-flow-contract-filter-map
       (lambda (entry)
         (and (string? entry) (string->symbol entry)))
       (poo-flow-json-schema-array-value required))
      '())))

;; Boundary: required-slot lookup is a contract membership check over already
;; normalized symbols, so object parsing does not duplicate list traversal.
;; poo-flow-json-schema-required-slot?
;;   : (-> Symbol [Symbol] Boolean)
;;   | doc m%
;;       Check whether an object property is declared in the required symbol
;;       list using the project contract membership helper.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-required-slot? 'name '(name email))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-json-schema-required-slot? name required)
  (poo-flow-contract-member? name required))

;; : (-> JsonObject [Symbol] Alist Pair)
(def (poo-flow-json-schema-parse-properties schema required context)
  (let ((properties
         (poo-flow-contract-object-ref schema "properties" +poo-flow-json-schema-missing+)))
    (cond
     ((eq? properties +poo-flow-json-schema-missing+) (cons '() '()))
     ((poo-flow-json-schema-json-object? properties)
      (poo-flow-json-schema-parse-property-pairs properties required context))
     (else
      (cons '()
            (list (poo-flow-json-schema-diagnostic
                   'warning 'invalid-properties
                   "JSON Schema properties must be an object."
                   properties context)))))))

;; : (-> JsonObject [Symbol] Alist Pair)
(import (only-in :std/pregexp pregexp))

;; : (-> JsonSchemaPairEntry JsonSchemaPairEntryValue)
(def (poo-flow-json-schema-pair-entry-value entry)
  (let (tail (cdr entry))
    (if (and (pair? tail)
             (null? (cdr tail))
             (not (poo-flow-json-schema-json-object? tail))
             (poo-flow-json-schema-json-object? (car tail)))
      (car tail)
      tail)))

;; : (-> Alist [Symbol] Object Object)
(def (poo-flow-json-schema-parse-property-pairs properties required context)
  (poo-flow-contract-map-pair-with-diagnostics
   (lambda (entry)
     (let* ((name (car entry))
        (value (poo-flow-json-schema-pair-entry-value entry))
            (slot (poo-flow-contract-key->symbol name))
            (parsed (poo-flow-json-schema-parse/context
                     value
                     (cons (cons 'property slot) context))))
       (cons (poo-flow-json-schema-property-record
              slot
              (car parsed)
              (poo-flow-json-schema-required-slot? slot required)
              (poo-flow-json-schema-schema-description value)
              '())
             (cdr parsed))))
   properties
   '()))

;; : (-> JsonObject Alist (U Boolean Pair))
(def (poo-flow-json-schema-parse-additional-properties schema context)
  (let ((value
         (poo-flow-contract-object-ref schema "additionalProperties" +poo-flow-json-schema-missing+)))
    (cond
     ((eq? value +poo-flow-json-schema-missing+) #t)
     ((boolean? value) value)
     ((poo-flow-json-schema-json-object? value)
      (poo-flow-json-schema-parse/context
       value
       (cons (cons 'slot 'additional-properties) context)))
     (else
      (cons #f
            (list (poo-flow-json-schema-diagnostic
                   'warning 'invalid-additional-properties
                   "JSON Schema additionalProperties must be boolean or object."
                   value context)))))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-pattern-properties schema context)
  (let ((patterns
         (poo-flow-contract-object-ref schema "patternProperties" +poo-flow-json-schema-missing+)))
    (cond
     ((eq? patterns +poo-flow-json-schema-missing+) (cons '() '()))
     ((poo-flow-json-schema-json-object? patterns)
      (poo-flow-json-schema-parse-pattern-property-pairs patterns context))
     (else
      (cons '()
            (list (poo-flow-json-schema-diagnostic
                   'warning 'invalid-pattern-properties
                   "JSON Schema patternProperties must be an object."
                   patterns context)))))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-pattern-property-pairs patterns context)
  (poo-flow-contract-map-pair-with-diagnostics
   (lambda (entry)
     (let* ((name (car entry))
        (value (poo-flow-json-schema-pair-entry-value entry))
            (parsed (poo-flow-json-schema-parse/context
                     value
                     (cons (cons 'pattern-property
                                 (poo-flow-contract-key->string name))
                           context))))
       (cons (poo-flow-json-schema-pattern-property-record
              (poo-flow-contract-key->string name)
         (pregexp (poo-flow-contract-key->string name))
              (car parsed))
             (cdr parsed))))
   patterns
   '()))

;; : (-> JsonObject Pair)
(def (poo-flow-json-schema-parse-definitions schema)
  (let ((definitions
         (poo-flow-contract-object-ref schema "definitions" +poo-flow-json-schema-missing+))
        (defs
         (poo-flow-contract-object-ref schema "$defs" +poo-flow-json-schema-missing+)))
    (let ((definitions-result
           (if (poo-flow-json-schema-json-object? definitions)
             (poo-flow-json-schema-parse-definition-pairs definitions 'definitions)
             (cons '() '())))
          (defs-result
           (if (poo-flow-json-schema-json-object? defs)
             (poo-flow-json-schema-parse-definition-pairs defs '$defs)
             (cons '() '()))))
      (cons (append (car definitions-result) (car defs-result))
            (append (cdr definitions-result) (cdr defs-result))))))

;; : (-> JsonObject Symbol Pair)
(def (poo-flow-json-schema-parse-definition-pairs definitions slot)
  (poo-flow-contract-map-pair-with-diagnostics
   (lambda (entry)
     (let* ((name (car entry))
        (value (poo-flow-json-schema-pair-entry-value entry))
            (parsed (poo-flow-json-schema-parse/context
                     value
                     (list (cons 'definition (poo-flow-contract-key->symbol name))
                           (cons 'slot slot)))))
       (cons (cons (poo-flow-contract-key->symbol name) (car parsed))
             (cdr parsed))))
   definitions
   '()))

;; : (-> JsonObject Alist Alist)
(def (poo-flow-json-schema-array-metadata schema context)
  (let (constraints
        (poo-flow-json-schema-filter-missing
         (list (cons 'minItems
                     (poo-flow-contract-object-ref schema "minItems" +poo-flow-json-schema-missing+))
               (cons 'maxItems
                     (poo-flow-contract-object-ref schema "maxItems" +poo-flow-json-schema-missing+))
               (cons 'uniqueItems
                     (poo-flow-contract-object-ref schema "uniqueItems" +poo-flow-json-schema-missing+)))))
    (poo-flow-json-schema-filter-missing
     (list (cons 'context context)
           (cons 'constraints constraints)))))

;; : (-> JsonObject Alist Alist)
(def (poo-flow-json-schema-object-metadata schema context)
  (let (constraints
        (poo-flow-json-schema-filter-missing
         (list (cons 'minProperties
                     (poo-flow-contract-object-ref schema "minProperties" +poo-flow-json-schema-missing+))
               (cons 'maxProperties
                     (poo-flow-contract-object-ref schema "maxProperties" +poo-flow-json-schema-missing+)))))
    (poo-flow-json-schema-filter-missing
     (list (cons 'context context)
           (cons 'title
                 (poo-flow-contract-object-ref schema "title" +poo-flow-json-schema-missing+))
           (cons 'description
                 (poo-flow-contract-object-ref schema "description" +poo-flow-json-schema-missing+))
           (cons 'constraints constraints)))))

;; : (-> Object Object)
(def (poo-flow-json-schema-schema-description schema)
  (if (poo-flow-json-schema-json-object? schema)
    (poo-flow-contract-object-ref schema "description" +poo-flow-json-schema-missing+)
    +poo-flow-json-schema-missing+))

;; poo-flow-json-schema-json-object?
;;   : (-> Object Boolean)
;;   | doc m%
;;       Accept JSON-like alists whose keys are strings or symbols before
;;       parsing object-specific schema slots. The predicate uses SRFI-1 `every`
;;       instead of a local accumulator loop.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-json-object? '(("properties" . ())))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-json-schema-json-object? value)
  (and (poo-flow-contract-json-object? value)
       (every (lambda (entry)
                (and (pair? entry)
                     (let ((key (car entry)))
                       (or (string? key) (symbol? key)))))
              value)))

;; : (-> Object [Object])
(def (poo-flow-json-schema-array-value value)
  (let ((items (poo-flow-contract-json-array->list value)))
    (if (and (pair? items)
             (null? (cdr items))
             (list? (car items))
             (not (poo-flow-json-schema-json-object? (car items))))
      (car items)
      items)))

;; Boundary: parse metadata removes only the shared missing sentinel.
;; Invariant: explicit schema values such as #f must remain visible.
;; poo-flow-json-schema-filter-missing
;;   : (-> Alist Alist)
;;   | doc m%
;;       Remove metadata entries that still hold the JSON Schema missing
;;       sentinel. This keeps metadata declaration code compact and makes
;;       absence explicit for downstream facts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-filter-missing `((title . ,+poo-flow-json-schema-missing+)))
;;       ;; => ()
;;       ```
;;     %
(def (poo-flow-json-schema-filter-missing entries)
  (poo-flow-contract-filter-map
   (lambda (entry)
     (and (not (eq? (cdr entry) +poo-flow-json-schema-missing+)) entry))
   entries))

(poo-flow-json-schema-register-object-parsers!
 poo-flow-json-schema-parse-object-schema
 poo-flow-json-schema-parse-array-schema)
