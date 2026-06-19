;;; -*- Gerbil -*-
;;; Boundary: hygienic authoring macros for extension-owned workflow constructors.
;;; Invariant: macros expand to public extension constructors, not a workflow DSL.

(import :extensions/custom-task
        :extensions/docker
        :extensions/store
        :extensions/workflow)

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
;; : (-> Identifier Identifier StringExpr NatExpr ContractExpr ContractExpr FlowBinding)
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
;; : (-> Identifier Identifier ImageExpr CommandExpr ArgsExpr VolumesExpr OutputPolicyExpr ContractExpr ContractExpr FlowBinding)
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
;; : (-> Identifier Identifier StoreOperation PayloadExpr ContractExpr ContractExpr FlowBinding)
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
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-ccompilation-flow ()
  ((_ binding flow-name)
   (def binding
     (make-ccompilation-flow 'flow-name))))

;;; Boundary: the store workflow macro preserves the two-step descriptor shape.
;;; Docker compile and Store manifest semantics remain in their extensions.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-ccompilation-store-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-ccompilation-store-workflow 'flow-name))))

;;; Boundary: training flow authoring names the descriptor only.
;;; Model training and filesystem effects stay runtime-owned.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-tensorflow-train-flow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-train-flow 'flow-name))))

;;; Boundary: inference flow authoring names the descriptor only.
;;; Image rendering and model loading stay behind runtime adapters.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-tensorflow-inference-flow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-inference-flow 'flow-name))))

;;; Boundary: Tensorflow workflow authoring composes existing public flows.
;;; It does not add a scheduler or Tensorflow interpreter in Scheme.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-tensorflow-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-tensorflow-workflow 'flow-name))))

;;; Boundary: makefile parse authoring emits an external request declaration.
;;; Makefile parsing is still delegated to the runtime owner.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-makefile-tool-parse-flow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-parse-flow 'flow-name))))

;;; Boundary: makefile run authoring emits an external request declaration.
;;; Process execution and output capture stay outside Scheme.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-makefile-tool-run-flow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-run-flow 'flow-name))))

;;; Boundary: makefile workflow authoring composes parse then run descriptors.
;;; The macro does not inspect Makefiles or touch the filesystem.
;; : (-> Identifier Identifier FlowBinding)
(defrules defpoo-makefile-tool-workflow ()
  ((_ binding flow-name)
   (def binding
     (make-makefile-tool-workflow 'flow-name))))

;;; Boundary: descriptor macros create inert runtime command descriptors only.
;;; Argument builders and process execution are consumed later by adapters.
;; : (-> Identifier Identifier ExecutableExpr RuntimeCommandDescriptorBinding)
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
