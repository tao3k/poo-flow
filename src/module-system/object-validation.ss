;;; -*- Gerbil -*-
;;; Boundary: public facade for module object validation.

(import :poo-flow/src/module-system/object-validation-support/facts
        :poo-flow/src/module-system/object-validation-support/harness
        :poo-flow/src/module-system/object-validation-support/object
        :poo-flow/src/module-system/object-validation-support/summary)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-field-contract-validation-kind
        poo-flow-module-object-validation-source-ref
        poo-flow-module-field-contract-validation-source-ref
        poo-flow-module-object-direct-field-identities
        poo-flow-module-object-resolved-field-identities
        poo-flow-module-object-inheritance-chain
        poo-flow-module-object-field-origin
        poo-flow-module-object-field-origins
        poo-flow-module-object-validation-phases
        poo-flow-module-object-harness-validation
        poo-flow-module-field-contract-validation
        poo-flow-module-field-contract-validation-valid?
        poo-flow-module-field-contract-validation->alist
        poo-flow-module-object-field-contract-validations
        poo-flow-module-object-validation
        poo-flow-module-object-validation?
        poo-flow-module-object-validation-valid?
        poo-flow-module-object-validation-diagnostics
        poo-flow-module-object-validation->alist
        poo-flow-module-objects-validation
        poo-flow-module-objects-validation->alists
        poo-flow-module-objects-validation-summary
        poo-flow-require-module-object-validation!
        poo-flow-require-module-objects-validation!)
