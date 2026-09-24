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
        (check-equal? (.call UIntTrieSet .count joined) 4)))
    (test-case "native recursive query matches the MRR Ascent closure fixture"
      ;; Node encoding: Ada=1, Bob=2, Cy=3, Dan=4. The edge set and
      ;; five reachable pairs are from mrr-ascent/tests/unit/contracts.rs.
      ;; POO's self slot closes a recursive *query function*; UIntTrieSet
      ;; guards cycles. This does not establish semi-naive rule evaluation.
      (let* ((reachability
              (.o (:: self [] edges nodes)
                  (reachable?
                   (lambda (source target visited)
                     (and (not (.call UIntTrieSet .elt? visited source))
                          (let (visited*
                                (.call UIntTrieSet .cons source visited))
                            (ormap
                             (lambda (edge)
                               (and (= (car edge) source)
                                    (or (= (cadr edge) target)
                                        ((.ref self 'reachable?)
                                         (cadr edge) target visited*))))
                             edges)))))
                  (closure
                   (apply append
                          (map (lambda (source)
                                 (filter-map
                                  (lambda (target)
                                    (and ((.ref self 'reachable?)
                                          source target
                                          (.ref UIntTrieSet '.empty))
                                         (list source target)))
                                  nodes))
                               nodes)))))
             (inputs
              (.o (nodes '(1 2 3 4))
                  (edges '((1 2) (2 3) (1 4) (4 3)))))
             (program (.mix reachability inputs)))
        (check-equal? (.ref program 'closure)
                      '((1 2) (1 3) (1 4) (2 3) (4 3)))
        (let (cyclic
              (.mix (.o (nodes '(1 2 3))
                        (edges '((1 2) (2 3) (3 1) (1 2))))
                    reachability inputs))
          (check-equal? (.ref cyclic 'closure)
                        '((1 1) (1 2) (1 3) (2 1) (2 2) (2 3)
                          (3 1) (3 2) (3 3))))
        ;; A source withdrawal creates a new POO instance. The old demanded
        ;; value stays bound to its original input snapshot.
        (let (retracted
              (.mix (.o (edges '((1 2) (1 4) (4 3))))
                    reachability inputs))
          (check-equal? (.ref retracted 'closure)
                        '((1 2) (1 3) (1 4) (4 3)))
          (check-equal? (.ref program 'closure)
                        '((1 2) (1 3) (1 4) (2 3) (4 3))))
        (let (disconnected
              (.mix (.o (edges '((1 2) (1 4))))
                    reachability inputs))
          (check-equal? (.ref disconnected 'closure)
                        '((1 2) (1 4))))))))
