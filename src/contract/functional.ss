;;; -*- Gerbil -*-
;;; Contract: pure helpers for contract-boundary normalization.
;;; Invariant: this module owns contract data plumbing, not JSON Schema
;;; semantics, object contracts, or runtime execution.

(import (only-in :std/srfi/1
                 any
                 append-map
                 every
                 find
                 filter-map
                 fold-right
                 map
                 member
                 remove)
        (only-in :std/srfi/13
                 string-drop
                 string-prefix?))

(export poo-flow-contract-key->string
        poo-flow-contract-key->symbol
        poo-flow-contract-key=?
        poo-flow-contract-json-object?
        poo-flow-contract-json-array->list
        poo-flow-contract-object-ref
        poo-flow-contract-option
        poo-flow-contract-string-prefix?
        poo-flow-contract-string-drop-prefix
        poo-flow-contract-member?
        poo-flow-contract-any?
        poo-flow-contract-all?
        poo-flow-contract-project-list
        poo-flow-contract-filter-map
        poo-flow-contract-append-map
        poo-flow-contract-remove
        poo-flow-contract-map-pair-with-diagnostics)

;; poo-flow-contract-key->string
;;   : (-> ContractKey MaybeString)
;;   | doc m%
;;       Convert symbol/string keys at JSON-like contract boundaries to strings.
;;       Other values return #f so callers can produce domain diagnostics.
;;     %
(def (poo-flow-contract-key->string key)
  (cond
   ((string? key) key)
   ((symbol? key) (symbol->string key))
   (else #f)))

;; poo-flow-contract-key->symbol
;;   : (-> ContractKey Symbol)
;;   | doc m%
;;       Convert symbol/string keys to stable Scheme slot symbols.
;;     %
(def (poo-flow-contract-key->symbol key)
  (cond
   ((symbol? key) key)
   ((string? key) (string->symbol key))
   (else 'unknown-contract-key)))

;; poo-flow-contract-key=?
;;   : (-> ContractKey ContractKey Boolean)
;;   | doc m%
;;       Compare symbol/string keys by their string spelling.
;;     %
(def (poo-flow-contract-key=? candidate key)
  (let ((candidate-name (poo-flow-contract-key->string candidate))
        (key-name (poo-flow-contract-key->string key)))
    (and candidate-name key-name (string=? candidate-name key-name))))

;; poo-flow-contract-json-object?
;;   : (-> Object Boolean)
;;   | doc m%
;;       Recognize JSON-like objects represented as alists at contract import
;;       boundaries.
;;     %
(def (poo-flow-contract-json-object? value)
  (and (list? value)
       (if (every pair? value) #t #f)))

;; poo-flow-contract-json-array->list
;;   : (-> Object [Object])
;;   | doc m%
;;       Normalize vector/list JSON-like arrays into lists. Non-array values are
;;       treated as empty because callers decide whether that is diagnostic.
;;     %
(def (poo-flow-contract-json-array->list value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else '())))

;; poo-flow-contract-any?
;;   : (-> Procedure [Object] Boolean)
;;   | doc m%
;;       Run a SRFI-1 `any` scan at the contract boundary and return a strict
;;       boolean for validators and diagnostics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-any? string? '(1 "x"))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-contract-any? predicate values)
  (if (any predicate values) #t #f))

;; poo-flow-contract-all?
;;   : (-> Procedure [Object] Boolean)
;;   | doc m%
;;       Run a SRFI-1 `every` scan at the contract boundary and return a strict
;;       boolean for list-shaped contract predicates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-all? symbol? '(a b))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-contract-all? predicate values)
  (if (every predicate values) #t #f))

;; poo-flow-contract-object-ref
;;   : (-> Alist ContractKey Object Object)
;;   | result: matched row value or DEFAULT-VALUE
;;   | doc m%
;;       Lookup a symbol/string key in a JSON-like object with explicit fallback.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-object-ref '((type . "object")) 'type #f)
;;       ;; => "object"
;;       ```
;;     %
(def (poo-flow-contract-object-ref object key default-value)
  (let (row (find
             (lambda (candidate)
               (and (pair? candidate)
                    (poo-flow-contract-key=? (car candidate) key)))
             object))
    (if row (cdr row) default-value)))

;; poo-flow-contract-option
;;   : (-> Alist ContractKey Object Object)
;;   | doc m%
;;       Read an optional contract option from a JSON-like alist while keeping
;;       symbol/string key comparison centralized.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-option '((owner . workflow)) 'owner #f)
;;       ;; => workflow
;;       ```
;;     %
(def (poo-flow-contract-option options key default-value)
  (poo-flow-contract-object-ref options key default-value))

;; poo-flow-contract-string-prefix?
;;   : (-> String String Boolean)
;;   | doc m%
;;       Check string prefixes through SRFI-13 without allocating temporary
;;       substrings. Non-string inputs are rejected.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-string-prefix? "#/" "#/definitions/User")
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-contract-string-prefix? prefix value)
  (and (string? prefix)
       (string? value)
       (string-prefix? prefix value)))

;; poo-flow-contract-string-drop-prefix
;;   : (-> String String MaybeString)
;;   | doc m%
;;       Return the suffix after PREFIX when VALUE has that prefix. This keeps
;;       boundary parsers on SRFI-13 string operations instead of hand-written
;;       substring arithmetic.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-string-drop-prefix "#/definitions/" "#/definitions/User")
;;       ;; => "User"
;;       ```
;;     %
(def (poo-flow-contract-string-drop-prefix prefix value)
  (and (poo-flow-contract-string-prefix? prefix value)
       (string-drop value (string-length prefix))))

;; poo-flow-contract-member?
;;   : (-> Object [Object] Boolean)
;;   | doc m%
;;       Wrap SRFI-1 `member` as a strict boolean for enum, seen-set, and
;;       supported-keyword checks.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-member? 'type '(type properties))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-contract-member? value values)
  (if (member value values) #t #f))

;; poo-flow-contract-project-list
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       Project a list through SRFI-1 `map` at the contract boundary so schema
;;       owners do not call generic list primitives directly.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-project-list symbol->string '(a b))
;;       ;; => ("a" "b")
;;       ```
;;     %
(def (poo-flow-contract-project-list projector values)
  (map projector values))

;; poo-flow-contract-filter-map
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       Project and drop rejected rows through SRFI-1 `filter-map`, preserving
;;       encounter order for diagnostics and generated contract slots.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-filter-map (lambda (x) (and x x)) '(#f a))
;;       ;; => (a)
;;       ```
;;     %
(def (poo-flow-contract-filter-map projector values)
  (filter-map projector values))

;; poo-flow-contract-append-map
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       Flatten one projected list layer through SRFI-1 `append-map` for
;;       contract facts that expand one input node into many output rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-append-map (lambda (x) (list x x)) '(a b))
;;       ;; => (a a b b)
;;       ```
;;     %
(def (poo-flow-contract-append-map projector values)
  (append-map projector values))

;; poo-flow-contract-remove
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       Remove rows matching a predicate through SRFI-1 `remove`, usually for
;;       bounded contract projections that need explicit deletion semantics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-remove string? '(a "b" c))
;;       ;; => (a c)
;;       ```
;;     %
(def (poo-flow-contract-remove predicate values)
  (remove predicate values))

;; poo-flow-contract-map-pair-with-diagnostics
;;   : (-> Procedure [Object] [Diagnostic] Pair)
;;   | doc m%
;;       Map values whose projector returns `(value . diagnostics)`, preserving
;;       result order and appending diagnostics in encounter order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-contract-map-pair-with-diagnostics parse rows '())
;;       ;; => (values . diagnostics)
;;       ```
;;     %
(def (poo-flow-contract-map-pair-with-diagnostics project values diagnostics)
  (fold-right
   (lambda (value accumulated)
     (let (parsed (project value))
       (cons (cons (car parsed) (car accumulated))
             (append (cdr parsed) (cdr accumulated)))))
   (cons '() diagnostics)
   values))
