;;; -*- Gerbil -*-
;;; CI/CD runtime handoff facade.
;;; Downstream policy families import this module as the stable runtime surface,
;;; while checks, graph analysis, pipeline projection, and Marlin ABI assembly
;;; stay in separate owner leaves to keep policy repair local to the branch that
;;; owns the behavior.

(import :poo-flow/src/modules/workflow/cicd-runtime/checks
        :poo-flow/src/modules/workflow/cicd-runtime/graph
        :poo-flow/src/modules/workflow/cicd-runtime/pipeline
        :poo-flow/src/modules/workflow/cicd-runtime/marlin-abi)

(export (import: :poo-flow/src/modules/workflow/cicd-runtime/checks)
        (import: :poo-flow/src/modules/workflow/cicd-runtime/graph)
        (import: :poo-flow/src/modules/workflow/cicd-runtime/pipeline)
        (import: :poo-flow/src/modules/workflow/cicd-runtime/marlin-abi))
