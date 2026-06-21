;;; -*- Gerbil -*-
;;; Boundary: planning produces inspectable control-plane artifacts.
;;; Invariant: execution stays in the runner/runtime-adapter layer.

(import :poo-flow/src/core/flow
        :poo-flow/src/core/task)

(export make-plan-node
        plan-node?
        plan-node-id
        plan-node-ordinal
        plan-node-step
        plan-node-kind
        plan-node-name
        plan-node-dependencies
        flow-dag-receipt-kind
        +flow-dag-runtime-manifest-schema+
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
        execution-plan-root-node-ids
        execution-plan-terminal-node-ids
        execution-plan-ready-nodes
        execution-plan-ready-node-ids
        plan-node-root?
        plan-node-depends-on?
        plan-node-ready?
        plan-node->dag-entry
        execution-plan->dag-receipt
        flow->dag-receipt
        execution-plan->dag-runtime-manifest
        flow->dag-runtime-manifest
        plan-empty?
        plan-node-count)

;;; A node keeps both the original step and normalized metadata; dependencies
;;; expose a DAG-ready plan without moving execution into Scheme.
;; : (-> Symbol Nat Step Symbol Symbol [Symbol] PlanNode)
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
;; : (-> Symbol [PlanNode] Contract Contract ExecutionPlan)
(defstruct execution-plan
  (flow-name
   nodes
   input-contract
   output-contract)
  transparent: #t)

;;; DAG receipts are report-only graph projections. They are not run receipts,
;;; and they must not imply scheduling, adapter submission, or state writes.
;; : (-> Unit FlowDagReceiptKind)
(def flow-dag-receipt-kind
  "poo-flow.core.flow-dag-receipt.v1")

;;; Boundary: runtime manifest schema is discovery metadata only.
;;; Intent: Marlin can discover DAG receipt shape without guessing entrypoints.
;; : (-> Unit FlowDagRuntimeManifestSchema)
(def +flow-dag-runtime-manifest-schema+
  'poo-flow.core.flow-dag-runtime-manifest.v1)

;; : (-> Flow ExecutionPlan)
(def (flow->linear-plan flow)
  (make-execution-plan (flow-name flow)
                       (steps->plan-nodes (flow-name flow) (flow-steps flow))
                       (flow-input-contract flow)
                       (flow-output-contract flow)))

;;; Ordinals and predecessor pairs are data, not loop state: together they
;;; preserve order while exposing dependency edges for later schedulers.
;; : (-> Symbol [Step] [PlanNode])
(def (steps->plan-nodes flow-name steps)
  (let ((lowered (lower-steps flow-name steps '() 0)))
    (car lowered)))

;; : (-> Symbol Nat Step [Id] PlanNode)
(def (step->plan-node flow-name ordinal step dependencies)
  (let* ((kind (step-kind step))
         (name (step-name step))
         (id (plan-node-id-for flow-name ordinal step)))
    (make-plan-node id ordinal step kind name dependencies)))

;;; Intent: lower declarations into a topologically sorted node stream.
;;; The returned triple is nodes, current terminal ids, and the next ordinal;
;;; branch lowering uses the terminal ids to create fan-out and join edges.
;; : (-> Symbol [Step] [Id] Nat LoweredSteps)
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

;; : (-> Symbol Step [Id] Nat LoweredStep)
(def (lower-step flow-name step previous-terminal-ids ordinal)
  (if (branch-step? step)
    (lower-branch-step flow-name step previous-terminal-ids ordinal)
    (lower-linear-step flow-name step previous-terminal-ids ordinal)))

;;; A normal step becomes one node; branch-specific fan-out is handled by
;;; lower-branch-step so the linear case keeps the old node id shape.
;; : (-> Symbol Step [Id] Nat LoweredStep)
(def (lower-linear-step flow-name step previous-terminal-ids ordinal)
  (let ((node (step->plan-node flow-name ordinal step previous-terminal-ids)))
    (list (list node)
          (list (plan-node-id node))
          (+ ordinal 1))))

;;; Branch lowering creates two parallel flow nodes with the same prerequisites
;;; and one join node that depends on both branch results.
;; : (-> Symbol BranchStep [Id] Nat LoweredStep)
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

;; : (-> Symbol Nat Symbol Flow [Id] PlanNode)
(def (branch-arm-node plan-flow-name ordinal kind flow dependencies)
  (make-plan-node (list 'node plan-flow-name ordinal kind (flow-name flow))
                  ordinal
                  flow
                  kind
                  (flow-name flow)
                  dependencies))

;; : (-> Symbol Nat BranchStep Id)
(def (branch-join-node-id plan-flow-name ordinal branch)
  (list 'node plan-flow-name ordinal 'branch (branch-step-name branch)))

;; : (-> Symbol Nat Step Symbol)
(def (plan-node-id-for flow-name ordinal step)
  (list 'node flow-name ordinal (step-kind step) (step-name step)))

;;; Graph inspection is deliberately read-only: strategies and receipts can
;;; reason about topology without smuggling scheduling behavior into planning.
;; : (-> ExecutionPlan [Id])
(def (execution-plan-node-ids plan)
  (map plan-node-id (execution-plan-nodes plan)))

;;; Edges are emitted as prerequisite -> dependent pairs, matching the order a
;;; scheduler or Rust adapter needs for readiness and receipt correlation.
;; : (-> ExecutionPlan [[Id Id]])
(def (execution-plan-dependency-edges plan)
  (nodes->dependency-edges (execution-plan-nodes plan)))

;;; Root and terminal frontiers give later DAG schedulers stable boundary
;;; facts while the current runner continues to execute the linear node stream.
;; : (-> ExecutionPlan [PlanNode])
(def (execution-plan-root-nodes plan)
  (select-plan-nodes plan-node-root? (execution-plan-nodes plan)))

;; : (-> ExecutionPlan [Id])
;;; Root ids are a compact receipt field for consumers that only need DAG
;;; frontier facts, not the full plan-node payload.
;; : (-> ExecutionPlan [Id])
(def (execution-plan-root-node-ids plan)
  (map plan-node-id (execution-plan-root-nodes plan)))

;;; Intent: compute the sink frontier by filtering plan nodes against the
;;; dependency-edge table.
;;; The one-argument predicate receives each candidate node and checks whether
;;; its id appears as a prerequisite endpoint.
;;; Keeping this as a frontier selection preserves DAG shape without mixing
;;; edge discovery and terminal-node policy in one manual loop.
;; : (-> ExecutionPlan [PlanNode])
(def (execution-plan-terminal-nodes plan)
  (let ((edges (execution-plan-dependency-edges plan)))
    (select-plan-nodes
     (lambda (node)
       (not (id-has-dependent? (plan-node-id node) edges)))
     (execution-plan-nodes plan))))

;; : (-> ExecutionPlan [Id])
;;; Terminal ids identify the sink frontier for handoff receipts and future
;;; schedulers without implying that Scheme will execute those sinks.
;; : (-> ExecutionPlan [Id])
(def (execution-plan-terminal-node-ids plan)
  (map plan-node-id (execution-plan-terminal-nodes plan)))

;;; Intent: compute the runnable frontier from completed node ids without
;;; changing the plan's original node order.
;;; The one-argument predicate tests each candidate node against a completed-id
;;; set, so future schedulers can choose from ready nodes without re-parsing
;;; flow steps or task internals.
;; : (-> ExecutionPlan [Id] [PlanNode])
(def (execution-plan-ready-nodes plan completed-node-ids)
  (select-plan-nodes
   (lambda (node)
     (plan-node-ready? node completed-node-ids))
   (execution-plan-nodes plan)))

;;; Intent: expose a lightweight frontier shape for strategy receipts and
;;; adapter requests that do not need the full plan-node payload.
;;; The map projection reuses plan-node-id so ready-frontier evidence matches
;;; dependency-edge endpoints exactly.
;; : (-> ExecutionPlan [Id] [Id])
(def (execution-plan-ready-node-ids plan completed-node-ids)
  (map plan-node-id
       (execution-plan-ready-nodes plan completed-node-ids)))

;;; Dependency predicates stay at the node/id level so tests and adapters can
;;; audit graph shape without depending on task internals.
;; : (-> PlanNode Boolean)
(def (plan-node-root? node)
  (null? (plan-node-dependencies node)))

;;; Dependency checks compare normalized node ids instead of step names, so
;;; nested flows and repeated task names remain unambiguous to adapters.
;; : (-> PlanNode Id Boolean)
(def (plan-node-depends-on? node dependency-id)
  (id-member? dependency-id (plan-node-dependencies node)))

;;; Readiness has two independent guards: the node itself must not already be
;;; complete, and every declared dependency must be present in the completed
;;; id set.
;; : (-> PlanNode [Id] Boolean)
(def (plan-node-ready? node completed-node-ids)
  (and (not (id-member? (plan-node-id node) completed-node-ids))
       (ids-subset? (plan-node-dependencies node) completed-node-ids)))

;;; Edge expansion is factored from the public API to keep future non-linear
;;; plan constructors responsible only for node dependencies, not edge shape.
;; : (-> [PlanNode] [[Id Id]])
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
;; : (-> PlanNode [[Id Id]])
(def (node->dependency-edges node)
  (map (lambda (dependency-id)
         (list dependency-id (plan-node-id node)))
       (plan-node-dependencies node)))

;;; Node entries are the per-node part of the strategy-facing DAG receipt.
;;; They intentionally omit the raw step payload so external consumers inspect
;;; topology without receiving executable Scheme procedures or task internals.
;; : (-> PlanNode Alist)
(def (plan-node->dag-entry node)
  (list (cons 'id (plan-node-id node))
        (cons 'ordinal (plan-node-ordinal node))
        (cons 'kind (plan-node-kind node))
        (cons 'name (plan-node-name node))
        (cons 'dependencies (plan-node-dependencies node))))

;;; The DAG receipt is a durable planning projection for Marlin and strategy
;;; code. It reports graph shape only; runtime execution remains behind runner
;;; and adapter layers.
;; : (-> ExecutionPlan Alist)
(def (execution-plan->dag-receipt plan)
  (list (cons 'kind flow-dag-receipt-kind)
        (cons 'flow (execution-plan-flow-name plan))
        (cons 'input-contract (execution-plan-input-contract plan))
        (cons 'output-contract (execution-plan-output-contract plan))
        (cons 'node-count (plan-node-count plan))
        (cons 'nodes (map plan-node->dag-entry (execution-plan-nodes plan)))
        (cons 'node-ids (execution-plan-node-ids plan))
        (cons 'dependency-edges (execution-plan-dependency-edges plan))
        (cons 'root-node-ids (execution-plan-root-node-ids plan))
        (cons 'terminal-node-ids (execution-plan-terminal-node-ids plan))
        (cons 'strategy-facing #t)
        (cons 'report-only #t)
        (cons 'descriptor-realized? #f)
        (cons 'runtime-executed #f)))

;;; Flow projection is the ergonomic entrypoint for functional-kernel arrows:
;;; callers hand it a declaration and receive graph evidence, not execution.
;; : (-> Flow Alist)
(def (flow->dag-receipt flow)
  (execution-plan->dag-receipt (flow->linear-plan flow)))

;;; Runtime manifest projection is the discovery surface for Marlin-facing
;;; consumers. It wraps the report-only DAG receipt and names the Scheme
;;; entrypoints, but it never schedules nodes or submits adapter requests.
;; : (-> ExecutionPlan [RequestId] Alist)
(def (execution-plan->dag-runtime-manifest plan . maybe-request-id)
  (let ((request-id (if (null? maybe-request-id)
                      #f
                      (car maybe-request-id)))
        (receipt (execution-plan->dag-receipt plan)))
    (list (cons 'schema +flow-dag-runtime-manifest-schema+)
          (cons 'kind 'flow-dag-runtime-manifest)
          (cons 'bridge 'runtime-manifest)
          (cons 'producer 'poo-flow)
          (cons 'consumer 'marlin-agent-core)
          (cons 'operation 'inspect-flow-dag)
          (cons 'request-id request-id)
          (cons 'flow (execution-plan-flow-name plan))
          (cons 'receipt-schema flow-dag-receipt-kind)
          (cons 'dag-receipt receipt)
          (cons 'node-count (plan-node-count plan))
          (cons 'node-ids (execution-plan-node-ids plan))
          (cons 'dependency-edges (execution-plan-dependency-edges plan))
          (cons 'root-node-ids (execution-plan-root-node-ids plan))
          (cons 'terminal-node-ids (execution-plan-terminal-node-ids plan))
          (cons 'entrypoints
                '((flow . flow->dag-runtime-manifest)
                  (execution-plan . execution-plan->dag-runtime-manifest)
                  (receipt . flow->dag-receipt)))
          (cons 'runtime-boundary
                '((local-execution . validation-only)
                  (production-execution . marlin-agent-core)))
          (cons 'control-owner 'gerbil)
          (cons 'execution-owner 'marlin-agent-core)
          (cons 'report-only #t)
          (cons 'descriptor-realized? #f)
          (cons 'runtime-executed #f))))

;;; Flow projection is the public ergonomic discovery entrypoint. It lowers the
;;; flow to a plan first so Marlin receives the same manifest shape whether the
;;; caller starts from a flow declaration or an already planned graph.
;; : (-> Flow [RequestId] Alist)
(def (flow->dag-runtime-manifest flow . maybe-request-id)
  (let ((plan (flow->linear-plan flow)))
    (if (null? maybe-request-id)
      (execution-plan->dag-runtime-manifest plan)
      (execution-plan->dag-runtime-manifest plan (car maybe-request-id)))))

;; : (-> Predicate [PlanNode] [PlanNode])
(def (select-plan-nodes predicate nodes)
  (cond
   ((null? nodes) '())
   ((predicate (car nodes))
    (cons (car nodes)
          (select-plan-nodes predicate (cdr nodes))))
   (else
    (select-plan-nodes predicate (cdr nodes)))))

;; : (-> Id [[Id Id]] Boolean)
(def (id-has-dependent? id edges)
  (cond
   ((null? edges) #f)
   ((equal? id (car (car edges))) #t)
   (else (id-has-dependent? id (cdr edges)))))

;; : (-> Id [Id] Boolean)
(def (id-member? id ids)
  (cond
   ((null? ids) #f)
   ((equal? id (car ids)) #t)
   (else (id-member? id (cdr ids)))))

;; : (-> [Id] [Id] Boolean)
(def (ids-subset? candidate-ids available-ids)
  (cond
   ((null? candidate-ids) #t)
   ((id-member? (car candidate-ids) available-ids)
    (ids-subset? (cdr candidate-ids) available-ids))
   (else #f)))

;; : (-> Step Symbol)
(def (step-kind step)
  (cond
   ((task? step) (task-kind step))
   ((flow? step) 'flow)
   ((branch-step? step) 'branch)
   ((try-step? step) 'try)
   ((kleisli-step? step) 'kleisli)
   (else (error "flow step is neither task nor flow" step))))

;; : (-> Step Symbol)
(def (step-name step)
  (cond
   ((task? step) (task-name step))
   ((flow? step) (flow-name step))
   ((branch-step? step) (branch-step-name step))
   ((try-step? step) (try-step-name step))
   ((kleisli-step? step) (kleisli-step-name step))
   (else (error "flow step is neither task nor flow" step))))

;; : (-> ExecutionPlan Boolean)
(def (plan-empty? plan)
  (null? (execution-plan-nodes plan)))

;; : (-> ExecutionPlan Nat)
(def (plan-node-count plan)
  (length (execution-plan-nodes plan)))
