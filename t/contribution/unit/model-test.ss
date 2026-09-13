(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/contribution/model)
(export model-test)

(def Base
  (poo-clos-class 'contribution-test/base
    direct-slots: (list (poo-clos-direct-slot-definition 'value type-predicate: integer?))))
(def Positive
  (poo-clos-class 'contribution-test/positive direct-superclasses: (list Base)
    direct-slots: (list (poo-clos-direct-slot-definition 'value
                         type-predicate: (lambda (v) (and (number? v) (> v 0)))))))
(def good (.o (:: @ (poo-flow-model-prototype Positive)) value: 2))
(def Shared
  (poo-clos-class 'contribution-test/shared
    direct-slots: (list (poo-clos-direct-slot-definition 'value allocation: 'class))))
(def model-test
  (test-suite "CLOS-governed pure model values"
  (test-case "CLOS inheritance applies all effective slot predicates"
    (check-equal? (poo-flow-model? Positive good) #t)
    (check-equal? (poo-flow-model? Base good) #t)
    (check-equal? (poo-flow-model? Positive (.o (:: @ good) value: -1)) #f)
    (check-equal? (poo-flow-model? Positive (.o (:: @ good) value: 1.5)) #f))
  (test-case "shape and copied class markers cannot impersonate ancestry"
    (check-equal? (poo-flow-model? Positive (.o value: 2 %poo-clos-class: Positive)) #f)
    (check-equal? (poo-flow-model? Positive (.o (:: @ (poo-flow-model-prototype Positive)))) #f)
    (check-equal? (poo-flow-model? Positive #f) #f)
    (check-exception (poo-flow-check-model Positive (.o (:: @ good) value: 'bad)) Error?))
  (test-case "checking and extending preserve the input snapshot"
    (check-eq? (poo-flow-check-model Positive good) good)
    (check-equal? (.ref good 'value) 2))
  (test-case "shared lifecycle storage cannot masquerade as a pure snapshot"
    (check-equal? (poo-flow-model? Shared
                   (.o (:: @ (poo-flow-model-prototype Shared)) value: 2)) #f))))
