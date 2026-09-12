;;; -*- Gerbil -*-
;;; Qualifier grouping and operator policy for POO-native method combinations.
;;;
;;; This leaf is pure with the exception of typed admission failures.  Method
;;; invocation and effective-method ownership remain in dispatch.ss.

(import (only-in :clan/poo/object .ref)
        (only-in :std/srfi/1 find)
        (only-in :std/sugar ormap)
        "types.ss" "objects.ss")

(export poo-clos-methods-with-qualifier
        poo-clos-partition-long-methods
        poo-clos-execute-short-operator)

;;; Qualifier partitioning happens after one shared specificity sort, so every
;;; group observes the same class/eql precedence decision.
;; : (-> [(Pair ClosMethod [Natural])] MethodQualifier [ClosMethod])
(def (poo-clos-methods-with-qualifier ranked qualifier)
  (map car
       (filter (lambda (entry)
                 (equal? (.ref (car entry) 'qualifier) qualifier))
               ranked)))

;;; Long-form qualifier lists adapt the kernel's =primary= marker to ANSI's
;;; unqualified empty list while preserving explicit symbol/list qualifiers.
;; : (-> ClosMethod [SchemeValue])
(def (method-qualifiers method)
  (let (qualifier (.ref method 'qualifier))
    (cond
     ((eq? qualifier 'primary) '())
     ((symbol? qualifier) (list qualifier))
     (else qualifier))))

;;; A proper pattern matches length exactly.  A dotted tail =*= accepts any
;;; number of remaining qualifiers, while an element =*= matches one position.
;; : (-> SchemeValue [SchemeValue] Boolean)
(def (qualifier-pattern-matches? pattern qualifiers)
  (cond
   ((eq? pattern '*) #t)
   ((null? pattern) (null? qualifiers))
   ((pair? pattern)
    (and (pair? qualifiers)
         (or (eq? (car pattern) '*)
             (equal? (car pattern) (car qualifiers)))
         (qualifier-pattern-matches? (cdr pattern) (cdr qualifiers))))
   (else #f)))

;;; Predicate matchers receive the complete qualifier list.  Pattern matchers
;;; remain declarative and cannot execute user code.
;; : (-> ClosMethodGroup ClosMethod Boolean)
(def (method-group-matches? group method)
  (let (qualifiers (method-qualifiers method))
    (ormap (lambda (matcher)
             (if (procedure? matcher)
               (matcher qualifiers)
               (qualifier-pattern-matches? matcher qualifiers)))
           (.ref group 'matchers))))

;; : (forall (a) (-> a [(Pair a [SchemeValue])]
;;        (Pair SchemeValue [Natural]) [(Pair a [SchemeValue])]))
(def (add-ranked-to-group target grouped entry)
  (map (lambda (group-entry)
         (if (eq? (car group-entry) target)
           (cons target (cons entry (cdr group-entry)))
           group-entry))
       grouped))

;;; Equal specializer precedence with distinct qualifiers has no ANSI ordering
;;; inside one long-form group and is rejected before body execution.
;; : (-> [(Pair ClosMethod [Natural])] Boolean)
(def (ambiguous-ranked-group? entries)
  (let loop ((rest entries))
    (and (pair? rest) (pair? (cdr rest))
         (or (and (equal? (cdar rest) (cdr (cadr rest)))
                  (not (equal? (.ref (caar rest) 'qualifier)
                               (.ref (car (cadr rest)) 'qualifier))))
             (loop (cdr rest))))))

;;; Each applicable method joins only the first matching group.  Group-local
;;; ordering is normalized after assignment and required groups fail before an
;;; effective executor is published.
;; : (-> ClosGenericFunction [(Pair ClosMethod [Natural])]
;;        [(Pair Symbol [ClosMethod])])
(def (poo-clos-partition-long-methods generic ranked)
  (let* ((combination (.ref generic 'method-combination))
         (groups (.ref combination 'groups))
         (initial (map (lambda (group) (cons group '())) groups))
         (assigned
          (foldl
           (lambda (entry grouped)
             (let (group
                   (find (lambda (candidate)
                           (method-group-matches? candidate (car entry)))
                         groups))
               (unless group
                 (clos-fail 'invalid-method-qualifier
                            generic: (.ref generic 'identity)
                            qualifier: (.ref (car entry) 'qualifier)
                            method: (.ref (car entry) 'identity)))
               (add-ranked-to-group group grouped entry)))
           initial ranked)))
    (map
     (lambda (entry)
       (let* ((group (car entry))
              (ranked-values
               (if (eq? (.ref group 'order) 'most-specific-last)
                 (cdr entry)
                 (reverse (cdr entry)))))
         (when (ambiguous-ranked-group? ranked-values)
           (clos-fail 'ambiguous-method-group-order
                      generic: (.ref generic 'identity)))
         (when (and (.ref group 'required?) (null? ranked-values))
           (clos-fail 'required-method-group-empty
                      generic: (.ref generic 'identity)))
         (cons (.ref group 'identity) (map car ranked-values))))
     assigned)))

;;; Control operators own evaluation order and therefore receive a deferred
;;; one-method invocation procedure.
;; : (-> [ClosMethod] (-> ClosMethod SchemeValue) SchemeValue)
(def (execute-short-and methods invoke-one)
  (foldl (lambda (method value)
           (and value (invoke-one method)))
         #t methods))

;; : (-> [ClosMethod] (-> ClosMethod SchemeValue) SchemeValue)
(def (execute-short-or methods invoke-one)
  (foldl (lambda (method value)
           (or value (invoke-one method)))
         #f methods))

;; : (-> [ClosMethod] (-> ClosMethod SchemeValue) SchemeValue)
(def (execute-short-progn methods invoke-one)
  (foldl (lambda (method _value) (invoke-one method)) #f methods))

;;; Eager operators are selected through one closed lookup boundary.  A custom
;;; procedure bypasses symbolic lookup but keeps the same ordered value list.
;; : (-> (U Symbol Procedure) Procedure)
(def (short-eager-operator operator)
  (if (procedure? operator)
    operator
    (case operator
      ((+) +)
      ((append) append)
      ((list) list)
      ((max) max)
      ((min) min)
      ((nconc) append!)
      (else (clos-fail 'unsupported-method-combination-operator)))))

;;; Named drivers prevent operator classification from nesting inside the
;;; public execution boundary.
;; : (-> Symbol (Maybe Procedure))
(def (short-control-driver operator)
  (case operator
    ((and) execute-short-and)
    ((or) execute-short-or)
    ((progn) execute-short-progn)
    (else #f)))

;; : (-> (U Symbol Procedure) [ClosMethod]
;;        (-> ClosMethod SchemeValue) SchemeValue)
(def (poo-clos-execute-short-operator operator methods invoke-one)
  (let (driver (and (symbol? operator) (short-control-driver operator)))
    (if driver
      (driver methods invoke-one)
      (apply (short-eager-operator operator) (map invoke-one methods)))))
