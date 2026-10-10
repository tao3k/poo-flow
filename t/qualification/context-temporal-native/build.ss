;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The native compiler owns object jobs and their final link barrier.
(import (only-in :std/make make)
        (only-in :std/source this-source-file)
        :gerbil/compiler/driver :gerbil/expander)
(export main)

(def (main output)
  (let* ((root (path-normalize
                (path-expand "../../.." (path-directory (this-source-file)))))
         (executable (path-expand output))
         (entry "t/qualification/context-temporal-native/native-test")
         (ctx (import-module (path-expand (string-append entry ".ss") root) #f #f))
         (deps (append (gxc#find-runtime-module-deps ctx) (list ctx)))
         (names (filter-map
                  (lambda (dep)
                    (let* ((id (expander-context-id dep))
                           (name (if (symbol? id) (symbol->string id) id)))
                      (and (not (and (>= (string-length name) 7)
                                     (equal? (substring name 0 7) "gerbil/")))
                           (not (member #\~ (string->list name))) name)))
                  deps)))
    (make `("t/temporal-evaluator-test"
            "t/ai-agentic-context-session-host-test"
            "t/ai-agentic-context-delta-test"
            "t/session-attempt-test"
            "t/ai-agentic-context-org-anchors-test"
            "t/query-orgize-source-test"
            (exe: "t/qualification/context-temporal-native/native-test"
                  bin: ,(path-strip-directory executable)))
          srcdir: root prefix: "poo-flow"
          bindir: (path-directory executable))
    ;; Build-time traversal avoids recursively loading the full SSI graph
    ;; before the runtime watchdog can observe individual completed imports.
    (call-with-output-file (string-append executable ".modules")
      (lambda (port) (write names port) (newline port)))))
