;;; -*- Gerbil -*-
;;; Sandbox profile policy facade.
;;; Keep the public policy API here so downstream modules keep one stable import
;;; path; backend capability construction, backend diagnostics, profile policy
;;; construction, and profile validation are split into owner leaves so policy
;;; repairs stay local to the semantic family that owns the behavior.

(import :poo-flow/src/modules/sandbox-core/profile-support/policy-core
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-capability
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-validation
        :poo-flow/src/modules/sandbox-core/profile-support/policy-profile-core
        :poo-flow/src/modules/sandbox-core/profile-support/policy-profile-validation)

(export poo-flow-sandbox-backend-capability-kind
        poo-flow-sandbox-backend-capability-registry-kind
        poo-flow-sandbox-backend-capability-registry-diagnostic-kind
        poo-flow-sandbox-backend-capability-registry-validation-kind
        poo-flow-sandbox-profile-policy-kind
        poo-flow-sandbox-profile-policy-diagnostic-kind
        poo-flow-sandbox-profile-policy-validation-kind
        poo-flow-sandbox-profile-policy-projection-kind
        poo-flow-sandbox-backend-capability
        poo-flow-sandbox-backend-capability?
        poo-flow-sandbox-backend-capability/backend-kind
        poo-flow-sandbox-backend-capability/capabilities
        poo-flow-sandbox-backend-capability-supports?
        poo-flow-sandbox-backend-capability-registry
        poo-flow-sandbox-backend-capability-registry?
        poo-flow-sandbox-backend-capability-registry-entries
        poo-flow-sandbox-backend-capability-registry-aliases
        poo-flow-sandbox-backend-capability-registry-default
        poo-flow-sandbox-backend-capability-registry-extend
        poo-flow-sandbox-backend-capability-registry-merge
        poo-flow-sandbox-backend-capability-registry-diagnostic
        poo-flow-sandbox-backend-capability-registry-diagnostic?
        poo-flow-sandbox-backend-capability-registry-validation
        poo-flow-sandbox-backend-capability-registries-validation
        poo-flow-sandbox-backend-capability-registry-validation?
        poo-flow-sandbox-backend-capability-registry-validation-valid?
        poo-flow-sandbox-backend-capability-registry-validation-diagnostics
        poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
        poo-flow-sandbox-backend-capability-registry-ref
        poo-flow-sandbox-backend-capability/sandbox
        poo-flow-sandbox-backend-capability/nono
        poo-flow-sandbox-backend-capability/cube
        poo-flow-sandbox-backend-capability/docker
        poo-flow-sandbox-backend-capability-registry/sandbox-core
        poo-flow-sandbox-backend-capability-registry/default
        poo-flow-sandbox-backend-capability-ref
        poo-flow-sandbox-profile-policy
        poo-flow-sandbox-profile-policy?
        poo-flow-sandbox-profile-policy-required-capabilities
        poo-flow-sandbox-profile-policy-resource-policy
        poo-flow-sandbox-profile-policy-durable-policy
        poo-flow-sandbox-profile-policy-durable-policy-ref
        poo-flow-sandbox-profile-policy-sandbox-handle-class
        poo-flow-sandbox-profile-policy/default
        poo-flow-sandbox-profile-policy-diagnostic
        poo-flow-sandbox-profile-policy-diagnostic?
        poo-flow-sandbox-profile-policy-diagnostics
        poo-flow-sandbox-profile-policy-validation
        poo-flow-sandbox-profile-policy-validation-valid?
        poo-flow-sandbox-profile-policy-validation-diagnostics
        poo-flow-sandbox-profile-policy-validation-diagnostic-count
        poo-flow-sandbox-profile-policy-projection-validation
        poo-flow-sandbox-profile-policy-projection-valid?
        poo-flow-sandbox-profile-policy-projection-diagnostics
        poo-flow-sandbox-profile-policy-projection)
