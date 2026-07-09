;;; Boundary: owns the core JSON Schema normalization parser entry points and
;;; parser registry plumbing used by the contract harness.
;;; Invariant: callers should trust this owner for parser-visible diagnostics
;;; and normalized IR construction, while emit/runtime behavior remains outside
;;; this module.

(import (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node-record
                 poo-flow-json-schema-diagnostic-record)
        (only-in :std/srfi/1
                 every
                 iota
                 map)
        (only-in "./functional.ss"
                 poo-flow-contract-json-object?
                 poo-flow-contract-json-array->list
                 poo-flow-contract-object-ref
                 poo-flow-contract-string-drop-prefix
                 poo-flow-contract-filter-map
                 poo-flow-contract-map-pair-with-diagnostics))

(export +poo-flow-json-schema-missing+
        poo-flow-json-schema-parse
        poo-flow-json-schema-parse/context
        poo-flow-json-schema-local-definition-name
        poo-flow-json-schema-register-object-parsers!)

;; Engineering boundary: this owner is the JSON Schema parser dispatch core.
;; Keep object/array specialization behind registered parser callbacks and keep
;; list traversal in SRFI-1/project contract helpers so diagnostics remain
;; stable for generated facts.

;; : JsonSchemaMissingSentinel
(def +poo-flow-json-schema-missing+ (list 'poo-flow-json-schema-missing))
;; : MaybeProcedure
(def +poo-flow-json-schema-object-parser+ #f)
;; : MaybeProcedure
(def +poo-flow-json-schema-array-parser+ #f)

;; : (-> Procedure Procedure Void)
(def (poo-flow-json-schema-register-object-parsers! object-parser array-parser)
  (set! +poo-flow-json-schema-object-parser+ object-parser)
  (set! +poo-flow-json-schema-array-parser+ array-parser))

;; : (-> Object Diagnostics Pair)
(def (poo-flow-json-schema-result node diagnostics) (cons node diagnostics))

;; : (-> Symbol Symbol String Object Alist JsonSchemaDiagnostic)
(def (poo-flow-json-schema-diagnostic severity reason message value context)
  (poo-flow-json-schema-diagnostic-record severity reason message value context))

;; : (-> Symbol Object Alist Pair)
(def (poo-flow-json-schema-node-result kind value context)
  (poo-flow-json-schema-result
   (poo-flow-json-schema-node-record kind value context)
   '()))

;; : (-> Symbol Object Alist Symbol String Pair)
(def (poo-flow-json-schema-invalid-result kind value context reason message)
  (poo-flow-json-schema-result
   (poo-flow-json-schema-node-record kind value context)
   (list (poo-flow-json-schema-diagnostic
          'warning reason message value context))))

;; : (-> Object Pair)
(def (poo-flow-json-schema-parse schema)
  (poo-flow-json-schema-parse/context schema '()))

;; : (-> Object Alist Pair)
(def (poo-flow-json-schema-parse/context schema context)
  (cond
   ((poo-flow-json-schema-json-object? schema)
    (poo-flow-json-schema-parse-object schema context))
   ((boolean? schema)
    (poo-flow-json-schema-node-result 'boolean-schema schema context))
   (else
    (poo-flow-json-schema-invalid-result
     'invalid schema context 'invalid-schema
     "JSON Schema entry must be an object or boolean."))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-object schema context)
  (let ((ref (poo-flow-contract-object-ref schema "$ref" +poo-flow-json-schema-missing+)))
    (if (eq? ref +poo-flow-json-schema-missing+)
      (poo-flow-json-schema-parse-non-ref-object schema context)
      (if (string? ref)
        (poo-flow-json-schema-node-result
         'ref ref (cons (cons 'schema schema) context))
        (poo-flow-json-schema-invalid-result
         'invalid-ref ref context 'invalid-ref
         "JSON Schema $ref must be a string.")))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-non-ref-object schema context)
  (let ((logical (poo-flow-json-schema-parse-logical schema context)))
    (if logical
      logical
      (let ((declared-type
             (poo-flow-contract-object-ref schema "type" +poo-flow-json-schema-missing+)))
        (if (eq? declared-type +poo-flow-json-schema-missing+)
          (poo-flow-json-schema-parse-implicit schema context)
          (poo-flow-json-schema-parse-type declared-type schema context))))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-implicit schema context)
  (cond
   ((not (eq? (poo-flow-contract-object-ref schema "properties" +poo-flow-json-schema-missing+)
              +poo-flow-json-schema-missing+))
    (poo-flow-json-schema-object-dispatch schema context))
   ((not (eq? (poo-flow-contract-object-ref schema "additionalProperties" +poo-flow-json-schema-missing+)
              +poo-flow-json-schema-missing+))
    (poo-flow-json-schema-object-dispatch schema context))
   ((not (eq? (poo-flow-contract-object-ref schema "patternProperties" +poo-flow-json-schema-missing+)
              +poo-flow-json-schema-missing+))
    (poo-flow-json-schema-object-dispatch schema context))
   ((not (eq? (poo-flow-contract-object-ref schema "items" +poo-flow-json-schema-missing+)
              +poo-flow-json-schema-missing+))
    (poo-flow-json-schema-array-dispatch schema context))
   (else
    (poo-flow-json-schema-node-result
     'any schema (poo-flow-json-schema-schema-metadata schema context)))))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-object-dispatch schema context)
  (if +poo-flow-json-schema-object-parser+
    (+poo-flow-json-schema-object-parser+ schema context)
    (poo-flow-json-schema-invalid-result
     'object schema context 'object-parser-missing
     "JSON Schema object parser is not registered.")))

;; : (-> JsonObject Alist Pair)
(def (poo-flow-json-schema-array-dispatch schema context)
  (if +poo-flow-json-schema-array-parser+
    (+poo-flow-json-schema-array-parser+ schema context)
    (poo-flow-json-schema-invalid-result
     'array schema context 'array-parser-missing
     "JSON Schema array parser is not registered.")))

;; : (-> JsonObject Alist (U Pair False))
(def (poo-flow-json-schema-parse-logical schema context)
  (let ((all-of (poo-flow-contract-object-ref schema "allOf" +poo-flow-json-schema-missing+))
        (any-of (poo-flow-contract-object-ref schema "anyOf" +poo-flow-json-schema-missing+))
        (one-of (poo-flow-contract-object-ref schema "oneOf" +poo-flow-json-schema-missing+))
        (not-schema (poo-flow-contract-object-ref schema "not" +poo-flow-json-schema-missing+)))
    (cond
     ((not (eq? all-of +poo-flow-json-schema-missing+))
      (poo-flow-json-schema-parse-logical-list 'all-of all-of context))
     ((not (eq? any-of +poo-flow-json-schema-missing+))
      (poo-flow-json-schema-parse-logical-list 'any-of any-of context))
     ((not (eq? one-of +poo-flow-json-schema-missing+))
      (poo-flow-json-schema-parse-logical-list 'one-of one-of context))
     ((not (eq? not-schema +poo-flow-json-schema-missing+))
      (let ((parsed (poo-flow-json-schema-parse/context
                     not-schema (cons (cons 'logical 'not) context))))
        (poo-flow-json-schema-result
         (poo-flow-json-schema-node-record 'not (car parsed) context)
         (cdr parsed))))
     (else #f))))

;; Boundary: logical arrays are pure parser projections, not runtime
;; validation; keep index context aligned with encounter order for proof facts.
;; poo-flow-json-schema-parse-logical-list
;;   : (-> Symbol JsonArray Alist Pair)
;;   | doc m%
;;       Parse allOf/anyOf/oneOf entries through the shared functional
;;       diagnostic mapper. The mapper preserves encounter order while carrying
;;       the per-entry index required by downstream facts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-parse-logical-list 'all-of schemas '())
;;       ;; => (node . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-parse-logical-list kind value context)
  (let ((items (poo-flow-json-schema-array-value value)))
    (if (list? items)
      (let* ((indexed-items (map cons items (iota (length items))))
             (parsed-items
              (poo-flow-contract-map-pair-with-diagnostics
               (lambda (entry)
                 (let ((parsed (poo-flow-json-schema-parse/context
                                (car entry)
                                (cons (cons 'index (cdr entry))
                                      (cons (cons 'logical kind) context)))))
                   (cons (car parsed) (cdr parsed))))
               indexed-items
               '())))
        (poo-flow-json-schema-result
         (poo-flow-json-schema-node-record kind (car parsed-items) context)
         (cdr parsed-items)))
      (poo-flow-json-schema-invalid-result
       'invalid value context 'invalid-logical-list
       "JSON Schema logical keyword must contain an array."))))

;; : (-> Object JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-type declared-type schema context)
  (cond
   ((string? declared-type)
    (poo-flow-json-schema-parse-type-name
     (string->symbol declared-type) schema context))
   ((list? (poo-flow-json-schema-array-value declared-type))
    (poo-flow-json-schema-parse-type-list
     (poo-flow-json-schema-array-value declared-type) schema context))
   (else
    (poo-flow-json-schema-invalid-result
     'invalid declared-type context 'invalid-type
     "JSON Schema type must be a string or string array."))))

;; Boundary: invalid type-array entries become diagnostics, not exceptions.
;; Invariant: the one-of node only contains successfully parsed type nodes.
;; poo-flow-json-schema-parse-type-list
;;   : (-> [Object] JsonObject Alist Pair)
;;   | doc m%
;;       Parse a JSON Schema type array as a one-of node. Invalid entries become
;;       diagnostics, while missing nodes are filtered through the project
;;       contract helper instead of a local accumulator loop.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-parse-type-list '("string" "number") schema '())
;;       ;; => (one-of-node . diagnostics)
;;       ```
;;     %
(def (poo-flow-json-schema-parse-type-list type-list schema context)
  (let ((parsed-types
         (poo-flow-contract-map-pair-with-diagnostics
          (lambda (entry)
            (if (string? entry)
              (let ((parsed (poo-flow-json-schema-parse-type-name
                             (string->symbol entry) schema context)))
                (cons (car parsed) (cdr parsed)))
              (cons +poo-flow-json-schema-missing+
                    (list (poo-flow-json-schema-diagnostic
                           'warning 'invalid-type-entry
                           "JSON Schema type array entry must be a string."
                           entry context)))))
          type-list
          '())))
    (poo-flow-json-schema-result
     (poo-flow-json-schema-node-record
      'one-of
      (poo-flow-contract-filter-map
       (lambda (node)
         (and (not (eq? node +poo-flow-json-schema-missing+)) node))
       (car parsed-types))
      context)
     (cdr parsed-types))))

;; : (-> Symbol JsonObject Alist Pair)
(def (poo-flow-json-schema-parse-type-name type-name schema context)
  (case type-name
    ((object) (poo-flow-json-schema-object-dispatch schema context))
    ((array) (poo-flow-json-schema-array-dispatch schema context))
    ((string number integer boolean null)
     (poo-flow-json-schema-scalar-result type-name schema context))
    (else
     (poo-flow-json-schema-invalid-result
      'unknown-type type-name context 'unknown-type
      "JSON Schema type is not supported."))))

;; : (-> Symbol JsonObject Alist Pair)
(def (poo-flow-json-schema-scalar-result type-name schema context)
  (poo-flow-json-schema-result
   (poo-flow-json-schema-node-record
    type-name schema (poo-flow-json-schema-schema-metadata schema context))
   (poo-flow-json-schema-constraint-diagnostics schema context)))

;; : (-> JsonObject Alist Diagnostics)
(def (poo-flow-json-schema-constraint-diagnostics schema context)
  (append
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "minLength" context)
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "maxLength" context)
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "minItems" context)
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "maxItems" context)
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "minProperties" context)
   (poo-flow-json-schema-nonnegative-integer-diagnostic schema "maxProperties" context)
   (poo-flow-json-schema-number-diagnostic schema "minimum" context)
   (poo-flow-json-schema-number-diagnostic schema "maximum" context)
   (poo-flow-json-schema-number-diagnostic schema "exclusiveMinimum" context)
   (poo-flow-json-schema-number-diagnostic schema "exclusiveMaximum" context)
   (poo-flow-json-schema-number-diagnostic schema "multipleOf" context)
   (poo-flow-json-schema-string-diagnostic schema "pattern" context)
   (poo-flow-json-schema-string-diagnostic schema "format" context)))

;; : (-> JsonObject String Alist Diagnostics)
(def (poo-flow-json-schema-nonnegative-integer-diagnostic schema keyword context)
  (let ((value (poo-flow-contract-object-ref schema keyword +poo-flow-json-schema-missing+)))
    (cond
     ((eq? value +poo-flow-json-schema-missing+) '())
     ((and (integer? value) (>= value 0)) '())
     (else
      (list (poo-flow-json-schema-diagnostic
             'warning 'invalid-constraint-value
             "JSON Schema constraint must be a non-negative integer."
             value
             (cons (cons 'keyword keyword) context)))))))

;; : (-> JsonObject String Alist Diagnostics)
(def (poo-flow-json-schema-number-diagnostic schema keyword context)
  (let ((value (poo-flow-contract-object-ref schema keyword +poo-flow-json-schema-missing+)))
    (cond
     ((eq? value +poo-flow-json-schema-missing+) '())
     ((number? value) '())
     (else
      (list (poo-flow-json-schema-diagnostic
             'warning 'invalid-constraint-value
             "JSON Schema constraint must be a number."
             value
             (cons (cons 'keyword keyword) context)))))))

;; : (-> JsonObject String Alist Diagnostics)
(def (poo-flow-json-schema-string-diagnostic schema keyword context)
  (let ((value (poo-flow-contract-object-ref schema keyword +poo-flow-json-schema-missing+)))
    (cond
     ((eq? value +poo-flow-json-schema-missing+) '())
     ((string? value) '())
     (else
      (list (poo-flow-json-schema-diagnostic
             'warning 'invalid-constraint-value
             "JSON Schema constraint must be a string."
             value
             (cons (cons 'keyword keyword) context)))))))

;; : (-> JsonObject Alist Alist)
(def (poo-flow-json-schema-schema-metadata schema context)
  (let (constraints
        (poo-flow-json-schema-filter-missing
         (list (cons 'minLength (poo-flow-contract-object-ref schema "minLength" +poo-flow-json-schema-missing+))
               (cons 'maxLength (poo-flow-contract-object-ref schema "maxLength" +poo-flow-json-schema-missing+))
               (cons 'minimum (poo-flow-contract-object-ref schema "minimum" +poo-flow-json-schema-missing+))
               (cons 'maximum (poo-flow-contract-object-ref schema "maximum" +poo-flow-json-schema-missing+))
               (cons 'exclusiveMinimum (poo-flow-contract-object-ref schema "exclusiveMinimum" +poo-flow-json-schema-missing+))
               (cons 'exclusiveMaximum (poo-flow-contract-object-ref schema "exclusiveMaximum" +poo-flow-json-schema-missing+))
               (cons 'minItems (poo-flow-contract-object-ref schema "minItems" +poo-flow-json-schema-missing+))
               (cons 'maxItems (poo-flow-contract-object-ref schema "maxItems" +poo-flow-json-schema-missing+))
               (cons 'minProperties (poo-flow-contract-object-ref schema "minProperties" +poo-flow-json-schema-missing+))
               (cons 'maxProperties (poo-flow-contract-object-ref schema "maxProperties" +poo-flow-json-schema-missing+))
               (cons 'pattern (poo-flow-contract-object-ref schema "pattern" +poo-flow-json-schema-missing+)))))
    (poo-flow-json-schema-filter-missing
     (list (cons 'context context)
           (cons 'title (poo-flow-contract-object-ref schema "title" +poo-flow-json-schema-missing+))
           (cons 'description (poo-flow-contract-object-ref schema "description" +poo-flow-json-schema-missing+))
           (cons 'format (poo-flow-contract-object-ref schema "format" +poo-flow-json-schema-missing+))
           (cons 'enum (poo-flow-contract-object-ref schema "enum" +poo-flow-json-schema-missing+))
           (cons 'const (poo-flow-contract-object-ref schema "const" +poo-flow-json-schema-missing+))
           (cons 'constraints constraints)))))

;; Boundary: metadata absence is represented only by the shared sentinel.
;; Invariant: explicit false/null-like values must survive this projection.
;; poo-flow-json-schema-filter-missing
;;   : (-> Alist Alist)
;;   | doc m%
;;       Remove entries whose value is the JSON Schema missing sentinel while
;;       preserving explicit false/null-like values for metadata and proofs.
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

;; : (-> String MaybeSymbol)
(def (poo-flow-json-schema-local-definition-name reference)
  (and (string? reference)
       (let ((definitions-name
              (poo-flow-contract-string-drop-prefix "#/definitions/" reference))
             (defs-name
              (poo-flow-contract-string-drop-prefix "#/$defs/" reference)))
         (let ((name (or definitions-name defs-name)))
           (and name (not (string=? name "")) (string->symbol name))))))

;; poo-flow-json-schema-json-object?
;;   : (-> Object Boolean)
;;   | doc m%
;;       Accept JSON-like alists whose keys are strings or symbols. This guards
;;       the parser against treating arbitrary pair lists as schema objects
;;       while keeping the scan in a declarative SRFI-1 predicate.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-json-object? '(("type" . "string")))
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
