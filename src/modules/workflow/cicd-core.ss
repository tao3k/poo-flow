;;; -*- Gerbil -*-
;;; Boundary: workflow CI/CD POO check and check-map objects.
;;; Invariant: declarations validate shape but never execute commands.

(import (only-in :clan/poo/object .o .ref object? object<-alist)
        (only-in :poo-flow/src/module-system/durable-policy
                 +poo-flow-durable-action-classes+)
        :poo-flow/src/modules/workflow/cicd-projection-syntax)

(export +poo-flow-cicd-check-map-schema+
        +poo-flow-cicd-check-receipt-schema+
        +poo-flow-cicd-pipeline-run-schema+
        +poo-flow-cicd-pipeline-result-schema+
        +poo-flow-cicd-runtime-manifest-readiness-schema+
        +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
        +poo-flow-cicd-marlin-runtime-owner+
        +poo-flow-cicd-marlin-runtime-handoff-abi-fields+
        poo-flow-cicd-check-kind
        poo-flow-cicd-check-map-kind
        poo-flow-cicd-check
        poo-flow-cicd-check?
        poo-flow-cicd-check-map
        poo-flow-cicd-check-map?
        poo-flow-cicd-check-name
        poo-flow-cicd-check-profile
        poo-flow-cicd-check-command
        poo-flow-cicd-check-dependency-refs
        poo-flow-cicd-check-durable-task-id
        poo-flow-cicd-check-action-class
        poo-flow-cicd-check-compensation-refs
        poo-flow-cicd-check-artifact-retention
        poo-flow-cicd-check-artifacts
        poo-flow-cicd-check-cache
        poo-flow-cicd-check-secrets
        poo-flow-cicd-check-runtime
        poo-flow-cicd-check-map-name
        poo-flow-cicd-check-map-checks
        poo-flow-cicd-every?
        poo-flow-cicd-require
        poo-flow-cicd-alist-ref
        poo-flow-cicd-symbol-member?
        poo-flow-cicd-symbol-add)


