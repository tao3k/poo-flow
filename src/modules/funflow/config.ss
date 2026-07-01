;;; -*- Gerbil -*-
;;; Boundary: Funflow module configuration belongs to the Funflow module owner.
;;; Invariant: this file only declares maintained Funflow module rows.

(import (only-in :std/sugar filter-map)
        (only-in :clan/poo/object .ref object<-alist)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/config-prototype-syntax
        :poo-flow/src/module-system/projection-syntax
        (only-in :poo-flow/src/modules/workflow/cicd-core
                 poo-flow-cicd-alist-ref
                 poo-flow-cicd-symbol-member?)
        :poo-flow/src/modules/workflow/cicd)

(export poo-flow-funflow-cicd-default-payload
        +poo-flow-funflow-workflow-agreement-contract+
        funflow-check
        funflow-pipeline
        poo-flow-funflow-config-flags
        poo-flow-funflow-poo-check?
        poo-flow-funflow-poo-pipeline?
        poo-flow-funflow-poo-check->cicd-check
        poo-flow-funflow-poo-pipeline->check-map
        funflow-dag-edge
        funflow-composition-step
        funflow-functional-dag
        poo-flow-funflow-dag-edge
        poo-flow-funflow-dag-edge?
        poo-flow-funflow-dag-edge->alist
        poo-flow-funflow-composition-step
        poo-flow-funflow-composition-step?
        poo-flow-funflow-composition-step->alist
        poo-flow-funflow-functional-dag?
        poo-flow-funflow-functional-dag->alist
        poo-flow-funflow-check-map->functional-dag
        poo-flow-funflow-poo-pipeline->functional-dag
        poo-flow-funflow-poo-config-flags
        poo-flow-funflow-workflow-ref?
        poo-flow-funflow-workflow-agreement
        poo-flow-funflow-pipeline-runtime-command-manifests
        poo-flow-funflow-module-bundles
        poo-upstream-flow-funflow-module-bundles)

;;; The CI/CD payload is a Funflow feature, not a new top-level category. It is
;;; inspectable module data; adapters such as GitHub, Docker, or Nix stay out.
;; : UserModuleFlagEntry
(def poo-flow-funflow-cicd-default-payload
  '(+cicd
    (checks +parallel +typed-receipts)
    (artifacts +export)
    (release +manual-gate)
    (webhook +server)
    (runtime +manifest-handoff)))

