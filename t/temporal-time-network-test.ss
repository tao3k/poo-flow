;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        :poo-flow/modules/temporal-causality/time/interface)
(export temporal-time-network-test)
(def (point id n domain: (domain-value "logical"))
  (poo-flow-temporal-instant id domain-value n "finite-inventory" 'observed))
(def (choice id values) (poo-flow-temporal-time-choice id values))
(def (before id a b) (poo-flow-temporal-time-constraint id a b '(before)))
(def temporal-time-network-test
  (test-suite "finite temporal constraint network"
    (poo-flow-test-case "exhaustive finite domains establish a witness or contradiction"
      (let* ((a (choice "a" (list (point "a1" 1) (point "a3" 3))))
             (b (choice "b" (list (point "b2" 2))))
             (model (poo-flow-temporal-time-network "ordered" (list a b) (list (before "a-b" "a" "b"))))
             (result (poo-flow-temporal-time-network-solve model #f)))
        (check (.ref result 'status) => 'consistent-with-inventory)
        (check (.ref result 'explored-assignments) => 2)
        (check (.ref result 'exhausted?) => #t)
        (check (.ref (poo-flow-temporal-time-network-assessment-replay result model) 'status) => 'consistent-with-inventory)
        (check-exception (poo-flow-temporal-time-network-assessment-replay (.o (:: @ result) status: 'inconsistent) model) true)
        (check (.ref (poo-flow-temporal-time-network-solve
                     (poo-flow-temporal-time-network "cycle" (list a b)
                       (list (before "a-b" "a" "b") (before "b-a" "b" "a"))) #f) 'status) => 'inconsistent)
        (check-exception (poo-flow-temporal-time-network-replay (.o (:: @ model) semantic-digest: "forged")) true)))
    (poo-flow-test-case "unconverted clocks and execution frontier preserve unknown"
      (let ((a (choice "a" (list (point "a1" 1))))
            (b (choice "b" (list (point "b2" 2 domain: "other")))))
        (check (.ref (poo-flow-temporal-time-network-solve
                     (poo-flow-temporal-time-network "cross-clock" (list a b) (list (before "order" "a" "b"))) #f) 'status) => 'unknown)
        (check (.ref (poo-flow-temporal-time-network-solve
                     (poo-flow-temporal-time-network "frontier" (list a b) '()) #f node-limit: 1) 'status) => 'unknown)
        (check-exception (poo-flow-temporal-time-network "bad-point-relation" (list a b)
                          (list (poo-flow-temporal-time-constraint "c" "a" "b" '(overlaps)))) true)))
    (poo-flow-test-case "interval relations use declared extents"
      (let* ((a (poo-flow-temporal-interval "ia" (point "s1" 1) (point "e4" 4) #t #t))
             (b (poo-flow-temporal-interval "ib" (point "s2" 2) (point "e5" 5) #t #t))
             (network (poo-flow-temporal-time-network "overlap" (list (choice "a" (list a)) (choice "b" (list b)))
                        (list (poo-flow-temporal-time-constraint "c" "a" "b" '(overlaps))))))
        (check (.ref (poo-flow-temporal-time-network-solve network #f) 'status) => 'consistent-with-inventory)
        (check-exception (poo-flow-temporal-time-network "mixed" (list (choice "a" (list a)) (choice "b" (list (point "p" 2))))
                          (list (before "c" "a" "b"))) true)))))
