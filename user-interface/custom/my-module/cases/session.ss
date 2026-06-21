;;; -*- Gerbil -*-
;;; Boundary: downstream session dataflow case.
;;; Invariant: this standalone module declares report-only objects.

(import (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        :poo-flow/src/modules/session/config)

(def custom-session-placement
  (poo-flow-session-placement-resolve
   'agent/nono
   poo-flow-default-sandbox-profiles
   '((source . user-interface)
     (case . openrath-session-first))))

(def custom-session-root
  (poo-flow-session-value
   'custom/session-root
   (list
    (poo-flow-session-chunk
     'request
     'user
     "Run the POO Flow package checks and keep receipts."))
   (poo-flow-session-lineage 'custom/session-root '() 'root)
   custom-session-placement
   '((source . user-interface)
     (case . openrath-session-first))))

(def custom-session-branch
  (poo-flow-session-value
   'custom/session-branch
   (list
    (poo-flow-session-chunk
     'branch-request
     'user
     "Fork the package-check session for sandbox placement review."))
   (poo-flow-session-lineage
    'custom/session-branch
    '(custom/session-root)
    'fork)
   custom-session-placement
   '((source . user-interface)
     (case . openrath-session-first)
     (branch . sandbox-placement))))

(def custom-session-presentation
  (pooFlowSessionGraphPresentation
   (list custom-session-root custom-session-branch)))
