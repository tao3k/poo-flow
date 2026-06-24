;;; -*- Gerbil -*-
;;; Boundary: downstream session transform case.
;;; Invariant: loaded by ../config.ss; it derives session receipts only.

(let* ((custom-session-review-memory
        (poo-flow-session-memory-intent
         'custom/review-memory
         'session/memory
         'project-workspace
         '(repository-summary review-notes)
         'commit-derived-session
         '((source . user-interface)
           (case . session-transform))))
       (custom-session-review-transform
        (poo-flow-session-transform
         'custom-review-agent
         'review
         "Review a custom session and derive a follow-up session."
         '(+provider-handoff +receipt-only +session-derivation)
         '((source . user-interface)
           (case . session-transform))
         (list custom-session-review-memory)))
       (custom-session-transform-root
        (poo-flow-session-value
         'custom/session-transform-root
         (list (poo-flow-session-chunk
                'request
                'user
                "Create a report-only custom session transform receipt."))
         (poo-flow-session-lineage
          'custom/session-transform-root
          '()
          'root)
         (poo-flow-session-default-placement
          'agent/nono
          '((source . user-interface)
            (case . session-transform)))
         '((source . user-interface)
           (case . session-transform))))
       (custom-session-transform-receipt
        (poo-flow-session-transform-apply
         custom-session-review-transform
         custom-session-transform-root
         'custom/session-transform-review
         (list (poo-flow-session-chunk
                'review
                'assistant
                "Review the custom session transform receipt."))
         '((source . user-interface)
           (case . session-transform)
           (stage . review)))))
  (list custom-session-review-memory
        custom-session-review-transform
        custom-session-transform-root
        custom-session-transform-receipt))
