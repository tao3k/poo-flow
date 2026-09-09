#!/usr/bin/env gxi
;;; Example owner: a browser profile remains declarative until a downstream
;;; runtime chooses to realize its staged composition.

(import :poo-flow/src/module-system/profile-composition/interface)

(export browser-profile-composition)

;;; Composition boundary: this example is a pure declarative value; runtime
;;; scheduling and evidence effects remain behind the selected runtime profile.
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
