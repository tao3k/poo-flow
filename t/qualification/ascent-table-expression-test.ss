;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test check-equal? check-exception test-case test-suite)
        (only-in :clan/poo/object .o .mix .ref .call)
        (only-in :clan/poo/trie UIntTrieSet)
        (only-in :poo-flow/src/qualification/ascent-table-expression
                 poo-flow-ascent-table-expression-prototype))

(export ascent-table-expression-test)

(def ascent-table-expression-test
  (test-suite "ASCENT table expression over native persistent tries"
    (test-case "indexed composition deduplicates the diamond's two-hop path"
      ;; Radix 8: 1->2=10, 2->3=19, 1->4=12, 4->3=35.
      (let* ((source
              (.o (source-pairs (.call UIntTrieSet .<-list '(10 19 12 35)))
                  (radix 8)))
             (expression (.mix poo-flow-ascent-table-expression-prototype
                               source)))
        (check-equal? (.ref expression 'two-hop-pairs)
                      '(11))
        (check-equal?
         ((.ref expression 'compose-left)
          (.call UIntTrieSet .singleton 10))
         '(11))
        (check-equal? (.ref expression 'at-most-two-hop-pairs)
                      '(10 11 12 19 35))
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) 11) #t)
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) 13) #f)
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) -1) #f)
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) 64) #f)
        (let* ((withdrawn
                (.mix (.o (source-pairs
                           (.call UIntTrieSet .remove
                                  (.ref source 'source-pairs) 19)))
                      poo-flow-ascent-table-expression-prototype source)))
          (check-equal? (.ref withdrawn 'two-hop-pairs)
                        '(11))
          (check-equal? ((.ref withdrawn 'at-most-two-hop-contains?) 19) #f)
          (check-equal? ((.ref expression 'at-most-two-hop-contains?) 19) #t)
          (check-equal? (.ref expression 'at-most-two-hop-pairs)
                        '(10 11 12 19 35)))))
    (test-case "a cycle produces only its bounded two-hop self pairs"
      (let* ((source (.o (source-pairs
                          (.call UIntTrieSet .<-list '(10 17)))
                         (radix 8)))
             (expression (.mix poo-flow-ascent-table-expression-prototype
                               source)))
        (check-equal? (.ref expression 'two-hop-pairs)
                      '(9 18))))
    (test-case "larger radix retains sparse snapshot and membership behavior"
      (let* ((source (.o (source-pairs
                          (.call UIntTrieSet .<-list '(515 1029)))
                         (radix 513)))
             (expression (.mix poo-flow-ascent-table-expression-prototype
                               source)))
        (check-equal? (.ref expression 'at-most-two-hop-pairs)
                      '(515 516 1029))
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) 516) #t)
        (check-equal? ((.ref expression 'at-most-two-hop-contains?) 517) #f)))
    (test-case "rejects a radix that would alias pair identities"
      (let (invalid
            (.mix poo-flow-ascent-table-expression-prototype
                  (.o (source-pairs (.call UIntTrieSet .<-list '(10)))
                      (radix 2))))
        (check-exception (.ref invalid 'right-index) true)))))