;; : Symbol
(def +poo-flow-cicd-check-map-schema+
  'poo-flow.modules.workflow.cicd.check-map.v1)

;; : Symbol
(def +poo-flow-cicd-check-receipt-schema+
  'poo-flow.modules.workflow.cicd.check-receipt.v1)

;;; Pipeline-run rows are declarative admission records. They prove ordering
;;; and handoff readiness without claiming a backend executed any check.
;; : Symbol
(def +poo-flow-cicd-pipeline-run-schema+
  'poo-flow.modules.workflow.cicd.pipeline-run.v1)

;;; Pipeline-result rows summarize the declarative run outcome. A successful
;;; result means "ready for Marlin handoff", not "commands completed".
;; : Symbol
(def +poo-flow-cicd-pipeline-result-schema+
  'poo-flow.modules.workflow.cicd.pipeline-result.v1)

;; : Symbol
(def +poo-flow-cicd-runtime-manifest-readiness-schema+
  'poo-flow.modules.workflow.cicd.runtime-manifest-readiness.v1)

;; : Symbol
(def +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
  'poo-flow.workflow.cicd.marlin-runtime-handoff-abi.v1)

;; : String
(def +poo-flow-cicd-marlin-runtime-owner+ "marlin-agent-core")

;; : [Symbol]
(def +poo-flow-cicd-marlin-runtime-handoff-abi-fields+
  '(operation
    request-id
    artifact-handle
    argv
    request
    policy
    plan-id
    node-id
    frontier
    durable-task-id
    action-class
    artifact-refs
    artifact-provenance
    artifact-retention
    sandbox-refs
    checkpoint-ref
    compensation-refs
    runtime-owner
    handoff-required
    runtime-executed))

;; : (-> Unit Symbol)
(def (poo-flow-cicd-check-kind)
  'poo-flow.workflow.cicd.check)

;; : (-> Unit Symbol)
(def (poo-flow-cicd-check-map-kind)
  'poo-flow.workflow.cicd.check-map)

;;; Keep local validation small and structural: the check-map object is allowed
;;; to reference runtime-owned profiles, but it must not normalize them here.
;; : (forall (a) (-> (-> a Boolean) (List a) Boolean))
(def (poo-flow-cicd-every? pred values)
  (cond
   ((null? values) #t)
   ((pair? values)
    (and (pred (car values))
         (poo-flow-cicd-every? pred (cdr values))))
   (else #f)))

;;; Validation failures are programmer errors at the declarative object boundary.
;;; Runtime failures belong to the later adapter that consumes the manifest.
;; : (-> String Boolean Value Void)
(def (poo-flow-cicd-require message ok? value)
  (if ok?
    (void)
    (error message value)))

;;; Profile refs may be a symbol, a POO object, or a nested inheritance list.
;;; This validator keeps that shape declarative and avoids resolving profiles.
;; : (-> PooFlowCicdProfileRefCandidate Boolean)
(def (poo-flow-cicd-profile-ref? value)
  (or (symbol? value)
      (object? value)
      (and (pair? value)
           (list? value)
           (poo-flow-cicd-every? poo-flow-cicd-profile-ref? value))))

;;; Commands must be non-empty argv vectors because runtime adapters consume
;;; an executable plus arguments, not a shell string.
;; : (-> PooFlowCicdCommandCandidate Boolean)
(def (poo-flow-cicd-command-vector? value)
  (and (pair? value)
       (list? value)
       (poo-flow-cicd-every? string? value)))

;;; List slot validation is deliberately structural. Semantic meaning for
;;; inputs, cache, secrets, and results is owned by later runtime projections.
;; : (-> String PooFlowCicdListCandidate Void)
(def (poo-flow-cicd-require-list field value)
  (poo-flow-cicd-require
   (string-append "cicd check " field " must be a list")
   (list? value)
   value))

;;; Constructor slot names are namespace-qualified to avoid Gerbil POO internal
;;; collisions such as =name= and =command= while keeping receipt fields simple.
;; : (-> Symbol PooFlowCicdProfileRef [String] List List List List List List Symbol PooFlowCicdCheck)
(def (poo-flow-cicd-check name
                          profile
                          command
                          inputs
                          config
                          artifacts
                          cache
                          secrets
                          result
                          runtime
                          . maybe-metadata)
  (poo-flow-cicd-require "cicd check name must be a symbol"
                         (symbol? name)
                         name)
  (poo-flow-cicd-require "cicd check profile must be a symbol, POO object, or non-empty list of refs"
                         (poo-flow-cicd-profile-ref? profile)
                         profile)
  (poo-flow-cicd-require "cicd check command must be a non-empty string list"
                         (poo-flow-cicd-command-vector? command)
                         command)
  (poo-flow-cicd-require-list "inputs" inputs)
  (poo-flow-cicd-require-list "config" config)
  (poo-flow-cicd-require-list "artifacts" artifacts)
  (poo-flow-cicd-require-list "cache" cache)
  (poo-flow-cicd-require-list "secrets" secrets)
  (poo-flow-cicd-require-list "result" result)
  (poo-flow-cicd-require "cicd check runtime must be a symbol"
                         (symbol? runtime)
                         runtime)
  (object<-alist
   (poo-flow-cicd-field-rows
    (kind (poo-flow-cicd-check-kind))
    (schema +poo-flow-cicd-check-map-schema+)
    (check-name name)
    (profile-ref profile)
    (command-vector command)
    (input-bindings inputs)
    (config-sources config)
    (artifact-outputs artifacts)
    (cache-intents cache)
    (secret-requirements secrets)
    (result-protocol result)
    (runtime-mode runtime)
    (runtime-executed #f)
    (metadata (if (null? maybe-metadata) '() (car maybe-metadata))))))

;;; Check predicates verify the public POO kind slot only. They do not inspect
;;; command or sandbox semantics, which stay in constructor validation.
;; : (-> PooFlowCicdCheckCandidate Boolean)
(def (poo-flow-cicd-check? value)
  (and (object? value)
       (eq? (.ref value 'kind) (poo-flow-cicd-check-kind))))

;; : (-> PooFlowCicdCheck Symbol)
(def (poo-flow-cicd-check-name check)
  (.ref check 'check-name))

;; : (-> PooFlowCicdCheck PooFlowCicdProfileRef)
(def (poo-flow-cicd-check-profile check)
  (.ref check 'profile-ref))

;; : (-> PooFlowCicdCheck [String])
(def (poo-flow-cicd-check-command check)
  (.ref check 'command-vector))

;;; CI/CD dependency refs are local check names; sandbox/profile inheritance
;;; stays in the profile-ref path instead of overloading graph edges.
;; : (-> [PooFlowCicdDependencyRefCandidate] Boolean)
(def (poo-flow-cicd-symbol-list? values)
  (and (list? values)
       (poo-flow-cicd-every? symbol? values)))

;;; Alist lookup is total so invalid or partial pipeline declarations can still
;;; produce diagnostics instead of aborting graph projection.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-cicd-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default)))

;;; Dependencies are graph intent, not execution order. They are carried in
;;; metadata so older check constructors remain source-compatible while Funflow
;;; can lower `:needs` into explicit DAG edges.
;; : (-> PooFlowCicdCheck [Symbol])
(def (poo-flow-cicd-check-dependency-refs check)
  (let (refs (poo-flow-cicd-alist-ref (.ref check 'metadata)
                                       'dependency-refs
                                       '()))
    (poo-flow-cicd-require
     "cicd check dependency-refs must be a list of symbols"
     (poo-flow-cicd-symbol-list? refs)
     refs)
    refs))

;; : (-> PooFlowCicdCheck Symbol)
(def (poo-flow-cicd-check-durable-task-id check)
  (let (task-id (poo-flow-cicd-alist-ref (.ref check 'metadata)
                                         'durable-task-id
                                         (poo-flow-cicd-check-name check)))
    (poo-flow-cicd-require
     "cicd check durable-task-id must be a symbol"
     (symbol? task-id)
     task-id)
    task-id))

;; : (-> PooFlowCicdCheck Symbol)
(def (poo-flow-cicd-check-action-class check)
  (let (action-class (poo-flow-cicd-alist-ref (.ref check 'metadata)
                                             'action-class
                                             'idempotent))
    (poo-flow-cicd-require
     "cicd check action-class must be a known durable action class"
     (and (symbol? action-class)
          (member action-class +poo-flow-durable-action-classes+))
     action-class)
    action-class))

;; : (-> PooFlowCicdCheck [Symbol])
(def (poo-flow-cicd-check-compensation-refs check)
  (let (refs (poo-flow-cicd-alist-ref (.ref check 'metadata)
                                      'compensation-refs
                                      '()))
    (poo-flow-cicd-require
     "cicd check compensation-refs must be a list of symbols"
     (poo-flow-cicd-symbol-list? refs)
     refs)
    refs))

;; : (-> PooFlowCicdCheck Symbol)
(def (poo-flow-cicd-check-artifact-retention check)
  (let (retention (poo-flow-cicd-alist-ref (.ref check 'metadata)
                                           'artifact-retention
                                           'workflow-retained))
    (poo-flow-cicd-require
     "cicd check artifact-retention must be a symbol"
     (symbol? retention)
     retention)
    retention))

;; : (-> PooFlowCicdCheck List)
(def (poo-flow-cicd-check-artifacts check)
  (.ref check 'artifact-outputs))

;; : (-> PooFlowCicdCheck List)
(def (poo-flow-cicd-check-cache check)
  (.ref check 'cache-intents))

;; : (-> PooFlowCicdCheck List)
(def (poo-flow-cicd-check-secrets check)
  (.ref check 'secret-requirements))

;; : (-> PooFlowCicdCheck Symbol)
(def (poo-flow-cicd-check-runtime check)
  (.ref check 'runtime-mode))

;;; A check-map keeps checks as POO objects so later module objects can extend
;;; them by inheritance before this projection layer emits receipts.
;; : (-> Symbol [PooFlowCicdCheck] PooFlowCicdCheckMap)
(def (poo-flow-cicd-check-map name checks . maybe-metadata)
  (poo-flow-cicd-require "cicd check-map name must be a symbol"
                         (symbol? name)
                         name)
  (poo-flow-cicd-require "cicd check-map checks must be a list"
                         (list? checks)
                         checks)
  (poo-flow-cicd-require "cicd check-map checks must contain only cicd checks"
                         (poo-flow-cicd-every? poo-flow-cicd-check? checks)
                         checks)
  (.o kind: (poo-flow-cicd-check-map-kind)
      schema: +poo-flow-cicd-check-map-schema+
      map-name: name
      check-objects: checks
      runtime-executed: #f
      metadata: (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> PooFlowCicdCheckMapCandidate Boolean)
(def (poo-flow-cicd-check-map? value)
  (and (object? value)
       (eq? (.ref value 'kind) (poo-flow-cicd-check-map-kind))))

;; : (-> PooFlowCicdCheckMap Symbol)
(def (poo-flow-cicd-check-map-name check-map)
  (.ref check-map 'map-name))

;; : (-> PooFlowCicdCheckMap [PooFlowCicdCheck])
(def (poo-flow-cicd-check-map-checks check-map)
  (.ref check-map 'check-objects))

;;; Symbol membership normalizes `member` results to Boolean facts for
;;; dependency and profile ref diagnostics.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-cicd-symbol-member? value values)
  (and (member value values) #t))

;;; Symbol add preserves declaration order and keeps duplicate diagnostics
;;; deterministic without switching to a hash set.
;; : (-> Symbol [Symbol] [Symbol])
(def (poo-flow-cicd-symbol-add value values)
  (if (poo-flow-cicd-symbol-member? value values)
    values
    (poo-flow-cicd-rows/tail values (list value))))
