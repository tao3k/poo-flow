;;; -*- Gerbil -*-
;;; Boundary: focused native test for module-object POO ancestry.
;;; Invariant: field resolution is delegated to gerbil-poo supers and C3.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/object-core/interface)

(export module-object-native-inheritance-test)

;; : (-> Symbol Symbol PooModuleFieldContract)
(def (symbol-field name default)
  (poo-flow-module-field-contract
   name PooFlowModuleSymbolType 'override default '()))

;; : TestSuite
(def module-object-native-inheritance-test
  (test-suite "native POO module-object inheritance"
    (test-case "diamond field precedence follows native C3 supers"
      (let* ((root
              (poo-flow-module-object
               'object/root '()
               (list (symbol-field 'shared 'root)
                     (symbol-field 'root-only 'root-only))
               '()))
             (right
              (poo-flow-module-object
               'object/right (list root)
               (list (symbol-field 'shared 'right)
                     (symbol-field 'right-only 'right-only))
               '()))
             (left
              (poo-flow-module-object
               'object/left (list root)
               (list (symbol-field 'shared 'left)
                     (symbol-field 'left-only 'left-only))
               '()))
             (child
              (poo-flow-module-object
               'object/child (list left right)
               (list (symbol-field 'child-only 'child-only))
               '())))
        (check-equal?
         (map poo-flow-module-field-contract-identity
              (poo-flow-module-object-resolved-fields child))
         '(shared root-only right-only left-only child-only))
        (check-equal?
         (poo-flow-module-field-contract-default
          (poo-flow-module-object-field child 'shared))
         'left)
        (check-equal?
         (poo-flow-module-field-contract-default
          (poo-flow-module-object-field child 'right-only))
         'right-only)))
    (test-case "inconsistent native C3 ancestry is rejected"
      (let* ((root (poo-flow-module-object 'root '() '() '()))
             (a (poo-flow-module-object 'a (list root) '() '()))
             (b (poo-flow-module-object 'b (list root) '() '()))
             (x (poo-flow-module-object 'x (list a b) '() '()))
             (y (poo-flow-module-object 'y (list b a) '() '()))
             (broken (poo-flow-module-object 'broken (list x y) '() '()))
             (failure
              (with-catch
               (lambda (caught) caught)
               (lambda ()
                 (poo-flow-module-object-resolved-fields broken)
                 #f))))
        (check-equal? (not (not failure)) #t)))))

(run-tests! module-object-native-inheritance-test)
