;;; -*- Gerbil -*-
;;; Scenario: user-interface CrewAI-style composition instance.

(import (only-in :clan/poo/object .ref)
        (only-in :std/test check-equal? run-tests! test-case test-suite)
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/profile-composition-accessors)

(def crewai
  (eval (call-with-input-file "user-interface/profiles/crewai.ss" read)))

(def poo-flow-custom-module-crewai-module crewai)

(load! "../user-interface/cases/crewai")

(def crewai-composition
  poo-flow-custom-module-crewai-case)

(def (stage-clause-payload stage kind)
  (let loop ((clauses (poo-flow-composition-stage-clauses stage)))
    (cond
     ((null? clauses) (error "missing composition clause" kind))
     ((equal? (.ref (car clauses) 'clause-kind) kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(def (single-stage composition)
  (car (poo-flow-composition-stages composition)))

(run-tests!
 (test-suite "crewai user composition"
  (test-case "crewai declares one reusable production composition"
    (let* ((stage (single-stage crewai-composition))
           (compose-payload
            (poo-flow-composition-profiles crewai-composition))
           (graph-payload (stage-clause-payload stage 'graph))
           (loop-payload (stage-clause-payload stage 'loop))
           (prove-payload (stage-clause-payload stage 'prove))
           (handoff-payload (stage-clause-payload stage 'handoff)))
      (check-equal? (poo-flow-composition? crewai-composition) #t)
      (check-equal? (poo-flow-composition-name crewai-composition) 'crewai)
      (check-equal? (length (poo-flow-composition-modules
                             crewai-composition))
                    1)
      (check-equal? (poo-flow-composition-stage-name stage) 'production)
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
