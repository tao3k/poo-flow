;;; -*- Gerbil -*-
;;; Boundary: custom user-interface AgentParam scenario.
;;; Invariant: AgentParam rows bind topology to effective policy validation
;;; without opening providers, tools, memory stores, streams, or sandboxes.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-agent-param-test)

(load! "../user-interface/custom/my-module/cases/session-agent-param")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-session-agent-param-test
  (test-suite "poo-flow custom user-interface session-agent-param case"
    (test-case "projects custom AgentParam contract without runtime work"
      (let (row poo-flow-custom-module-session-agent-param-case)
        (check-equal? (test-ref row 'kind)
                      'poo-flow.session.agent-param-contract)
        (check-equal? (test-ref row 'contract-id)
                      'agent-param/custom-build)
        (check-equal? (test-ref row 'agent-id) 'agent/build)
        (check-equal? (test-ref row 'provider-ref) 'marlin/provider)
        (check-equal? (test-ref row 'effective-model-ref)
                      'marlin/model/build-review)
        (check-equal? (test-ref row 'validation-valid?) #t)
        (check-equal? (test-ref row 'validation-diagnostic-count) 0)
        (check-equal? (test-ref row 'tool-refs)
                      '(read-workspace-file run-build-command))
        (check-equal? (test-ref row 'memory-refs) '(session/memory))
        (check-equal? (test-ref row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-agent-param-test)
