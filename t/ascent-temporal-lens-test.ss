;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Consumer qualification of the pinned package; no new POO causal authority.
(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :clan/poo/object object?)
        (only-in :gerbil-ascent/temporal/lens
                 temporal-lens temporal-source temporal-solve temporal-rows
                 temporal-status temporal-evidence-verdicts temporal-verify))
(export ascent-temporal-lens-test)
(def ascent-temporal-lens-test
  (test-suite "pinned ASCENT temporal value consumer"
    (test-case "POO values keep native evidence separate from cut authority"
      (let* ((lens (temporal-lens 0 'owner-clock 0 5 4 'owner-cut '(a b c) 3 #t))
             (source (temporal-source 'owner-source 0 'owner-clock
                       '((a 0 0) (b 1 1) (c 2 4)) '((a b) (b c))))
             (answer (temporal-solve lens source 'a))
             (open (temporal-solve
                    (temporal-lens 0 'owner-clock 0 5 3 'owner-cut '(a b c) 3 #t)
                    source 'a)))
        (check-equal? (object? lens) #t)
        (check-equal? (object? source) #t)
        (check-equal? (object? answer) #t)
        (check-equal? (temporal-status answer) 'complete)
        (check-equal? (temporal-rows answer) '((a b) (a c)))
        (check-equal? (temporal-evidence-verdicts answer) '(valid valid))
        (check-equal? (temporal-verify lens source 'a answer) 'valid)
        (check-equal? (temporal-status open) 'partial)
        (check-equal? (temporal-rows open) [])
        (check-equal? (temporal-evidence-verdicts open) '(not-produced not-produced))
        (check-equal? (temporal-verify lens source 'a open) 'invalid)))))
