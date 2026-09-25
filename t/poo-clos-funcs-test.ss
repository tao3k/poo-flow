;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         :std/test
        (only-in :poo-flow/src/module-system/poo-clos/funcs
                 poo-clos-initarg-list? poo-clos-initarg-ref
                 poo-clos-initarg-index poo-clos-initarg-index-first-of
                 poo-clos-identity-index poo-clos-leftmost-index-by
                 poo-clos-first-invalid-initarg
                 poo-clos-position-index/identity
                 poo-clos-natural-permutation?))

(export poo-clos-funcs-test)

(def poo-clos-funcs-test
  (test-suite "POO CLOS linear algorithm functions"
    (poo-flow-test-case "plist traversal preserves presence and leftmost values"
      (check (poo-clos-initarg-list? '(alpha 1 beta #f alpha 2)) => #t)
      (check (poo-clos-initarg-list? '(alpha 1 beta)) => #f)
      (check (call-with-values
              (lambda () (poo-clos-initarg-ref '(alpha #f alpha 2) 'alpha))
              cons)
             => '(#t . #f)))
    (poo-flow-test-case "ordered indexes select call order across aliases"
      (let (index (poo-clos-initarg-index '(second 2 first 1 second 9)))
        (check (call-with-values
                (lambda ()
                  (poo-clos-initarg-index-first-of index '(first second)))
                cons)
               => '(#t . 2))))
    (poo-flow-test-case "identity indexes support one-pass invalid-key admission"
      (let (valid (poo-clos-identity-index '(alpha beta)))
        (check (poo-clos-first-invalid-initarg
                '(alpha 1 allow-other-keys #t gamma 3)
                valid (lambda (name) (eq? name 'allow-other-keys)))
               => 'gamma)))
    (poo-flow-test-case "object indexes retain the first declaration"
      (let* ((first '(payload first))
             (second '(payload second))
             (index
              (poo-clos-leftmost-index-by car (list first second))))
        (check (hash-get index 'payload) => first)))
    (poo-flow-test-case "positions and natural permutations use bounded native indexes"
      (let* ((a (cons 'a '())) (b (cons 'b '()))
             (positions (poo-clos-position-index/identity (list a b))))
        (check (hash-get positions a) => 0)
        (check (hash-get positions b) => 1)
        (check (poo-clos-natural-permutation? '(2 0 1) 3) => #t)
        (check (poo-clos-natural-permutation? '(2 0 2) 3) => #f)
        (check (poo-clos-natural-permutation? '(3 0 1) 3) => #f)))))
