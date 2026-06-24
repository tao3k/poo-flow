;;; -*- Gerbil -*-
;;; Boundary: downstream session dataflow case.
;;; Invariant: this standalone module declares report-only objects.

(import :poo-flow/src/modules/session/config)

(def custom-session-root
  (session custom/session-root
    (chunk request user
           "Run the POO Flow package checks and keep receipts.")
    (lineage root)
    (placement agent/nono)
    (metadata (source . user-interface)
              (case . openrath-session-first))))

(def custom-session-branch
  (session custom/session-branch
    (chunk branch-request user
           "Fork the package-check session for sandbox placement review.")
    (lineage fork custom/session-root)
    (placement agent/nono)
    (metadata (source . user-interface)
              (case . openrath-session-first)
              (branch . sandbox-placement))))

(def custom-session-presentation
  (session-graph custom-session-root custom-session-branch))
