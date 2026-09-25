;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: stable public facade for native POO Profile composition.

(import (only-in :poo-flow/src/module-system/profile-composition/binding-syntax
                 use-module user-composition)
        (only-in :poo-flow/src/module-system/profile-composition/profile-bundle
                 +poo-flow-profile-export-kind+
                 +poo-flow-profile-selection-proof-kind+
                 +poo-flow-profile-bundle-kind+
                 +poo-flow-profile-composition-strategy-kind+
                 PooFlowProfileExport
                 PooFlowProfileSelectionProof
                 PooFlowProfileBundle
                 PooFlowStageSpace
                 PooFlowProfileCompositionStrategy
                 profiles
                 compose
                 poo-flow-profile-export
                 poo-flow-module-profiles
                 poo-flow-select-module-profiles
                 poo-flow-profile-bundle
                 poo-flow-profile-bundle?
                 poo-flow-profile-bundle-root
                 PooFlowProfileCompositionConflict?
                 PooFlowProfileCompositionConflict-receipt
                 poo-flow-profile-composition-conflict-presentation)
        (only-in :poo-flow/src/module-system/profile-composition/builders
                 poo-flow-profile-ref
                 poo-flow-scenario-module-binding
                 poo-flow-scenario-profile-binding
                 poo-flow-scenario-case-multiplicity
                 poo-flow-scenario-case-launch-range
                 poo-flow-scenario-case-multiplicities->launch-ranges
                 poo-flow-scenario-case-workload
                 poo-flow-scenario-case-workload/ref)
        (only-in :poo-flow/src/module-system/profile-composition/plan-projection
                 poo-flow-scenario-case->execution-plan)
        (only-in :poo-flow/src/module-system/profile-composition/accessors
                 poo-flow-scenario-case-name
                 poo-flow-scenario-case-modules
                 poo-flow-scenario-case-profiles
                 poo-flow-scenario-case-stages)
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

(export use-module
        user-composition
        +poo-flow-profile-export-kind+
        +poo-flow-profile-selection-proof-kind+
        +poo-flow-profile-bundle-kind+
        +poo-flow-profile-composition-strategy-kind+
        PooFlowProfileExport
        PooFlowProfileSelectionProof
        PooFlowProfileBundle
        PooFlowStageSpace
        PooFlowProfileCompositionStrategy
        PooFlowProfileCompositionConflict?
        PooFlowProfileCompositionConflict-receipt
        poo-flow-profile-composition-conflict-presentation
        profiles
        compose
        poo-flow-profile-export
        poo-flow-module-profiles
        poo-flow-select-module-profiles
        poo-flow-profile-bundle
        poo-flow-profile-bundle?
        poo-flow-profile-bundle-root
        poo-flow-profile-ref
        poo-flow-scenario-module-binding
        poo-flow-scenario-profile-binding
        poo-flow-scenario-case
        poo-flow-scenario-case-multiplicity
        poo-flow-scenario-case-launch-range
        poo-flow-scenario-case-multiplicities->launch-ranges
        poo-flow-scenario-case-workload
        poo-flow-scenario-case-workload/ref
        poo-flow-scenario-case->execution-plan
        poo-flow-scenario-case-name
        poo-flow-scenario-case-modules
        poo-flow-scenario-case-profiles
        poo-flow-scenario-case-stages
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
