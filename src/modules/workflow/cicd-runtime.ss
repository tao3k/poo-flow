;;; -*- Gerbil -*-
;;; Boundary: CI/CD dependency graph, runtime manifest, receipt, and Marlin ABI projection.
;;; Invariant: Scheme emits handoff data only; runtime execution stays Marlin-owned.

(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        :poo-flow/src/modules/workflow/cicd-core
        :poo-flow/src/modules/workflow/cicd-sandbox)

(export poo-flow-cicd-check-map->dependency-graph
        poo-flow-cicd-check->pipeline-run-step
        poo-flow-cicd-check-map->pipeline-run
        poo-flow-cicd-pipeline-run->result
        poo-flow-cicd-check-map->pipeline-result
        poo-flow-cicd-check->receipt
        poo-flow-cicd-check-map->receipts
        poo-flow-cicd-check-map->runtime-manifest-readiness
        poo-flow-cicd-check->runtime-command-manifest
        poo-flow-cicd-check-map->runtime-command-manifests
        poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
        poo-flow-cicd-check-map->marlin-runtime-handoff-abi)

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

;;; Unresolved dependency refs are graph diagnostics, not constructor errors.
;;; Keeping this local to one check lets the map-level report aggregate every
;;; missing edge before a backend scheduler sees the pipeline.
;; : (-> PooFlowCicdCheck [Symbol] [Symbol])
(def (poo-flow-cicd-check-unresolved-dependency-refs check check-names)
  (filter (lambda (dependency-ref)
            (not (poo-flow-cicd-symbol-member? dependency-ref check-names)))
          (poo-flow-cicd-check-dependency-refs check)))

;;; Dependency edges are emitted as inert `from` and `to` facts. The runtime
;;; scheduler can choose its own execution plan from the graph report later.
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

