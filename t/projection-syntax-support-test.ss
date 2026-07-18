;;; -*- Gerbil -*-
;;; Boundary: tests shared static receipt expansion through domain-owned macros.
;;; Invariant: public core/runtime/module declaration shapes and generated alist
;;; behavior remain stable while compile-time support stays centralized.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        :poo-flow/src/core/projection-syntax
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/module-system/runtime-projection-syntax)

(export projection-syntax-support-test)

(def core-projection-binding-evaluations 0)
(def runtime-projection-binding-evaluations 0)
(def module-projection-binding-evaluations 0)

(defpoo-core-receipt-projection
  make-core-static-projection
  (value)
  (bindings
   ((normalized
     (begin
       (set! core-projection-binding-evaluations
             (+ core-projection-binding-evaluations 1))
       value))))
  (fields ((kind 'core) (value normalized))))

(defpoo-runtime-receipt-projection
  make-runtime-static-projection
  (value)
  (bindings
   ((normalized
     (begin
       (set! runtime-projection-binding-evaluations
             (+ runtime-projection-binding-evaluations 1))
       value))))
  (fields (('kind 'runtime) ('value normalized))))

(defpoo-module-final-projection
  make-module-static-projection
  (enabled value)
  (guard enabled '((status . disabled)))
  (bindings
   ((normalized
     (begin
       (set! module-projection-binding-evaluations
             (+ module-projection-binding-evaluations 1))
       value))))
  (fields ((kind 'module) (value normalized))))

(def projection-syntax-support-test
  (test-suite "shared static receipt projection syntax"
    (test-case "core wrapper keeps literal field declaration shape"
      (set! core-projection-binding-evaluations 0)
      (check-equal? (make-core-static-projection 42)
                    '((kind . core) (value . 42)))
      (check-equal? core-projection-binding-evaluations 1))
    (test-case "runtime wrapper keeps quoted field declaration shape"
      (set! runtime-projection-binding-evaluations 0)
      (check-equal? (make-runtime-static-projection 42)
                    '((kind . runtime) (value . 42)))
      (check-equal? runtime-projection-binding-evaluations 1))
    (test-case "module wrapper keeps guard and fallback evaluation boundary"
      (set! module-projection-binding-evaluations 0)
      (check-equal? (make-module-static-projection #t 42)
                    '((kind . module) (value . 42)))
      (check-equal? module-projection-binding-evaluations 1)
      (check-equal? (make-module-static-projection #f 99)
                    '((status . disabled)))
      (check-equal? module-projection-binding-evaluations 1))))
