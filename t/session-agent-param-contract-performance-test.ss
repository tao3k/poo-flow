;;; -*- Gerbil -*-
;;; Boundary: AgentParam contract performance gate.
;;; Invariant: batch AgentParam projection stays bounded and report-only.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        :poo-flow/src/modules/session/config)

(export session-agent-param-contract-performance-test)

;; : String
(def session-agent-param-contract-fixture-path
  "t/scenarios/performance/session-agent-param-contract/benchmark.ss")

;; : Alist
(def session-agent-param-contract-fixture
  (call-with-input-file session-agent-param-contract-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (agent-param-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (agent-param-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] session-agent-param-contract ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> PooSessionAgentNode)
(def (agent-param-performance-node)
  (poo-flow-session-agent-node
   'agent/perf
   'project/agent-param
   'session/root
   'session/root
   'session/perf-system
   'session/root
   'session/perf
   '(session/audit)
   '(channel/perf-audit)
   'policy/perf-model
   'policy/perf-prompt
   'policy/perf-tools
   'policy/perf-hooks
   'policy/perf-resources
   'durable/perf
   '(read-workspace-file run-build-command)
   '(memory/perf)
   'agent/nono
   'builder
   'poo-flow.session.agent.perf-result.v1))

;; : (-> PooSessionPolicyValidationReceipt)
(def (agent-param-performance-validation)
  (let* ((read-grant
          (poo-flow-session-tool-grant
           'grant/read
           'read-workspace-file
           '(read)
           '(project-workspace)
           '(agent-turn hook/pre-check)))
         (model-policy
          (poo-flow-session-model-policy
           'policy/perf-model
           'session/perf
           'marlin/provider
           'marlin/model/perf
           '(tool-calling)
           'budget/perf))
         (prompt-policy
          (poo-flow-session-prompt-policy
           'policy/perf-prompt
           'session/perf
           'session/perf-system
           '(system)
           'parent-summary-only))
         (context-policy
          (poo-flow-session-context-policy
           'policy/perf-context
           'session/perf
           'parent-summary
           '(session/root)))
         (history-policy
          (poo-flow-session-history-policy
           'policy/perf-history
           'session/perf
           'bounded
           '(record/last-failure)))
         (communication-policy
          (poo-flow-session-communication-policy
           'policy/perf-communication
           'session/perf
           '(channel/perf-root)
           '(session/root)))
         (sharing-policy
          (poo-flow-session-resource-sharing-policy
           'policy/perf-sharing
           'session/perf
           '((project-workspace
              (access . read)
              (accounting . session/root)))
           'deny))
         (resource-policy
          (poo-flow-session-resource-policy
           'policy/perf-resource
           'session/perf
           '(budget/perf)
           '(project-workspace)
           'session/perf))
         (agent-tool-policy
          (poo-flow-session-tool-permission-policy
           'policy/perf-tools
           'session/perf
           (list read-grant)
           '(write-workspace-file)
           'deny))
         (hook-tool-policy
          (poo-flow-session-hook-tool-permission-policy
           'policy/perf-hooks
           'session/perf
           '(hook/pre-check)
           (list read-grant)
           'human-approval-on-escalation
           'deny)))
    (poo-flow-session-policy-validation-receipt
     'validation/perf-agent-param
     'session/perf
     model-policy
     prompt-policy
     context-policy
     history-policy
     communication-policy
     sharing-policy
     resource-policy
     agent-tool-policy
     hook-tool-policy
     '(session/root)
     '(record/last-failure)
     '(channel/perf-root)
     '(project-workspace)
     (list
      (poo-flow-session-policy-tool-attempt
       'attempt/perf-read
       'agent-turn
       'read-workspace-file
       'read
       'project-workspace
       'agent/perf))
     (list
      (poo-flow-session-policy-tool-attempt
       'attempt/perf-hook-read
       'hook/pre-check
       'read-workspace-file
       'read
       'project-workspace
       'hook/pre-check)))))

;; : (-> Integer Symbol)
(def (agent-param-performance-contract-id index)
  (string->symbol
   (string-append "agent-param/perf-" (number->string index))))

;; : (-> PooSessionAgentNode PooSessionPolicyValidationReceipt Integer PooSessionAgentParamContract)
(def (agent-param-performance-contract node validation index)
  (poo-flow-session-agent-param-contract
   (agent-param-performance-contract-id index)
   node
   validation
   'marlin/provider
   'streaming-disabled
   'events-receipt-only))

;; : (-> PooSessionAgentNode PooSessionPolicyValidationReceipt Integer Alist)
(def (agent-param-performance-summary node validation count)
  (let* ((contracts
          (poo-flow-performance-build-list
           count
           (lambda (index)
             (agent-param-performance-contract node validation index))))
         (rows
          (poo-flow-session-agent-param-contracts->alists contracts)))
    (list (cons 'contract-count (length rows))
          (cons 'first-agent
                (agent-param-performance-ref (car rows) 'agent-id))
          (cons 'last-contract
                (agent-param-performance-ref
                 (list-ref rows (- count 1))
                 'contract-id))
          (cons 'runtime-executed
                (agent-param-performance-ref
                 (car rows)
                 'runtime-executed)))))

;; : TestSuite
(def session-agent-param-contract-performance-test
  (test-suite "session AgentParam contract performance"
    (test-case "keeps AgentParam contract batch projection inside benchmark contract"
      (let* ((contract-count 200)
             (node (agent-param-performance-node))
             (validation (agent-param-performance-validation))
             (summary
              (agent-param-performance-summary node validation contract-count))
             (receipt
              (benchmark-run
               session-agent-param-contract-fixture
               (lambda ()
                 (agent-param-performance-summary
                  node
                  validation
                  contract-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? session-agent-param-contract-fixture)
         #t)
        (check-equal? (agent-param-performance-ref summary 'contract-count)
                      contract-count)
        (check-equal? (agent-param-performance-ref summary 'first-agent)
                      'agent/perf)
        (check-equal? (agent-param-performance-ref summary 'last-contract)
                      'agent-param/perf-199)
        (check-equal? (agent-param-performance-ref summary 'runtime-executed)
                      #f)
        (agent-param-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
