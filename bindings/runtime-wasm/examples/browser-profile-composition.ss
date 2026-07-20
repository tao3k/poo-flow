#!/usr/bin/env gxi

(import :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/composition-typescript)

(export browser-profile-composition)

(def browser-profile-composition
  (use-composition browser-profile-composition
    (use-module agentic-research as research
    (profile researcher
      :kind agent
      :scope research
      :capabilities (discover synthesize))
    (profile evidence-curator
      :kind agent
      :scope evidence
      :capabilities (qualify trace))
    (profile runtime
      :kind runtime
      :scope execution
      :capabilities (schedule observe)))
  (compose
    (profile research researcher)
    (profile research evidence-curator)
    (profile research runtime))
  (stage research-case
    (step researcher)
    (step evidence-curator)
    (edges (researcher evidence-curator)))
  (stage qualification-case
    (step evidence-curator)
    (prove admissible-evidence))
    (stage real-scenario
      (step research-case)
      (step qualification-case)
      (handoff runtime))))

(composition->typescript-file!
 browser-profile-composition
 "generated/browser-profile-composition.generated.ts")
