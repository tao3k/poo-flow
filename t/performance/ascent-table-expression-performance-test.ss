;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Standard ASP benchmark gate for the POO relation-expression qualification.

(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :clan/poo/object .o .mix .ref .call)
        (only-in :clan/poo/trie UIntTrieSet)
        (only-in :asp-gerbil-scheme/benchmark-api
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :poo-flow/src/qualification/ascent-table-expression
                 poo-flow-ascent-table-expression-prototype))

(export ascent-table-expression-performance-test)

(def ascent-table-expression-fixture-path
  "t/scenarios/performance/ascent-table-expression/benchmark.ss")

(def ascent-table-expression-fixture
  (call-with-input-file ascent-table-expression-fixture-path read))

(def (source-pair-set radix)
  (.call UIntTrieSet .<-list
         (let loop ((node 0) (pairs []))
           (if (= node radix)
               pairs
               (loop (+ node 1)
                     (cons (+ (* node radix) (modulo (+ node 2) radix))
                           (cons (+ (* node radix) (modulo (+ node 1) radix))
                                 pairs)))))))

(def (relation-expression-summary pairs pair-radix)
  (let* ((expression
          (.mix poo-flow-ascent-table-expression-prototype
                (.o (source-pairs pairs) (radix pair-radix))))
         (projected (.ref expression 'at-most-two-hop-pairs)))
    (list (cons 'source-count (.call UIntTrieSet .count pairs))
          (cons 'projected-count (.call UIntTrieSet .count projected)))))

(def ascent-table-expression-performance-test
  (test-suite "ASCENT table expression performance"
    (test-case "indexes and composes 512 source pairs through standard benchmark gate"
      (let* ((radix 256)
             (pairs (source-pair-set radix))
             (summary (relation-expression-summary pairs radix))
             (receipt
              (benchmark-run
               ascent-table-expression-fixture
               (lambda () (relation-expression-summary pairs radix)))))
        (check-equal?
         (benchmark-fixture-contract-pass?
          ascent-table-expression-fixture)
         #t)
        (check-equal? (cdr (assoc 'source-count summary)) 512)
        (check-equal? (cdr (assoc 'projected-count summary)) 1024)
        (display "[poo-flow-benchmark] ascent-table-expression ")
        (write receipt)
        (newline)
        (force-output)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
