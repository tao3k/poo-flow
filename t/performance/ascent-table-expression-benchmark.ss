;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Reproducible qualification microbenchmark. The scanning join is a baseline
;;; only; the POO expression uses the official persistent trie/table methods.

(import (only-in :clan/poo/object .o .mix .ref .call)
        (only-in :clan/poo/trie UIntTrieSet)
        (only-in :poo-flow/src/qualification/ascent-table-expression
                 poo-flow-ascent-table-expression-prototype))

(def pair-radix 256)

(def edge-pairs
  (.call UIntTrieSet .<-list
         (let loop ((node 0) (pairs []))
           (if (= node pair-radix)
               pairs
               (loop (+ node 1)
                     (cons (+ (* node pair-radix) (modulo (+ node 2) pair-radix))
                           (cons (+ (* node pair-radix) (modulo (+ node 1) pair-radix))
                                 pairs)))))))

(def indexed-expression
  (.mix poo-flow-ascent-table-expression-prototype
        (.o (source-pairs edge-pairs) (radix pair-radix))))
(def indexed-compose (.ref indexed-expression 'compose-left))

(def (scanning-compose left right)
  (.call UIntTrieSet .foldl
         (lambda (left-pair joined)
           (.call UIntTrieSet .foldl
                  (lambda (right-pair output)
                    (if (= (modulo left-pair pair-radix)
                           (quotient right-pair pair-radix))
                        (.call UIntTrieSet .cons
                               (+ (* (quotient left-pair pair-radix) pair-radix)
                                  (modulo right-pair pair-radix))
                               output)
                        output))
                  joined right))
         (.ref UIntTrieSet '.empty)
         left))

(def (repeat-indexed count)
  (let loop ((remaining count) (result #f))
    (if (zero? remaining)
        result
        (loop (- remaining 1) (indexed-compose edge-pairs)))))

(def (repeat-scanning count)
  (let loop ((remaining count) (result #f))
    (if (zero? remaining)
        result
        (loop (- remaining 1)
              (scanning-compose edge-pairs edge-pairs)))))

(def indexed-result (repeat-indexed 1))
(def scanning-result (repeat-scanning 1))
(unless (equal? (.call UIntTrieSet .list<- indexed-result)
                (.call UIntTrieSet .list<- scanning-result))
  (error "indexed and scanning relation compositions disagree"))

(display "source-pairs=")
(display (.call UIntTrieSet .count edge-pairs))
(display " output-pairs=")
(display (.call UIntTrieSet .count indexed-result))
(newline)
(display "indexed composition, cached index, three runs\n")
(time (repeat-indexed 3))
(display "scanning composition, three runs\n")
(time (repeat-scanning 3))
