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
(def (main . args)
  (displayln "poo-test: static module initialization completed") (force-output)
  (gerbil-load-expander!)
  (displayln "poo-test: official expander initialization completed") (force-output)
  (let* ((ctx (import-module ':poo-flow/modules/ai-agentic-context/session-host #f #t))
         (deps (gxc#find-runtime-module-deps ctx)))
    (for-each (lambda (dep)
      (let* ((id (expander-context-id dep))
             (name (if (symbol? id) (symbol->string id) id)))
        (unless (or (and (>= (string-length name) 7) (equal? (substring name 0 7) "gerbil/"))
                    (member #\~ (string->list name)))
          (import-module (string->symbol (string-append ":" name)) #f #t)
          (displayln "poo-test: expander import completed " name) (force-output)))) deps))
  (exit (apply gxtest-main args)))
