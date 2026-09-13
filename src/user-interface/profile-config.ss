;;; -*- Gerbil -*-
;;; Boundary: public facade for Doom-style profile config, doctor, and presentation.
;;; Invariant: profile objects, diagnostics, and presentations live in leaf owners.

(import :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/modules/sandbox-core/profile-catalog
        :poo-flow/src/modules/sandbox-core/backend-capability-catalog
        :poo-flow/src/modules/workflow/cicd-config
        :poo-flow/src/user-interface/presentation
        :poo-flow/src/user-interface/profile-core
        :poo-flow/src/user-interface/profile-gate
        :poo-flow/src/user-interface/profile-doctor
        :poo-flow/src/user-interface/profile-presentation)

(export (import: :poo-flow/src/module-system/declaration/interface)
        (import: :poo-flow/src/modules/sandbox-core/profile-catalog)
        (import: :poo-flow/src/modules/sandbox-core/backend-capability-catalog)
        (import: :poo-flow/src/modules/workflow/cicd-config)
        (import: :poo-flow/src/user-interface/presentation)
        poo-flow-user-profile-kind
        poo-flow-user-profile-set-kind
        poo-flow-user-profile-diagnostic-kind
        poo-flow-user-profile-presentation-kind
        poo-flow-user-profile-set-presentation-kind
        poo-flow-user-profile-doctor-report-kind
        poo-flow-user-profile-doctor-presentation-kind
        poo-flow-user-profile-set-doctor-report-kind
        poo-flow-user-profile-set-doctor-presentation-kind
        poo-flow-user-interface-profile-gate-kind
        poo-flow-user-interface-profile-gate-receipt-kind
        poo-flow-user-interface-profile-gate-fact-keys
        poo-flow-user-interface-profile-proof-statuses
        pooFlowUserProfile
        pooFlowUserProfileSet
        pooFlowUserProfileExtend
        poo-flow-user-interface-profile-gate-receipt
        poo-flow-user-interface-profile-gate
        poo-flow-user-interface-profile-gate/receipt
        pooFlowUserInterfaceProfileGateReceipt
        pooFlowUserInterfaceProfileGate
        pooFlowUserInterfaceProfileGateWithReceipt
        pooFlowDefaultUserSettings
        poo-flow-default-user-setting-keys
        pooFlowUserConfigFromProfile
        pooFlowUserProfileDoctor
        pooFlowUserProfileSetDoctor
        pooFlowUserProfilePresentation
        pooFlowUserProfileSetPresentation
        pooFlowUserProfileDoctorPresentation
        pooFlowUserProfileSetDoctorPresentation
        poo-flow-user-profile-doctor-ok?
        poo-flow-user-profile-set-doctor-ok?
        poo-flow-user-profile?
        poo-flow-user-profile-set?
        poo-flow-user-profile-name
        poo-flow-user-profile-set-name
        poo-flow-user-profile-set-default-profile-name
        poo-flow-user-profile-set-profiles
        poo-flow-user-profile-set-profile-names
        poo-flow-user-profile-set-find-profile
        poo-flow-user-profile-set-default-profile
        poo-flow-user-profile-module-bundles
        poo-flow-user-profile-modules
        poo-flow-user-profile-settings
        poo-flow-user-profile-setting-keys
        poo-flow-user-interface-profile-gate?
        poo-flow-user-interface-profile-gate-receipt?
        poo-flow-user-interface-profile-gate-profile-name
        poo-flow-user-interface-profile-gate-accepted?
        poo-flow-user-interface-profile-gate->lean-facts
        poo-flow-user-interface-profile-lean-fact-contract-complete?
        poo-flow-user-profile-diagnostics
        poo-flow-user-profile-set-diagnostics
        poo-flow-user-profile-diagnostic->alist)
