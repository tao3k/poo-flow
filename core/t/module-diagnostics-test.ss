;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object object?)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/observability/diagnostics)

(export module-diagnostics-test)

(def module-diagnostics-test
  (test-suite "Core Module diagnostic values"
    (poo-flow-test-case "POO values preserve facts without product coupling"
      (let* ((diagnostic
              (make-poo-flow-module-diagnostic
               'warning 'duplicate 'module '((name . example))))
             (report
              (make-poo-flow-module-doctor-report
               '(example) 'warning (list diagnostic))))
        (check-equal? (object? diagnostic) #t)
        (check-equal? (poo-flow-module-diagnostic? diagnostic) #t)
        (check-equal? (poo-flow-module-diagnostic-code diagnostic) 'duplicate)
        (check-equal? (poo-flow-module-doctor-report? report) #t)
        (check-equal? (poo-flow-module-doctor-report-modules report)
                      '(example))
        (check-equal? (poo-flow-module-doctor-ok? report) #f)))
    (poo-flow-test-case "status scans warnings and detects a late error"
      (let* ((warnings
              (map (lambda (index)
                     (make-poo-flow-module-diagnostic
                      'warning 'notice index '()))
                   (iota 1000)))
             (error-fact
              (make-poo-flow-module-diagnostic
               'error 'invalid 'module '())))
        (check-equal? (poo-flow-module-diagnostics-status '()) 'ok)
        (check-equal? (poo-flow-module-diagnostics-status warnings) 'warning)
        (check-equal? (poo-flow-module-diagnostics-status
                       (append warnings (list error-fact)))
                      'error)))))
