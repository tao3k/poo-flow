;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Pure allocations are plans. Only the trusted runtime coordinator can issue
;;; authenticated, durable, one-shot grants. Failed attempts never refund them.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list find) "budget-types.ss" "budget-objects.ss")
(export poo-flow-temporal-duration-budget-replay poo-flow-temporal-duration-budget-reserve)
(def (poo-flow-temporal-duration-budget-replay budget)
  (unless (poo-flow-temporal-duration-budget? budget) (error "invalid duration budget"))
  (let loop ((grants (.ref budget 'allocations)) (seen '()) (total 0))
    (if (null? grants)
      (unless (= (+ total (.ref budget 'remaining-ms)) (.ref budget 'capacity-ms)) (error "duration budget does not conserve capacity"))
      (let (g (car grants))
        (unless (and (object? g) (.slot? g 'identity) (.slot? g 'amount-ms) (.slot? g 'publication-digest)
                     (string? (.ref g 'identity)) (> (string-length (.ref g 'identity)) 0)
                     (string? (.ref g 'publication-digest)) (> (string-length (.ref g 'publication-digest)) 0)
                     (exact-integer? (.ref g 'amount-ms)) (> (.ref g 'amount-ms) 0)
                     (not (member (.ref g 'identity) seen))) (error "invalid or duplicate allocation"))
        (loop (cdr grants) (cons (.ref g 'identity) seen) (+ total (.ref g 'amount-ms)))))) budget)
(def (poo-flow-temporal-duration-budget-reserve budget nonce publication-sha amount)
  (poo-flow-temporal-duration-budget-replay budget)
  (unless (and (string? nonce) (> (string-length nonce) 0) (string? publication-sha) (> (string-length publication-sha) 0)
               (exact-integer? amount) (> amount 0)) (error "invalid duration allocation"))
  (let (prior (find (lambda (g) (equal? nonce (.ref g 'identity))) (.ref budget 'allocations)))
    (if prior
      (begin (unless (and (= amount (.ref prior 'amount-ms)) (equal? publication-sha (.ref prior 'publication-digest)))
               (error "allocation nonce collision")) budget)
      (begin
        (when (> amount (.ref budget 'remaining-ms)) (error "duration budget exhausted"))
        (poo-flow-temporal-duration-budget-replay
          (poo-flow-temporal-duration-budget-value (.ref budget 'identity) (.ref budget 'capacity-ms)
            (- (.ref budget 'remaining-ms) amount)
            (append (.ref budget 'allocations)
              (list (.o identity: nonce amount-ms: amount publication-digest: publication-sha)))))))))