;;; A step is admitted only when the declarative graph accepts its dependency
;;; path and sandbox profile refs are resolved. This is not execution state.
;; : (-> Alist Alist Symbol Symbol)
(def (poo-flow-cicd-pipeline-run-step-status graph readiness check-name)
  (cond
   ((not (poo-flow-cicd-alist-ref graph 'valid? #f)) 'blocked)
   ((not (null? (poo-flow-cicd-alist-ref
                 readiness
                 'sandbox-unresolved-profile-refs
                 '())))
    'blocked)
   ((poo-flow-cicd-symbol-member?
     check-name
     (poo-flow-cicd-alist-ref graph 'ready-order '()))
    'admitted)
   (else 'blocked)))

;;; Pipeline-run diagnostics keep graph errors and sandbox errors distinct.
;;; Agents can decide whether to edit dependencies or profile bindings first.
;; : (-> Alist Alist Symbol [Symbol])
(def (poo-flow-cicd-pipeline-run-step-diagnostics graph readiness check-name)
  (append
   (if (poo-flow-cicd-alist-ref graph 'valid? #f)
     '()
     '(blocked-dependency-graph))
   (if (null? (poo-flow-cicd-alist-ref
               readiness
               'sandbox-unresolved-profile-refs
               '()))
     '()
     '(unresolved-sandbox-profile-refs))
   (if (or (not (poo-flow-cicd-alist-ref graph 'valid? #f))
           (poo-flow-cicd-symbol-member?
            check-name
            (poo-flow-cicd-alist-ref graph 'ready-order '())))
     '()
     '(blocked-dependency-order))))

;;; Pipeline-run steps wrap the existing readiness row with pipeline admission
;;; facts so users can see a concrete run plan without running the command.
;; : (-> PooFlowCicdCheck Alist [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check->pipeline-run-step check
                                             graph
                                             . maybe-profile-catalog)
  (poo-flow-cicd-require "pipeline run step requires a cicd check"
                         (poo-flow-cicd-check? check)
                         check)
  (let* ((profile-catalog (if (null? maybe-profile-catalog)
                            '()
                            (car maybe-profile-catalog)))
         (readiness
          (poo-flow-cicd-check->runtime-manifest-readiness
           check
           profile-catalog))
         (check-name (poo-flow-cicd-check-name check))
         (status
          (poo-flow-cicd-pipeline-run-step-status
           graph
           readiness
           check-name))
         (unresolved-profile-refs
          (poo-flow-cicd-alist-ref
           readiness
           'sandbox-unresolved-profile-refs
           '()))
         (diagnostics
          (poo-flow-cicd-pipeline-run-step-diagnostics
           graph
           readiness
           check-name)))
    (list (cons 'schema +poo-flow-cicd-pipeline-run-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.pipeline-run-step)
          (cons 'check check-name)
          (cons 'status status)
          (cons 'handoff-ready
                (and (eq? status 'admitted)
                     (null? unresolved-profile-refs)))
          (cons 'profile (poo-flow-cicd-check-profile check))
          (cons 'profile-refs (poo-flow-cicd-check-profile-refs check))
          (cons 'dependency-refs
                (poo-flow-cicd-check-dependency-refs check))
          (cons 'command (poo-flow-cicd-check-command check))
          (cons 'argv (poo-flow-cicd-check-command check))
          (cons 'runtime (poo-flow-cicd-check-runtime check))
          (cons 'result (.ref check 'result-protocol))
          (cons 'artifacts (poo-flow-cicd-check-artifacts check))
          (cons 'sandbox-unresolved-profile-refs unresolved-profile-refs)
          (cons 'diagnostics diagnostics)
          (cons 'valid? (and (eq? status 'admitted)
                             (null? diagnostics)))
          (cons 'runtime-readiness readiness)
          (cons 'runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
          (cons 'runtime-executed #f))))

;;; Unique diagnostic projection preserves first-seen order while removing
;;; repeated step diagnostics from large pipelines.
;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-symbol-list-unique/fold values seen)
  (cond
   ((null? values) seen)
   (else
    (poo-flow-cicd-symbol-list-unique/fold
     (cdr values)
     (poo-flow-cicd-symbol-add (car values) seen)))))

;; : (-> [Symbol] [Symbol])
(def (poo-flow-cicd-symbol-list-unique values)
  (poo-flow-cicd-symbol-list-unique/fold values '()))

;;; Step diagnostics are aggregated at the pipeline level so result rows can be
;;; audited without traversing every step.
;; : (-> [Alist] [Symbol])
(def (poo-flow-cicd-pipeline-run-steps-diagnostics steps)
  (cond
   ((null? steps) '())
   (else
    (append
     (poo-flow-cicd-alist-ref (car steps) 'diagnostics '())
     (poo-flow-cicd-pipeline-run-steps-diagnostics (cdr steps))))))

;;; Pipeline diagnostics merge graph, step, and blocked-step facts into a
;;; stable report-only list for user-interface and agent editing loops.
;; : (-> Alist [Alist] [Symbol] [Symbol])
(def (poo-flow-cicd-pipeline-run-diagnostics graph steps blocked-steps)
  (poo-flow-cicd-symbol-list-unique
   (append
    (poo-flow-cicd-alist-ref graph 'diagnostics '())
    (poo-flow-cicd-pipeline-run-steps-diagnostics steps)
    (if (null? blocked-steps) '() '(blocked-steps)))))

;;; Pipeline run status is a control-plane admission result. It stays blocked
;;; when graph diagnostics or sandbox refs prevent a clean Marlin handoff.
;; : (-> Alist [Alist] Symbol)
(def (poo-flow-cicd-pipeline-run-status graph steps)
  (if (and (poo-flow-cicd-alist-ref graph 'valid? #f)
           (null? (filter (lambda (step)
                            (not (eq? (poo-flow-cicd-alist-ref
                                       step
                                       'status
                                       'blocked)
                                      'admitted)))
                          steps)))
    'admitted
    'blocked))

;;; The pipeline run is the concrete, inspectable plan produced from a
;;; check-map. It includes DAG order, steps, and handoff status but no output.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->pipeline-run check-map . maybe-profile-catalog)
  (poo-flow-cicd-require "pipeline run requires a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let* ((profile-catalog (if (null? maybe-profile-catalog)
                            '()
                            (car maybe-profile-catalog)))
         (graph (poo-flow-cicd-check-map->dependency-graph check-map))
         (steps
          (map (lambda (check)
                 (poo-flow-cicd-check->pipeline-run-step
                  check
                  graph
                  profile-catalog))
               (poo-flow-cicd-check-map-checks check-map)))
         (blocked-steps
          (map (lambda (step) (poo-flow-cicd-alist-ref step 'check #f))
               (filter (lambda (step)
                         (not (eq? (poo-flow-cicd-alist-ref
                                    step
                                    'status
                                    'blocked)
                                   'admitted)))
                       steps)))
         (status (poo-flow-cicd-pipeline-run-status graph steps))
         (diagnostics
          (poo-flow-cicd-pipeline-run-diagnostics
           graph
           steps
           blocked-steps)))
    (list (cons 'schema +poo-flow-cicd-pipeline-run-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.pipeline-run)
          (cons 'check-map (poo-flow-cicd-check-map-name check-map))
          (cons 'status status)
          (cons 'step-count (length steps))
          (cons 'steps steps)
          (cons 'ready-order
                (poo-flow-cicd-alist-ref graph 'ready-order '()))
          (cons 'blocked-steps blocked-steps)
          (cons 'diagnostics diagnostics)
          (cons 'dependency-graph graph)
          (cons 'handoff-required #t)
          (cons 'handoff-ready (and (eq? status 'admitted)
                                    (null? diagnostics)))
          (cons 'valid? (null? diagnostics))
          (cons 'runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
          (cons 'runtime-executed #f))))

;;; Pipeline results summarize the projected run. They are the tutorial-facing
;;; "what would this produce" surface before a runtime returns real outputs.
;; : (-> Alist Alist)
(def (poo-flow-cicd-pipeline-run->result run)
  (let* ((blocked-steps
          (poo-flow-cicd-alist-ref run 'blocked-steps '()))
         (diagnostics
          (poo-flow-cicd-alist-ref run 'diagnostics '()))
         (handoff-ready
          (and (eq? (poo-flow-cicd-alist-ref run 'status 'blocked)
                    'admitted)
               (null? diagnostics))))
    (list (cons 'schema +poo-flow-cicd-pipeline-result-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.pipeline-result)
          (cons 'check-map (poo-flow-cicd-alist-ref run 'check-map #f))
          (cons 'status (if handoff-ready 'handoff-ready 'blocked))
          (cons 'pipeline-run-status
                (poo-flow-cicd-alist-ref run 'status 'blocked))
          (cons 'step-count (poo-flow-cicd-alist-ref run 'step-count 0))
          (cons 'ready-order (poo-flow-cicd-alist-ref run 'ready-order '()))
          (cons 'blocked-steps blocked-steps)
          (cons 'diagnostics diagnostics)
          (cons 'valid? handoff-ready)
          (cons 'handoff-required #t)
          (cons 'handoff-ready handoff-ready)
          (cons 'runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
          (cons 'runtime-executed #f))))

;;; The check-map shortcut keeps callers on the public object surface when they
;;; only need the result projection rather than the full run step payload.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->pipeline-result check-map
                                                . maybe-profile-catalog)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (poo-flow-cicd-pipeline-run->result
     (poo-flow-cicd-check-map->pipeline-run check-map profile-catalog))))

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

;;; Policy lookup stays nested under the manifest policy field. The ABI wrapper
;;; should not depend on incidental top-level keys from runtime descriptors.
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

;;; Entry projection is a one-to-one map over command manifests. Keeping it a
;;; map preserves order and prevents the ABI layer from inventing scheduler data.
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

;;; The check-map shortcut keeps callers on the public POO object surface while
;;; delegating ABI formation through the manifest-map boundary above.
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
