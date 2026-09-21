;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Reusable Scenario object; root config decides whether to compose it.

(import (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition)
        :poo-flow/user-interface/profiles/crewai)
(export crewai-scenario)

(def crewai-scenario
  (use-composition crewai
  (use-module crewai as crew
    (profiles
      agent
      task
      crew
      planning
      memory
      knowledge
      sequential-process
      flow-state
      flow-router
      flow-persist
      guardrail
      human-input
      observability
      runtime-handoff))
  (compose
    (profiles crew
      agent
      task
      crew
      planning
      memory
      knowledge
      sequential-process
      flow-state
      flow-router
      flow-persist
      guardrail
      human-input
      observability
      runtime-handoff))
  (stage production
    (graph crewai-flow-graph)
    (loop #:fuel 6 #:exit final-output)
    (prove agent-tool-scope-contained
           task-dependencies-closed
           crew-members-declared
           planning-before-task-dispatch
           memory-scope-contained
           knowledge-sources-declared
           task-order-respects-dependencies
           router-targets-declared
           checkpoint-before-resume
           guardrail-before-downstream-task
           human-review-before-final-output
           trace-covers-agent-task-flow
           handoff-after-proof-gate)
    (handoff marlin-control-plane))))
