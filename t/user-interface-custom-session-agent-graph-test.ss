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
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-flag-entry
                 poo-flow-user-module-selection-key)
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/modules/session/config)

(export user-interface-custom-session-agent-graph-test)

(load! "../user-interface/custom/my-module/cases/session-agent-graph")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> [Alist] Symbol [Alist])
(def (rows-with-kind rows kind)
  (let loop ((remaining rows)
             (rows-rev '()))
    (if (null? remaining)
      (reverse rows-rev)
      (let (row (car remaining))
        (loop (cdr remaining)
              (if (and (list? row)
                       (eq? (test-ref row 'kind) kind))
                (cons row rows-rev)
                rows-rev))))))

;; : (-> [PooUserModuleSelection] [Value])
(def (module-config-rows module-selection-bundle)
  (let* ((selection (car module-selection-bundle))
         (entry
          (poo-flow-user-module-selection-flag-entry selection ':session-rows)))
    (if entry (cdr entry) '())))

;; : TestSuite
(def user-interface-custom-session-agent-graph-test
  (test-suite "poo-flow custom user-interface session-agent-graph case"
    (test-case "projects custom session graph and communication receipts"
      (let* ((selection (car poo-flow-custom-module-session-agent-graph-case))
             (rows
              (module-config-rows
               poo-flow-custom-module-session-agent-graph-case))
             (registry-entry-count (.ref (car rows) 'entry-count))
             (graph (poo-flow-session-agent-graph->alist (cadr rows)))
             (build-audit-channel
              (poo-flow-session-communication-channel-receipt->alist
               (list-ref rows 2)))
             (build-audit (poo-flow-session-communication-receipt->alist
                           (list-ref rows 4)))
             (communication-channel-rows
              (rows-with-kind
               rows
               'poo-flow.session.communication-channel-receipt))
             (communication-rows
              (rows-with-kind rows 'poo-flow.session.communication-receipt)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(session . session-core))
        (check-equal? registry-entry-count 3)
        (check-equal? (test-ref graph 'kind)
                      'poo-flow.session.agent-graph)
        (check-equal? (test-ref graph 'agent-count) 2)
        (check-equal? (test-ref graph 'session-count) 3)
        (check-equal? (test-ref graph 'agent-ids)
                      '(agent/build agent/audit))
        (check-equal? (test-ref graph 'communication-receipt-count) 2)
        (check-equal? (map (lambda (row) (test-ref row 'relation-kind))
                           (test-ref graph 'communication-receipts))
                      '(sibling child-parent))
        (check-equal? (test-ref graph 'communication-channel-receipt-count) 2)
        (check-equal? (map (lambda (row) (test-ref row 'channel-id))
                           (test-ref graph 'communication-channel-receipts))
                      '(channel/build-audit channel/audit-root))
        (check-equal? (test-ref graph 'runtime-executed) #f)
        (check-equal? (test-ref build-audit-channel 'channel-id)
                      'channel/build-audit)
        (check-equal? (test-ref build-audit 'relation-kind) 'sibling)
        (check-equal? (test-ref build-audit 'runtime-executed) #f)
        (check-equal? (length communication-channel-rows) 2)
        (check-equal? (length communication-rows) 2)))))

(run-tests! user-interface-custom-session-agent-graph-test)
