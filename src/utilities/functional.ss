;;; -*- Gerbil -*-
;;; Boundary: pure functional helpers for reusable Scheme control-plane code.
;;; Invariant: this module owns algorithms and combinators, not workflow,
;;; sandbox, session, proof, or runtime semantics.

(import (only-in :std/srfi/1
                 assoc
                 any
                 append-map
                 every
                 find
                 filter-map
                 fold
                 fold-right
                 map
                 member
        remove)
        (only-in :std/srfi/13
                 string-drop
                 string-prefix?))

(export poo-flow-fold-left
        poo-flow-fold-right
        poo-flow-map
        poo-flow-find
        poo-flow-filter-map
        poo-flow-remove
        poo-flow-append-map
        poo-flow-any?
        poo-flow-all?
        poo-flow-member?
        poo-flow-alist?
        poo-flow-list-of?
        poo-flow-string-prefix?
        poo-flow-string-drop-prefix
        poo-flow-predicate-and
        poo-flow-predicate-or
        poo-flow-predicate-exactly-one
        poo-flow-alist-ref/default
        poo-flow-alist-select
        poo-flow-alist-delete-key
        poo-flow-alist-merge-right)

;; poo-flow-fold-left
;;   : (-> Procedure Object [Object] Object)
;;   | doc m%
;;       `poo-flow-fold-left` delegates ordinary left folds to SRFI-1 while
;;       keeping shared control-plane algorithms behind a project-owned name.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-fold-left cons '() '(a b))
;;       ;; => (b a)
;;       ```
;;     %
(def (poo-flow-fold-left combine seed values)
  (fold combine seed values))

;; poo-flow-fold-right
;;   : (-> Procedure Object [Object] Object)
;;   | doc m%
;;       `poo-flow-fold-right` preserves right-associated list construction and
;;       projection order without hand-written recursive loops in callers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-fold-right cons '() '(a b))
;;       ;; => (a b)
;;       ```
;;     %
(def (poo-flow-fold-right combine seed values)
  (fold-right combine seed values))

;; poo-flow-map
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       `poo-flow-map` is the project-level pure projection boundary for
;;       keeping field extraction and manifest row construction out of
;;       hand-written recursion.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-map (lambda (value) (* value 2)) '(1 2 3))
;;       ;; => (2 4 6)
;;       ```
;;     %
(def (poo-flow-map project values)
  (map project values))

;; poo-flow-find
;;   : (-> Procedure [Object] Object)
;;   | doc m%
;;       `poo-flow-find` is the project-level pure lookup boundary for
;;       replacing recursive scans that return the matching value.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-find odd? '(2 4 5 6))
;;       ;; => 5
;;       ```
;;     %
(def (poo-flow-find predicate values)
  (find predicate values))

;; poo-flow-filter-map
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       `poo-flow-filter-map` is the default projection helper when a mapper
;;       may reject rows by returning `#f`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-filter-map (lambda (x) (and (odd? x) x)) '(1 2 3))
;;       ;; => (1 3)
;;       ```
;;     %
(def (poo-flow-filter-map project values)
  (filter-map project values))

;; poo-flow-remove
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       `poo-flow-remove` delegates negative filtering to SRFI-1 `remove` so
;;       callers do not hand-roll `(filter (lambda (...) (not ...)) ...)`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-remove even? '(1 2 3))
;;       ;; => (1 3)
;;       ```
;;     %
(def (poo-flow-remove predicate values)
  (remove predicate values))

;; poo-flow-append-map
;;   : (-> Procedure [Object] [Object])
;;   | doc m%
;;       `poo-flow-append-map` flattens one projection layer and should replace
;;       local map/append loops in ordinary list expansion code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-append-map (lambda (x) (list x x)) '(a b))
;;       ;; => (a a b b)
;;       ```
;;     %
(def (poo-flow-append-map project values)
  (append-map project values))

;; poo-flow-any?
;;   : (-> Procedure [Object] Boolean)
;;   | doc m%
;;       `poo-flow-any?` normalizes SRFI-1 `any` into a strict boolean for
;;       predicates used by contract and policy gates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-any? symbol? '(1 two))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-any? predicate values)
  (if (any predicate values) #t #f))

;; poo-flow-all?
;;   : (-> Procedure [Object] Boolean)
;;   | doc m%
;;       `poo-flow-all?` normalizes SRFI-1 `every` into a strict boolean for
;;       list-shaped contract predicates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-all? integer? '(1 2 3))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-all? predicate values)
  (if (every predicate values) #t #f))

;; poo-flow-member?
;;   : (-> Object [Object] Boolean)
;;   | doc m%
;;       `poo-flow-member?` wraps `member` as a strict boolean so callers do
;;       not duplicate `(and (member value values) #t)` in predicates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-member? 'mode '(owner mode))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-member? value values)
  (if (member value values) #t #f))

;; poo-flow-alist?
;;   : (-> Object Boolean)
;;   | doc m%
;;       `poo-flow-alist?` recognizes proper association lists without assigning
;;       any domain meaning to the keys or values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-alist? '((owner . contract)))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-alist? value)
  (and (list? value)
       (poo-flow-all? pair? value)))

;; poo-flow-list-of?
;;   : (-> Procedure Object Boolean)
;;   | doc m%
;;       `poo-flow-list-of?` checks that a value is a list and that every element
;;       satisfies a supplied predicate.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-list-of? symbol? '(alpha beta))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-list-of? predicate value)
  (and (list? value)
       (poo-flow-all? predicate value)))

