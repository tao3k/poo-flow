;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/funs)

(export module-context-test)

(def module-context-test
  (test-suite "Core Module context queries"
    (poo-flow-test-case "phase and hook queries read metadata only"
      (let (module
            (.o phase-files: '((config . "config.ss"))
                hooks: '((after-config . one))))
        (check-equal? (poo-flow-module-phase-file module 'config) "config.ss")
        (check-equal? (poo-flow-module-phase-file module 'init 'absent) 'absent)
        (check-equal? (poo-flow-module-hook-values module 'after-config)
                      '(one))))
    (poo-flow-test-case "positive and negative flags are pure predicates"
      (let (module (.o flags: '(+fast +safe)))
        (check-equal? (poo-flow-module-flag-enabled? module '+fast) #t)
        (check-equal? (poo-flow-module-flags-enabled?
                       module '(+fast -missing))
                      #t)
        (check-equal? (poo-flow-module-flag-enabled? module '-safe) #f)))
    (poo-flow-test-case "depth order is stable for equal values"
      (let* ((late (.o name: 'late depth: (cons 10 20)))
             (first (.o name: 'first depth: (cons -10 0)))
             (second (.o name: 'second depth: (cons 0 0))))
        (check-equal? (poo-flow-module-depth-value late 'init) 10)
        (check-equal?
         (poo-flow-module-phase-order (list late first second) 'config)
         (list first second late))))))
