;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/module-system/graph/funs)

(export module-graph-test)

(def (key-of module) (.ref module 'name))
(def (imports-of module) (.ref module 'imports))
(def (inline-imports module)
  (filter (lambda (value) (not (symbol? value))) (imports-of module)))

(def module-graph-test
  (test-suite "Core Module closure"
    (poo-flow-test-case "depth-first inline closure is ordered and unique"
      (let* ((leaf (.o name: 'leaf imports: '()))
             (root (.o name: 'root imports: (list leaf leaf 'missing)))
             (closed (module-closure (list root) key-of inline-imports)))
        (check-equal? (map key-of closed) '(root leaf))
        (check-equal?
         (module-missing-imports closed key-of imports-of symbol? (lambda (x) x))
         '(((module . root) (import . missing))))))))
