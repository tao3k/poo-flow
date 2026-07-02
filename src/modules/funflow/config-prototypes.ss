;;; -*- Gerbil -*-
;;; Boundary: Funflow POO prototype families.
;;; Invariant: this owner declares static prototype slots and predicates only.

(import (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/config-prototype-syntax)

(export funflow-check
        funflow-pipeline
        funflow-dag-edge
        funflow-composition-step
        funflow-functional-dag
        poo-flow-funflow-poo-check?
        poo-flow-funflow-poo-pipeline?
        poo-flow-funflow-dag-edge?
        poo-flow-funflow-composition-step?
        poo-flow-funflow-functional-dag?
        +poo-flow-funflow-check-prototype-kind+
        +poo-flow-funflow-pipeline-prototype-kind+
        +poo-flow-funflow-dag-edge-prototype-kind+
        +poo-flow-funflow-composition-step-prototype-kind+
        +poo-flow-funflow-functional-dag-prototype-kind+)

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
