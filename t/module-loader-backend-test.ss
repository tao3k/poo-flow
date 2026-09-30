;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/source/objects
        :core/module-system/loader/objects)

(export module-loader-backend-test)

(def module-loader-backend-test
  (test-suite "Core Module Loader Backend"
    (poo-flow-test-case "lazy values do not invoke their backend before force"
      (let* ((calls 0)
             (source (make-poo-flow-module-local-source "feature/interface.ss"))
             (module (.o name: 'feature))
             (backend
              (make-poo-flow-module-loader-backend
               'static 'local
               (lambda (requested)
                 (set! calls (+ calls 1))
                 (if (poo-flow-module-source-ref=? requested source)
                   module
                   #f))
               '()))
             (deferred (poo-flow-make-lazy-load-plan (list backend) source)))
        (check-equal? calls 0)
        (check-equal? (poo-flow-lazy-load-plan-forced? deferred) #f)
        (check-equal? (poo-flow-module-load-receipt-code
                       (poo-flow-lazy-load-plan-receipt deferred))
                      'deferred)
        (let* ((forced (poo-flow-force-lazy-load-plan deferred))
               (receipt (poo-flow-lazy-load-plan-receipt forced)))
          (check-equal? calls 1)
          (check-equal? (poo-flow-lazy-load-plan-forced? forced) #t)
          (check-equal? (poo-flow-module-load-receipt-loaded? receipt) #t)
          (check-equal? (poo-flow-module-load-receipt->alist receipt)
                        '((source (kind . local)
                                  (value . "feature/interface.ss")
                                  (metadata))
                          (module . feature)
                          (backend-name . static)
                          (loaded? . #t)
                          (code . loaded)
                          (messages)
                          (metadata))))))
    (poo-flow-test-case "unsupported sources remain missing receipts"
      (let* ((source (make-poo-flow-module-package-source 'other))
             (backend (poo-flow-module-static-loader 'local 'local '()))
             (receipt (poo-flow-module-load-source-receipt
                       (list backend) source)))
        (check-equal? (poo-flow-module-load-receipt-loaded? receipt) #f)
        (check-equal? (poo-flow-module-load-receipt-code receipt)
                      'missing-loader)))))
