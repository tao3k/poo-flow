;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/source/objects)

(export module-source-test)

(def module-source-test
  (test-suite "Core Module SourceRef identity"
    (poo-flow-test-case "native source family and resolver identity"
      (let* ((left (make-poo-flow-module-source-ref
                    'local "module/interface.ss" '((origin . first))))
             (right (make-poo-flow-module-source-ref
                     'local "module/interface.ss" '((origin . second)))))
        (check-equal? (poo-flow-module-source-ref? left) #t)
        (check-equal? (poo-flow-module-source-ref=? left right) #t)
        (check-equal? (poo-flow-module-source-ref->alist left)
                      '((kind . local)
                        (value . "module/interface.ss")
                        (metadata (origin . first))))))
    (poo-flow-test-case "source kinds remain inert values"
      (check-equal?
       (poo-flow-module-source-ref-kind
        (make-poo-flow-module-standard-library-source 'std/test))
       'standard-library)
      (check-equal?
       (poo-flow-module-source-ref-metadata
        (make-poo-flow-module-standard-library-source 'std/test))
       '((library . standard))))))
