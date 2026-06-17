;;; -*- Gerbil -*-
;;; Boundary: planning produces inspectable control-plane artifacts.
;;; Invariant: execution stays in the runner/runtime-adapter layer.

(import :core/flow
        :core/task)

(export make-plan-node
        plan-node?
        plan-node-id
        plan-node-ordinal
        plan-node-step
        plan-node-kind
        plan-node-name
        plan-node-dependencies
        make-execution-plan
        execution-plan?
        execution-plan-flow-name
        execution-plan-nodes
        execution-plan-input-contract
        execution-plan-output-contract
        flow->linear-plan
        execution-plan-node-ids
        execution-plan-dependency-edges
        execution-plan-root-nodes
        execution-plan-terminal-nodes
        plan-node-root?
        plan-node-depends-on?
        plan-empty?
        plan-node-count)

;;; A node keeps both the original step and normalized metadata; dependencies
;;; expose a DAG-ready plan without moving execution into Scheme.
;; PlanNode <- Symbol Nat Step Symbol Symbol [Symbol]
(defstruct plan-node
  (id
   ordinal
   step
   kind
   name
   dependencies)
  transparent: #t)

;;; The plan mirrors the flow boundary contracts while exposing a flat node
;;; stream for strategy selection and audit receipts.
;; ExecutionPlan <- Symbol [PlanNode] Contract Contract
(defstruct execution-plan
  (flow-name
   nodes
   input-contract
   output-contract)
  transparent: #t)

;; ExecutionPlan <- Flow
(def (flow->linear-plan flow)
  (make-execution-plan (flow-name flow)
                       (steps->plan-nodes (flow-name flow) (flow-steps flow))
                       (flow-input-contract flow)
                       (flow-output-contract flow)))

;;; Ordinals and predecessor pairs are data, not loop state: together they
;;; preserve order while exposing dependency edges for later schedulers.
;; [PlanNode] <- Symbol [Step]
(def (steps->plan-nodes flow-name steps)
  (map (lambda (ordinal step previous)
         (step->plan-node flow-name ordinal step previous))
       (iota (length steps))
       steps
       (cons #f steps)))

;; PlanNode <- Symbol Nat Step MaybeStep
(def (step->plan-node flow-name ordinal step previous)
  (let* ((kind (step-kind step))
         (name (step-name step))
         (id (plan-node-id-for flow-name ordinal step))
         (dependencies
          (if previous
            (list (plan-node-id-for flow-name (- ordinal 1) previous))
            '())))
    (make-plan-node id ordinal step kind name dependencies)))

;; Symbol <- Symbol Nat Step
(def (plan-node-id-for flow-name ordinal step)
  (list 'node flow-name ordinal (step-kind step) (step-name step)))

;;; Graph inspection is deliberately read-only: strategies and receipts can
;;; reason about topology without smuggling scheduling behavior into planning.
;; [Id] <- ExecutionPlan
(def (execution-plan-node-ids plan)
  (map plan-node-id (execution-plan-nodes plan)))

;;; Edges are emitted as prerequisite -> dependent pairs, matching the order a
;;; scheduler or Rust adapter needs for readiness and receipt correlation.
;; [[Id Id]] <- ExecutionPlan
(def (execution-plan-dependency-edges plan)
  (nodes->dependency-edges (execution-plan-nodes plan)))

;;; Root and terminal frontiers give later DAG schedulers stable boundary
;;; facts while the current runner continues to execute the linear node stream.
;; [PlanNode] <- ExecutionPlan
(def (execution-plan-root-nodes plan)
  (select-plan-nodes plan-node-root? (execution-plan-nodes plan)))

;;; Intent: compute the sink frontier by filtering plan nodes against the
;;; dependency-edge table.
;;; The one-argument predicate receives each candidate node and checks whether
;;; its id appears as a prerequisite endpoint.
;;; Keeping this as a frontier selection preserves DAG shape without mixing
;;; edge discovery and terminal-node policy in one manual loop.
;; [PlanNode] <- ExecutionPlan
(def (execution-plan-terminal-nodes plan)
  (let ((edges (execution-plan-dependency-edges plan)))
    (select-plan-nodes
     (lambda (node)
       (not (id-has-dependent? (plan-node-id node) edges)))
     (execution-plan-nodes plan))))

;;; Dependency predicates stay at the node/id level so tests and adapters can
;;; audit graph shape without depending on task internals.
;; Boolean <- PlanNode
(def (plan-node-root? node)
  (null? (plan-node-dependencies node)))

;;; Dependency checks compare normalized node ids instead of step names, so
;;; nested flows and repeated task names remain unambiguous to adapters.
;; Boolean <- PlanNode Id
(def (plan-node-depends-on? node dependency-id)
  (id-member? dependency-id (plan-node-dependencies node)))

;;; Edge expansion is factored from the public API to keep future non-linear
;;; plan constructors responsible only for node dependencies, not edge shape.
;; [[Id Id]] <- [PlanNode]
(def (nodes->dependency-edges nodes)
  (if (null? nodes)
    '()
    (append (node->dependency-edges (car nodes))
            (nodes->dependency-edges (cdr nodes)))))

;;; Intent: map every dependency id on a node into a prerequisite-to-dependent
;;; edge while reusing the current node id as the dependent endpoint.
;;; The one-argument lambda is the whole transform over dependency-id values.
;;; A manual loop would hide the invariant that each emitted edge belongs to
;;; exactly one dependency of this node.
;; [[Id Id]] <- PlanNode
(def (node->dependency-edges node)
  (map (lambda (dependency-id)
         (list dependency-id (plan-node-id node)))
       (plan-node-dependencies node)))

;; [PlanNode] <- Predicate [PlanNode]
(def (select-plan-nodes predicate nodes)
  (cond
   ((null? nodes) '())
   ((predicate (car nodes))
    (cons (car nodes)
          (select-plan-nodes predicate (cdr nodes))))
   (else
    (select-plan-nodes predicate (cdr nodes)))))

;; Boolean <- Id [[Id Id]]
(def (id-has-dependent? id edges)
  (cond
   ((null? edges) #f)
   ((equal? id (car (car edges))) #t)
   (else (id-has-dependent? id (cdr edges)))))

;; Boolean <- Id [Id]
(def (id-member? id ids)
  (cond
   ((null? ids) #f)
   ((equal? id (car ids)) #t)
   (else (id-member? id (cdr ids)))))

;; Symbol <- Step
(def (step-kind step)
  (cond
   ((task? step) (task-kind step))
   ((flow? step) 'flow)
   (else (error "flow step is neither task nor flow" step))))

;; Symbol <- Step
(def (step-name step)
  (cond
   ((task? step) (task-name step))
   ((flow? step) (flow-name step))
   (else (error "flow step is neither task nor flow" step))))

;; Boolean <- ExecutionPlan
(def (plan-empty? plan)
  (null? (execution-plan-nodes plan)))

;; Nat <- ExecutionPlan
(def (plan-node-count plan)
  (length (execution-plan-nodes plan)))
