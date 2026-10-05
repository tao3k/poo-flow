;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import :std/test (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/testing-api poo-flow-test-case)
        (only-in :gerbil-ascent/candidate/reasoning
                 reasoning-source-snapshot reasoning-attempt reasoning-receipt-status reasoning-receipt-proof
                 reasoning-receipt-rows reasoning-receipt-bound?)
        (only-in :gerbil-ascent/candidate/provenance positive-proof-status positive-proof-nodes proof-node-row)
        :poo-flow/modules/temporal-causality/evaluator/interface
        :poo-flow/modules/temporal-causality/time/objects
        :poo-flow/modules/temporal-causality/revisions/interface
        :poo-flow/modules/temporal-causality/truth-maintenance/support/interface
        :poo-flow/modules/temporal-causality/truth-maintenance/support/policy-host)
(export temporal-evaluator-test)
;;; Original ASCENT owner data is used only at the explicitly named owner adapter.
(def (source generation) (reasoning-source-snapshot 'graph generation '((edge 2 ((1 2) (2 3))))))
(def proposal '(candidate (relation path 2)
                 (rule (path ?x ?y) (edge ?x ?y))
                 (rule (path ?x ?z) (path ?x ?y) (edge ?y ?z))
                 (query path 1 3) (limits 8 16 32)))
(def (admit snapshot datum receipt (steps 512) (nodes 32))
  (poo-flow-temporal-positive-proof-from-ascent "proof" snapshot datum receipt steps nodes))

