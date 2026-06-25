;;; -*- Gerbil -*-
;;; Boundary: public facade for module extension graph operations.

(import :poo-flow/src/module-system/extension-support/data
        :poo-flow/src/module-system/extension-support/merge
        :poo-flow/src/module-system/extension-support/apply)

(export poo-flow-module-extension-node-kind
        poo-flow-module-extension-operation-kind
        poo-flow-module-extension-contribution-kind
        poo-flow-module-extension-result-kind
        poo-flow-module-extension-node
        poo-flow-module-extension-node?
        poo-flow-module-extension-node-identity
        poo-flow-module-extension-node-slots
        poo-flow-module-extension-node-children
        poo-flow-module-extension-child-ref
        poo-flow-module-extension-slot-override
        poo-flow-module-extension-slot-append
        poo-flow-module-extension-slot-prepend
        poo-flow-module-extension-slot-remove
        poo-flow-module-extension-node-extend
        poo-flow-module-extension-node-remove
        poo-flow-module-extension-contribution
        poo-flow-module-extension-contribution?
        poo-flow-module-extension-contribution-target
        poo-flow-module-extension-contribution-operations
        poo-flow-module-extension-apply-contribution
        poo-flow-module-extension-apply-contributions
        poo-flow-module-extension-fixed-point
        poo-flow-module-extension-result
        poo-flow-module-extension-result?
        poo-flow-module-extension-result-root
        poo-flow-module-extension-result-iterations
        poo-flow-module-extension-result-stable?
        poo-flow-module-extension-node-snapshot)