;; poo-flow-string-prefix?
;;   : (-> String String Boolean)
;;   | doc m%
;;       `poo-flow-string-prefix?` checks string prefixes without allocating
;;       temporary substrings. Non-string inputs are rejected.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-string-prefix? "src/" "src/contract")
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-string-prefix? prefix value)
  (and (string? prefix)
       (string? value)
       (string-prefix? prefix value)))

;; poo-flow-string-drop-prefix
;;   : (-> String String MaybeString)
;;   | doc m%
;;       `poo-flow-string-drop-prefix` returns the suffix after PREFIX when
;;       VALUE has that prefix; otherwise it returns `#f`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-string-drop-prefix "src/" "src/contract")
;;       ;; => "contract"
;;       ```
;;     %
(def (poo-flow-string-drop-prefix prefix value)
  (and (poo-flow-string-prefix? prefix value)
       (string-drop value (string-length prefix))))

;; poo-flow-predicate-and
;;   : (-> [Procedure] Procedure)
;;   | doc m%
;;       `poo-flow-predicate-and` builds one predicate that accepts a value only
;;       when every predicate in the supplied list accepts it.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((poo-flow-predicate-and (list integer? positive?)) 3)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-predicate-and predicates)
  (lambda (value)
    (poo-flow-all?
     (lambda (predicate)
       (predicate value))
     predicates)))

;; poo-flow-predicate-or
;;   : (-> [Procedure] Procedure)
;;   | doc m%
;;       `poo-flow-predicate-or` builds one predicate that accepts a value when
;;       any predicate in the supplied list accepts it.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((poo-flow-predicate-or (list string? symbol?)) 'agent)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-predicate-or predicates)
  (lambda (value)
    (poo-flow-any?
     (lambda (predicate)
       (predicate value))
     predicates)))

;; poo-flow-predicate-exactly-one
;;   : (-> [Procedure] Procedure)
;;   | doc m%
;;       `poo-flow-predicate-exactly-one` builds one predicate that accepts a
;;       value only when exactly one predicate in the supplied list accepts it.
;;       JSON Schema `oneOf` and mutually exclusive policy branches use this
;;       instead of duplicating counting loops.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((poo-flow-predicate-exactly-one (list string? symbol?)) 'agent)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-predicate-exactly-one predicates)
  (lambda (value)
    (= (poo-flow-fold-left
        (lambda (predicate count)
          (if (predicate value)
            (+ count 1)
            count))
        0
        predicates)
       1)))

;; poo-flow-alist-ref/default
;;   : (-> Alist Symbol Object Object)
;;   | doc m%
;;       `poo-flow-alist-ref/default` reads an association-list key and returns
;;       an explicit fallback when the key is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-alist-ref/default '((mode . strict)) 'missing 'fallback)
;;       ;; => fallback
;;       ```
;;     %
(def (poo-flow-alist-ref/default alist key default-value)
  (let (entry (assoc key alist))
    (if entry
      (cdr entry)
      default-value)))

;; poo-flow-alist-select
;;   : (-> [Symbol] Alist Alist)
;;   | doc m%
;;       `poo-flow-alist-select` projects keys in caller-provided order and
;;       drops missing keys without allocating placeholder rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-alist-select '(mode owner) '((owner . kernel) (mode . strict)))
;;       ;; => ((mode . strict) (owner . kernel))
;;       ```
;;     %
(def (poo-flow-alist-select keys alist)
  (poo-flow-filter-map
   (lambda (key)
     (let (entry (assoc key alist))
       (and entry
            (cons key (cdr entry)))))
   keys))

;; poo-flow-alist-delete-key
;;   : (-> Symbol Alist Alist)
;;   | doc m%
;;       `poo-flow-alist-delete-key` removes entries matching one key using
;;       `equal?` key comparison.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-alist-delete-key 'budget '((budget . 10) (mode . strict)))
;;       ;; => ((mode . strict))
;;       ```
;;     %
(def (poo-flow-alist-delete-key key alist)
  (poo-flow-remove
   (lambda (entry)
     (equal? key (car entry)))
   alist))

;; poo-flow-alist-merge-right
;;   : (-> Alist Alist Alist)
;;   | doc m%
;;       `poo-flow-alist-merge-right` returns a deterministic right-biased merge:
;;       entries from the right side override matching keys from the left side.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-alist-merge-right '((mode . strict)) '((mode . relaxed)))
;;       ;; => ((mode . relaxed))
;;       ```
;;     %
(def (poo-flow-alist-merge-right left right)
  (poo-flow-fold-right
   (lambda (entry merged)
     (cons entry
           (poo-flow-alist-delete-key (car entry) merged)))
   left
   right))
