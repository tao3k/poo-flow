;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        :std/test
        :poo-flow/modules/temporal-causality/time/interface)
(export temporal-time-test)

(def (instant id domain coordinate modality)
  (poo-flow-temporal-instant id domain coordinate "ledger" modality))

(def temporal-time-test
  (test-suite "temporal type algebra"
    (poo-flow-test-case "clock domains and modality preserve partial order"
      (check (poo-flow-temporal-compare
              (instant "a" "event" 1 'observed)
              (instant "b" "event" 2 'observed)) => 'before)
      (check (poo-flow-temporal-compare
              (instant "a" "event" 1 'observed)
              (instant "b" "ingest" 2 'observed)) => 'incomparable)
      (check (poo-flow-temporal-compare
              (instant "a" "event" 1 'declared)
              (instant "b" "event" 2 'observed)) => 'unknown)
      (check (poo-flow-temporal-compare
              (instant "a" "event" 1 'corrected)
              (instant "b" "event" 2 'observed)) => 'unknown))
    (poo-flow-test-case "interval endpoint openness is explicit"
      (let ((span
             (poo-flow-temporal-interval
              "window" (instant "start" "event" 1 'observed)
              (instant "end" "event" 3 'observed) #t #f)))
        (check (poo-flow-temporal-interval? span) => #t)
        (check (poo-flow-temporal-interval-contains?
                span (instant "at-start" "event" 1 'observed)) => #t)
        (check (poo-flow-temporal-interval-contains?
                span (instant "at-end" "event" 3 'observed)) => #f)
        (check (poo-flow-temporal-interval-contains?
                span (instant "other" "ingest" 2 'observed))
               => 'incomparable)))
    (poo-flow-test-case "event, ingress and processing axes remain distinct"
      (let ((axes (poo-flow-temporal-axes
                   "event-1" (instant "event" "device" 1 'observed)
                   (instant "ingress" "server" 8 'observed) #f)))
        (check (poo-flow-temporal-axes? axes) => #t)))))
