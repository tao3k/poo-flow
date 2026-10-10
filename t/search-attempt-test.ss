;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import :std/test (only-in :clan/poo/object .ref)
        :poo-flow/src/core/object-syntax
        :poo-flow/modules/search/interface)
(export search-attempt-test)
(def stage (poo-flow-search-stage 'a 'acquire '() 'source 'candidates
                                   poo-flow-search-acquisition-role))
(def (initial) (poo-flow-search-attempt-state stage "generation" "config" "cut"))
(def (rejected? thunk)
  (with-catch (lambda (_) #t) (lambda () (thunk) #f)))
(def search-attempt-test
  (test-suite "Search temporal attempt admission"
    (test-case "current attempt settles exactly once"
      (let* ((issued (poo-flow-search-attempt-issue (initial)))
             (state (.ref issued 'state)) (request (.ref issued 'request))
             (done (poo-flow-search-attempt-settle state request)))
        (check (.ref done 'active) => #f)
        (check (rejected? (lambda () (poo-flow-search-attempt-settle done request))) => #t)
        (check (rejected? (lambda () (poo-flow-search-attempt-issue state))) => #t)))
    (test-case "all original identity fields are admitted"
      (let* ((issued (poo-flow-search-attempt-issue (initial)))
             (state (.ref issued 'state)) (request (.ref issued 'request)))
        (for-each
         (lambda (wrong)
           (check (rejected? (lambda () (poo-flow-search-attempt-settle state wrong))) => #t))
         (list
          (poo-core-role-object (slots ((stage (poo-flow-search-stage 'b 'acquire '() 'source 'candidates poo-flow-search-acquisition-role)))) (supers request))
          (poo-core-role-object (slots ((attempt 99))) (supers request))
          (poo-core-role-object (slots ((revision 1))) (supers request))
          (poo-core-role-object (slots ((source-cut "foreign"))) (supers request))
          (poo-core-role-object (slots ((generation "foreign"))) (supers request))
          (poo-core-role-object (slots ((configuration "foreign"))) (supers request))))))
    (test-case "revision fences old work even with an unchanged cut"
      (let* ((issued (poo-flow-search-attempt-issue (initial)))
             (old (.ref issued 'request))
             (revised (poo-flow-search-attempt-revise (.ref issued 'state) "cut"))
             (again (poo-flow-search-attempt-issue revised))
             (state (.ref again 'state)))
        (check (.ref (.ref again 'request) 'attempt) => 1)
        (check (.ref state 'revision) => 1)
        (check (rejected? (lambda () (poo-flow-search-attempt-settle state old))) => #t)
        (check (.ref (poo-flow-search-attempt-settle state (.ref again 'request)) 'active) => #f)))
    (test-case "retirement rejects issue completion and revision"
      (let* ((issued (poo-flow-search-attempt-issue (initial)))
             (request (.ref issued 'request))
             (state (poo-flow-search-attempt-retire (.ref issued 'state))))
        (check (.ref (poo-flow-search-attempt-retire state) 'retired?) => #t)
        (check (rejected? (lambda () (poo-flow-search-attempt-issue state))) => #t)
        (check (rejected? (lambda () (poo-flow-search-attempt-settle state request))) => #t)
        (check (rejected? (lambda () (poo-flow-search-attempt-revise state "new"))) => #t)))
    (test-case "request source proposals do not mutate the retained scope"
      (let* ((issued (poo-flow-search-attempt-issue (initial)))
             (state (.ref issued 'state)) (request (.ref issued 'request)))
        (string-set! (.ref request 'source-cut) 0 #\x)
        (check (.ref state 'source-cut) => "cut")
        (check (rejected? (lambda () (poo-flow-search-attempt-settle state request))) => #t)))))
