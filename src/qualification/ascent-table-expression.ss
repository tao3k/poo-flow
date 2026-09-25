;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Bounded binary-relation expression. The input is an official persistent
;;; UIntTrieSet snapshot; the indexed join uses local Scheme containers and
;;; publishes a canonical, distinct list of encoded pairs.

(import (only-in :clan/poo/object .o .ref .call)
        (only-in :clan/poo/trie UIntTrieSet))

(export poo-flow-ascent-table-expression-prototype)

(def (relation-index pairs radix)
  (unless (and (exact-integer? radix) (> radix 1))
    (error "Ascent table radix must be an integer greater than one" radix))
  (let (index (make-vector radix []))
    (.call UIntTrieSet .foldl
           (lambda (pair _)
             (let ((source (quotient pair radix))
                   (target (modulo pair radix)))
               (when (>= source radix)
                 (error "Ascent table pair exceeds the declared radix" pair))
               (vector-set! index source
                            (cons target (vector-ref index source)))))
           (void) pairs)
    ;; The vector and its mutable lists stay private behind a visitor.
    (lambda (source visit)
      (for-each visit (vector-ref index source)))))

(def (relation-join-index left neighbors-of radix include-source?)
  (let (joined (make-hash-table))
    (.call UIntTrieSet .foldl
           (lambda (pair _)
             (let ((source (quotient pair radix))
                   (middle (modulo pair radix)))
               (when (>= source radix)
                 (error "Ascent table pair exceeds the declared radix" pair))
               (when include-source? (hash-put! joined pair #t))
               (neighbors-of
                middle
                (lambda (target)
                  (hash-put! joined (+ (* source radix) target) #t)))))
           (void) left)
    joined))

(def (relation-projection left neighbors-of radix include-source?)
  (let (joined (relation-join-index left neighbors-of radix include-source?))
    (.o (contains? (lambda (pair) (hash-get joined pair)))
        (pairs (list-sort < (map car (hash->list joined)))))))

(def (relation-compose left neighbors-of radix include-source?)
  (.ref (relation-projection left neighbors-of radix include-source?) 'pairs))

(def poo-flow-ascent-table-expression-prototype
  (.o (:: self [] source-pairs radix)
      (right-index (relation-index source-pairs radix))
      (compose-left
       (lambda (left-pairs)
         (relation-compose left-pairs (.ref self 'right-index) radix #f)))
      (two-hop-pairs
       ((.ref self 'compose-left) source-pairs))
      (at-most-two-hop-projection
       (relation-projection source-pairs (.ref self 'right-index) radix #t))
      (at-most-two-hop-contains?
       (.ref (.ref self 'at-most-two-hop-projection) 'contains?))
      (at-most-two-hop-pairs
       (.ref (.ref self 'at-most-two-hop-projection) 'pairs))))
