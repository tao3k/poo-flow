;;; -*- Gerbil -*-
;;; Boundary: session policy validation performance gate for multi-agent rows.
;;; Invariant: POO policy authoring projects to bounded validation receipts
;;; without executing tools, hooks, providers, sandboxes, or communication.

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

(export session-policy-validation-performance-test)

;; : String
(def session-policy-validation-fixture-path
  "t/scenarios/performance/session-policy-validation/benchmark.ss")

;; : Alist
(def session-policy-validation-fixture
  (call-with-input-file session-policy-validation-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (session-policy-validation-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (session-policy-validation-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] session-policy-validation ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> Integer Symbol)
(def (session-policy-validation-performance-id prefix index)
  (string->symbol
   (string-append prefix "/" (number->string index))))

;; : (-> Integer PooSessionToolAttempt)
(def (session-policy-validation-performance-agent-attempt index)
  (let (tool-ref (if (= (modulo index 3) 0)
                   'write-workspace-file
                   'run-build-command))
    (poo-flow-session-policy-tool-attempt
     (session-policy-validation-performance-id "attempt/agent" index)
     'agent-turn
     tool-ref
     (if (eq? tool-ref 'write-workspace-file) 'write 'run)
     'project-workspace
     'agent/build)))

;; : (-> Integer PooSessionToolAttempt)
(def (session-policy-validation-performance-hook-attempt index)
  (let (tool-ref (if (= (modulo index 2) 0)
                   'read-workspace-file
                   'run-build-command))
    (poo-flow-session-policy-tool-attempt
     (session-policy-validation-performance-id "attempt/hook" index)
     'hook/pre-check
     tool-ref
     (if (eq? tool-ref 'read-workspace-file) 'read 'run)
     'project-workspace
     'hook/pre-check)))

;; : (-> Alist)
(def (session-policy-validation-performance-context)
  (let* ((read-grant
          (poo-flow-session-tool-grant
           'grant/read
           'read-workspace-file
           '(read)
           '(project-workspace)
           '(agent-turn hook/pre-check)))
         (build-grant
          (poo-flow-session-tool-grant
           'grant/build
           'run-build-command
           '(run)
           '(project-workspace build-cache)
           '(agent-turn)))
         (model-policy
          (poo-flow-session-model-policy
           'policy/perf-model
           'session/perf-build
           'marlin/provider
           'marlin/model/build-review
           '(tool-calling structured-output)
           'budget/build))
         (prompt-policy
          (poo-flow-session-prompt-policy
           'policy/perf-prompt
           'session/perf-build
           'session/perf-system
           '(system build-contract)
           'parent-summary-only))
         (context-policy
          (poo-flow-session-context-policy
           'policy/perf-context
           'session/perf-build
           'parent-summary
           '(session/root)))
         (history-policy
          (poo-flow-session-history-policy
           'policy/perf-history
           'session/perf-build
           'bounded
           '(record/last-failure)))
         (communication-policy
          (poo-flow-session-communication-policy
           'policy/perf-communication
           'session/perf-build
           '(channel/build-root)
           '(session/root)))
         (sharing-policy
          (poo-flow-session-resource-sharing-policy
           'policy/perf-sharing
           'session/perf-build
           '((project-workspace
              (access . read)
              (accounting . session/root))
             (build-cache
              (access . read-write)
              (accounting . session/perf-build)))
           'deny))
         (resource-policy
          (poo-flow-session-resource-policy
           'policy/perf-resource
           'session/perf-build
           '(budget/build)
           '(project-workspace build-cache)
           'session/perf-build))
         (agent-tool-policy
          (poo-flow-session-tool-permission-policy
           'policy/perf-agent-tools
           'session/perf-build
           (list read-grant build-grant)
           '(write-workspace-file)
           'deny))
         (hook-tool-policy
          (poo-flow-session-hook-tool-permission-policy
           'policy/perf-hook-tools
           'session/perf-build
           '(hook/pre-check)
           (list read-grant)
           'human-approval-on-escalation
           'deny)))
    (list (cons 'model model-policy)
          (cons 'prompt prompt-policy)
          (cons 'context context-policy)
          (cons 'history history-policy)
          (cons 'communication communication-policy)
          (cons 'sharing sharing-policy)
          (cons 'resource resource-policy)
          (cons 'agent-tool agent-tool-policy)
          (cons 'hook-tool hook-tool-policy))))

;; : (-> Alist Integer Alist)
(def (session-policy-validation-performance-summary context attempt-count)
  (let* ((agent-attempts
          (poo-flow-performance-build-list
           attempt-count
           session-policy-validation-performance-agent-attempt))
         (hook-attempts
          (poo-flow-performance-build-list
           attempt-count
           session-policy-validation-performance-hook-attempt))
         (receipt
          (poo-flow-session-policy-validation-receipt
           'validation/perf-build
           'session/perf-build
           (session-policy-validation-performance-ref context 'model)
           (session-policy-validation-performance-ref context 'prompt)
           (session-policy-validation-performance-ref context 'context)
           (session-policy-validation-performance-ref context 'history)
           (session-policy-validation-performance-ref context 'communication)
           (session-policy-validation-performance-ref context 'sharing)
           (session-policy-validation-performance-ref context 'resource)
           (session-policy-validation-performance-ref context 'agent-tool)
           (session-policy-validation-performance-ref context 'hook-tool)
           '(session/root session/audit)
           '(record/last-failure record/full-transcript)
           '(channel/build-root channel/build-audit)
           '(project-workspace build-cache network-egress)
           agent-attempts
           hook-attempts)))
    (list (cons 'valid? (.ref receipt 'valid?))
          (cons 'agent-attempt-count (length agent-attempts))
          (cons 'hook-attempt-count (length hook-attempts))
          (cons 'allowed-agent-count
                (length (.ref receipt 'allowed-agent-tool-attempts)))
          (cons 'denied-agent-count
                (length (.ref receipt 'denied-agent-tool-attempts)))
          (cons 'allowed-hook-count
                (length (.ref receipt 'allowed-hook-tool-attempts)))
          (cons 'denied-hook-count
                (length (.ref receipt 'denied-hook-tool-attempts)))
          (cons 'diagnostic-count (.ref receipt 'diagnostic-count))
          (cons 'runtime-executed (.ref receipt 'runtime-executed)))))

;; : TestSuite
(def session-policy-validation-performance-test
  (test-suite "session policy validation performance"
    (test-case "keeps multi-agent policy validation inside benchmark contract"
      (let* ((attempt-count 240)
             (context (session-policy-validation-performance-context))
             (summary
              (session-policy-validation-performance-summary
               context
               attempt-count))
             (receipt
              (benchmark-run
               session-policy-validation-fixture
               (lambda ()
                 (session-policy-validation-performance-summary
                  context
                  attempt-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? session-policy-validation-fixture)
         #t)
        (check-equal?
         (session-policy-validation-performance-ref summary 'valid?)
         #f)
        (check-equal?
         (session-policy-validation-performance-ref summary
                                                    'agent-attempt-count)
         attempt-count)
        (check-equal?
         (session-policy-validation-performance-ref summary
                                                    'hook-attempt-count)
         attempt-count)
        (check-equal?
         (session-policy-validation-performance-ref summary
                                                    'denied-agent-count)
         80)
        (check-equal?
         (session-policy-validation-performance-ref summary
                                                    'denied-hook-count)
         120)
        (check-equal?
         (session-policy-validation-performance-ref summary
                                                    'runtime-executed)
         #f)
        (session-policy-validation-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