(def (at n) (poo-flow-temporal-instant (number->string n) "txn" n "host-clock" 'observed))
(def (policy rev) (poo-flow-temporal-support-policy "policy" rev (at 1) (at 4)))
(def program (poo-flow-temporal-support-program "p" "policy" #t
  (list (poo-flow-temporal-support "s" "claim" "unadmitted-label"
    (list (poo-flow-temporal-support-premise "source" "r1")) '()))))
(def journal (poo-flow-temporal-evidence-journal "j" "txn"
  (list (poo-flow-temporal-evidence-revision "r1" "source" 'assert #f (at 1) (poo-flow-temporal-interval "valid" (at 0) (at 10) #t #f) "content"))))
(def (guard host gen p)
  (poo-flow-temporal-support-policy-host-guard host gen (.ref p 'semantic-digest)
    program journal (at 1) #f 128))
(def temporal-evaluator-test
  (test-suite "original evaluator positive proof admission"
    (poo-flow-test-case "native positive query and original proof replay produce POO admission"
      (let* ((s (source 1)) (receipt (reasoning-attempt s proposal 512)) (a (admit s proposal receipt))
             (replay (poo-flow-temporal-positive-proof-replay a s proposal receipt 512 32)))
        (check (reasoning-receipt-status receipt) => 'complete)
        (check (.ref a 'rows) => '((1 3)))
        (check (.ref a 'proof-admitted?) => #t)
        (check (.ref a 'source-authenticated?) => #f)
        (check (.ref a 'selection-admitted?) => #f)
        (check (.ref a 'action-authorized?) => #f)
        (check (.ref a 'durable?) => #f)
        (check (.ref replay 'semantic-digest) => (.ref a 'semantic-digest))))
    (poo-flow-test-case "stale snapshot changed proposal and forged admission reject"
      (let* ((s (source 1)) (receipt (reasoning-attempt s proposal 512)) (a (admit s proposal receipt))
             (changed '(candidate (relation path 2) (rule (path ?x ?y) (edge ?x ?y))
                          (query path 1 2) (limits 8 16 32))))
        (check-exception (admit (source 2) proposal receipt) true)
        (check-exception (admit s changed receipt) true)
        (check-exception (poo-flow-temporal-positive-proof-replay
          (.o (:: @ a) proof-digest: "forged") s proposal receipt 512 32) true)
        (check-exception (poo-flow-temporal-positive-proof-replay
          (.o (:: @ a) rows: '((1 99))) s proposal receipt 512 32) true)
        (check-exception (poo-flow-temporal-positive-proof-replay
          (.o (:: @ a) action-authorized?: #t) s proposal receipt 512 32) true)))
    (poo-flow-test-case "bounded proof and bounded verification do not become admitted"
      (let* ((s (source 1)) (bounded (reasoning-attempt s proposal 1))
             (complete (reasoning-attempt s proposal 512)))
        (check (reasoning-receipt-status bounded) => 'complete)
        (check (positive-proof-status (reasoning-receipt-proof bounded)) => 'bounded)
        (check-exception (admit s proposal bounded) true)
        (check-exception (admit s proposal complete 512 1) true)
        (check-exception (admit s proposal complete 1 32) true)
        (check-exception (admit s proposal complete 4097 32) true)
        (check-exception (admit s proposal complete 512 129) true)))
    (poo-flow-test-case "hypothetical premise and empty query have no source-only positive admission"
      (let* ((s (reasoning-source-snapshot 'graph 1 '((edge 2 ((1 2))))))
             (hypothetical '(candidate (relation path 2) (fact edge 2 3)
                              (rule (path ?x ?y) (edge ?x ?y))
                              (rule (path ?x ?z) (path ?x ?y) (edge ?y ?z))
                              (query path 1 3) (limits 8 16 32)))
             (h (reasoning-attempt s hypothetical 512))
             (empty (reasoning-attempt s proposal 512)))
        (check (reasoning-receipt-status h) => 'complete)
        (check-exception (admit s hypothetical h) true)
        (check (reasoning-receipt-status empty) => 'complete)
        (check-exception (admit s proposal empty) true)))
    (poo-flow-test-case "host refresh selects registered time and refuses stale generation"
      (let* ((host (poo-flow-temporal-support-policy-host)) (p (policy "rev1"))
             (registered (poo-flow-temporal-support-policy-host-refresh! host p 1 (at 1)))
             (historical (guard host 1 p)))
        (check (.ref registered 'generation) => 1)
        (check (.ref historical 'policy-status) => 'applicable)
        (poo-flow-temporal-support-policy-host-refresh! host p 2 (at 4))
        (check (.ref (guard host 2 p) 'policy-status) => 'expired-policy)
        (check-exception (guard host 1 p) true)
        (check (.ref (poo-flow-temporal-support-guard-replay historical program journal p) 'policy-status) => 'applicable)
        (check (.ref (guard host 2 p) 'action-authorized?) => #f)))
    (poo-flow-test-case "host replacement preserves revision identity and rollback failures preserve current"
      (let* ((host (poo-flow-temporal-support-policy-host)) (old (policy "rev1")) (new (policy "rev2")))
        (poo-flow-temporal-support-policy-host-refresh! host old 1 (at 1))
        (poo-flow-temporal-support-policy-host-refresh! host new 2 (at 2))
        (check (.ref (guard host 2 old) 'policy-status) => 'stale-policy)
        (check (.ref (guard host 2 new) 'policy-status) => 'applicable)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! host old 1 (at 2)) true)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! host new 3 (at 1)) true)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! host old 2 (at 2)) true)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! host
          (poo-flow-temporal-support-policy "policy" "rev2" (at 1) (at 6)) 3 (at 3)) true)
        (check (.ref (guard host 2 new) 'policy-status) => 'applicable)))
    (poo-flow-test-case "host capability instances are isolated and exact snapshot replay is idempotent"
      (let* ((a (poo-flow-temporal-support-policy-host)) (b (poo-flow-temporal-support-policy-host))
             (p (policy "rev1"))
             (first (poo-flow-temporal-support-policy-host-refresh! a p 1 (at 1))))
        (check-exception (guard b 1 p) true)
        (check (.ref (poo-flow-temporal-support-policy-host-refresh! a p 1 (at 1)) 'generation) => 1)
        (check (.ref (guard a 1 p) 'source-authenticated?) => #f)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! a p 2
          (poo-flow-temporal-instant "wrong" "foreign" 2 "host" 'observed)) true)
        (check-exception (poo-flow-temporal-support-policy-host-refresh! a p 2
          (poo-flow-temporal-instant "uncertain" "txn" 2 "host" 'uncertain)) true)
        (check (.ref first 'durable?) => #f)))
    (poo-flow-test-case "original evaluator rule node tamper rejects despite intact native rows and binding"
      (let* ((s (source 1)) (receipt (reasoning-attempt s proposal 512))
             (nodes (positive-proof-nodes (reasoning-receipt-proof receipt)))
             (last-node (list-ref nodes (- (length nodes) 1))))
        (set-car! (proof-node-row last-node) 99)
        (check (reasoning-receipt-bound? receipt s proposal) => #t)
        (check (reasoning-receipt-rows receipt) => '((1 3)))
        (check-exception (admit s proposal receipt) true)))
    (poo-flow-test-case "full host revision inventory rejects overflow without replacing current"
      (let ((host (poo-flow-temporal-support-policy-host)))
        (let loop ((n 1))
          (when (<= n 128)
            (poo-flow-temporal-support-policy-host-refresh! host (policy (number->string n)) n (at 1))
            (loop (+ n 1))))
        (check-exception (poo-flow-temporal-support-policy-host-refresh! host (policy "129") 129 (at 1)) true)
        (check (.ref (guard host 128 (policy "128")) 'policy-status) => 'applicable)))
    (poo-flow-test-case "positive query row projection uses canonical set order"
      (let* ((s (source 1))
             (all '(candidate (relation path 2)
                     (rule (path ?x ?y) (edge ?x ?y))
                     (rule (path ?x ?z) (path ?x ?y) (edge ?y ?z))
                     (query path ?x ?y) (limits 8 16 32)))
             (receipt (reasoning-attempt s all 512))
             (a (admit s all receipt)))
        (check (.ref a 'rows) => '((1 2) (1 3) (2 3)))
        (check (.ref (poo-flow-temporal-positive-proof-replay a s all receipt 512 32) 'semantic-digest)
               => (.ref a 'semantic-digest))))))
