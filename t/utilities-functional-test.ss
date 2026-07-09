;;; -*- Gerbil -*-
;;; Boundary: behavior checks for generic functional utilities.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in "../src/utilities/functional.ss"
                 poo-flow-fold-right
                 poo-flow-map
                 poo-flow-find
                 poo-flow-filter-map
                 poo-flow-append-map
                 poo-flow-any?
                 poo-flow-all?
                 poo-flow-list-of?
                 poo-flow-predicate-and
                 poo-flow-predicate-or
                 poo-flow-predicate-exactly-one
                 poo-flow-alist-ref/default
                 poo-flow-alist-select
                 poo-flow-alist-delete-key
                 poo-flow-alist-merge-right))

(export utilities-functional-test)

;; : TestSuite
(def utilities-functional-test
  (test-suite "utilities functional helpers"
    (test-case "delegates core list operations to std functional algorithms"
      (check-equal?
       (poo-flow-fold-right cons [] '(a b c))
       '(a b c))
      (check-equal?
       (poo-flow-map
        (lambda (value)
          (* value 2))
        '(1 2 3))
       '(2 4 6))
      (check-equal?
       (poo-flow-find odd? '(2 4 5 6))
       5)
      (check-equal?
       (poo-flow-filter-map
        (lambda (value)
          (and (odd? value) value))
        '(1 2 3 4 5))
       '(1 3 5))
      (check-equal?
       (poo-flow-append-map
        (lambda (value)
          (list value value))
        '(a b c))
       '(a a b b c c)))
    (test-case "composes predicates without duplicating loop code"
      (let ((positive-even?
             (poo-flow-predicate-and (list integer? positive? even?)))
            (string-or-symbol?
             (poo-flow-predicate-or (list string? symbol?)))
            (exact-string-or-symbol?
             (poo-flow-predicate-exactly-one (list string? symbol?))))
        (check-equal? (poo-flow-any? symbol? '(1 "two" three)) #t)
        (check-equal? (poo-flow-all? integer? '(1 2 3)) #t)
        (check-equal? (poo-flow-list-of? symbol? '(alpha beta)) #t)
        (check-equal? (poo-flow-list-of? symbol? 'not-a-list) #f)
        (check-equal? (positive-even? 4) #t)
        (check-equal? (positive-even? -4) #f)
        (check-equal? (string-or-symbol? "agent") #t)
        (check-equal? (string-or-symbol? 'agent) #t)
        (check-equal? (string-or-symbol? 42) #f)
        (check-equal? (exact-string-or-symbol? "agent") #t)
        (check-equal? (exact-string-or-symbol? 'agent) #t)
        (check-equal? (exact-string-or-symbol? 42) #f)))
    (test-case "projects and merges association lists deterministically"
      (let ((base '((owner . kernel)
                    (budget . 100)
                    (mode . strict)))
            (override '((budget . 50)
                        (doctor . enabled))))
        (check-equal?
         (poo-flow-alist-ref/default base 'missing 'fallback)
         'fallback)
        (check-equal?
         (poo-flow-alist-select '(mode owner missing) base)
         '((mode . strict) (owner . kernel)))
        (check-equal?
         (poo-flow-alist-delete-key 'budget base)
         '((owner . kernel) (mode . strict)))
        (check-equal?
         (poo-flow-alist-merge-right base override)
         '((budget . 50)
           (doctor . enabled)
           (owner . kernel)
           (mode . strict)))))))
