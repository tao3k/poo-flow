;;; -*- Gerbil -*-
;;; Boundary: downstream tool-core case loaded by custom/my-module/config.ss.
;;; Invariant: this declares tool specs and policy validation receipts only;
;;; no shell, filesystem, or MCP runtime is started.

(let* ((selection
        (car
         (use-module tool-core
           :config
           (.def (calculator-tool @ tool-spec
                                  tool-ref tool-kind actions
                                  input-schema output-schema
                                  runtime-owner handoff-operation
                                  sandbox-required? sandbox-profile-ref
                                  runtime-backend metadata)
             tool-ref: 'calculator
             tool-kind: 'custom
             actions: '(calculate)
             input-schema: '((expression . string))
             output-schema: '((result . number))
             runtime-owner: "marlin-agent-core"
             handoff-operation: 'tool/calculator
             |sandbox-required?|: #f
             sandbox-profile-ref: #f
             runtime-backend: 'marlin-tool-adapter
             metadata: '((source . user-interface)
                         (case . tool-core)))
           (.def (custom-tool-catalog @ tool-catalog catalog-ref metadata)
             catalog-ref: 'tool-core/custom
             metadata: '((source . user-interface)
                         (case . tool-core))))))
       (catalog
        (cdr
         (poo-flow-user-module-selection-flag-entry
          selection
          ':tool-catalog)))
       (calculator-grant
        (poo-flow-session-tool-grant
         'grant/calculator
         'calculator
         '(calculate)
         '(session/input)
         '(agent-turn)))
       (calculator-bad-action-grant
        (poo-flow-session-tool-grant
         'grant/calculator-delete
         'calculator
         '(delete)
         '(session/input)
         '(agent-turn)))
       (agent-policy
        (poo-flow-session-tool-permission-policy
         'policy/tool-core-custom-agent
         'custom/session-tool-core
         (list calculator-grant calculator-bad-action-grant)
         '(write-workspace-file)
         'deny))
       (hook-policy
        (poo-flow-session-hook-tool-permission-policy
         'policy/tool-core-custom-hook
         'custom/session-tool-core
         '(hook/pre-check)
         (list calculator-grant)
         'human-approval-on-escalation
         'deny))
       (validation
        (poo-flow-tool-policy-catalog-validation-receipt
         'validation/custom-tool-core
         catalog
         agent-policy
         hook-policy
         '((source . user-interface)
           (case . tool-core)))))
  (list
   (poo-flow-user-module-selection->alist selection)
   (poo-flow-tool-catalog->alist catalog)
   (poo-flow-tool-policy-catalog-validation-receipt->alist validation)))
