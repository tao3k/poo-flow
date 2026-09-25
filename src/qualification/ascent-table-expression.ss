;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Experimental binary-relation expression over official persistent tables.
;;; Pair encoding is local to this qualification, not an MRR fact identity.

(import (only-in :clan/poo/object .o .ref .call)
        (only-in :clan/poo/number UInt)
        (only-in :clan/poo/trie SimpleTrie UIntTrieSet))

(export poo-flow-ascent-table-expression-prototype)

(def AdjacencyTable (SimpleTrie UInt UIntTrieSet))

(def (relation-index pairs radix)
  (unless (and (exact-integer? radix) (> radix 1))
    (error "Ascent table radix must be an integer greater than one" radix))
  (.call UIntTrieSet .foldl
         (lambda (pair index)
           (let* ((source (quotient pair radix))
                  (target (modulo pair radix))
                  (neighbors (.call AdjacencyTable .ref index source
                                    (lambda () (.ref UIntTrieSet '.empty)))))
             (when (>= source radix)
               (error "Ascent table pair exceeds the declared radix" pair))
             (.call AdjacencyTable .acons source
                    (.call UIntTrieSet .cons target neighbors)
                    index)))
         (.ref AdjacencyTable '.empty)
         pairs))

(def (relation-compose left right-index radix)
  (.call UIntTrieSet .foldl
         (lambda (pair joined)
           (let* ((source (quotient pair radix))
                  (middle (modulo pair radix))
                  (destinations
                   (.call AdjacencyTable .ref right-index middle
                          (lambda () (.ref UIntTrieSet '.empty)))))
             (when (>= source radix)
               (error "Ascent table pair exceeds the declared radix" pair))
             (.call UIntTrieSet .foldl
                    (lambda (target output)
                      (.call UIntTrieSet .cons
                             (+ (* source radix) target) output))
                    joined destinations)))
         (.ref UIntTrieSet '.empty)
         left))

(def poo-flow-ascent-table-expression-prototype
  (.o (:: self [] source-pairs radix)
      (right-index (relation-index source-pairs radix))
      (compose-left
       (lambda (left-pairs)
         (relation-compose left-pairs (.ref self 'right-index) radix)))
      (two-hop-pairs
       ((.ref self 'compose-left) source-pairs))
      (at-most-two-hop-pairs
       (.call UIntTrieSet .union source-pairs
              (.ref self 'two-hop-pairs)))))
