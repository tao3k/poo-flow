;;; -*- Gerbil -*-
;;; Boundary: downstream session communication case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: communication rows are report-only; Scheme does not deliver
;;; messages, mutate sessions, or open runtime channels.

(let* ((parent-child
        (poo-flow-session-communication-receipt
         'custom/project
         'parent-child
         'custom/root-session
         'custom/root-session
         'custom/root-session
         'custom/build-session
         'agent/root
         'agent/build
         'channel/root-build
         'request
         '((summary . "run build checks")
           (artifact-ref . request/current))
         'receipt-only
         '((source . user-interface)
           (case . session-communication)
           (communication-ledger-ref . runtime/custom-communication-ledger)
           (durable-policy-ref . durable/custom-project))))
       (child-parent
        (poo-flow-session-communication-receipt
         'custom/project
         'child-parent
         'custom/root-session
         'custom/root-session
         'custom/build-session
         'custom/root-session
         'agent/build
         'agent/root
         'channel/build-root
         'result
         '((summary . "build checks completed")
           (receipt-ref . receipt/build-result))
         'receipt-only
         '((source . user-interface)
           (case . session-communication)
           (communication-ledger-ref . runtime/custom-communication-ledger)
           (durable-policy-ref . durable/custom-project))))
       (sibling
        (poo-flow-session-communication-receipt
         'custom/project
         'sibling
         'custom/root-session
         'custom/root-session
         'custom/build-session
         'custom/audit-session
         'agent/build
         'agent/audit
         'channel/build-audit
         'artifact
         '((artifact . build-report)
           (visibility . declared-channel))
         'declared-channel-only
         '((source . user-interface)
           (case . session-communication)
           (communication-ledger-ref . runtime/custom-communication-ledger)
           (durable-policy-ref . durable/custom-project))))
       (cross-root
        (poo-flow-session-communication-receipt
         'custom/project
         'cross-root
         'custom/root-session
         'custom/release-root
         'custom/audit-session
         'custom/release-session
         'agent/audit
         'agent/release
         'channel/audit-release
         'receipt
         '((receipt . release-gate)
           (approval . pending))
         'explicit-project-root
         '((source . user-interface)
           (case . session-communication)
           (communication-ledger-ref . runtime/custom-communication-ledger)
           (durable-policy-ref . durable/custom-project)))))
  (poo-flow-session-communication-receipts->alists
   (list parent-child child-parent sibling cross-root)))
