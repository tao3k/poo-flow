;;; -*- Gerbil -*-
;;; Boundary: downstream loop-engine case loaded by custom/my-module/config.ss.
;;; Invariant: pure use-module declaration; runtime work stays in Marlin.

;;; This case configures one concrete loop handoff story: an agent proposes a
;;; CI/CD repair, peer agents judge it, and a human node reviews release risk.
;; : [PooUserModuleSelection]
(use-module loop-engine
  (+use-case
   current-system-build-loop
   (level . l2)
   (mode . guarded-handoff)
   (workflow . funflow-cicd))
  (+governor +strategy +policy +collision-check)
  (+agent-judges
   (auditor ci-audit-agent)
   (verifier build-verifier-agent)
   (governor ci-loop-governor))
  (+human-audit +manual-gate +changes-requested)
  (+schedule (trigger . manual) (cadence . on-demand))
  (+state (store . file) (path . "loop-state/current-system-build.org"))
  (+sandbox (profile . ci/build) (isolation . project-copy))
  (+budget (max-actionable . 1) (max-attempts . 1))
  (+result
   (default . poo-flow.loop-governor.node-result.v1)
   (auditor . poo-flow.loop-governor.audit-result.v1)
   (verifier . poo-flow.loop-governor.review-result.v1)
   (governor . poo-flow.loop-governor.governor-result.v1)
   (human-audit . poo-flow.loop-governor.human-audit-decision.v1)
   (format . structured-alist)
   (required-fields decision summary evidence))
  (+observability (receipt . l2-guarded-handoff))
  (+runtime +manifest-handoff))
