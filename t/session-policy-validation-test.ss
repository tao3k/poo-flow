;;; -*- Gerbil -*-
;;; Boundary: effective multi-agent session policy validation.
;;; Invariant: validation inspects composed POO policies and bounded attempts;
;;; it does not run tools, hooks, providers, sandboxes, or communication.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/modules/session/config
        :poo-flow/src/modules/tool-core/config)

(export session-policy-validation-test)

;; : (-> Alist Symbol MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> [Alist] [Symbol])
(def (diagnostic-codes diagnostics)
  (map (lambda (diagnostic)
         (test-ref diagnostic 'code))
       diagnostics))

;; : (-> Symbol [Symbol] Boolean)
(def (has-code? code codes)
  (if (member code codes) #t #f))

;; : (-> Alist)
(def (make-session-policy-validation-context)
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
           'policy/build-model
           'session/build
           'marlin/provider
           'marlin/model/build-review
           '(tool-calling structured-output)
           'budget/build))
         (prompt-policy
          (poo-flow-session-prompt-policy
           'policy/build-prompt
           'session/build
           'session/build-system
           '(system build-contract)
           'parent-summary-only))
         (context-policy
          (poo-flow-session-context-policy
           'policy/build-context
           'session/build
           'parent-summary
           '(session/root)))
         (history-policy
          (poo-flow-session-history-policy
           'policy/build-history
           'session/build
           'bounded
           '(record/last-failure)))
         (communication-policy
          (poo-flow-session-communication-policy
           'policy/build-communication
           'session/build
           '(channel/build-root)
           '(session/root)))
         (sharing-policy
          (poo-flow-session-resource-sharing-policy
           'policy/build-sharing
           'session/build
           '((project-workspace
              (access . read))
             (build-cache
              (access . read-write)
              (accounting . session/build)))
           'deny))
         (resource-policy
          (poo-flow-session-resource-policy
           'policy/build-resource
           'session/build
           '(budget/build)
           '(project-workspace build-cache)
           'session/build))
         (agent-tool-policy
          (poo-flow-session-tool-permission-policy
           'policy/build-agent-tools
           'session/build
           (list read-grant build-grant)
           '(write-workspace-file)
           'deny))
         (hook-tool-policy
          (poo-flow-session-hook-tool-permission-policy
           'policy/build-hook-tools
           'session/build
           '(hook/pre-check)
           (list read-grant)
           'human-approval-on-escalation
           'deny))
         (tool-catalog
          (poo-flow-tool-catalog
           'tool-core/session-policy-test
           (list poo-flow-tool-core-builtin-read-workspace-file)))
         (tool-catalog-validation-row
          (poo-flow-tool-policy-catalog-validation-receipt->alist
           (poo-flow-tool-policy-catalog-validation-receipt
            'validation/session-policy-tool-catalog
            tool-catalog
            agent-tool-policy
            hook-tool-policy)))
         (agent-attempts
          (list
           (poo-flow-session-policy-tool-attempt
            'attempt/agent-read
            'agent-turn
            'read-workspace-file
            'read
            'project-workspace
            'agent/build)
           (poo-flow-session-policy-tool-attempt
            'attempt/agent-build
            'agent-turn
            'run-build-command
            'run
            'build-cache
            'agent/build)
           (poo-flow-session-policy-tool-attempt
            'attempt/agent-write
            'agent-turn
            'write-workspace-file
            'write
            'project-workspace
            'agent/build)))
         (hook-attempts
          (list
           (poo-flow-session-policy-tool-attempt
            'attempt/hook-read
            'hook/pre-check
            'read-workspace-file
            'read
            'project-workspace
            'hook/pre-check)
           (poo-flow-session-policy-tool-attempt
            'attempt/hook-build
            'hook/pre-check
            'run-build-command
            'run
            'build-cache
            'hook/pre-check))))
    (list (cons 'model model-policy)
          (cons 'prompt prompt-policy)
          (cons 'context context-policy)
          (cons 'history history-policy)
          (cons 'communication communication-policy)
          (cons 'sharing sharing-policy)
          (cons 'resource resource-policy)
          (cons 'agent-tool agent-tool-policy)
          (cons 'hook-tool hook-tool-policy)
          (cons 'tool-catalog-validation-row
                tool-catalog-validation-row)
          (cons 'agent-attempts agent-attempts)
          (cons 'hook-attempts hook-attempts))))

;; : TestSuite
(def session-policy-validation-test
  (test-suite "poo-flow session policy validation"
    (test-case "validates effective policy and reports denied session edges"
      (let* ((context (make-session-policy-validation-context))
             (receipt
              (poo-flow-session-policy-validation-receipt
               'validation/build-session
               'session/build
               (test-ref context 'model)
               (test-ref context 'prompt)
               (test-ref context 'context)
               (test-ref context 'history)
               (test-ref context 'communication)
               (test-ref context 'sharing)
               (test-ref context 'resource)
               (test-ref context 'agent-tool)
               (test-ref context 'hook-tool)
               '(session/root session/audit)
               '(record/last-failure record/full-transcript)
               '(channel/build-root channel/build-audit)
               '(project-workspace build-cache network-egress)
               (test-ref context 'agent-attempts)
               (test-ref context 'hook-attempts)
               (list
                (cons 'tool-catalog-validation
                      (test-ref context 'tool-catalog-validation-row)))))
             (diagnostics
              (poo-flow-session-policy-validation-receipt-diagnostics
               receipt))
             (receipt-row
              (poo-flow-session-policy-validation-receipt->alist receipt))
             (codes (diagnostic-codes diagnostics)))
        (check-equal?
         (poo-flow-session-policy-validation-receipt? receipt)
         #t)
        (check-equal?
         (poo-flow-session-policy-validation-receipt-valid? receipt)
         #f)
        (check-equal?
         (poo-flow-session-policy-validation-receipt-effective-model-ref
          receipt)
         'marlin/model/build-review)
        (check-equal?
         (poo-flow-session-policy-validation-receipt-effective-prompt-session-ref
          receipt)
         'session/build-system)
        (check-equal? (test-ref receipt-row 'allowed-context-refs)
                      '(session/root))
        (check-equal? (test-ref receipt-row 'denied-context-refs)
                      '(session/audit))
        (check-equal?
         (test-ref receipt-row 'allowed-communication-channels)
         '(channel/build-root))
        (check-equal? (test-ref receipt-row 'denied-resource-refs)
                      '(network-egress))
        (check-equal? (test-ref receipt-row 'tool-catalog-validation-id)
                      'validation/session-policy-tool-catalog)
        (check-equal? (test-ref receipt-row 'tool-catalog-ref)
                      'tool-core/session-policy-test)
        (check-equal? (test-ref receipt-row 'tool-catalog-valid?) #f)
        (check-equal? (test-ref receipt-row
                                'tool-catalog-resolved-tool-refs)
                      '(read-workspace-file))
        (check-equal? (test-ref receipt-row
                                'tool-catalog-unresolved-tool-refs)
                      '(run-build-command))
        (check-equal?
         (length (test-ref receipt-row 'allowed-agent-tool-attempts))
                      2)
        (check-equal?
         (length (test-ref receipt-row 'denied-agent-tool-attempts))
                      1)
        (check-equal?
         (length (test-ref receipt-row 'allowed-hook-tool-attempts))
                      1)
        (check-equal?
         (length (test-ref receipt-row 'denied-hook-tool-attempts))
                      1)
        (check-equal? (has-code? 'context-session-not-granted codes) #t)
        (check-equal? (has-code? 'history-record-not-granted codes) #t)
        (check-equal? (has-code? 'communication-channel-not-granted codes)
                      #t)
        (check-equal? (has-code? 'resource-capability-not-granted codes)
                      #t)
        (check-equal? (has-code? 'agent-tool-attempt-not-granted codes)
                      #t)
        (check-equal? (has-code? 'hook-tool-attempt-not-granted codes)
                      #t)
        (check-equal?
         (has-code? 'hook-tool-agent-permission-not-inherited codes)
         #t)
        (check-equal?
         (has-code? 'resource-sharing-missing-accounting-owner codes)
         #t)
        (check-equal? (has-code? 'tool-spec-not-in-catalog codes) #t)
        (check-equal? (test-ref receipt-row 'kind)
                      'poo-flow.session.policy-validation-receipt)
        (check-equal? (test-ref receipt-row 'diagnostic-count)
                      (length diagnostics))
        (check-equal? (test-ref receipt-row 'denied-context-refs)
                      '(session/audit))
        (check-equal?
         (poo-flow-session-policy-validation-receipt-runtime-executed?
          receipt)
         #f)))))

(run-tests! session-policy-validation-test)
