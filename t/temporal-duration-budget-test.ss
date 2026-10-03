;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        :poo-flow/modules/temporal-causality/time/interface)
(export temporal-duration-budget-test)
(def temporal-duration-budget-test
  (test-suite "duration budget conservation"
    (poo-flow-test-case "allocations conserve capacity and nonce cannot reset cost"
      (let* ((root (poo-flow-temporal-duration-budget "root" 1000))
             (one (poo-flow-temporal-duration-budget-reserve root "attempt" "publication-sha" 600)))
        (check (.ref root 'remaining-ms) => 1000)
        (check-exception (poo-flow-temporal-duration-budget-replay (.o (:: @ root) action-authorized?: #t)) true)
        (check (.ref one 'remaining-ms) => 400)
        (check (.ref (poo-flow-temporal-duration-budget-reserve one "attempt" "publication-sha" 600) 'remaining-ms) => 400)
        (check-exception (poo-flow-temporal-duration-budget-reserve one "attempt" "other-sha" 600) true)
        (check-exception (poo-flow-temporal-duration-budget-reserve one "next" "next-sha" 401) true)
        (check-exception (poo-flow-temporal-duration-budget-replay (.o (:: @ one) remaining-ms: 1000)) true)
        (check (.ref (poo-flow-temporal-duration-budget-reserve one "next" "next-sha" 400) 'remaining-ms) => 0)))))
