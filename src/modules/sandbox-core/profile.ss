;;; -*- Gerbil -*-
;;; Boundary: public facade for sandbox-core profile POO projection.

(import :poo-flow/src/modules/sandbox-core/profile-support/prototype
        :poo-flow/src/modules/sandbox-core/profile-support/authoring
        :poo-flow/src/modules/sandbox-core/profile-support/derivation
        :poo-flow/src/modules/sandbox-core/profile-support/resolve)

(export (import: :poo-flow/src/modules/sandbox-core/resource-contract)
        poo-flow-sandbox-core-profile-object
        poo-flow-sandbox-profile-object-row-slot
        poo-flow-sandbox-profile-object-row-operator?
        poo-flow-sandbox-profile-object-row-operator
        poo-flow-sandbox-profile-object-row-value
        poo-flow-sandbox-profile-object-authoring-diagnostic
        poo-flow-sandbox-profile-object-row-contains-symbol?
        poo-flow-sandbox-profile-object-runtime-executed-true?
        poo-flow-sandbox-profile-object-row-authoring-diagnostics
        poo-flow-sandbox-profile-object-authoring-diagnostics
        poo-flow-sandbox-profile-prototype
        poo-flow-sandbox-profile-prototype->profile
        poo-flow-sandbox-profile-prototypes
        poo-flow-sandbox-profile-object-profiles
        poo-flow-sandbox-profile-object-profiles/build
        poo-flow-sandbox-profile-object-derive
        poo-flow-sandbox-profile-object-config)
