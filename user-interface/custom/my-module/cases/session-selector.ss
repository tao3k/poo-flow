;;; -*- Gerbil -*-
;;; Boundary: downstream selector receipt case loaded by custom/my-module/config.ss.
;;; Invariant: selector declarations stay pending receipts; Marlin owns model
;;; scoring, workflow dispatch, and selected-result materialization.

(let* ((build-candidate
        (poo-flow-session-selector-candidate
         'candidate/build
         'transform
         'transform/build-agent
         "Run the build sub-agent transform."
         '(derived-session handoff-intent)
         '((source . user-interface)
           (case . session-selector))))
       (audit-candidate
        (poo-flow-session-selector-candidate
         'candidate/audit
         'workflow
         'workflow/audit-build
         "Audit build output and diagnostics."
         '(runtime-handoff diagnostics)
         '((source . user-interface)
           (case . session-selector))))
       (governor-candidate
        (poo-flow-session-selector-candidate
         'candidate/governor
         'agent-param
         'agent-param/custom-build
         "Ask the policy governor to decide whether the branch is safe."
         '(validation-valid? validation-diagnostic-count)
         '((source . user-interface)
           (case . session-selector))))
       (selector-receipt
        (poo-flow-session-selector-receipt
         'selector/custom-router
         'custom/project
         'custom/root-session
         'custom/root-session
         (list build-candidate audit-candidate governor-candidate)
         '((strategy . llm-router)
           (judge-inputs . (parent-summary last-failure build-report))
           (result-contract . workflow-or-transform-ref))
         'empty-workflow
         '((source . user-interface)
           (case . session-selector)))))
  (poo-flow-session-selector-receipt->alist selector-receipt))
