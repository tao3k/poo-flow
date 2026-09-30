;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref)
        :core/poo-clos/interface
        :std/test :std/error)
(export poo-clos-model-test)

(def Base
  (poo-clos-class 'model-test/base
    direct-slots: (list (poo-clos-direct-slot-definition
                         'value type-predicate: integer?))))
(def Positive
  (poo-clos-class 'model-test/positive direct-superclasses: (list Base)
    direct-slots: (list (poo-clos-direct-slot-definition
                         'value
                         type-predicate:
                         (lambda (v) (and (number? v) (> v 0)))))))
(def good (.o (:: @ (poo-clos-model-prototype Positive)) value: 2))
(def Shared
  (poo-clos-class 'model-test/shared
    direct-slots: (list (poo-clos-direct-slot-definition
                         'value allocation: 'class))))

(def poo-clos-model-test
  (test-suite "CLOS-governed pure model values"
    (poo-flow-test-case "inherited effective slot predicates apply"
      (check-equal? (poo-clos-model? Positive good) #t)
      (check-equal? (poo-clos-model? Base good) #t)
      (check-equal? (poo-clos-model? Positive (.o (:: @ good) value: -1)) #f)
      (check-equal? (poo-clos-model? Positive (.o (:: @ good) value: 1.5)) #f))
    (poo-flow-test-case "copied class markers cannot impersonate ancestry"
      (check-equal?
       (poo-clos-model-validation-failure
        Positive (.o (:: @ good) value: 'bad))
       '(type-predicate-failed value bad))
      (check-equal?
       (poo-clos-model-validation-failure
        Positive (.o (:: @ (poo-clos-model-prototype Positive))))
       '(missing-slot value))
      (check-equal?
       (poo-clos-model? Positive (.o value: 2 %poo-clos-class: Positive)) #f)
      (check-equal?
       (poo-clos-model?
        Positive (.o (:: @ (poo-clos-model-prototype Positive)))) #f)
      (check-equal? (poo-clos-model? Positive #f) #f)
      (check-exception
       (poo-clos-check-model Positive (.o (:: @ good) value: 'bad))
       Error?))
    (poo-flow-test-case "checking preserves the input value"
      (check-eq? (poo-clos-check-model Positive good) good)
      (check-equal? (.ref good 'value) 2))
    (poo-flow-test-case "class storage is not a pure model slot"
      (check-equal?
       (poo-clos-model? Shared
                        (.o (:: @ (poo-clos-model-prototype Shared)) value: 2))
       #f))))
