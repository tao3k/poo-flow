;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: stable public facade for declarative and native POO composition.

(import (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition)
        (only-in :poo-flow/src/module-system/profile-composition/identity
                 +poo-flow-composition-identity-kind+
                 poo-flow-official-composition-identity
                 poo-flow-user-composition-identity
                 poo-flow-composition-identity?
                 poo-flow-composition-identity-namespace
                 poo-flow-composition-identity-local-name
                 poo-flow-composition-identity-qualified-name
                 poo-flow-composition-identity-official?)
        (only-in :poo-flow/src/module-system/profile-composition/builders
                 poo-flow-profile-ref
                 poo-flow-scenario-module-binding
                 poo-flow-scenario-clause
                 poo-flow-scenario-stage
                 poo-flow-scenario-case-multiplicity
                 poo-flow-scenario-case-launch-range
                 poo-flow-scenario-case-multiplicities->launch-ranges
                 poo-flow-scenario-case-workload
                 poo-flow-scenario-case-workload/ref)
        (only-in :poo-flow/src/module-system/profile-composition/inline-runtime
                 poo-flow-scenario-inline-profile-ref/default
                 poo-flow-scenario-inline-profile-normalize
                 poo-flow-scenario-inline-apply-hooks
                 poo-flow-scenario-inline-module
                 poo-flow-scenario-inline-profile)
        (only-in :poo-flow/src/module-system/profile-composition/plan-projection
                 poo-flow-scenario-case->execution-plan)
        (only-in :poo-flow/src/module-system/profile-composition/accessors
                 poo-flow-scenario-case-name
                 poo-flow-scenario-case-modules
                 poo-flow-scenario-case-profiles
                 poo-flow-scenario-case-stages
                 poo-flow-scenario-stage-name
                 poo-flow-scenario-stage-clauses)
        (only-in :poo-flow/src/module-system/profile-composition/scenario-case
                 +poo-flow-scenario-case-kind+
                 +poo-flow-scenario-session-kind+
                 +poo-flow-scenario-admission-kind+
                 +poo-flow-scenario-presentation-kind+
                 poo-flow-scenario-case
                 poo-flow-scenario-case?
                 poo-flow-scenario-session
                 poo-flow-scenario-session?
                 poo-flow-scenario-session-state
                 poo-flow-scenario-session-events
                 poo-flow-scenario-session-last-result))

(export use-composition
        +poo-flow-composition-identity-kind+
        poo-flow-official-composition-identity
        poo-flow-user-composition-identity
        poo-flow-composition-identity?
        poo-flow-composition-identity-namespace
        poo-flow-composition-identity-local-name
        poo-flow-composition-identity-qualified-name
        poo-flow-composition-identity-official?
        poo-flow-profile-ref
        poo-flow-scenario-module-binding
        poo-flow-scenario-clause
        poo-flow-scenario-stage
        poo-flow-scenario-case
        poo-flow-scenario-case-multiplicity
        poo-flow-scenario-case-launch-range
        poo-flow-scenario-case-multiplicities->launch-ranges
        poo-flow-scenario-case-workload
        poo-flow-scenario-case-workload/ref
        poo-flow-scenario-inline-profile-ref/default
        poo-flow-scenario-inline-profile-normalize
        poo-flow-scenario-inline-apply-hooks
        poo-flow-scenario-inline-module
        poo-flow-scenario-inline-profile
        poo-flow-scenario-case->execution-plan
        poo-flow-scenario-case-name
        poo-flow-scenario-case-modules
        poo-flow-scenario-case-profiles
        poo-flow-scenario-case-stages
        poo-flow-scenario-stage-name
        poo-flow-scenario-stage-clauses
        +poo-flow-scenario-case-kind+
        +poo-flow-scenario-session-kind+
        +poo-flow-scenario-admission-kind+
        +poo-flow-scenario-presentation-kind+
        poo-flow-scenario-case?
        poo-flow-scenario-session
        poo-flow-scenario-session?
        poo-flow-scenario-session-state
        poo-flow-scenario-session-events
        poo-flow-scenario-session-last-result)
