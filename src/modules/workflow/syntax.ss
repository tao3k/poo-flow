;;; -*- Gerbil -*-
;;; Boundary: hygienic authoring macros for workflow module constructors.
;;; Invariant: macros expand to public module constructors, not a separate DSL runtime.

(import :poo-flow/src/modules/custom-task
        :poo-flow/src/modules/docker
        :poo-flow/src/workflow/store
        :poo-flow/src/modules/workflow/flows)

(export defpoo-custom-repeat-flow
        defpoo-docker-flow
        defpoo-store-flow
        defpoo-ccompilation-flow
        defpoo-ccompilation-store-workflow
        defpoo-tensorflow-train-flow
        defpoo-tensorflow-inference-flow
        defpoo-tensorflow-workflow
        defpoo-makefile-tool-parse-flow
        defpoo-makefile-tool-run-flow
        defpoo-makefile-tool-workflow
        defpoo-makefile-tool-runtime-command-descriptor)

;;; Boundary: Tutorial2 repeat authoring stays in the custom-task extension.
;;; The macro only binds a flow name around custom-repeat request data.
;; defpoo-custom-repeat-flow
;;   : (-> Identifier Identifier StringExpr NatExpr ContractExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-custom-repeat-flow` documents the workflow boundary that the
;;       Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-custom-repeat-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-custom-repeat-flow ()
  ((_ binding flow-name text count input-contract output-contract)
   (def binding
     (custom-repeat-flow 'flow-name
                         text
                         count
                         input-contract
                         output-contract))))

;;; Boundary: Docker authoring emits request data only; runtime stays external.
;;; Image pulls, mounts, processes, and artifacts remain adapter-owned.
;; defpoo-docker-flow
;;   : (-> Identifier Identifier ImageExpr CommandExpr ArgsExpr VolumesExpr OutputPolicyExpr ContractExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-docker-flow` documents the workflow boundary that the Gerbil
;;       policy harness treats as agent-facing behavior. The example keeps the
;;       call shape visible without duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-docker-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-docker-flow ()
  ((_ binding flow-name image command args volumes output-policy input-contract output-contract)
   (def binding
     (docker-flow 'flow-name
                  image
                  command
                  args
                  volumes
                  output-policy
                  input-contract
                  output-contract))))

;;; Boundary: Store authoring emits CAS/store request data only.
;;; Cache materialization and artifact persistence remain runtime-owned.
;; defpoo-store-flow
;;   : (-> Identifier Identifier StoreOperation PayloadExpr ContractExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-store-flow` documents the workflow boundary that the Gerbil
;;       policy harness treats as agent-facing behavior. The example keeps the
;;       call shape visible without duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-store-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-store-flow ()
  ((_ binding flow-name operation payload input-contract output-contract)
   (def binding
     (store-flow 'flow-name
                 'operation
                 payload
                 input-contract
                 output-contract))))

;;; Boundary: CCompilation authoring emits the tutorial Docker descriptor only.
;;; Compilation, process handles, and mounted artifacts stay runtime-owned.
;; defpoo-ccompilation-flow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-ccompilation-flow` documents the workflow boundary that the
;;       Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-ccompilation-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-ccompilation-flow ()
  ((_ binding flow-name)
   (def binding
     (make-ccompilation-flow 'flow-name))))

;;; Boundary: the store workflow macro preserves the two-step descriptor shape.
;;; Docker compile and Store manifest semantics remain in their extensions.
;; defpoo-ccompilation-store-workflow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-ccompilation-store-workflow` documents the workflow boundary
;;       that the Gerbil policy harness treats as agent-facing behavior. The
;;       example keeps the call shape visible without duplicating
;;       implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-ccompilation-store-workflow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-ccompilation-store-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-ccompilation-store-workflow 'flow-name))))

;;; Boundary: training flow authoring names the descriptor only.
;;; Model training and filesystem effects stay runtime-owned.
;; defpoo-tensorflow-train-flow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-tensorflow-train-flow` documents the workflow boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-tensorflow-train-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-tensorflow-train-flow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-train-flow 'flow-name))))

;;; Boundary: inference flow authoring names the descriptor only.
;;; Image rendering and model loading stay behind runtime adapters.
;; defpoo-tensorflow-inference-flow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-tensorflow-inference-flow` documents the workflow boundary
;;       that the Gerbil policy harness treats as agent-facing behavior. The
;;       example keeps the call shape visible without duplicating
;;       implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-tensorflow-inference-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-tensorflow-inference-flow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-inference-flow 'flow-name))))

;;; Boundary: Tensorflow workflow authoring composes existing public flows.
;;; It does not add a scheduler or Tensorflow interpreter in Scheme.
;; defpoo-tensorflow-workflow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-tensorflow-workflow` documents the workflow boundary that the
;;       Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-tensorflow-workflow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-tensorflow-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-workflow 'flow-name))))

;;; Boundary: makefile parse authoring emits an external request declaration.
;;; Makefile parsing is still delegated to the runtime owner.
;; defpoo-makefile-tool-parse-flow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-makefile-tool-parse-flow` documents the workflow boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-makefile-tool-parse-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-makefile-tool-parse-flow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-parse-flow 'flow-name))))

;;; Boundary: makefile run authoring emits an external request declaration.
;;; Process execution and output capture stay outside Scheme.
;; defpoo-makefile-tool-run-flow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-makefile-tool-run-flow` documents the workflow boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-makefile-tool-run-flow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-makefile-tool-run-flow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-run-flow 'flow-name))))

;;; Boundary: makefile workflow authoring composes parse then run descriptors.
;;; The macro does not inspect Makefiles or touch the filesystem.
;; defpoo-makefile-tool-workflow
;;   : (-> Identifier Identifier FlowBinding)
;;   | doc m%
;;       `defpoo-makefile-tool-workflow` documents the workflow boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-makefile-tool-workflow ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-makefile-tool-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-workflow 'flow-name))))

;;; Boundary: descriptor macros create inert runtime command descriptors only.
;;; Argument builders and process execution are consumed later by adapters.
;; defpoo-makefile-tool-runtime-command-descriptor
;;   : (-> Identifier Identifier ExecutableExpr RuntimeCommandDescriptorBinding)
;;   | doc m%
;;       `defpoo-makefile-tool-runtime-command-descriptor` documents the
;;       workflow boundary that the Gerbil policy harness treats as agent-
;;       facing behavior. The example keeps the call shape visible without
;;       duplicating implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-makefile-tool-runtime-command-descriptor ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules defpoo-makefile-tool-runtime-command-descriptor ()
  ((_ binding descriptor-name executable)
   (def binding
     (make-makefile-tool-runtime-command-descriptor
      'descriptor-name
      executable)))
  ((_ binding descriptor-name executable options)
   (def binding
     (make-makefile-tool-runtime-command-descriptor
      'descriptor-name
      executable
      options))))
