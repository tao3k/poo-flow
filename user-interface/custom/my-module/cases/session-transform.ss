;;; -*- Gerbil -*-
;;; Boundary: downstream session transform case.
;;; Invariant: loaded by ../config.ss; it derives session receipts only.

(use-module session-core
  :rows
  (let* ((custom-session-review-memory
          (session-memory-intent custom/review-memory
            (store session/memory)
            (scope project-workspace)
            (recall repository-summary review-notes)
            (commit commit-derived-session)
            (metadata (source . user-interface)
                      (case . session-transform))))
         (custom-session-review-transform
          (session-transform custom-review-agent
            (intent review)
            (description "Review a custom session and derive a follow-up session.")
            (capabilities +provider-handoff +receipt-only +session-derivation)
            (memory-intents custom-session-review-memory)
            (metadata (source . user-interface)
                      (case . session-transform))))
         (custom-session-transform-root
          (session custom/session-transform-root
            (chunk request user
                   "Create a report-only custom session transform receipt.")
            (lineage root)
            (placement agent/nono)
            (metadata (source . user-interface)
                      (case . session-transform))))
         (custom-session-transform-receipt
          (transform-session custom-session-review-transform
                             custom-session-transform-root
                             custom/session-transform-review
            (chunk review assistant
                   "Review the custom session transform receipt.")
            (metadata (source . user-interface)
                      (case . session-transform)
                      (stage . review)))))
    (list custom-session-review-memory
          custom-session-review-transform
          custom-session-transform-root
          custom-session-transform-receipt))
  :metadata
  '((source . user-interface)
    (case . session-transform)))
