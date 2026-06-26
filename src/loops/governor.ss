;;; -*- Gerbil -*-
;;; Boundary: public facade for loop governor core roles and policy projections.
;;; Invariant: scheduling and runtime effects remain outside this module.

(import :poo-flow/src/loops/governor-core
        :poo-flow/src/loops/governor-policy)

(export +loop-governor-schema+
        +loop-governor-node-schema+
        +loop-governor-default-state-key+
        +loop-governor-default-collision-policy+
        +loop-governor-default-aggregate-budget+
        +loop-governor-default-agent-judges+
        +loop-governor-default-human-inbox+
        +loop-governor-default-handoff+
        loop-governor-role
        loop-governor-node-role
        loop-governor-agent-node-role
        loop-governor-human-node-role
        loop-governor-priority-role
        loop-governor-state-role
        loop-governor-budget-role
        loop-governor-collision-role
        loop-governor-agent-judge-role
        loop-governor-inbox-role
        loop-governor-handoff-role
        loop-governor-node-prototype
        make-loop-governor-agent-node
        make-loop-governor-human-node
        loop-governor-prototype
        make-loop-governor
        loop-governor-node?
        loop-governor-node-slot
        loop-governor-node-name
        loop-governor-node-kind
        loop-governor-node-responsibility
        loop-governor-node-human-intervention?
        loop-governor-node-control-owner
        loop-governor-node-execution-owner
        loop-governor-node-metadata
        loop-governor-node->contract
        loop-governor-node-contracts
        loop-governor?
        loop-governor-slot
        loop-governor-name
        loop-governor-strategy
        loop-governor-priority-table
        loop-governor-shared-denylist
        loop-governor-aggregate-budget
        loop-governor-state-key
        loop-governor-collision-policy
        loop-governor-agent-judges
        loop-governor-agent-judge-nodes
        loop-governor-human-inbox
        loop-governor-handoff
        loop-governor-control-owner
        loop-governor-execution-owner
        loop-governor-metadata
        loop-governor-state-field
        loop-governor-budget-limit
        loop-governor-pattern-action-key
        loop-governor-state-action-key
        loop-governor-pattern-denied?
        loop-governor-pattern-conflicted?
        loop-governor-denied-patterns
        loop-governor-conflicting-patterns
        loop-governor-open-patterns
        loop-governor-human-inbox-items
        loop-governor-validation-errors
        validate-loop-governor
        loop-governor->contract/validated
        loop-governor->contract)
