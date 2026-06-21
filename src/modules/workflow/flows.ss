;;; -*- Gerbil -*-
;;; Boundary: public facade for workflow feature flows and Funflow tutorial alignment.
;;; Invariant: alignment reports and workflow builders live in leaf owners.

(import :poo-flow/src/modules/workflow/flows-alignment-specs
        :poo-flow/src/modules/workflow/flows-alignment-report
        :poo-flow/src/modules/workflow/flows-builders)

(export make-docker-store-run-config
        poo-flow-funflow-tutorial-alignment-schema
        poo-flow-funflow-tutorial-alignment-spec-kind
        poo-flow-funflow-tutorial-alignment-report-kind
        poo-flow-funflow-tutorial-alignment-spec
        poo-flow-funflow-tutorial-alignment-spec?
        poo-flow-funflow-tutorial-alignment-report?
        poo-flow-funflow-tutorial-alignment-spec-id
        poo-flow-funflow-tutorial-alignment-spec-status
        poo-flow-funflow-tutorial-alignment-specs
        poo-flow-funflow-tutorial-alignment-report
        make-ccompilation-flow
        make-ccompilation-store-workflow
        make-tensorflow-train-flow
        make-tensorflow-inference-flow
        make-tensorflow-workflow
        make-makefile-tool-parse-flow
        make-makefile-tool-run-flow
        make-makefile-tool-workflow
        make-makefile-tool-runtime-arguments
        make-makefile-tool-runtime-command-descriptor)
