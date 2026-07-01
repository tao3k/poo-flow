;;; -*- Gerbil -*-
;;; Boundary: downstream session dataflow case.
;;; Invariant: this standalone module declares report-only objects.

(use-module session-core
  :config
  (session-case custom-session-case
    (metadata (source . user-interface)
              (case . openrath-session-first))
    (objects
     (custom-session-root
      (session custom/session-root
        (chunk request user
               "Run the POO Flow package checks and keep receipts.")
        (lineage root)
        (placement agent/nono)
        (metadata (source . user-interface)
                  (case . openrath-session-first))))
     (custom-session-branch
      (session custom/session-branch
        (chunk branch-request user
               "Fork the package-check session for sandbox placement review.")
        (lineage fork custom/session-root)
        (placement agent/nono)
        (metadata (source . user-interface)
                  (case . openrath-session-first)
                  (branch . sandbox-placement))))
     (custom-session-presentation
      (session-graph custom-session-root custom-session-branch)))
    (rows custom-session-root
          custom-session-branch
          custom-session-presentation)))
