;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Scenario: user-interface CrewAI-style composition instance.

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/test check-equal? test-case test-suite)
        (only-in :poo-flow/src/module-system/loader/fragment-syntax load!)
        (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition)
        (only-in :poo-flow/src/module-system/profile-composition/scenario-case
                 poo-flow-scenario-case?)
        :poo-flow/src/module-system/profile-composition/accessors)


(def crewai
  (eval (call-with-input-file "user-interface/profiles/crewai.ss" read)))

(def poo-flow-custom-module-crewai-module crewai)

(load! "../user-interface/cases/crewai")

(def crewai-composition
  poo-flow-custom-module-crewai-case)

(def (stage-clause-payload stage kind)
  (let loop ((clauses (poo-flow-scenario-stage-clauses stage)))
    (cond
     ((null? clauses) (error "missing composition clause" kind))
     ((equal? (.ref (car clauses) 'clause-kind) kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(def (single-stage composition)
  (car (poo-flow-scenario-case-stages composition)))

(def crewai-user-composition-test
 (test-suite "crewai user composition"
  (test-case "crewai declares one reusable production composition"
    (let* ((stage (single-stage crewai-composition))
           (compose-payload
            (poo-flow-scenario-case-profiles crewai-composition))
           (graph-payload (stage-clause-payload stage 'graph))
           (loop-payload (stage-clause-payload stage 'loop))
           (prove-payload (stage-clause-payload stage 'prove))
           (handoff-payload (stage-clause-payload stage 'handoff)))
      (check-equal? (poo-flow-scenario-case? crewai-composition) #t)
      (check-equal? (poo-flow-scenario-case-name crewai-composition) 'crewai)
      (check-equal? (length (poo-flow-scenario-case-modules
                             crewai-composition))
                    1)
      (check-equal? (poo-flow-scenario-stage-name stage) 'production)
      (check-equal? (length compose-payload) 14)
      (check-equal? (map (lambda (profile) (.ref profile 'name))
                         compose-payload)
                    '(agent
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
      (check-equal? graph-payload '(crewai-flow-graph))
      (check-equal? (length loop-payload) 4)
      (check-equal? (cadr loop-payload) 6)
      (check-equal? (cadddr loop-payload) 'final-output)
      (check-equal? prove-payload
                    '(agent-tool-scope-contained
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
                      handoff-after-proof-gate))
      (check-equal? handoff-payload '(marlin-control-plane))))))
