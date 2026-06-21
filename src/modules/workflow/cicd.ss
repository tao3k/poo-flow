;;; -*- Gerbil -*-
;;; Boundary: CI/CD check maps are workflow control-plane objects.
;;; Invariant: this module projects receipts and runtime handoff readiness only;
;;; it never executes commands or binds a backend adapter.

(import (only-in :clan/poo/object .o .ref object?)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile?
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-name
                 poo-flow-sandbox-profile-runtime-summary))

(export +poo-flow-cicd-check-map-schema+
        +poo-flow-cicd-check-receipt-schema+
        +poo-flow-cicd-runtime-manifest-readiness-schema+
        +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
        +poo-flow-cicd-marlin-runtime-owner+
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
        poo-flow-cicd-check-artifacts
        poo-flow-cicd-check-cache
        poo-flow-cicd-check-secrets
        poo-flow-cicd-check-runtime
        poo-flow-cicd-check-map-name
        poo-flow-cicd-check-map-checks
        poo-flow-cicd-check-profile-refs
        poo-flow-cicd-check-sandbox-runtime-summaries
        poo-flow-cicd-check-sandbox-handoff-summaries
        poo-flow-cicd-check-sandbox-unresolved-profile-refs
        poo-flow-cicd-check-map->dependency-graph
        poo-flow-cicd-check->receipt
        poo-flow-cicd-check-map->receipts
        poo-flow-cicd-check->runtime-manifest-readiness
        poo-flow-cicd-check-map->runtime-manifest-readiness
        poo-flow-cicd-check->runtime-command-manifest
        poo-flow-cicd-check-map->runtime-command-manifests
        poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
        poo-flow-cicd-check-map->marlin-runtime-handoff-abi)

