;;; -*- Gerbil -*-
;;; Boundary: hygienic authoring macros for the functional flow kernel.
;;; Invariant: macros expand to public flow/plan combinators, not a workflow DSL.

(import :poo-flow/src/core/flow
        :poo-flow/src/core/plan)

(export defpoo-flow-arr
        defpoo-flow-identity
        defpoo-flow-compose
        defpoo-flow-map
        defpoo-flow-bind
        defpoo-flow-kleisli
        defpoo-flow-fanout
        defpoo-flow-dag
        defpoo-flow-dag-artifacts
        defpoo-flow-try
        defpoo-flow-first
        defpoo-flow-second)

;; defpoo-flow-arr
;;   : (-> Identifier Identifier ProcedureExpr ContractExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-arr` defines a pure arrow flow with an identifier-owned
;;       flow name while leaving the procedure and contracts as caller
;;       expressions.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-arr parse-flow parse-request parse request-contract result-contract)
;;       ;; => flow binding
;;       ```
;;     %
(defrules defpoo-flow-arr ()
  ((_ binding flow-name proc input-contract output-contract)
   (def binding
     (flow-arr 'flow-name proc input-contract output-contract))))

;; defpoo-flow-identity
;;   : (-> Identifier Identifier ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-identity` defines a category identity flow for one
;;       contract boundary.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-identity id-flow identity request-contract)
;;       ;; => identity flow binding
;;       ```
;;     %
(defrules defpoo-flow-identity ()
  ((_ binding flow-name contract)
   (def binding
     (flow-identity 'flow-name contract))))

;; defpoo-flow-compose
;;   : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-compose` defines sequential composition over already-built
;;       flows.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-compose checked-flow checked parse-flow validate-flow)
;;       ;; => composed flow binding
;;       ```
;;     %
(defrules defpoo-flow-compose ()
  ((_ binding flow-name left right)
   (def binding
     (flow-then 'flow-name left right))))

;; defpoo-flow-map
;;   : (-> Identifier Identifier FlowExpr ProcedureExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-map` defines a functional output map over an existing
;;       flow.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-map rendered render checked-flow render-result output-contract)
;;       ;; => mapped flow binding
;;       ```
;;     %
(defrules defpoo-flow-map ()
  ((_ binding flow-name source proc output-contract)
   (def binding
     (flow-map 'flow-name source proc output-contract))))

;; defpoo-flow-bind
;;   : (-> Identifier Identifier FlowExpr ProcedureExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-bind` defines a Kleisli bind where the binder returns the
;;       next flow.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-bind routed route source-flow choose-flow output-contract)
;;       ;; => bound flow binding
;;       ```
;;     %
(defrules defpoo-flow-bind ()
  ((_ binding flow-name source binder output-contract)
   (def binding
     (flow-bind 'flow-name source binder output-contract))))

;; defpoo-flow-kleisli
;;   : (-> Identifier Identifier FlowExpr ProcedureExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-kleisli` is the authoring-layer alias for the Kleisli bind
;;       form.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-kleisli routed route source-flow choose-flow output-contract)
;;       ;; => bound flow binding
;;       ```
;;     %
(defrules defpoo-flow-kleisli ()
  ((_ binding flow-name source binder output-contract)
   (def binding
     (flow-kleisli 'flow-name source binder output-contract))))

;; defpoo-flow-fanout
;;   : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-fanout` defines Arrow-style fanout without selecting a
;;       scheduler.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-fanout split-flow split left-flow right-flow)
;;       ;; => fanout flow binding
;;       ```
;;     %
(defrules defpoo-flow-fanout ()
  ((_ binding flow-name left right)
   (def binding
     (flow-fanout 'flow-name left right))))

;; defpoo-flow-dag
;;   : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-dag` defines a functional DAG flow as Arrow fanout while
;;       keeping receipt and manifest projection separate.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-dag dag-flow dag left-flow right-flow)
;;       ;; => dag flow binding
;;       ```
;;     %
(defrules defpoo-flow-dag ()
  ((_ binding flow-name left right)
   (def binding
     (flow-fanout 'flow-name left right))))

;; defpoo-flow-dag-artifacts
;;   : (-> Identifier Identifier FlowExpr RequestIdExpr DagArtifactBindings)
;;   | doc m%
;;       `defpoo-flow-dag-artifacts` defines report-only DAG artifacts for an
;;       existing flow binding without executing runtime work.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-dag-artifacts receipt manifest dag-flow request-id)
;;       ;; => artifact bindings
;;       ```
;;     %
(defrules defpoo-flow-dag-artifacts ()
  ((_ receipt-binding manifest-binding source request-id)
   (begin
     (def receipt-binding
       (flow->dag-receipt source))
     (def manifest-binding
       (flow->dag-runtime-manifest source request-id)))))

;; defpoo-flow-try
;;   : (-> Identifier Identifier FlowExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-try` defines a Funflow-style try boundary over an existing
;;       flow.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-try guarded-flow guarded source-flow)
;;       ;; => try flow binding
;;       ```
;;     %
(defrules defpoo-flow-try ()
  ((_ binding flow-name source)
   (def binding
     (try-flow 'flow-name source))))

;; defpoo-flow-first
;;   : (-> Identifier Identifier FlowExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-first` defines Arrow `first` over a pair-shaped value.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-first first-flow first source-flow second-contract)
;;       ;; => first flow binding
;;       ```
;;     %
(defrules defpoo-flow-first ()
  ((_ binding flow-name source second-contract)
   (def binding
     (flow-first 'flow-name source second-contract))))

;; defpoo-flow-second
;;   : (-> Identifier Identifier FlowExpr ContractExpr FlowBinding)
;;   | doc m%
;;       `defpoo-flow-second` defines Arrow `second` over a pair-shaped value.
;;
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-second second-flow second source-flow first-contract)
;;       ;; => second flow binding
;;       ```
;;     %
(defrules defpoo-flow-second ()
  ((_ binding flow-name source first-contract)
   (def binding
     (flow-second 'flow-name source first-contract))))
