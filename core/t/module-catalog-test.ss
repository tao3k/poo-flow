;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/source/objects
        :core/module-system/catalog/objects)

(export module-catalog-test)

(def module-catalog-test
  (test-suite "Core Module Catalog"
    (poo-flow-test-case "first SourceRef match ignores provenance metadata"
      (let* ((source (make-poo-flow-module-source-ref
                      'local "feature/interface.ss" '((origin . first))))
             (same-source (make-poo-flow-module-source-ref
                           'local "feature/interface.ss" '((origin . later))))
             (first (.o name: 'first))
             (later (.o name: 'later))
             (catalog
              (make-poo-flow-module-catalog
               'test
               (list (make-poo-flow-module-catalog-entry source first)
                     (make-poo-flow-module-catalog-entry same-source later)))))
        (check-equal? (resolve-poo-flow-module-source/default
                       catalog same-source 'missing)
                      first)
        (check-equal? (poo-flow-module-catalog-modules catalog)
                      (list first later))
        (check-equal? (poo-flow-module-catalog->alist catalog)
                      '((name . test)
                        (entries
                         ((source (kind . local)
                                  (value . "feature/interface.ss")
                                  (metadata (origin . first)))
                          (module . first))
                         ((source (kind . local)
                                  (value . "feature/interface.ss")
                                  (metadata (origin . later)))
                          (module . later)))))))
    (poo-flow-test-case "missing source returns caller default without I/O"
      (let* ((catalog (make-poo-flow-module-catalog 'empty '()))
             (source (make-poo-flow-module-package-source 'absent)))
        (check-equal? (resolve-poo-flow-module-source/default
                       catalog source 'not-found)
                      'not-found)))))
