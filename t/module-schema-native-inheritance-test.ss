;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: focused native test for module-object POO ancestry.
;;; Invariant: field resolution is delegated to gerbil-poo supers and C4.

(import (only-in :core/observability/testing-case poo-flow-test-case)
         (only-in :std/test
                 check-equal?
                 test-suite)
        :core/module-system/schema/interface
        :core/extension-graph/interface)

(export module-object-native-inheritance-test)

;; : (-> Symbol Symbol PooModuleFieldContract)
(def (symbol-field name default)
  (poo-flow-module-field-contract
   name PooFlowModuleSymbolType 'override default '()))

;; : TestSuite
(def module-object-native-inheritance-test
  (test-suite "native POO module-object inheritance"
    (poo-flow-test-case "diamond field precedence follows native C4 supers"
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
    (poo-flow-test-case "inconsistent native C4 ancestry is rejected"
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
        (check-equal? (not (not failure)) #t)))
    (poo-flow-test-case "root contributions leave the child-only fast path"
      (let* ((child
              (poo-flow-module-object
               'object/child '() (list (symbol-field 'marker 'base)) '()))
             (base (poo-flow-module-objects-node (list child)))
             (contributions
              (list
               (poo-flow-module-field-contribution
                'objects (symbol-field 'namespace 'objects) 'updated)
               (poo-flow-module-field-contribution
                'object/child (symbol-field 'marker 'base) 'changed)))
             (result
              (poo-flow-module-objects-resolve-contributions/node
               base contributions))
             (resolved (poo-flow-module-field-resolution-result-root result))
             (resolved-child
              (poo-flow-module-objects-ref resolved 'object/child)))
        (check-equal?
         (cdr (assoc 'namespace (poo-flow-module-extension-node-slots resolved)))
         'updated)
        (check-equal?
         (cdr (assoc 'marker
                     (poo-flow-module-extension-node-slots resolved-child)))
         'changed)
        (check-equal? (poo-flow-module-field-resolution-result-stable? result)
                      #t)))))
