;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/loader/load-path)

(export module-load-path-test)

(def (source identity-value entries)
  (.o (:: @ poo-flow-module-source-collection-prototype)
      (identity identity-value)
      (locate (lambda (_ key roles)
                (if (and (equal? key '(custom . found))
                         (equal? roles '(interface)))
                  entries
                  '())))))

(def module-load-path-test
  (test-suite "Core ordered Module LoadPath"
    (poo-flow-test-case "first matching collection wins and extension appends"
      (let* ((empty (source 'empty '()))
             (first (source 'first '(primary)))
             (second (source 'second '(fallback)))
             (base (make-poo-flow-module-load-path 'base (list empty first)))
             (extended (extend-poo-flow-module-load-path
                        base 'extended (list second))))
        (check-equal? (poo-flow-module-load-path? extended) #t)
        (check-equal? (poo-flow-module-load-path-identity extended) 'extended)
        (check-equal? (map poo-flow-module-source-collection-identity
                           (poo-flow-module-load-path-collections extended))
                      '(empty first second))
        (check-equal? (poo-flow-module-load-path-locate
                       extended '(custom . found))
                      '(primary))
        (check-equal? (poo-flow-module-load-path-locate
                       extended '(custom . absent))
                      '())))
    (poo-flow-test-case "duplicate identities and noncollections are rejected"
      (let (first (source 'same '(primary)))
        (check-exception
         (make-poo-flow-module-load-path 'bad (list first first))
         (lambda (_) #t))
        (check-exception
         (make-poo-flow-module-load-path 'bad (list first 'not-a-source))
         (lambda (_) #t))))
    (poo-flow-test-case "one thousand overlays preserve last-resort lookup"
      (let* ((empty-sources
              (map (lambda (index)
                     (source (string->symbol
                              (string-append "overlay-" (number->string index)))
                             '()))
                   (iota 1000)))
             (path
              (make-poo-flow-module-load-path
               'many (append empty-sources (list (source 'last '(located)))))))
        (check-equal? (length (poo-flow-module-load-path-collections path))
                      1001)
        (check-equal? (poo-flow-module-load-path-locate
                       path '(custom . found))
                      '(located))))))