;;; Workflow agreement is Funflow-owned vocabulary. Loop engines can reference
;;; these refs, but the validity of a Funflow workflow stays with this module.
;; : Symbol
(def +poo-flow-funflow-workflow-agreement-contract+
  'poo-flow.funflow.workflow-agreement.v1)

;; : Symbol
(def +poo-flow-funflow-check-prototype-kind+
  'poo-flow.funflow.check.prototype)

;; : Symbol
(def +poo-flow-funflow-pipeline-prototype-kind+
  'poo-flow.funflow.pipeline.prototype)

;; : Symbol
(def +poo-flow-funflow-dag-edge-prototype-kind+
  'poo-flow.funflow.dag-edge.prototype)

;; : Symbol
(def +poo-flow-funflow-composition-step-prototype-kind+
  'poo-flow.funflow.composition-step.prototype)

;; : Symbol
(def +poo-flow-funflow-functional-dag-prototype-kind+
  'poo-flow.funflow.functional-dag.prototype)

;; : PooFlowFunflowCheckPrototype
(defpoo-module-config-prototype
  funflow-check
  (slots ((kind +poo-flow-funflow-check-prototype-kind+)
          (check-name #f)
          (profile-ref #f)
          (command-vector '())
          (input-bindings '())
          (config-sources '())
          (artifact-outputs '())
          (cache-intents '())
          (secret-requirements '())
          (result-protocol '())
          (runtime-mode 'manifest-handoff)
          (dependency-refs '())
          (durable-task-id #f)
          (action-class 'idempotent)
          (compensation-refs '())
          (artifact-retention 'workflow-retained)
          (observability #f)
          (observes '())
          (guards '())
          (report #f)
          (metadata '())
          (runtime-executed #f))))

;; : PooFlowFunflowPipelinePrototype
(defpoo-module-config-prototype
  funflow-pipeline
  (slots ((kind +poo-flow-funflow-pipeline-prototype-kind+)
          (pipeline-name #f)
          (checks '())
          (metadata '())
          (runtime-executed #f))))

;; : PooFlowFunflowDagEdgePrototype
(defpoo-module-config-prototype
  funflow-dag-edge
  (slots ((kind +poo-flow-funflow-dag-edge-prototype-kind+)
          (from #f)
          (to #f)
          (composition-style 'kleisli)
          (metadata '())
          (runtime-executed #f))))

;; : PooFlowFunflowCompositionStepPrototype
(defpoo-module-config-prototype
  funflow-composition-step
  (slots ((kind +poo-flow-funflow-composition-step-prototype-kind+)
          (schema 'poo-flow.modules.funflow.composition-step.v1)
          (step-kind #f)
          (check-name #f)
          (from #f)
          (to #f)
          (composition-style #f)
          (metadata '())
          (runtime-executed #f))))

;; : PooFlowFunflowFunctionalDagPrototype
(defpoo-module-config-prototype
  funflow-functional-dag
  (slots ((kind +poo-flow-funflow-functional-dag-prototype-kind+)
          (schema 'poo-flow.modules.funflow.functional-dag.v1)
          (pipeline-name #f)
          (check-map #f)
          (composition-style 'arrow-kleisli)
          (composition-steps '())
          (composition-step-count 0)
          (nodes '())
          (edges '())
          (edge-count 0)
          (entry-nodes '())
          (terminal-nodes '())
          (ready-order '())
          (unordered-nodes '())
          (blocked-order? #f)
          (diagnostics '())
          (valid? #t)
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

;; : (-> Symbol Boolean)
(def (poo-flow-funflow-workflow-ref? workflow-ref)
  (or (eq? workflow-ref 'funflow)
      (eq? workflow-ref 'funflow-cicd)))

;;; Boundary: funflow check map names is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [PooFlowCicdCheckMap] [Symbol])
(def (poo-flow-funflow-check-map-names check-maps)
  (cond
   ((null? check-maps) '())
   (else
    (cons (poo-flow-cicd-check-map-name (car check-maps))
          (poo-flow-funflow-check-map-names (cdr check-maps))))))

;;; `funflow-cicd` requires at least one declared pipeline/check-map. Plain
;;; non-Funflow refs remain valid but explicitly outside Funflow ownership.
;; : (-> Symbol [PooFlowCicdCheckMap] [Alist])
(def (poo-flow-funflow-workflow-agreement-diagnostics workflow-ref check-maps)
  (cond
   ((and (eq? workflow-ref 'funflow-cicd)
         (null? check-maps))
    (list
     (list (cons 'field 'workflow-ref)
           (cons 'code 'missing-funflow-workflow-pipeline)
           (cons 'workflow-ref workflow-ref))))
   (else '())))

;;; The agreement is report-only data that lets loop-engine handoff receipts
;;; prove whether a workflow ref is backed by a Funflow-owned pipeline.
;; : (-> Symbol [PooFlowCicdCheckMap] Alist)
(def (poo-flow-funflow-workflow-agreement workflow-ref check-maps)
  (let* ((diagnostics
          (poo-flow-funflow-workflow-agreement-diagnostics
           workflow-ref
           check-maps))
         (functional-dag-rows
          (map poo-flow-funflow-functional-dag->alist
               (map poo-flow-funflow-check-map->functional-dag
                    check-maps))))
    (list
     (cons 'kind 'funflow-workflow-agreement)
     (cons 'contract +poo-flow-funflow-workflow-agreement-contract+)
     (cons 'workflow-ref workflow-ref)
     (cons 'funflow-owned? (poo-flow-funflow-workflow-ref? workflow-ref))
     (cons 'pipeline-count (length check-maps))
     (cons 'pipeline-names (poo-flow-funflow-check-map-names check-maps))
     (cons 'functional-dag-count (length functional-dag-rows))
     (cons 'functional-dags functional-dag-rows)
     (cons 'diagnostic-count (length diagnostics))
     (cons 'diagnostics diagnostics)
     (cons 'valid? (null? diagnostics))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; POO-native check and pipeline objects stay shallow: Funflow owns the public
;;; prototype surface, while sandbox profile refs and runtime descriptors remain
;;; unresolved until later module/object validation.
;; : (forall (a) (-> String Boolean a Void))
(def (poo-flow-funflow-require message ok? value)
  (if ok?
    (void)
    (error message value)))

;;; Funflow `:needs` names other checks in the same pipeline. Object/profile
;;; inheritance stays in `:inherits` so the two extension axes do not blur.
;; : (-> [FunflowPipelineDependencyRefCandidate] Boolean)
(def (poo-flow-funflow-symbol-list? values)
  (cond
   ((null? values) #t)
   ((and (pair? values)
         (symbol? (car values)))
    (poo-flow-funflow-symbol-list? (cdr values)))
   (else #f)))

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-funflow-poo-check?
  +poo-flow-funflow-check-prototype-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-funflow-poo-pipeline?
  +poo-flow-funflow-pipeline-prototype-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-funflow-dag-edge?
  +poo-flow-funflow-dag-edge-prototype-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-funflow-composition-step?
  +poo-flow-funflow-composition-step-prototype-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-funflow-functional-dag?
  +poo-flow-funflow-functional-dag-prototype-kind+)

;;; Boundary: funflow optional metadata is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (forall (a) (-> Symbol a [Pair]))
(def (poo-flow-funflow-optional-metadata key value)
  (if value
    (list (cons key value))
    '()))

;;; Boundary: funflow list metadata is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Symbol List [Pair])
(def (poo-flow-funflow-list-metadata key values)
  (if (null? values)
    '()
    (list (cons key values))))

;; : (-> Symbol Symbol [Alist] PooFlowFunflowDagEdge)
(def (poo-flow-funflow-dag-edge from to . maybe-metadata)
  (poo-flow-funflow-require "funflow DAG edge from must be a symbol"
                            (symbol? from)
                            from)
  (poo-flow-funflow-require "funflow DAG edge to must be a symbol"
                            (symbol? to)
                            to)
  (object<-alist
   (list
    (cons 'kind +poo-flow-funflow-dag-edge-prototype-kind+)
    (cons 'from from)
    (cons 'to to)
    (cons 'composition-style 'kleisli)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata)))
    (cons 'runtime-executed #f))))

;; : (-> Symbol MaybeSymbol MaybeSymbol MaybeSymbol [Alist] PooFlowFunflowCompositionStep)
(def (poo-flow-funflow-composition-step step-kind check-name from to . maybe-metadata)
  (poo-flow-funflow-require "funflow composition step kind must be a symbol"
                            (symbol? step-kind)
                            step-kind)
  (poo-flow-funflow-require "funflow composition step check-name must be a symbol or #f"
                            (or (not check-name) (symbol? check-name))
                            check-name)
  (poo-flow-funflow-require "funflow composition step from must be a symbol or #f"
                            (or (not from) (symbol? from))
                            from)
  (poo-flow-funflow-require "funflow composition step to must be a symbol or #f"
                            (or (not to) (symbol? to))
                            to)
  (object<-alist
   (list
    (cons 'kind +poo-flow-funflow-composition-step-prototype-kind+)
    (cons 'schema 'poo-flow.modules.funflow.composition-step.v1)
    (cons 'step-kind step-kind)
    (cons 'check-name check-name)
    (cons 'from from)
    (cons 'to to)
    (cons 'composition-style
          (if (eq? step-kind 'kleisli-bind) 'kleisli 'arrow))
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata)))
    (cons 'runtime-executed #f))))

;; : (-> PooFlowFunflowDagEdge Alist)
(defpoo-module-final-projection
  poo-flow-funflow-dag-edge->alist (edge)
  (bindings ((_guard
              (poo-flow-funflow-require
               "funflow DAG edge projection requires an edge"
               (poo-flow-funflow-dag-edge? edge)
               edge))))
  (fields ((kind (.ref edge 'kind))
           (from (.ref edge 'from))
           (to (.ref edge 'to))
           (composition-style (.ref edge 'composition-style))
           (metadata (.ref edge 'metadata))
           (runtime-executed (.ref edge 'runtime-executed)))))

;; : (-> PooFlowFunflowCompositionStep Alist)
(defpoo-module-final-projection
  poo-flow-funflow-composition-step->alist (step)
  (bindings ((_guard
              (poo-flow-funflow-require
               "funflow composition step projection requires a composition step"
               (poo-flow-funflow-composition-step? step)
               step))))
  (fields ((kind (.ref step 'kind))
           (schema (.ref step 'schema))
           (step-kind (.ref step 'step-kind))
           (check-name (.ref step 'check-name))
           (from (.ref step 'from))
           (to (.ref step 'to))
           (composition-style (.ref step 'composition-style))
           (metadata (.ref step 'metadata))
           (runtime-executed (.ref step 'runtime-executed)))))

;; : (-> [Symbol] [PooFlowFunflowDagEdge] [Symbol])
(def (poo-flow-funflow-entry-nodes nodes edges)
  (let (targets (map (lambda (edge) (.ref edge 'to)) edges))
    (filter (lambda (node)
              (not (poo-flow-cicd-symbol-member? node targets)))
            nodes)))

;; : (-> [Symbol] [PooFlowFunflowDagEdge] [Symbol])
(def (poo-flow-funflow-terminal-nodes nodes edges)
  (let (sources (map (lambda (edge) (.ref edge 'from)) edges))
    (filter (lambda (node)
              (not (poo-flow-cicd-symbol-member? node sources)))
            nodes)))

;; : (-> Alist PooFlowFunflowDagEdge)
(def (poo-flow-funflow-dependency-edge->dag-edge edge)
  (poo-flow-funflow-dag-edge
   (poo-flow-cicd-alist-ref edge 'from #f)
   (poo-flow-cicd-alist-ref edge 'to #f)
   (list (cons 'source 'workflow-cicd-dependency-graph))))

;; : (-> [Alist] [PooFlowFunflowDagEdge])
(def (poo-flow-funflow-dependency-edges->dag-edges edges)
  (map poo-flow-funflow-dependency-edge->dag-edge edges))

;; : (-> Symbol PooFlowFunflowCompositionStep)
(def (poo-flow-funflow-node->composition-step node)
  (poo-flow-funflow-composition-step
   'arrow-node
   node
   #f
   #f
   (list (cons 'source 'funflow-functional-kernel))))

;; : (-> PooFlowFunflowDagEdge PooFlowFunflowCompositionStep)
(def (poo-flow-funflow-edge->composition-step edge)
  (poo-flow-funflow-composition-step
   'kleisli-bind
   #f
   (.ref edge 'from)
   (.ref edge 'to)
   (list (cons 'source 'funflow-functional-kernel)
         (cons 'edge-composition-style
               (.ref edge 'composition-style)))))

;; : (-> [Symbol] [PooFlowFunflowDagEdge] [PooFlowFunflowCompositionStep])
(def (poo-flow-funflow-dag-composition-steps nodes edges)
  (append
   (map poo-flow-funflow-node->composition-step nodes)
   (map poo-flow-funflow-edge->composition-step edges)))

;; : (-> PooFlowFunflowFunctionalDag Alist)
(defpoo-module-final-projection
  poo-flow-funflow-functional-dag->alist (dag)
  (bindings ((_guard
              (poo-flow-funflow-require
               "funflow functional DAG projection requires a DAG"
               (poo-flow-funflow-functional-dag? dag)
               dag))))
  (fields ((kind (.ref dag 'kind))
           (schema (.ref dag 'schema))
           (pipeline-name (.ref dag 'pipeline-name))
           (check-map (.ref dag 'check-map))
           (composition-style (.ref dag 'composition-style))
           (composition-steps
            (map poo-flow-funflow-composition-step->alist
                 (.ref dag 'composition-steps)))
           (composition-step-count
            (.ref dag 'composition-step-count))
           (nodes (.ref dag 'nodes))
           (edges
            (map poo-flow-funflow-dag-edge->alist
                 (.ref dag 'edges)))
           (edge-count (.ref dag 'edge-count))
           (entry-nodes (.ref dag 'entry-nodes))
           (terminal-nodes (.ref dag 'terminal-nodes))
           (ready-order (.ref dag 'ready-order))
           (unordered-nodes (.ref dag 'unordered-nodes))
           (blocked-order? (.ref dag 'blocked-order?))
           (diagnostics (.ref dag 'diagnostics))
           (valid? (.ref dag 'valid?))
           (metadata (.ref dag 'metadata))
           (runtime-owner (.ref dag 'runtime-owner))
           (runtime-executed (.ref dag 'runtime-executed)))))

;; : (-> PooFlowFunflowCheckPrototype Alist)
(def (poo-flow-funflow-poo-check-metadata check)
  (let ((dependency-refs (.ref check 'dependency-refs))
        (metadata (.ref check 'metadata)))
    (poo-flow-funflow-require
     "funflow POO check dependency-refs must be a list of symbols"
     (poo-flow-funflow-symbol-list? dependency-refs)
     dependency-refs)
    (poo-flow-funflow-require
     "funflow POO check metadata must be an alist"
     (list? metadata)
     metadata)
    (append
     (list (cons 'source 'funflow-poo-prototype)
           (cons 'check (.ref check 'check-name))
           (cons 'dependency-refs dependency-refs))
     (poo-flow-funflow-optional-metadata
      'observability
      (.ref check 'observability))
     (poo-flow-funflow-optional-metadata
      'durable-task-id
      (.ref check 'durable-task-id))
     (poo-flow-funflow-optional-metadata
      'action-class
      (.ref check 'action-class))
     (poo-flow-funflow-list-metadata
      'compensation-refs
      (.ref check 'compensation-refs))
     (poo-flow-funflow-optional-metadata
      'artifact-retention
      (.ref check 'artifact-retention))
     (poo-flow-funflow-list-metadata
      'observes
      (.ref check 'observes))
     (poo-flow-funflow-list-metadata
      'guards
      (.ref check 'guards))
     (poo-flow-funflow-optional-metadata
      'report
      (.ref check 'report))
     metadata)))

;; : (-> PooFlowFunflowCheckPrototype PooFlowCicdCheck)
(def (poo-flow-funflow-poo-check->cicd-check check)
  (poo-flow-funflow-require
   "funflow config object must extend funflow-check"
   (poo-flow-funflow-poo-check? check)
   check)
  (poo-flow-cicd-check
   (.ref check 'check-name)
   (.ref check 'profile-ref)
   (.ref check 'command-vector)
   (.ref check 'input-bindings)
   (.ref check 'config-sources)
   (.ref check 'artifact-outputs)
   (.ref check 'cache-intents)
   (.ref check 'secret-requirements)
   (.ref check 'result-protocol)
   (.ref check 'runtime-mode)
   (poo-flow-funflow-poo-check-metadata check)))

;;; Boundary: funflow poo checks to cicd checks is the policy-visible edge for
;;; policy behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [PooFlowFunflowCheckPrototype] [PooFlowCicdCheck])
(def (poo-flow-funflow-poo-checks->cicd-checks checks)
  (cond
   ((null? checks) '())
   ((pair? checks)
    (cons (poo-flow-funflow-poo-check->cicd-check (car checks))
          (poo-flow-funflow-poo-checks->cicd-checks (cdr checks))))
   (else
    (error "funflow POO pipeline checks slot must be a list" checks))))

;; : (-> PooFlowFunflowPipelinePrototype PooFlowCicdCheckMap)
(def (poo-flow-funflow-poo-pipeline->check-map pipeline)
  (poo-flow-funflow-require
   "funflow config object must extend funflow-pipeline"
   (poo-flow-funflow-poo-pipeline? pipeline)
   pipeline)
  (let ((pipeline-name (.ref pipeline 'pipeline-name))
        (metadata (.ref pipeline 'metadata)))
    (poo-flow-funflow-require
     "funflow POO pipeline metadata must be an alist"
     (list? metadata)
     metadata)
    (poo-flow-cicd-check-map
     pipeline-name
     (poo-flow-funflow-poo-checks->cicd-checks
      (.ref pipeline 'checks))
     (append
      (list (cons 'source 'funflow-poo-config)
            (cons 'pipeline pipeline-name))
      metadata))))

;;; Functional DAGs are Funflow-owned POO objects derived from a pipeline. They
;;; keep the authoring model functional and inspectable while leaving runtime
;;; scheduling to Marlin.
;; : (-> PooFlowCicdCheckMap PooFlowFunflowFunctionalDag)
(def (poo-flow-funflow-check-map->functional-dag check-map)
  (poo-flow-funflow-require
   "funflow functional DAG requires a cicd check-map"
   (poo-flow-cicd-check-map? check-map)
   check-map)
  (let* ((graph (poo-flow-cicd-check-map->dependency-graph check-map))
         (nodes (poo-flow-cicd-alist-ref graph 'nodes '()))
         (edges (poo-flow-funflow-dependency-edges->dag-edges
                 (poo-flow-cicd-alist-ref graph 'edges '())))
         (composition-steps
          (poo-flow-funflow-dag-composition-steps nodes edges)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-funflow-functional-dag-prototype-kind+)
      (cons 'schema 'poo-flow.modules.funflow.functional-dag.v1)
      (cons 'pipeline-name (poo-flow-cicd-check-map-name check-map))
      (cons 'check-map (poo-flow-cicd-check-map-name check-map))
      (cons 'composition-style 'arrow-kleisli)
      (cons 'composition-steps composition-steps)
      (cons 'composition-step-count (length composition-steps))
      (cons 'nodes nodes)
      (cons 'edges edges)
      (cons 'edge-count (length edges))
      (cons 'entry-nodes
            (poo-flow-funflow-entry-nodes nodes edges))
      (cons 'terminal-nodes
            (poo-flow-funflow-terminal-nodes nodes edges))
      (cons 'ready-order
            (poo-flow-cicd-alist-ref graph 'ready-order '()))
      (cons 'unordered-nodes
            (poo-flow-cicd-alist-ref graph 'unordered-nodes '()))
      (cons 'blocked-order?
            (poo-flow-cicd-alist-ref graph 'blocked-order? #f))
      (cons 'diagnostics
            (poo-flow-cicd-alist-ref graph 'diagnostics '()))
      (cons 'valid?
            (poo-flow-cicd-alist-ref graph 'valid? #f))
      (cons 'metadata
            (list (cons 'source 'funflow-functional-kernel)
                  (cons 'dependency-graph-kind
                        (poo-flow-cicd-alist-ref graph 'kind #f))))
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)))))

;; : (-> PooFlowFunflowPipelinePrototype PooFlowFunflowFunctionalDag)
(def (poo-flow-funflow-poo-pipeline->functional-dag pipeline)
  (poo-flow-funflow-check-map->functional-dag
   (poo-flow-funflow-poo-pipeline->check-map pipeline)))

;;; Boundary: funflow poo config pipelines is the policy-visible edge for
;;; policy behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [PooFlowFunflowConfigPrototype] [PooFlowCicdCheckMap])
(def (poo-flow-funflow-poo-config-pipelines prototypes)
  (if (list? prototypes)
    (filter-map poo-flow-funflow-poo-config-pipeline prototypes)
    (error "funflow POO config prototypes must be a list" prototypes)))

;; : (-> PooFlowFunflowConfigPrototype MaybePooFlowCicdCheckMap)
(def (poo-flow-funflow-poo-config-pipeline prototype)
  (and (poo-flow-funflow-poo-pipeline? prototype)
       (poo-flow-funflow-poo-pipeline->check-map prototype)))

;; : (-> [PooFlowFunflowConfigPrototype] Alist [UserModuleFlagEntry])
(def (poo-flow-funflow-poo-config-flags prototypes user-config)
  (let (pipelines (poo-flow-funflow-poo-config-pipelines prototypes))
    (poo-flow-funflow-require
     "funflow POO config must define exactly one funflow-pipeline"
     (= (length pipelines) 1)
     prototypes)
    (poo-flow-funflow-config-flags (car pipelines) user-config)))

;;; Funflow owns the public pipeline object, while workflow/cicd owns the
;;; runtime-command manifest projection shape.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-funflow-pipeline-runtime-command-manifests
      pipeline
      . maybe-profile-catalog)
  (if (null? maybe-profile-catalog)
    (poo-flow-cicd-check-map->runtime-command-manifests pipeline)
    (poo-flow-cicd-check-map->runtime-command-manifests
     pipeline
     (car maybe-profile-catalog))))

;;; Config flags carry both the normal Funflow feature vocabulary and the POO
;;; check-map object. This keeps `use-module` ergonomic while giving downstream
;;; tools a typed object to inspect before runtime handoff.
;; : (-> PooFlowCicdCheckMap Alist [UserModuleFlagEntry])
(def (poo-flow-funflow-config-flags pipeline user-config)
  (list '+functional
        '+dag
        '+typed-receipts
        '+runtime-manifest
        poo-flow-funflow-cicd-default-payload
        (cons ':config (list pipeline))
        (cons ':workflow-pipeline pipeline)
        (cons ':user-config user-config)))

;;; The Funflow module is the default functional DAG flow surface.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-funflow-module-bundles
  (list
   (list
    (poo-flow-user-module-selection
     'flow
     'funflow
     (list '+functional
           '+dag
           '+typed-receipts
           '+runtime-manifest
           poo-flow-funflow-cicd-default-payload)))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-upstream-flow-funflow-module-bundles
  poo-flow-funflow-module-bundles)
