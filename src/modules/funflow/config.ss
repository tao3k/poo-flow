;;; -*- Gerbil -*-
;;; Boundary: Funflow module configuration belongs to the Funflow module owner.
;;; Invariant: this file only declares maintained Funflow module rows.

(import (only-in :clan/poo/object .ref object<-alist)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/projection-syntax
        (only-in :poo-flow/src/modules/workflow/cicd-core
                 poo-flow-cicd-alist-ref
                 poo-flow-cicd-symbol-member?)
        :poo-flow/src/modules/funflow/config-prototypes
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
     (poo-flow-module-field-rows
      (field 'workflow-ref)
      (code 'missing-funflow-workflow-pipeline)
      (workflow-ref workflow-ref))))
   (else '())))

;; : (-> [PooFlowCicdCheckMap] Alist)
(def (poo-flow-funflow-workflow-agreement-summary check-maps)
  (poo-flow-module-field-rows
   (pipeline-count (length check-maps))
   (pipeline-names (map poo-flow-cicd-check-map-name check-maps))
   (functional-dag-rows
    (map (lambda (check-map)
           (poo-flow-funflow-functional-dag->alist
            (poo-flow-funflow-check-map->functional-dag check-map)))
         check-maps))))

;;; The agreement is report-only data that lets loop-engine handoff receipts
;;; prove whether a workflow ref is backed by a Funflow-owned pipeline.
;; : (-> Symbol [PooFlowCicdCheckMap] Alist)
(def (poo-flow-funflow-workflow-agreement workflow-ref check-maps)
  (let* ((diagnostics
          (poo-flow-funflow-workflow-agreement-diagnostics
           workflow-ref
           check-maps))
         (summary
          (poo-flow-funflow-workflow-agreement-summary check-maps))
         (functional-dag-rows
          (poo-flow-cicd-alist-ref summary 'functional-dag-rows '())))
    (poo-flow-module-field-rows
     (kind 'funflow-workflow-agreement)
     (contract +poo-flow-funflow-workflow-agreement-contract+)
     (workflow-ref workflow-ref)
     (funflow-owned? (poo-flow-funflow-workflow-ref? workflow-ref))
     (pipeline-count
      (poo-flow-cicd-alist-ref summary 'pipeline-count 0))
     (pipeline-names
      (poo-flow-cicd-alist-ref summary 'pipeline-names '()))
     (functional-dag-count (length functional-dag-rows))
     (functional-dags functional-dag-rows)
     (diagnostic-count (length diagnostics))
     (diagnostics diagnostics)
     (valid? (null? diagnostics))
     (runtime-owner "marlin-agent-core")
     (runtime-executed #f))))

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

;;; Boundary: funflow optional metadata is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (forall (a) (-> Symbol a [Pair] [Pair]))
(def (poo-flow-funflow-optional-metadata/tail key value tail)
  (if value
    (cons (cons key value) tail)
    tail))

;;; Boundary: funflow list metadata is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Symbol List [Pair] [Pair])
(def (poo-flow-funflow-list-metadata/tail key values tail)
  (if (null? values)
    tail
    (cons (cons key values) tail)))

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

;; : (-> [PooFlowFunflowDagEdge] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-funflow-dag-edges->alists (edges)
  (projector poo-flow-funflow-dag-edge->alist)
  (error-message "funflow DAG edge projection requires a list"))

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

;; : (-> [PooFlowFunflowCompositionStep] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-funflow-composition-steps->alists (steps)
  (projector poo-flow-funflow-composition-step->alist)
  (error-message "funflow composition step projection requires a list"))

;; : (-> [PooFlowFunflowDagEdge] [Symbol] [Symbol] Pair)
(def (poo-flow-funflow-edge-endpoint-summary/rev edges sources-rev targets-rev)
  (if (null? edges)
    (cons (reverse sources-rev) (reverse targets-rev))
    (poo-flow-funflow-edge-endpoint-summary/rev
     (cdr edges)
     (cons (.ref (car edges) 'from) sources-rev)
     (cons (.ref (car edges) 'to) targets-rev))))

;; : (-> [PooFlowFunflowDagEdge] Alist)
(def (poo-flow-funflow-edge-endpoint-summary edges)
  (let (summary
        (poo-flow-funflow-edge-endpoint-summary/rev edges '() '()))
    (list
     (cons 'sources (car summary))
     (cons 'targets (cdr summary)))))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-funflow-nodes-not-in nodes blocked-nodes)
  (cond
   ((null? nodes) '())
   ((poo-flow-cicd-symbol-member? (car nodes) blocked-nodes)
    (poo-flow-funflow-nodes-not-in (cdr nodes) blocked-nodes))
   (else
    (cons (car nodes)
          (poo-flow-funflow-nodes-not-in (cdr nodes) blocked-nodes)))))

;; : (-> Alist PooFlowFunflowDagEdge)
(def (poo-flow-funflow-dependency-edge->dag-edge edge)
  (poo-flow-funflow-dag-edge
   (poo-flow-cicd-alist-ref edge 'from #f)
   (poo-flow-cicd-alist-ref edge 'to #f)
   (poo-flow-module-field-rows
    (source 'workflow-cicd-dependency-graph))))

;; : (-> [Alist] [PooFlowFunflowDagEdge])
(def (poo-flow-funflow-dependency-edges->dag-edges edges)
  (cond
   ((null? edges) '())
   ((pair? edges)
    (cons (poo-flow-funflow-dependency-edge->dag-edge (car edges))
          (poo-flow-funflow-dependency-edges->dag-edges (cdr edges))))
   (else
    (error "funflow dependency edges must be a list" edges))))

;; : (-> Symbol PooFlowFunflowCompositionStep)
(def (poo-flow-funflow-node->composition-step node)
  (poo-flow-funflow-composition-step
   'arrow-node
   node
   #f
   #f
   (poo-flow-module-field-rows
    (source 'funflow-functional-kernel))))

;; : (-> PooFlowFunflowDagEdge PooFlowFunflowCompositionStep)
(def (poo-flow-funflow-edge->composition-step edge)
  (poo-flow-funflow-composition-step
   'kleisli-bind
   #f
   (.ref edge 'from)
   (.ref edge 'to)
   (poo-flow-module-field-rows
    (source 'funflow-functional-kernel)
    (edge-composition-style
     (.ref edge 'composition-style)))))

;; : (-> [Symbol] [PooFlowFunflowCompositionStep] [PooFlowFunflowCompositionStep])
(def (poo-flow-funflow-node-composition-steps/rev nodes steps-rev)
  (if (null? nodes)
    steps-rev
    (poo-flow-funflow-node-composition-steps/rev
     (cdr nodes)
     (cons (poo-flow-funflow-node->composition-step (car nodes))
           steps-rev))))

;; : (-> [PooFlowFunflowDagEdge] [PooFlowFunflowCompositionStep] [PooFlowFunflowCompositionStep])
(def (poo-flow-funflow-edge-composition-steps/rev edges steps-rev)
  (if (null? edges)
    steps-rev
    (poo-flow-funflow-edge-composition-steps/rev
     (cdr edges)
     (cons (poo-flow-funflow-edge->composition-step (car edges))
           steps-rev))))

;; : (-> [Symbol] [PooFlowFunflowDagEdge] [PooFlowFunflowCompositionStep])
(def (poo-flow-funflow-dag-composition-steps nodes edges)
  (reverse
   (poo-flow-funflow-edge-composition-steps/rev
    edges
    (poo-flow-funflow-node-composition-steps/rev nodes '()))))

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
            (poo-flow-funflow-composition-steps->alists
             (.ref dag 'composition-steps)))
           (composition-step-count
            (.ref dag 'composition-step-count))
           (nodes (.ref dag 'nodes))
           (edges
            (poo-flow-funflow-dag-edges->alists
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
    (cons (cons 'source 'funflow-poo-prototype)
          (cons (cons 'check (.ref check 'check-name))
                (cons (cons 'dependency-refs dependency-refs)
                      (poo-flow-funflow-optional-metadata/tail
                       'observability
                       (.ref check 'observability)
                       (poo-flow-funflow-optional-metadata/tail
                        'durable-task-id
                        (.ref check 'durable-task-id)
                        (poo-flow-funflow-optional-metadata/tail
                         'action-class
                         (.ref check 'action-class)
                         (poo-flow-funflow-list-metadata/tail
                          'compensation-refs
                          (.ref check 'compensation-refs)
                          (poo-flow-funflow-optional-metadata/tail
                           'artifact-retention
                           (.ref check 'artifact-retention)
                           (poo-flow-funflow-list-metadata/tail
                            'observes
                            (.ref check 'observes)
                            (poo-flow-funflow-list-metadata/tail
                             'guards
                             (.ref check 'guards)
                             (poo-flow-funflow-optional-metadata/tail
                              'report
                              (.ref check 'report)
                              metadata)))))))))))))

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
     (poo-flow-module-field-rows/tail
      metadata
      (source 'funflow-poo-config)
      (pipeline pipeline-name)))))

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
          (poo-flow-funflow-dag-composition-steps nodes edges))
         (endpoint-summary
          (poo-flow-funflow-edge-endpoint-summary edges)))
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
            (poo-flow-funflow-nodes-not-in
             nodes
             (poo-flow-cicd-alist-ref endpoint-summary 'targets '())))
      (cons 'terminal-nodes
            (poo-flow-funflow-nodes-not-in
             nodes
             (poo-flow-cicd-alist-ref endpoint-summary 'sources '())))
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
            (poo-flow-module-field-rows
             (source 'funflow-functional-kernel)
             (dependency-graph-kind
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
;; : (-> [PooFlowFunflowConfigPrototype] [PooFlowCicdCheckMap] [PooFlowCicdCheckMap])
(def (poo-flow-funflow-poo-config-pipelines/rev prototypes pipelines-rev)
  (if (null? prototypes)
    pipelines-rev
    (let (pipeline
          (poo-flow-funflow-poo-config-pipeline (car prototypes)))
      (poo-flow-funflow-poo-config-pipelines/rev
       (cdr prototypes)
       (if pipeline
         (cons pipeline pipelines-rev)
         pipelines-rev)))))

;; : (-> [PooFlowFunflowConfigPrototype] [PooFlowCicdCheckMap])
(def (poo-flow-funflow-poo-config-pipelines prototypes)
  (if (list? prototypes)
    (reverse (poo-flow-funflow-poo-config-pipelines/rev prototypes '()))
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
