;;; -*- Gerbil -*-
;;; Boundary: downstream loop-engine profile declarations.
;;; Invariant: included by ../config.ss; it declares workflow loop intent only.

(use-module loop-engine
  (+use-cases
   (repo-doctor
    (level . l1)
    (mode . report-only)
    (goal . inspect-profile-and-policy-warnings))
   (pull-request-review
    (level . l2)
    (mode . worktree-review)
    (goal . verify-maker-output-before-handoff))
   (release-approval
    (level . l2+)
    (mode . human-gated)
    (goal . require-human-signoff-before-release)))
  (+governor +strategy +policy +node-graph)
  (+agent-judges
   (auditor repo-audit-agent)
   (verifier repo-verifier-agent)
   (governor repo-governor))
  (+human-audit +approval +rejection +changes-requested)
  (+result
   (default . poo-flow.loop-governor.profile-node-result.v1)
   (auditor . poo-flow.loop-governor.profile-audit-result.v1)
   (verifier . poo-flow.loop-governor.profile-review-result.v1)
   (governor . poo-flow.loop-governor.profile-governor-result.v1)
   (human-audit . poo-flow.loop-governor.profile-human-audit-decision.v1)
   (format . structured-alist)
   (required-fields decision summary evidence action-items))
  (+schedule
   (repo-doctor . manual)
   (pull-request-review . on-pr)
   (release-approval . manual-gate))
  (+state
   (store . file)
   (path . "loop-state/custom-my-module.org")
   (acting-on . project-workspace))
  (+sandbox
   (repo-doctor . agent/task)
   (pull-request-review . agent/task-cache)
   (release-approval . ci/build))
  (+budget
   (max-actionable . 1)
   (max-attempts . 2)
   (weekly-runs . 20))
  (+observability
   (receipt . loop-engine-intent)
   (run-log . "loop-run-log/custom-my-module.org"))
  (+runtime +manifest-handoff +l1-receipts))
