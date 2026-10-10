;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (rename-in (only-in :gerbil/tools/gxtest main) (main gxtest-main))
        (only-in :gerbil/runtime/init gerbil-load-expander!)
        :gerbil/compiler/driver :gerbil/expander
        "../../temporal-evaluator-test.ss"
        "../../ai-agentic-context-session-host-test.ss"
        "../../ai-agentic-context-delta-test.ss"
        "../../session-attempt-test.ss"
        "../../ai-agentic-context-org-anchors-test.ss"
        "../../query-orgize-source-test.ss")
(export main)
;;; Native static closure follows the established parser/family qualification.
;;; Upstream gxtest still discovers suites and owns assertions and exit status.
(def (main . arguments)
  (unless (and (>= (length arguments) 2)
               (equal? (car arguments) "--module-order"))
    (error "native qualification requires its build-owned module order"))
  (def modules (call-with-input-file (cadr arguments) read))
  (def args (cddr arguments))
  (displayln "poo-test: static module initialization completed") (force-output)
  (gerbil-load-expander!)
  (displayln "poo-test: official expander initialization completed") (force-output)
  (for-each
    (lambda (name)
      (import-module (string->symbol (string-append ":" name)) #f #t)
      (displayln "poo-test: expander import completed " name) (force-output))
    modules)
  (exit (apply gxtest-main args)))
