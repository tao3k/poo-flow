(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/profile-composition)

(load "user-interface/profiles/crewai.ss")

(def poo-flow-custom-module-crewai-module
  (.o (agent (.o (name 'crewai-agent)))
      (task (.o (name 'crewai-task)))
      (crew (.o (name 'crewai-crew)))
      (sequential-process (.o (name 'crewai-sequential-process)))
      (flow-state (.o (name 'crewai-flow-state)))
      (flow-router (.o (name 'crewai-flow-router)))
      (flow-persist (.o (name 'crewai-flow-persist)))
      (guardrail (.o (name 'crewai-guardrail)))
      (human-input (.o (name 'crewai-human-input)))
      (observability (.o (name 'crewai-observability)))
      (runtime-handoff (.o (name 'crewai-runtime-handoff)))))

(def crewai-composition-fragment
  (load "user-interface/cases/crewai-research-flow.ss"))

(unless poo-flow-custom-module-crewai-module
  (error "CrewAI profile fragment did not load"))

(unless crewai-composition-fragment
  (error "CrewAI composition fragment did not load"))

(void)
