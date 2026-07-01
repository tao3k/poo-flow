;;; -*- Gerbil -*-
;;; Boundary: downstream session policy case loaded by custom/my-module/config.ss.
;;; Invariant: loaded config fragments are expressions; they describe
;;; permissions only and never execute tools, hooks, providers, or sandboxes.

(let* ((custom-durable-default
        (poo-flow-durable-policy
         'durable/custom-project
         'custom/session-root
         '((journal-owner . runtime/fact-log)
           (checkpoint-store . runtime/checkpoint-store)
           (resume-identity . session-id)
           (repair-mode . fail-closed)
           (action-classes . (replayable idempotent compensatable manual))
           (metadata . ((project . custom)
                        (owner . marlin-agent-core))))))
       (custom-session-read-grant
        (poo-flow-session-tool-grant
         'grant/project-read
         'read-workspace-file
         '(read)
         '(project-workspace)
         '(agent-turn hook/pre-check)
         '((scope . session)
           (owner . root-agent))))
       (custom-session-build-grant
        (poo-flow-session-tool-grant
         'grant/project-build
         'run-build-command
         '(run)
         '(project-workspace build-cache)
         '(agent-turn)
         '((scope . child-session)
           (owner . build-agent))))
       (custom-session-main-agent-tool-policy
        (poo-flow-session-tool-permission-policy
         'policy/main-agent-tools
         'custom/session-root
         (list custom-session-read-grant)
         '(write-workspace-file run-build-command)
         'deny
         '((principal . main-agent)
           (sharing . explicit-grants-only))))
       (custom-session-build-agent-tool-policy
        (poo-flow-session-tool-permission-policy
         'policy/build-agent-tools
         'custom/session-build-child
         (list custom-session-read-grant custom-session-build-grant)
         '(write-workspace-file)
         'deny
         '((principal . build-agent)
           (sharing . explicit-grants-only))))
       (custom-session-hook-tool-policy
        (poo-flow-session-hook-tool-permission-policy
         'policy/pre-check-hook-tools
         'custom/session-root
         '(hook/pre-check)
         (list custom-session-read-grant)
         'human-approval-on-escalation
         'deny
         '((principal . hook/pre-check)
           (inherits-agent-tools? . #f))))
       (custom-session-build-tool
        (poo-flow-tool-spec
         'run-build-command
         'builtin-command
         '(run)
         '((argv . list) (cwd . string))
         '((exit-status . integer)
           (stdout-ref . artifact)
           (stderr-ref . artifact))
         "marlin-agent-core"
         'tool/run-build-command
         #t
         'agent/nono
         'marlin-tool-adapter
         '((source . user-interface)
           (case . session-policy))))
       (custom-session-tool-catalog
        (poo-flow-tool-catalog
         'tool-core/custom-session-policy
         (list poo-flow-tool-core-builtin-read-workspace-file
               custom-session-build-tool)
         '((source . user-interface)
           (case . session-policy))))
       (custom-session-tool-catalog-validation-row
        (poo-flow-tool-policy-catalog-validation-receipt->alist
         (poo-flow-tool-policy-catalog-validation-receipt
          'validation/custom-session-tool-catalog
          custom-session-tool-catalog
          custom-session-build-agent-tool-policy
          custom-session-hook-tool-policy
          '((source . user-interface)
            (case . session-policy)))))
       (custom-session-model-policy
        (poo-flow-session-model-policy
         'policy/build-agent-model
         'custom/session-build-child
         'marlin/provider
         'marlin/model/build-review
         '(tool-calling structured-output)
         'budget/build-agent
         '((principal . build-agent))))
       (custom-session-prompt-policy
        (poo-flow-session-prompt-policy
         'policy/build-agent-prompt
         'custom/session-build-child
         'custom/session-build-system
         '(system-instruction build-contract)
         'parent-summary-only
         '((principal . build-agent)
           (sibling-context . denied))))
       (custom-session-context-policy
        (poo-flow-session-context-policy
         'policy/build-agent-context
         'custom/session-build-child
         'parent-summary
         '(custom/session-root)
         '((sibling-context . denied))))
       (custom-session-history-policy
        (poo-flow-session-history-policy
         'policy/build-agent-history
         'custom/session-build-child
         'bounded
         '(record/last-failure)
         '((history . bounded))))
       (custom-session-communication-policy
        (poo-flow-session-communication-policy
         'policy/build-agent-communication
         'custom/session-build-child
         '(channel/build-root)
         '(custom/session-root)
         '((peer-communication . declared-channel-only))))
       (custom-session-sandbox-policy
        (poo-flow-session-sandbox-policy
         'policy/build-agent-sandbox
         'custom/session-build-child
         'sandbox/nono-build
         'parent-profile
         'isolated-filesystem
         '((sandbox . nono)
           (filesystem . project-workspace))))
       (custom-session-sharing-policy
        (poo-flow-session-sharing-policy
         'policy/build-agent-sharing
         'custom/session-build-child
         '(memory/project)
         '(artifact/build-log)
         '(tool-result/test-summary)
         '("build/" "reports/")
         '((sharing . explicit-refs-only))))
       (custom-session-resource-policy
        (poo-flow-session-resource-sharing-policy
         'policy/build-agent-resources
         'custom/session-build-child
         '((project-workspace
            (access . read)
            (accounting . root-session))
           (build-cache
            (access . read-write)
            (accounting . child-session)))
         'deny
         '((sharing . session-id-scoped))))
       (custom-session-capability-policy
        (poo-flow-session-resource-policy
         'policy/build-agent-capabilities
         'custom/session-build-child
         '(budget/build-agent)
         '(project-workspace build-cache)
         'custom/session-build-child
         '((resource . accounted))))
       (custom-session-agent-execution-policy
        (poo-flow-session-policy-attach-durable
         (poo-flow-session-agent-execution-policy
          'policy/build-agent-execution
          'agent/build
          'custom/session-build-child
          'policy/build-agent-model
          'policy/build-agent-prompt
          'policy/build-agent-tools
          'policy/pre-check-hook-tools
          'policy/build-agent-context
          'policy/build-agent-resources
          '((parent-session . custom/session-root)
            (communication . declared-channel-only)))
         custom-durable-default))
       (custom-session-validation
        (poo-flow-session-policy-validation-receipt
         'validation/custom-build
         'custom/session-build-child
         custom-session-model-policy
         custom-session-prompt-policy
         custom-session-context-policy
         custom-session-history-policy
         custom-session-communication-policy
         custom-session-resource-policy
         custom-session-capability-policy
         custom-session-build-agent-tool-policy
         custom-session-hook-tool-policy
         '(custom/session-root custom/audit-session)
         '(record/last-failure record/full-transcript)
         '(channel/build-root channel/build-audit)
         '(project-workspace build-cache network-egress)
         (list
          (poo-flow-session-policy-tool-attempt
           'attempt/custom-build
           'agent-turn
           'run-build-command
           'run
           'build-cache
           'agent/build))
         (list
         (poo-flow-session-policy-tool-attempt
          'attempt/custom-hook-build
          'hook/pre-check
           'run-build-command
           'run
           'build-cache
          'hook/pre-check))
         (list
          (cons 'source 'user-interface)
          (cons 'case 'session-policy)
          (cons 'tool-catalog-validation
                custom-session-tool-catalog-validation-row)))))
  (list (poo-flow-durable-policy-receipt->alist
         (poo-flow-durable-policy->receipt
          custom-durable-default
          '((project-id . custom/project)
            (root-session-id . custom/session-root)
            (session-id . custom/session-build-child)
            (parent-session-id . custom/session-root)
            (loop-run-id . custom/loop-run))))
        (poo-flow-session-policy->alist custom-session-main-agent-tool-policy)
        (poo-flow-session-policy->alist custom-session-build-agent-tool-policy)
        (poo-flow-session-policy->alist custom-session-hook-tool-policy)
        (poo-flow-tool-catalog->alist custom-session-tool-catalog)
        custom-session-tool-catalog-validation-row
        (poo-flow-session-policy->alist custom-session-model-policy)
        (poo-flow-session-policy->alist custom-session-prompt-policy)
        (poo-flow-session-policy->alist custom-session-context-policy)
        (poo-flow-session-policy->alist custom-session-history-policy)
        (poo-flow-session-policy->alist
         custom-session-communication-policy)
        (poo-flow-session-policy->alist custom-session-sandbox-policy)
        (poo-flow-session-policy->alist custom-session-sharing-policy)
        (poo-flow-session-policy->alist custom-session-resource-policy)
        (poo-flow-session-policy->alist custom-session-capability-policy)
        (poo-flow-session-policy->alist
         custom-session-agent-execution-policy)
        (poo-flow-session-policy-validation-receipt->alist
         custom-session-validation)))
