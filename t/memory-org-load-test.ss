;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :std/test check-equal? test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/modules/session/config
        :poo-flow/modules/memory-core/config
        :poo-flow/modules/memory-core/org-load
        :poo-flow/modules/session/org-memory-selection)

(export memory-org-load-test)

(def org-load
  (poo-flow-memory-org-load-receipt
   "project-one" "worktree-a" "notes/memory.org" "cut-a"
   "bytes-sha256" "orgize-pr21-revision" "parser-digest" "graph-digest"
   "tasks.open" "query-rule-sha256" 0
   (list (poo-flow-memory-org-candidate
          1 0 "headline" 19 41 "span-sha256"))))

(def org-store
  (poo-flow-memory-store-spec
   'memory/team 'org-worktree 'worktree '(worktree)
   '(exact-key) '(append) "marlin-agent-core" 'memory/team
   #t 'marlin-memory-adapter))

(def org-intent
  (poo-flow-session-memory-intent
   'intent/team 'memory/team 'worktree '(review) 'append))

(def org-session
  (poo-flow-session-value
   'session/one '()
   (poo-flow-session-lineage 'session/one '() 'root)
   (poo-flow-session-placement 'profile/test)))

(def (org-context worktree-id cut query expected current granted? active?)
  (poo-flow-session-org-memory-selection-context
   "project-one" worktree-id cut "bytes-sha256" query
   "orgize-pr21-revision" "parser-digest" "graph-digest" "query-rule-sha256"
   expected current granted? active?))

(def memory-org-load-test
  (test-suite "POO Flow Org Memory source selection"
    (poo-flow-test-case "accepts one same-cut, granted selection as a pure intent"
      (let (selection
            (poo-flow-session-org-memory-selection-intent
             org-load org-intent org-store org-session
             (org-context "worktree-a" "cut-a" "tasks.open" 3 3 #t #t)))
        (check-equal? (poo-flow-session-org-memory-selection-intent? selection) #t)
        (check-equal? (poo-flow-session-org-memory-selection-intent-eligible? selection) #t)
        (check-equal? (poo-flow-session-org-memory-selection-intent-diagnostics selection) '())
        (check-equal? (.ref selection 'semantic-admitted?) #f)
        (check-equal? (.ref selection 'runtime-executed) #f)))
    (poo-flow-test-case "refuses foreign WorkTree, stale cut, query and head"
      (let (selection
            (poo-flow-session-org-memory-selection-intent
             org-load org-intent org-store org-session
             (org-context "worktree-b" "cut-b" "tasks.done" 3 4 #t #t)))
        (check-equal?
         (poo-flow-session-org-memory-selection-intent-diagnostics selection)
         '(foreign-scope stale-source-cut query-not-granted stale-memory-head))))
    (poo-flow-test-case "refuses a revoked read and inactive Session"
      (let (selection
            (poo-flow-session-org-memory-selection-intent
             org-load org-intent org-store org-session
             (org-context "worktree-a" "cut-a" "tasks.open" 3 3 #f #f)))
        (check-equal?
         (poo-flow-session-org-memory-selection-intent-diagnostics selection)
         '(read-not-granted session-inactive))))
    (poo-flow-test-case "refuses stale graph and query pack at resume"
      (let* ((context
              (poo-flow-session-org-memory-selection-context
               "project-one" "worktree-a" "cut-a" "bytes-sha256" "tasks.open"
               "orgize-pr21-revision" "parser-digest" "new-graph"
               "new-query-rule" 3 3 #t #t))
             (selection
              (poo-flow-session-org-memory-selection-intent
               org-load org-intent org-store org-session context)))
        (check-equal?
         (poo-flow-session-org-memory-selection-intent-diagnostics selection)
         '(stale-orgize-graph stale-query-rule))))
    (poo-flow-test-case "refuses changed bytes at the same source cut"
      (let* ((context
              (poo-flow-session-org-memory-selection-context
               "project-one" "worktree-a" "cut-a" "new-bytes" "tasks.open"
               "orgize-pr21-revision" "parser-digest" "graph-digest"
               "query-rule-sha256" 3 3 #t #t))
             (selection
              (poo-flow-session-org-memory-selection-intent
               org-load org-intent org-store org-session context)))
        (check-equal?
         (poo-flow-session-org-memory-selection-intent-diagnostics selection)
         '(stale-org-bytes))))))
