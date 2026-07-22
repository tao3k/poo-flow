;;; -*- Gerbil -*-
;;; Boundary: stable public facade for declarative and native POO composition.

(import (only-in :poo-flow/src/module-system/profile-composition-use-syntax
                 use-composition)
        (only-in :poo-flow/src/module-system/profile-composition-builders
                 poo-flow-profile-ref
                 poo-flow-composition-module-binding
                 poo-flow-composition-clause
                 poo-flow-composition-stage
                 poo-flow-composition-object
                 poo-flow-composition-object/profiles)
        (only-in :poo-flow/src/module-system/profile-composition-inline-runtime
                 poo-flow-composition-inline-profile-ref/default
                 poo-flow-composition-inline-profile-normalize
                 poo-flow-composition-inline-apply-hooks
                 poo-flow-composition-inline-module
                 poo-flow-composition-inline-profile
                 poo-flow-composition->execution-plan)
        (only-in :poo-flow/src/module-system/profile-composition-accessors
                 poo-flow-composition?
                 poo-flow-composition-name
                 poo-flow-composition-modules
                 poo-flow-composition-profiles
                 poo-flow-composition-stages
                 poo-flow-composition-stage-name
                 poo-flow-composition-stage-clauses))

(export use-composition
        poo-flow-profile-ref
        poo-flow-composition-module-binding
        poo-flow-composition-clause
        poo-flow-composition-stage
        poo-flow-composition-object
        poo-flow-composition-object/profiles
        poo-flow-composition-inline-profile-ref/default
        poo-flow-composition-inline-profile-normalize
        poo-flow-composition-inline-apply-hooks
        poo-flow-composition-inline-module
        poo-flow-composition-inline-profile
        poo-flow-composition->execution-plan
        poo-flow-composition?
        poo-flow-composition-name
        poo-flow-composition-modules
        poo-flow-composition-profiles
        poo-flow-composition-stages
        poo-flow-composition-stage-name
        poo-flow-composition-stage-clauses)
