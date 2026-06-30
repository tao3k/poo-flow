;;; -*- Gerbil -*-
;;; Boundary: custom user-interface multi-agent session graph scenario.
;;; Invariant: graph, registry, and communication receipts are declarative;
;;; Scheme never delivers messages or starts agents.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/modules/session/config)

(export user-interface-custom-session-agent-graph-test)

(load! "../user-interface/custom/my-module/cases/session-agent-graph")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-session-agent-graph-test
  (test-suite "poo-flow custom user-interface session-agent-graph case"
    (test-case "projects custom session graph and communication receipts"
      (let* ((rows poo-flow-custom-module-session-agent-graph-case)
             (registry-entry-count (.ref (car rows) 'entry-count))
             (graph (poo-flow-session-agent-graph->alist (cadr rows)))
             (build-audit (poo-flow-session-communication-receipt->alist
                           (list-ref rows 2)))
             (communication-rows (list-ref rows 4)))
        (check-equal? registry-entry-count 3)
        (check-equal? (test-ref graph 'kind)
                      'poo-flow.session.agent-graph)
        (check-equal? (test-ref graph 'agent-count) 2)
        (check-equal? (test-ref graph 'session-count) 3)
        (check-equal? (test-ref graph 'agent-ids)
                      '(agent/build agent/audit))
        (check-equal? (test-ref graph 'runtime-executed) #f)
        (check-equal? (test-ref build-audit 'relation-kind) 'sibling)
        (check-equal? (test-ref build-audit 'runtime-executed) #f)
        (check-equal? (length communication-rows) 2)))))

(run-tests! user-interface-custom-session-agent-graph-test)
