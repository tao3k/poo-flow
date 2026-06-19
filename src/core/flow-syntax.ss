;;; -*- Gerbil -*-
;;; Boundary: hygienic authoring macros for the functional flow kernel.
;;; Invariant: macros expand to public flow/plan combinators, not a workflow DSL.

(import :core/flow
        :core/plan)

(export defpoo-flow-arr
        defpoo-flow-identity
        defpoo-flow-compose
        defpoo-flow-map
        defpoo-flow-fanout
        defpoo-flow-dag
        defpoo-flow-dag-artifacts
        defpoo-flow-try
        defpoo-flow-first
        defpoo-flow-second)

;;; Boundary: define a pure arrow flow with an identifier-owned flow name.
;;; The procedure and contracts remain caller expressions.
;; : (-> Identifier Identifier ProcedureExpr ContractExpr ContractExpr FlowBinding)
(defrules defpoo-flow-arr ()
  ((_ binding flow-name proc input-contract output-contract)
   (def binding
     (flow-arr 'flow-name proc input-contract output-contract))))

;;; Boundary: define a category identity flow.
;; : (-> Identifier Identifier ContractExpr FlowBinding)
(defrules defpoo-flow-identity ()
  ((_ binding flow-name contract)
   (def binding
     (flow-identity 'flow-name contract))))

;;; Boundary: define sequential composition over already-built flows.
;; : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
(defrules defpoo-flow-compose ()
  ((_ binding flow-name left right)
   (def binding
     (flow-then 'flow-name left right))))

;;; Boundary: define a functional output map over an existing flow.
;; : (-> Identifier Identifier FlowExpr ProcedureExpr ContractExpr FlowBinding)
(defrules defpoo-flow-map ()
  ((_ binding flow-name source proc output-contract)
   (def binding
     (flow-map 'flow-name source proc output-contract))))

;;; Boundary: define Arrow-style fanout without selecting a scheduler.
;; : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
(defrules defpoo-flow-fanout ()
  ((_ binding flow-name left right)
   (def binding
     (flow-fanout 'flow-name left right))))

;;; Boundary: define a functional DAG flow as Arrow fanout.  This is the
;;; user-facing Funflow-style DAG entrypoint; receipt and manifest projection
;;; stay separate so users can name those artifacts deliberately.
;; : (-> Identifier Identifier FlowExpr FlowExpr FlowBinding)
(defrules defpoo-flow-dag ()
  ((_ binding flow-name left right)
   (def binding
     (flow-fanout 'flow-name left right))))

;;; Boundary: define report-only DAG artifacts for an existing flow binding.
;;; The flow remains ordinary Scheme data; the artifacts expose graph evidence
;;; and Marlin discovery without executing runtime work.
;; : (-> Identifier Identifier FlowExpr RequestIdExpr DagArtifactBindings)
(defrules defpoo-flow-dag-artifacts ()
  ((_ receipt-binding manifest-binding source request-id)
   (begin
     (def receipt-binding
       (flow->dag-receipt source))
     (def manifest-binding
       (flow->dag-runtime-manifest source request-id)))))

;;; Boundary: define a Funflow-style try boundary over an existing flow.
;; : (-> Identifier Identifier FlowExpr FlowBinding)
(defrules defpoo-flow-try ()
  ((_ binding flow-name source)
   (def binding
     (try-flow 'flow-name source))))

;;; Boundary: define Arrow first over a pair-shaped value.
;; : (-> Identifier Identifier FlowExpr ContractExpr FlowBinding)
(defrules defpoo-flow-first ()
  ((_ binding flow-name source second-contract)
   (def binding
     (flow-first 'flow-name source second-contract))))

;;; Boundary: define Arrow second over a pair-shaped value.
;; : (-> Identifier Identifier FlowExpr ContractExpr FlowBinding)
(defrules defpoo-flow-second ()
  ((_ binding flow-name source first-contract)
   (def binding
     (flow-second 'flow-name source first-contract))))
