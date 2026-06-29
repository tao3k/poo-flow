;;; -*- Gerbil -*-
;;; Boundary: Funflow module configuration belongs to the Funflow module owner.
;;; Invariant: this file only declares maintained Funflow module rows.

(import (only-in :std/sugar filter-map)
        (only-in :clan/poo/object .o .ref .slot? object? object<-alist)
        :poo-flow/src/module-system/base
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

;; : PooFlowFunflowCheckPrototype
(def funflow-check
  (object<-alist
   (list
    (cons 'kind +poo-flow-funflow-check-prototype-kind+)
    (cons 'check-name #f)
    (cons 'profile-ref #f)
    (cons 'command-vector '())
    (cons 'input-bindings '())
    (cons 'config-sources '())
    (cons 'artifact-outputs '())
    (cons 'cache-intents '())
    (cons 'secret-requirements '())
    (cons 'result-protocol '())
    (cons 'runtime-mode 'manifest-handoff)
    (cons 'dependency-refs '())
    (cons 'observability #f)
    (cons 'observes '())
    (cons 'guards '())
    (cons 'report #f)
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : PooFlowFunflowPipelinePrototype
(def funflow-pipeline
  (.o kind: +poo-flow-funflow-pipeline-prototype-kind+
      pipeline-name: #f
      checks: '()
      metadata: '()
      runtime-executed: #f))

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
  (let ((diagnostics
         (poo-flow-funflow-workflow-agreement-diagnostics
          workflow-ref
          check-maps)))
    (list
     (cons 'kind 'funflow-workflow-agreement)
     (cons 'contract +poo-flow-funflow-workflow-agreement-contract+)
     (cons 'workflow-ref workflow-ref)
     (cons 'funflow-owned? (poo-flow-funflow-workflow-ref? workflow-ref))
     (cons 'pipeline-count (length check-maps))
     (cons 'pipeline-names (poo-flow-funflow-check-map-names check-maps))
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
(def (poo-flow-funflow-poo-check? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-funflow-check-prototype-kind+)))

;; : (-> POOObject Boolean)
(def (poo-flow-funflow-poo-pipeline? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-funflow-pipeline-prototype-kind+)))

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