;; : Symbol
(def +poo-flow-cicd-check-map-schema+
  'poo-flow.modules.workflow.cicd.check-map.v1)

;; : Symbol
(def +poo-flow-cicd-check-receipt-schema+
  'poo-flow.modules.workflow.cicd.check-receipt.v1)

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

;; : (-> PooFlowCicdProfileRefCandidate Boolean)
(def (poo-flow-cicd-profile-ref? value)
  (or (symbol? value)
      (object? value)
      (and (pair? value)
           (list? value)
           (poo-flow-cicd-every? poo-flow-cicd-profile-ref? value))))

;; : (-> PooFlowCicdCommandCandidate Boolean)
(def (poo-flow-cicd-command-vector? value)
  (and (pair? value)
       (list? value)
       (poo-flow-cicd-every? string? value)))

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
  (.o kind: (poo-flow-cicd-check-kind)
      schema: +poo-flow-cicd-check-map-schema+
      check-name: name
      profile-ref: profile
      command-vector: command
      input-bindings: inputs
      config-sources: config
      artifact-outputs: artifacts
      cache-intents: cache
      secret-requirements: secrets
      result-protocol: result
      runtime-mode: runtime
      runtime-executed: #f
      metadata: (if (null? maybe-metadata) '() (car maybe-metadata))))

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

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-cicd-symbol-member? value values)
  (and (member value values) #t))

;; : (-> Symbol [Symbol] [Symbol])
(def (poo-flow-cicd-symbol-add value values)
  (if (poo-flow-cicd-symbol-member? value values)
    values
    (append values (list value))))

;; : (-> PooFlowCicdProfileRef [Symbol] [Symbol])
(def (poo-flow-cicd-profile-refs/add profile refs)
  (cond
   ((symbol? profile)
    (poo-flow-cicd-symbol-add profile refs))
   ((poo-flow-sandbox-profile? profile)
    (poo-flow-cicd-symbol-add
     (poo-flow-sandbox-profile-name profile)
     refs))
   ((and (pair? profile) (list? profile))
    (poo-flow-cicd-profile-refs/list-add profile refs))
   (else refs)))

;; : (-> [PooFlowCicdProfileRef] [Symbol] [Symbol])
(def (poo-flow-cicd-profile-refs/list-add profiles refs)
  (cond
   ((null? profiles) refs)
   (else
    (poo-flow-cicd-profile-refs/list-add
     (cdr profiles)
     (poo-flow-cicd-profile-refs/add (car profiles) refs)))))

;; : (-> PooFlowCicdCheck [Symbol])
(def (poo-flow-cicd-check-profile-refs check)
  (poo-flow-cicd-profile-refs/add (poo-flow-cicd-check-profile check) '()))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] MaybePooSandboxProfile)
(def (poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
  (cond
   ((poo-flow-sandbox-profile? profile) profile)
   ((symbol? profile)
    (poo-flow-sandbox-profile-by-name profile-catalog profile))
   (else #f)))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-runtime-summaries profile profile-catalog)
  (cond
   ((and (pair? profile) (list? profile))
    (apply append
           (map (lambda (profile-ref)
                  (poo-flow-cicd-profile-runtime-summaries
                   profile-ref
                   profile-catalog))
                profile)))
   ((poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
    => (lambda (sandbox-profile)
         (list (poo-flow-sandbox-profile-runtime-summary sandbox-profile))))
   (else '())))

;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-sandbox-runtime-summaries check
                                                    . maybe-profile-catalog)
  (poo-flow-cicd-profile-runtime-summaries
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-handoff-summaries profile profile-catalog)
  (cond
   ((and (pair? profile) (list? profile))
    (apply append
           (map (lambda (profile-ref)
                  (poo-flow-cicd-profile-handoff-summaries
                   profile-ref
                   profile-catalog))
                profile)))
   ((poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
    => (lambda (sandbox-profile)
         (list (poo-flow-sandbox-profile-handoff-summary sandbox-profile))))
   (else '())))

;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-sandbox-handoff-summaries check
                                                    . maybe-profile-catalog)
  (poo-flow-cicd-profile-handoff-summaries
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Symbol])
(def (poo-flow-cicd-profile-unresolved-refs profile profile-catalog)
  (cond
   ((symbol? profile)
    (if (poo-flow-sandbox-profile-by-name profile-catalog profile)
      '()
      (list profile)))
   ((poo-flow-sandbox-profile? profile) '())
   ((and (pair? profile) (list? profile))
    (apply append
           (map (lambda (profile-ref)
                  (poo-flow-cicd-profile-unresolved-refs
                   profile-ref
                   profile-catalog))
                profile)))
   (else '())))

;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Symbol])
(def (poo-flow-cicd-check-sandbox-unresolved-profile-refs
      check
      . maybe-profile-catalog)
  (poo-flow-cicd-profile-unresolved-refs
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;;; Runtime readiness is a manifest-shaped promise. It is deliberately not a
;;; RuntimeCommandDescriptor because CI checks still need a sandbox/runtime owner
;;; to materialize the command envelope.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check->runtime-manifest-readiness check
                                                        . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime manifest readiness requires a cicd check"
                         (poo-flow-cicd-check? check)
                         check)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (list (cons 'schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.runtime-manifest-ready)
          (cons 'check (poo-flow-cicd-check-name check))
          (cons 'profile (poo-flow-cicd-check-profile check))
          (cons 'profile-refs (poo-flow-cicd-check-profile-refs check))
          (cons 'dependency-refs
                (poo-flow-cicd-check-dependency-refs check))
          (cons 'sandbox-runtime-summaries
                (poo-flow-cicd-check-sandbox-runtime-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-handoff-summaries
                (poo-flow-cicd-check-sandbox-handoff-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-unresolved-profile-refs
                (poo-flow-cicd-check-sandbox-unresolved-profile-refs
                 check
                 profile-catalog))
          (cons 'runtime (poo-flow-cicd-check-runtime check))
          (cons 'runtime-executed #f)
          (cons 'handoff-required #t)
          (cons 'command (poo-flow-cicd-check-command check))
          (cons 'argv (poo-flow-cicd-check-command check))
          (cons 'inputs (.ref check 'input-bindings))
          (cons 'config (.ref check 'config-sources))
          (cons 'artifacts (poo-flow-cicd-check-artifacts check))
          (cons 'cache (poo-flow-cicd-check-cache check))
          (cons 'secrets (poo-flow-cicd-check-secrets check))
          (cons 'result (.ref check 'result-protocol)))))

;;; The runtime command bridge intentionally consumes readiness data instead of
;;; executing it: Scheme produces the same manifest shape that runtime adapters
;;; already understand, while Marlin/Rust remains the process owner.
;; : (-> PooFlowCicdCheck Alist RuntimeCommandDescriptor)
(def (poo-flow-cicd-check-runtime-command-descriptor check readiness)
  (let (command (poo-flow-cicd-check-command check))
    (make-runtime-command-descriptor
     (poo-flow-cicd-check-name check)
     (car command)
     (cdr command)
     (.ref check 'result-protocol)
     (list (cons 'source 'poo-flow.workflow.cicd.check)
           (cons 'check (poo-flow-cicd-check-name check))
           (cons 'profile (poo-flow-cicd-check-profile check))
           (cons 'profile-refs
                 (poo-flow-cicd-check-profile-refs check))
           (cons 'dependency-refs
                 (poo-flow-cicd-check-dependency-refs check))
           (cons 'runtime (poo-flow-cicd-check-runtime check))
           (cons 'runtime-executed #f)
           (cons 'handoff-required #t)
           (cons 'artifacts (poo-flow-cicd-check-artifacts check))
           (cons 'cache (poo-flow-cicd-check-cache check))
          (cons 'secrets (poo-flow-cicd-check-secrets check))
          (cons 'readiness readiness)))))

;;; The envelope is intentionally the smallest runtime request shape: it names
;;; the workflow operation and carries readiness as data, while leaving plan and
;;; frontier fields inert until a real scheduler supplies them.
;; : (-> PooFlowCicdCheck Alist Alist)
(def (poo-flow-cicd-check-runtime-command-envelope check readiness)
  (list (cons 'schema +runtime-request-schema+)
        (cons 'operation 'workflow-cicd-check)
        (cons 'request-id
              (list 'poo-flow.workflow.cicd
                    (poo-flow-cicd-check-name check)))
        (cons 'artifact-handle (poo-flow-cicd-check-artifacts check))
        (cons 'request readiness)
        (cons 'policy
              (list (cons 'runtime (poo-flow-cicd-check-runtime check))
                    (cons 'dependency-refs
                          (poo-flow-cicd-check-dependency-refs check))
                    (cons 'runtime-executed #f)
                    (cons 'handoff-required #t)))
        (cons 'plan-id #f)
        (cons 'node-id (poo-flow-cicd-check-name check))
        (cons 'frontier '())))

;;; Public manifest projection is the handoff boundary for one check. It
;;; validates the POO check, reuses the readiness projector, and delegates final
;;; manifest shape to core runtime-adapter helpers instead of duplicating them.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check->runtime-command-manifest check
                                                     . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime command manifest requires a cicd check"
                         (poo-flow-cicd-check? check)
                         check)
  (let* ((profile-catalog (if (null? maybe-profile-catalog)
                            '()
                            (car maybe-profile-catalog)))
         (readiness
          (poo-flow-cicd-check->runtime-manifest-readiness
           check
           profile-catalog))
         (descriptor
          (poo-flow-cicd-check-runtime-command-descriptor check readiness))
         (envelope
          (poo-flow-cicd-check-runtime-command-envelope check readiness)))
    (runtime-command-descriptor->manifest descriptor envelope)))

;;; Receipts are normalized alists so Rust/Marlin can consume them without
;;; knowing the Gerbil POO object representation.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check->receipt check . maybe-profile-catalog)
  (poo-flow-cicd-require "cicd receipt requires a cicd check"
                         (poo-flow-cicd-check? check)
                         check)
  (let* ((profile-catalog (if (null? maybe-profile-catalog)
                            '()
                            (car maybe-profile-catalog)))
         (runtime-ready
          (poo-flow-cicd-check->runtime-manifest-readiness
           check
           profile-catalog)))
    (list (cons 'schema +poo-flow-cicd-check-receipt-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.check-receipt)
          (cons 'check (poo-flow-cicd-check-name check))
          (cons 'profile (poo-flow-cicd-check-profile check))
          (cons 'profile-refs
                (poo-flow-cicd-check-profile-refs check))
          (cons 'dependency-refs
                (poo-flow-cicd-check-dependency-refs check))
          (cons 'sandbox-runtime-summaries
                (poo-flow-cicd-check-sandbox-runtime-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-handoff-summaries
                (poo-flow-cicd-check-sandbox-handoff-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-unresolved-profile-refs
                (poo-flow-cicd-check-sandbox-unresolved-profile-refs
                 check
                 profile-catalog))
          (cons 'command (poo-flow-cicd-check-command check))
          (cons 'inputs (.ref check 'input-bindings))
          (cons 'config (.ref check 'config-sources))
          (cons 'artifacts (poo-flow-cicd-check-artifacts check))
          (cons 'cache (poo-flow-cicd-check-cache check))
          (cons 'secrets (poo-flow-cicd-check-secrets check))
          (cons 'result (.ref check 'result-protocol))
          (cons 'runtime (poo-flow-cicd-check-runtime check))
          (cons 'runtime-executed #f)
          (cons 'status 'ready)
          (cons 'runtime-manifest-ready runtime-ready))))

;;; Node names are kept in declaration order so diagnostics line up with the
;;; user-authored pipeline instead of a derived scheduler order.
;; : (-> [PooFlowCicdCheck] [Symbol])
(def (poo-flow-cicd-checks-names checks)
  (map poo-flow-cicd-check-name checks))

;;; Duplicate names make dependency refs ambiguous, so the graph reports them
;;; before any downstream scheduler tries to interpret edges.
;; : (-> [Symbol] [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-duplicate-symbols/fold names seen duplicates)
  (cond
   ((null? names) duplicates)
   ((poo-flow-cicd-symbol-member? (car names) seen)
    (poo-flow-cicd-duplicate-symbols/fold
     (cdr names)
     seen
     (poo-flow-cicd-symbol-add (car names) duplicates)))
   (else
    (poo-flow-cicd-duplicate-symbols/fold
     (cdr names)
     (poo-flow-cicd-symbol-add (car names) seen)
     duplicates))))

;; : (-> [Symbol] [Symbol])
(def (poo-flow-cicd-duplicate-symbols names)
  (poo-flow-cicd-duplicate-symbols/fold names '() '()))

;;; Dependency graph projection must work for empty declarative pipelines too;
;;; the runtime scheduler is downstream, so this layer only flattens facts.
;; : (-> (-> PooFlowCicdCheck List) [PooFlowCicdCheck] List)
(def (poo-flow-cicd-append-map proc values)
  (if (null? values)
    '()
    (apply append (map proc values))))

;; : (-> PooFlowCicdCheck [Symbol] [Symbol])
(def (poo-flow-cicd-check-unresolved-dependency-refs check check-names)
  (filter (lambda (dependency-ref)
            (not (poo-flow-cicd-symbol-member? dependency-ref check-names)))
          (poo-flow-cicd-check-dependency-refs check)))

;; : (-> PooFlowCicdCheck [Alist])
(def (poo-flow-cicd-check-dependency-edges check)
  (map (lambda (dependency-ref)
         (list (cons 'from dependency-ref)
               (cons 'to (poo-flow-cicd-check-name check))))
       (poo-flow-cicd-check-dependency-refs check)))

;;; Lookup is intentionally first-match because duplicate names are reported as
;;; diagnostics; graph projection should remain total even for invalid input.
;; : (-> [PooFlowCicdCheck] Symbol MaybePooFlowCicdCheck)
(def (poo-flow-cicd-check-by-name checks name)
  (cond
   ((null? checks) #f)
   ((eq? (poo-flow-cicd-check-name (car checks)) name)
    (car checks))
   (else
    (poo-flow-cicd-check-by-name (cdr checks) name))))

;;; DFS follows declared dependency refs only. Missing refs are not fatal here;
;;; they are reported separately as unresolved dependency diagnostics.
;; : (-> Symbol [Symbol] [PooFlowCicdCheck] [Symbol] Boolean)
(def (poo-flow-cicd-dependency-refs-reach? target refs checks visited)
  (cond
   ((null? refs) #f)
   ((eq? (car refs) target) #t)
   ((poo-flow-cicd-symbol-member? (car refs) visited)
    (poo-flow-cicd-dependency-refs-reach?
     target
     (cdr refs)
     checks
     visited))
   (else
    (let (dependency-check
          (poo-flow-cicd-check-by-name checks (car refs)))
      (if (and dependency-check
               (poo-flow-cicd-check-reaches?
                target
                dependency-check
                checks
                (poo-flow-cicd-symbol-add (car refs) visited)))
        #t
        (poo-flow-cicd-dependency-refs-reach?
         target
         (cdr refs)
         checks
         visited))))))

;;; Cycle detection reports participating node names only. Ordering and
;;; topological sort remain backend policy, not Scheme execution behavior.
;; : (-> Symbol PooFlowCicdCheck [PooFlowCicdCheck] [Symbol] Boolean)
(def (poo-flow-cicd-check-reaches? target check checks visited)
  (poo-flow-cicd-dependency-refs-reach?
   target
   (poo-flow-cicd-check-dependency-refs check)
   checks
   (poo-flow-cicd-symbol-add (poo-flow-cicd-check-name check) visited)))

;;; Cycle nodes are returned in check declaration order to keep reports stable
;;; across runs and independent of backend scheduling policy.
;; : (-> [PooFlowCicdCheck] [Symbol])
(def (poo-flow-cicd-cycle-nodes checks)
  (map poo-flow-cicd-check-name
       (filter (lambda (check)
                 (poo-flow-cicd-check-reaches?
                  (poo-flow-cicd-check-name check)
                  check
                  checks
                  '()))
               checks)))

;;; Diagnostics are coarse policy classes. Detailed data stays in sibling
;;; fields so downstream presenters can choose their own wording.
;; : (-> [Symbol] [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-dependency-graph-diagnostics
      duplicate-nodes
      unresolved-dependency-refs
      cycle-nodes)
  (append (if (null? duplicate-nodes) '() '(duplicate-nodes))
          (if (null? unresolved-dependency-refs)
            '()
            '(unresolved-dependency-refs))
          (if (null? cycle-nodes) '() '(cycle-detected))))

;;; The dependency graph is a declarative DAG handoff. It reports nodes, edges,
;;; and unresolved refs but deliberately does not sort or schedule the checks.
;; : (-> PooFlowCicdCheckMap Alist)
(def (poo-flow-cicd-check-map->dependency-graph check-map)
  (poo-flow-cicd-require "cicd dependency graph requires a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (letrec ((check-order-ready?
            (lambda (check ready-order)
              (poo-flow-cicd-every?
               (lambda (dependency-ref)
                 (poo-flow-cicd-symbol-member? dependency-ref ready-order))
               (poo-flow-cicd-check-dependency-refs check))))
           (ready-order-scan
            (lambda (checks ready-order)
              (cond
               ((null? checks) ready-order)
               ((poo-flow-cicd-symbol-member?
                 (poo-flow-cicd-check-name (car checks))
                 ready-order)
                (ready-order-scan (cdr checks) ready-order))
               ((check-order-ready? (car checks) ready-order)
                (ready-order-scan
                 (cdr checks)
                 (poo-flow-cicd-symbol-add
                  (poo-flow-cicd-check-name (car checks))
                  ready-order)))
               (else
                (ready-order-scan (cdr checks) ready-order)))))
           (ready-order/fix
            (lambda (checks ready-order)
              (let (next-ready-order (ready-order-scan checks ready-order))
                (if (= (length next-ready-order) (length ready-order))
                  ready-order
                  (ready-order/fix checks next-ready-order)))))
           (unordered-nodes
            (lambda (check-names ready-order)
              (filter (lambda (check-name)
                        (not (poo-flow-cicd-symbol-member?
                              check-name
                              ready-order)))
                      check-names))))
    (let* ((checks (poo-flow-cicd-check-map-checks check-map))
           (check-names (poo-flow-cicd-checks-names checks))
           (duplicate-nodes
            (poo-flow-cicd-duplicate-symbols check-names))
           (unresolved-dependency-refs
            (poo-flow-cicd-append-map
             (lambda (check)
               (poo-flow-cicd-check-unresolved-dependency-refs
                check
                check-names))
             checks))
           (cycle-nodes (poo-flow-cicd-cycle-nodes checks))
           (diagnostics
            (poo-flow-cicd-dependency-graph-diagnostics
             duplicate-nodes
             unresolved-dependency-refs
             cycle-nodes))
           (ready-order (if (null? duplicate-nodes)
                          (ready-order/fix checks '())
                          '()))
           (unordered-node-names
            (unordered-nodes check-names ready-order))
           (blocked-order?
            (or (not (null? diagnostics))
                (not (= (length ready-order) (length check-names))))))
      (list (cons 'kind 'poo-flow.workflow.cicd.dependency-graph)
            (cons 'check-map (poo-flow-cicd-check-map-name check-map))
            (cons 'order-policy 'declaration-topological-report)
            (cons 'nodes check-names)
            (cons 'duplicate-nodes duplicate-nodes)
            (cons 'edges
                  (poo-flow-cicd-append-map
                   poo-flow-cicd-check-dependency-edges
                   checks))
            (cons 'unresolved-dependency-refs unresolved-dependency-refs)
            (cons 'cycle-nodes cycle-nodes)
            (cons 'ready-order ready-order)
            (cons 'unordered-nodes unordered-node-names)
            (cons 'blocked-order? blocked-order?)
            (cons 'diagnostics diagnostics)
            (cons 'valid? (null? diagnostics))
            (cons 'runtime-executed #f)))))

;;; The map is the whole data-flow: each POO check becomes one immutable
;;; receipt row, preserving order without a hand-written accumulator.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-map->receipts check-map . maybe-profile-catalog)
  (poo-flow-cicd-require "cicd receipts require a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (map (lambda (check)
           (poo-flow-cicd-check->receipt check profile-catalog))
         (poo-flow-cicd-check-map-checks check-map))))

;;; Runtime readiness uses the same ordered sequence-map as receipts so every
;;; check has exactly one handoff row and no runtime side effect is introduced.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->runtime-manifest-readiness check-map
                                                              . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime manifest readiness requires a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (list (cons 'schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.runtime-manifest-ready-map)
          (cons 'check-map (poo-flow-cicd-check-map-name check-map))
          (cons 'runtime-executed #f)
          (cons 'handoff-required #t)
          (cons 'dependency-graph
                (poo-flow-cicd-check-map->dependency-graph check-map))
          (cons 'checks
                (map (lambda (check)
                       (poo-flow-cicd-check->runtime-manifest-readiness
                        check
                        profile-catalog))
                     (poo-flow-cicd-check-map-checks check-map))))))

;;; Check-map manifest projection keeps CI/CD orchestration declarative: each
;;; check contributes one runtime command manifest, and the wrapper records that
;;; this is still report-only handoff data, not an execution result.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->runtime-command-manifests check-map
                                                          . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime command manifests require a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (list (cons 'schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.runtime-command-manifest-map)
          (cons 'check-map (poo-flow-cicd-check-map-name check-map))
          (cons 'runtime-executed #f)
          (cons 'handoff-required #t)
          (cons 'dependency-graph
                (poo-flow-cicd-check-map->dependency-graph check-map))
          (cons 'manifests
                (map (lambda (check)
                       (poo-flow-cicd-check->runtime-command-manifest
                        check
                        profile-catalog))
                     (poo-flow-cicd-check-map-checks check-map))))))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-cicd-runtime-command-manifest-policy-ref manifest key default)
  (poo-flow-cicd-alist-ref
   (poo-flow-cicd-alist-ref manifest 'policy '())
   key
   default))

;;; Marlin handoff entries are a stable ABI view over runtime command
;;; manifests. They whitelist the fields Rust needs and keep Scheme-side POO
;;; objects out of the payload.
;; : (-> Alist Alist)
(def (poo-flow-cicd-runtime-command-manifest->marlin-handoff-entry manifest)
  (list (cons 'kind 'poo-flow.workflow.cicd.marlin-runtime-handoff-entry)
        (cons 'schema +poo-flow-cicd-marlin-runtime-handoff-abi-schema+)
        (cons 'request-schema
              (poo-flow-cicd-alist-ref manifest 'request-schema #f))
        (cons 'operation
              (poo-flow-cicd-alist-ref manifest 'operation #f))
        (cons 'request-id
              (poo-flow-cicd-alist-ref manifest 'request-id #f))
        (cons 'artifact-handle
              (poo-flow-cicd-alist-ref manifest 'artifact-handle #f))
        (cons 'argv
              (poo-flow-cicd-alist-ref manifest 'argv '()))
        (cons 'request
              (poo-flow-cicd-alist-ref manifest 'request '()))
        (cons 'policy
              (poo-flow-cicd-alist-ref manifest 'policy '()))
        (cons 'plan-id
              (poo-flow-cicd-alist-ref manifest 'plan-id #f))
        (cons 'node-id
              (poo-flow-cicd-alist-ref manifest 'node-id #f))
        (cons 'frontier
              (poo-flow-cicd-alist-ref manifest 'frontier '()))
        (cons 'metadata
              (poo-flow-cicd-alist-ref manifest 'metadata '()))
        (cons 'runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
        (cons 'handoff-required
              (poo-flow-cicd-runtime-command-manifest-policy-ref
               manifest
               'handoff-required
               #t))
        (cons 'runtime-executed #f)
        (cons 'runtime-parses-scheme-source #f)
        (cons 'scheme-manufactures-runtime-handlers #f)))

;; : (-> [Alist] [Alist])
(def (poo-flow-cicd-runtime-command-manifests->marlin-handoff-entries
      manifests)
  (map poo-flow-cicd-runtime-command-manifest->marlin-handoff-entry
       manifests))

;;; The ABI map is the Marlin-facing workflow payload. It keeps the full
;;; dependency graph and per-check command entries, but still records that no
;;; runtime has executed in Scheme.
;; : (-> Alist Alist)
(def (poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
      manifest-map)
  (let ((manifests (poo-flow-cicd-alist-ref manifest-map 'manifests '())))
    (list (cons 'schema +poo-flow-cicd-marlin-runtime-handoff-abi-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.marlin-runtime-handoff-abi)
          (cons 'check-map
                (poo-flow-cicd-alist-ref manifest-map 'check-map #f))
          (cons 'runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
          (cons 'runtime-executed #f)
          (cons 'runtime-parses-scheme-source #f)
          (cons 'scheme-manufactures-runtime-handlers #f)
          (cons 'handoff-required
                (poo-flow-cicd-alist-ref manifest-map 'handoff-required #t))
          (cons 'required-fields
                +poo-flow-cicd-marlin-runtime-handoff-abi-fields+)
          (cons 'manifest-count (length manifests))
          (cons 'dependency-graph
                (poo-flow-cicd-alist-ref manifest-map
                                         'dependency-graph
                                         '()))
          (cons 'entries
                (poo-flow-cicd-runtime-command-manifests->marlin-handoff-entries
                 manifests)))))

;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->marlin-runtime-handoff-abi check-map
                                                               . maybe-profile-catalog)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
     (poo-flow-cicd-check-map->runtime-command-manifests
      check-map
      profile-catalog))))
