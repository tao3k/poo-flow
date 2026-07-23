#!/usr/bin/env gxi

(import :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/feature-system/bundle-v1-composition-writer)

(export human-capability)

(def human-capability
  (use-composition human-capability
    (use-module human-ai-capability as capability
      (profile access
        :kind interface
        :scope knowledge
        :capabilities (discover retrieve attribute))
      (profile understand
        :kind human-ai
        :scope meaning
        :capabilities (contextualize inspect contest))
      (profile compose
        :kind human-ai
        :scope synthesis
        :capabilities (connect model frame))
      (profile qualify
        :kind authority
        :scope evidence
        :capabilities (verify constrain admit))
      (profile act
        :kind human-authority
        :scope execution
        :capabilities (decide execute pause stop))
      (profile learn
        :kind evidence-return
        :scope outcomes
        :capabilities (record correct reuse compound)))
    (compose
      (profile capability access)
      (profile capability understand)
      (profile capability compose)
      (profile capability qualify)
      (profile capability act)
      (profile capability learn))
    (stage knowledge
      (step access)
      (step understand)
      (step compose)
      (edges (access understand)
             (understand compose)))
    (stage governed-action
      (step qualify)
      (step act)
      (edges (qualify act)))
    (stage evidence-return
      (step learn))
    (stage human-capability-cycle
      (step knowledge)
      (step governed-action)
      (step evidence-return)
      (edges (knowledge governed-action)
             (governed-action evidence-return)))))

(poo-flow-write-composition-bundle-v1/from-environment! human-capability)
