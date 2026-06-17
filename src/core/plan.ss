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
        execution-plan-ready-nodes
        execution-plan-ready-node-ids
        plan-node-root?
        plan-node-depends-on?
        plan-node-ready?
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
  (let ((lowered (lower-steps flow-name steps '() 0)))
    (car lowered)))

;; PlanNode <- Symbol Nat Step [Id]
(def (step->plan-node flow-name ordinal step dependencies)
  (let* ((kind (step-kind step))
         (name (step-name step))
         (id (plan-node-id-for flow-name ordinal step)))
    (make-plan-node id ordinal step kind name dependencies)))

;;; Intent: lower declarations into a topologically sorted node stream.
;;; The returned triple is nodes, current terminal ids, and the next ordinal;
;;; branch lowering uses the terminal ids to create fan-out and join edges.
;; LoweredSteps <- Symbol [Step] [Id] Nat
(def (lower-steps flow-name steps previous-terminal-ids ordinal)
  (if (null? steps)
    (list '() previous-terminal-ids ordinal)
    (let* ((lowered-step (lower-step flow-name
                                     (car steps)
                                     previous-terminal-ids
                                     ordinal))
           (step-nodes (car lowered-step))
           (step-terminals (cadr lowered-step))
           (next-ordinal (caddr lowered-step))
           (lowered-rest (lower-steps flow-name
                                      (cdr steps)
                                      step-terminals
                                      next-ordinal)))
      (list (append step-nodes (car lowered-rest))
            (cadr lowered-rest)
            (caddr lowered-rest)))))

;; LoweredStep <- Symbol Step [Id] Nat
(def (lower-step flow-name step previous-terminal-ids ordinal)
  (if (branch-step? step)
    (lower-branch-step flow-name step previous-terminal-ids ordinal)
    (lower-linear-step flow-name step previous-terminal-ids ordinal)))

;;; A normal step becomes one node; branch-specific fan-out is handled by
;;; lower-branch-step so the linear case keeps the old node id shape.
;; LoweredStep <- Symbol Step [Id] Nat
(def (lower-linear-step flow-name step previous-terminal-ids ordinal)
  (let ((node (step->plan-node flow-name ordinal step previous-terminal-ids)))
    (list (list node)
          (list (plan-node-id node))
          (+ ordinal 1))))

;;; Branch lowering creates two parallel flow nodes with the same prerequisites
;;; and one join node that depends on both branch results.
;; LoweredStep <- Symbol BranchStep [Id] Nat
(def (lower-branch-step flow-name branch previous-terminal-ids ordinal)
  (let* ((left-flow (branch-step-left branch))
         (right-flow (branch-step-right branch))
         (left-node (branch-arm-node flow-name
                                     ordinal
                                     'branch-left
                                     left-flow
                                     previous-terminal-ids))
         (right-node (branch-arm-node flow-name
                                      (+ ordinal 1)
                                      'branch-right
                                      right-flow
                                      previous-terminal-ids))
         (join-node (make-plan-node (branch-join-node-id flow-name
                                                         (+ ordinal 2)
                                                         branch)
                                    (+ ordinal 2)
                                    branch
                                    'branch
                                    (branch-step-name branch)
                                    (list (plan-node-id left-node)
                                          (plan-node-id right-node)))))
    (list (list left-node right-node join-node)
          (list (plan-node-id join-node))
          (+ ordinal 3))))

;; PlanNode <- Symbol Nat Symbol Flow [Id]
(def (branch-arm-node plan-flow-name ordinal kind flow dependencies)
  (make-plan-node (list 'node plan-flow-name ordinal kind (flow-name flow))
                  ordinal
                  flow
                  kind
                  (flow-name flow)
                  dependencies))

;; Id <- Symbol Nat BranchStep
(def (branch-join-node-id plan-flow-name ordinal branch)
  (list 'node plan-flow-name ordinal 'branch (branch-step-name branch)))

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

;;; Intent: compute the runnable frontier from completed node ids without
;;; changing the plan's original node order.
;;; The one-argument predicate tests each candidate node against a completed-id
;;; set, so future schedulers can choose from ready nodes without re-parsing
;;; flow steps or task internals.
;; [PlanNode] <- ExecutionPlan [Id]
(def (execution-plan-ready-nodes plan completed-node-ids)
  (select-plan-nodes
   (lambda (node)
     (plan-node-ready? node completed-node-ids))
   (execution-plan-nodes plan)))

;;; Intent: expose a lightweight frontier shape for strategy receipts and
;;; adapter requests that do not need the full plan-node payload.
;;; The map projection reuses plan-node-id so ready-frontier evidence matches
;;; dependency-edge endpoints exactly.
;; [Id] <- ExecutionPlan [Id]
(def (execution-plan-ready-node-ids plan completed-node-ids)
  (map plan-node-id
       (execution-plan-ready-nodes plan completed-node-ids)))

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

;;; Readiness has two independent guards: the node itself must not already be
;;; complete, and every declared dependency must be present in the completed
;;; id set.
;; Boolean <- PlanNode [Id]
(def (plan-node-ready? node completed-node-ids)
  (and (not (id-member? (plan-node-id node) completed-node-ids))
       (ids-subset? (plan-node-dependencies node) completed-node-ids)))

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

;; Boolean <- [Id] [Id]
(def (ids-subset? candidate-ids available-ids)
  (cond
   ((null? candidate-ids) #t)
   ((id-member? (car candidate-ids) available-ids)
    (ids-subset? (cdr candidate-ids) available-ids))
   (else #f)))

;; Symbol <- Step
(def (step-kind step)
  (cond
   ((task? step) (task-kind step))
   ((flow? step) 'flow)
   ((branch-step? step) 'branch)
   (else (error "flow step is neither task nor flow" step))))

;; Symbol <- Step
(def (step-name step)
  (cond
   ((task? step) (task-name step))
   ((flow? step) (flow-name step))
   ((branch-step? step) (branch-step-name step))
   (else (error "flow step is neither task nor flow" step))))

;; Boolean <- ExecutionPlan
(def (plan-empty? plan)
  (null? (execution-plan-nodes plan)))

;; Nat <- ExecutionPlan
(def (plan-node-count plan)
  (length (execution-plan-nodes plan)))
