;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Audit native POO and Gerbil library operations for the ASCENT experiment.
;;; This is a dependency capability test, not a relational-closure test.

(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :clan/poo/object .o .mix .ref .call)
        (only-in :clan/poo/trie UIntTrieSet))

(export ascent-poo-primitives-test)

(def ascent-poo-primitives-test
  (test-suite "ASCENT native POO primitives"
    (test-case "late refinement supplies a demanded relation slot"
      (let* ((rule-prototype
              (.o (:: self [] edges)
                  (candidate-edges edges)))
             (input-prototype
              (.o (edges '((a b) (b c)))))
             (program (.mix rule-prototype input-prototype)))
        (check-equal? (.ref program 'candidate-edges)
                      '((a b) (b c)))))
    (test-case "C4 precedence composes a shared prototype once"
      (let* ((base (.o (origin 'base) (decision 'base)))
             (left (.o (:: self base) (decision 'left)))
             (right (.o (:: self base) (origin 'right)))
             (program (.mix left right)))
        (check-equal? (.ref program 'decision) 'left)
        (check-equal? (.ref program 'origin) 'right)))
    (test-case "set union is persistent and deduplicated"
      (let* ((left (.call UIntTrieSet .<-list '(1 3 5)))
             (right (.call UIntTrieSet .<-list '(3 4)))
             (joined (.call UIntTrieSet .union left right)))
        (check-equal? (.call UIntTrieSet .list<- left) '(1 3 5))
        (check-equal? (.call UIntTrieSet .list<- joined) '(1 3 4 5))
        (check-equal? (.call UIntTrieSet .count joined) 4)))))
