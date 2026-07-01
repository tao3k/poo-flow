;;; -*- Gerbil -*-
;;; Boundary: CI/CD dependency graph, runtime manifest, receipt, and Marlin ABI projection.
;;; Invariant: Scheme emits handoff data only; runtime execution stays Marlin-owned.

(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        :poo-flow/src/modules/workflow/cicd-core
        :poo-flow/src/modules/workflow/cicd-projection-syntax
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

;;; Durable fields are a bounded runtime receipt projection. They are derived
;;; from validated POO check metadata once, then copied into runtime handoff
;;; alists so Marlin never has to inspect the POO object graph.
;; : (-> PooFlowCicdCheck [Alist])
(def (poo-flow-cicd-check-artifact-provenance check)
  (let ((producer-check (poo-flow-cicd-check-name check))
        (durable-task-id (poo-flow-cicd-check-durable-task-id check))
        (retention (poo-flow-cicd-check-artifact-retention check)))
    (let loop ((remaining-artifact-refs (poo-flow-cicd-check-artifacts check)))
      (if (null? remaining-artifact-refs)
        '()
        (cons
         (poo-flow-cicd-field-rows
          (artifact-ref (car remaining-artifact-refs))
          (producer-check producer-check)
          (durable-task-id durable-task-id)
          (retention retention)
          (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
          (runtime-executed #f))
         (loop (cdr remaining-artifact-refs)))))))

;; : (-> PooFlowCicdCheck Alist)
(def (poo-flow-cicd-check-durable-fields check)
  (poo-flow-cicd-field-rows
   (durable-task-id (poo-flow-cicd-check-durable-task-id check))
   (action-class (poo-flow-cicd-check-action-class check))
   (artifact-refs (poo-flow-cicd-check-artifacts check))
   (artifact-provenance (poo-flow-cicd-check-artifact-provenance check))
   (artifact-retention (poo-flow-cicd-check-artifact-retention check))
   (sandbox-refs (poo-flow-cicd-check-profile-refs check))
   (checkpoint-ref
    (list 'workflow-cicd-check
          (poo-flow-cicd-check-name check)))
   (compensation-refs (poo-flow-cicd-check-compensation-refs check))))

;; : (-> PooFlowCicdCheck Alist Alist)
(def (poo-flow-cicd-check-runtime-metadata check readiness)
  (poo-flow-cicd-field-rows/tail
   (poo-flow-cicd-check-durable-fields check)
   (source 'poo-flow.workflow.cicd.check)
   (check (poo-flow-cicd-check-name check))
   (profile (poo-flow-cicd-check-profile check))
   (profile-refs (poo-flow-cicd-check-profile-refs check))
   (dependency-refs (poo-flow-cicd-check-dependency-refs check))
   (runtime (poo-flow-cicd-check-runtime check))
   (runtime-executed #f)
   (handoff-required #t)
   (artifacts (poo-flow-cicd-check-artifacts check))
   (cache (poo-flow-cicd-check-cache check))
   (secrets (poo-flow-cicd-check-secrets check))
   (readiness readiness)))

;; : (-> PooFlowCicdCheck Alist)
(def (poo-flow-cicd-check-runtime-policy check)
  (poo-flow-cicd-field-rows/tail
   (poo-flow-cicd-check-durable-fields check)
   (runtime (poo-flow-cicd-check-runtime check))
   (dependency-refs (poo-flow-cicd-check-dependency-refs check))
   (runtime-executed #f)
   (handoff-required #t)))

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
     (poo-flow-cicd-check-runtime-metadata check readiness))))

;;; The envelope is intentionally the smallest runtime request shape: it names
;;; the workflow operation and carries readiness as data, while leaving plan and
;;; frontier fields inert until a real scheduler supplies them.
;; : (-> PooFlowCicdCheck Alist Alist)
(def (poo-flow-cicd-check-runtime-command-envelope check readiness)
  (poo-flow-cicd-field-rows
   (schema +runtime-request-schema+)
   (operation 'workflow-cicd-check)
   (request-id
    (list 'poo-flow.workflow.cicd
          (poo-flow-cicd-check-name check)))
   (artifact-handle (poo-flow-cicd-check-artifacts check))
   (request readiness)
   (policy (poo-flow-cicd-check-runtime-policy check))
   (plan-id #f)
   (node-id (poo-flow-cicd-check-name check))
   (frontier '())))

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
;; : (-> PooFlowCicdCheck [PooSandboxProfile] Alist Alist)
(def (poo-flow-cicd-check-receipt-fields check
                                          profile-catalog
                                          runtime-ready)
  (poo-flow-cicd-field-rows/tail
   (poo-flow-cicd-check-durable-fields check)
   (schema +poo-flow-cicd-check-receipt-schema+)
   (kind 'poo-flow.workflow.cicd.check-receipt)
   (check (poo-flow-cicd-check-name check))
   (profile (poo-flow-cicd-check-profile check))
   (profile-refs (poo-flow-cicd-check-profile-refs check))
   (dependency-refs (poo-flow-cicd-check-dependency-refs check))
   (sandbox-runtime-summaries
    (poo-flow-cicd-check-sandbox-runtime-summaries
     check
     profile-catalog))
   (sandbox-handoff-summaries
    (poo-flow-cicd-check-sandbox-handoff-summaries
     check
     profile-catalog))
   (sandbox-unresolved-profile-refs
    (poo-flow-cicd-check-sandbox-unresolved-profile-refs
     check
     profile-catalog))
   (command (poo-flow-cicd-check-command check))
   (inputs (.ref check 'input-bindings))
   (config (.ref check 'config-sources))
   (artifacts (poo-flow-cicd-check-artifacts check))
   (cache (poo-flow-cicd-check-cache check))
   (secrets (poo-flow-cicd-check-secrets check))
   (result (.ref check 'result-protocol))
   (runtime (poo-flow-cicd-check-runtime check))
   (runtime-executed #f)
   (status 'ready)
   (runtime-manifest-ready runtime-ready)))

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
    (poo-flow-cicd-check-receipt-fields check
                                        profile-catalog
                                        runtime-ready)))

;;; Node names are kept in declaration order so diagnostics line up with the
;;; user-authored pipeline instead of a derived scheduler order.
;; : (-> [PooFlowCicdCheck] [Symbol])
(def (poo-flow-cicd-checks-names checks)
  (cond
   ((null? checks) '())
   (else
    (cons (poo-flow-cicd-check-name (car checks))
          (poo-flow-cicd-checks-names (cdr checks))))))

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

;;; Unresolved dependency refs are graph diagnostics, not constructor errors.
;;; Keeping this local to one check lets the map-level report aggregate every
;;; missing edge before a backend scheduler sees the pipeline.
;; : (-> PooFlowCicdCheck [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-check-unresolved-dependency-refs/rev check
                                                            check-names
                                                            refs-rev)
  (let loop ((remaining-refs (poo-flow-cicd-check-dependency-refs check))
             (refs-rev refs-rev))
    (cond
     ((null? remaining-refs) refs-rev)
     ((poo-flow-cicd-symbol-member? (car remaining-refs) check-names)
      (loop (cdr remaining-refs) refs-rev))
     (else
      (loop (cdr remaining-refs)
            (cons (car remaining-refs) refs-rev))))))

;; : (-> [PooFlowCicdCheck] [Symbol] [Symbol])
(def (poo-flow-cicd-unresolved-dependency-refs checks check-names)
  (let loop ((remaining-checks checks)
             (refs-rev '()))
    (if (null? remaining-checks)
      (reverse refs-rev)
      (loop (cdr remaining-checks)
            (poo-flow-cicd-check-unresolved-dependency-refs/rev
             (car remaining-checks)
             check-names
             refs-rev)))))

;;; Dependency edges are emitted as inert `from` and `to` facts. The runtime
;;; scheduler can choose its own execution plan from the graph report later.
;; : (-> PooFlowCicdCheck [Alist] [Alist])
(def (poo-flow-cicd-check-dependency-edges/rev check edges-rev)
  (let ((check-name (poo-flow-cicd-check-name check)))
    (let loop ((remaining-refs (poo-flow-cicd-check-dependency-refs check))
               (edges-rev edges-rev))
      (if (null? remaining-refs)
        edges-rev
        (loop (cdr remaining-refs)
              (cons (poo-flow-cicd-field-rows
                     (from (car remaining-refs))
                     (to check-name))
                    edges-rev))))))

;; : (-> [PooFlowCicdCheck] [Alist])
(def (poo-flow-cicd-dependency-edges checks)
  (let loop ((remaining-checks checks)
             (edges-rev '()))
    (if (null? remaining-checks)
      (reverse edges-rev)
      (loop (cdr remaining-checks)
            (poo-flow-cicd-check-dependency-edges/rev
             (car remaining-checks)
             edges-rev)))))

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
  (let loop ((remaining-checks checks)
             (nodes-rev '()))
    (cond
     ((null? remaining-checks)
      (reverse nodes-rev))
     ((poo-flow-cicd-check-reaches?
       (poo-flow-cicd-check-name (car remaining-checks))
       (car remaining-checks)
       checks
       '())
      (loop (cdr remaining-checks)
            (cons (poo-flow-cicd-check-name (car remaining-checks))
                  nodes-rev)))
     (else
      (loop (cdr remaining-checks) nodes-rev)))))

;;; Diagnostics are coarse policy classes. Detailed data stays in sibling
;;; fields so downstream presenters can choose their own wording.
;; : (-> [Symbol] [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-dependency-graph-diagnostics
      duplicate-nodes
      unresolved-dependency-refs
      cycle-nodes)
  (let* ((diagnostics0
          (if (null? duplicate-nodes) '() '(duplicate-nodes)))
         (diagnostics1
          (if (null? unresolved-dependency-refs)
            diagnostics0
            (cons 'unresolved-dependency-refs diagnostics0)))
         (diagnostics2
          (if (null? cycle-nodes)
            diagnostics1
            (cons 'cycle-detected diagnostics1))))
    (reverse diagnostics2)))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-unordered-nodes check-names ready-order)
  (cond
   ((null? check-names) '())
   ((poo-flow-cicd-symbol-member? (car check-names) ready-order)
    (poo-flow-cicd-unordered-nodes (cdr check-names) ready-order))
   (else
    (cons (car check-names)
          (poo-flow-cicd-unordered-nodes (cdr check-names) ready-order)))))

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
                  (ready-order/fix checks next-ready-order))))))
    (let* ((checks (poo-flow-cicd-check-map-checks check-map))
           (check-names (poo-flow-cicd-checks-names checks))
           (duplicate-nodes
            (poo-flow-cicd-duplicate-symbols check-names))
           (unresolved-dependency-refs
            (poo-flow-cicd-unresolved-dependency-refs checks check-names))
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
            (poo-flow-cicd-unordered-nodes check-names ready-order))
           (blocked-order?
            (or (not (null? diagnostics))
                (not (= (length ready-order) (length check-names))))))
      (poo-flow-cicd-field-rows
       (kind 'poo-flow.workflow.cicd.dependency-graph)
       (check-map (poo-flow-cicd-check-map-name check-map))
       (order-policy 'declaration-topological-report)
       (nodes check-names)
       (duplicate-nodes duplicate-nodes)
       (edges (poo-flow-cicd-dependency-edges checks))
       (unresolved-dependency-refs unresolved-dependency-refs)
       (cycle-nodes cycle-nodes)
       (ready-order ready-order)
       (unordered-nodes unordered-node-names)
       (blocked-order? blocked-order?)
       (diagnostics diagnostics)
       (valid? (null? diagnostics))
       (runtime-executed #f)))))

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
  (let* ((diagnostics0
          (if (poo-flow-cicd-alist-ref graph 'valid? #f)
            '()
            '(blocked-dependency-graph)))
         (diagnostics1
          (if (null? (poo-flow-cicd-alist-ref
                      readiness
                      'sandbox-unresolved-profile-refs
                      '()))
            diagnostics0
            (cons 'unresolved-sandbox-profile-refs diagnostics0)))
         (diagnostics2
          (if (or (not (poo-flow-cicd-alist-ref graph 'valid? #f))
                  (poo-flow-cicd-symbol-member?
                   check-name
                   (poo-flow-cicd-alist-ref graph 'ready-order '())))
            diagnostics1
            (cons 'blocked-dependency-order diagnostics1))))
    (reverse diagnostics2)))

;; : (-> PooFlowCicdCheck Symbol Symbol [Symbol] [Symbol] Alist Alist)
(def (poo-flow-cicd-pipeline-run-step-fields check
                                              check-name
                                              status
                                              unresolved-profile-refs
                                              diagnostics
                                              readiness)
  (poo-flow-cicd-field-rows/tail
   (poo-flow-cicd-check-durable-fields check)
   (schema +poo-flow-cicd-pipeline-run-schema+)
   (kind 'poo-flow.workflow.cicd.pipeline-run-step)
   (check check-name)
   (status status)
   (handoff-ready
    (and (eq? status 'admitted)
         (null? unresolved-profile-refs)))
   (profile (poo-flow-cicd-check-profile check))
   (profile-refs (poo-flow-cicd-check-profile-refs check))
   (dependency-refs
    (poo-flow-cicd-check-dependency-refs check))
   (command (poo-flow-cicd-check-command check))
   (argv (poo-flow-cicd-check-command check))
   (runtime (poo-flow-cicd-check-runtime check))
   (result (.ref check 'result-protocol))
   (artifacts (poo-flow-cicd-check-artifacts check))
   (sandbox-unresolved-profile-refs unresolved-profile-refs)
   (diagnostics diagnostics)
   (valid? (and (eq? status 'admitted)
                (null? diagnostics)))
   (runtime-readiness readiness)
   (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
   (runtime-executed #f)))

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
    (poo-flow-cicd-pipeline-run-step-fields check
                                            check-name
                                            status
                                            unresolved-profile-refs
                                            diagnostics
                                            readiness)))

;; : (-> [PooFlowCicdCheck] Alist [PooSandboxProfile] Alist)
(def (poo-flow-cicd-pipeline-run-step-summary checks graph profile-catalog)
  (let loop ((remaining-checks checks)
             (steps-rev '())
             (blocked-steps-rev '()))
    (if (null? remaining-checks)
      (list
       (cons 'steps (reverse steps-rev))
       (cons 'blocked-steps (reverse blocked-steps-rev)))
      (let* ((step
              (poo-flow-cicd-check->pipeline-run-step
               (car remaining-checks)
               graph
               profile-catalog))
             (check-name
              (poo-flow-cicd-alist-ref step 'check #f))
             (blocked?
              (not (eq? (poo-flow-cicd-alist-ref step
                                                  'status
                                                  'blocked)
                        'admitted))))
        (loop (cdr remaining-checks)
              (cons step steps-rev)
              (if blocked?
                (cons check-name blocked-steps-rev)
                blocked-steps-rev))))))

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

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-symbols-into/rev values result)
  (cond
   ((null? values) result)
   (else
    (poo-flow-cicd-symbols-into/rev
     (cdr values)
     (cons (car values) result)))))

;; : (-> [Alist] [Symbol] [Symbol])
(def (poo-flow-cicd-pipeline-run-steps-diagnostics/rev steps diagnostics-rev)
  (cond
   ((null? steps) diagnostics-rev)
   (else
    (poo-flow-cicd-pipeline-run-steps-diagnostics/rev
     (cdr steps)
     (poo-flow-cicd-symbols-into/rev
      (poo-flow-cicd-alist-ref (car steps) 'diagnostics '())
      diagnostics-rev)))))

;;; Step diagnostics are aggregated at the pipeline level so result rows can be
;;; audited without traversing every step.
;; : (-> [Alist] [Symbol])
(def (poo-flow-cicd-pipeline-run-steps-diagnostics steps)
  (reverse (poo-flow-cicd-pipeline-run-steps-diagnostics/rev steps '())))

;;; Pipeline diagnostics merge graph, step, and blocked-step facts into a
;;; stable report-only list for user-interface and agent editing loops.
;; : (-> Alist [Alist] [Symbol] [Symbol])
(def (poo-flow-cicd-pipeline-run-diagnostics graph steps blocked-steps)
  (let* ((diagnostics0
          (poo-flow-cicd-symbols-into/rev
           (poo-flow-cicd-alist-ref graph 'diagnostics '())
           '()))
         (diagnostics1
          (poo-flow-cicd-pipeline-run-steps-diagnostics/rev
           steps
           diagnostics0))
         (diagnostics2
          (if (null? blocked-steps)
            diagnostics1
            (cons 'blocked-steps diagnostics1))))
    (poo-flow-cicd-symbol-list-unique (reverse diagnostics2))))

;;; Pipeline run status is a control-plane admission result. It stays blocked
;;; when graph diagnostics or sandbox refs prevent a clean Marlin handoff.
;; : (-> [Alist] Boolean)
(def (poo-flow-cicd-pipeline-run-steps-admitted? steps)
  (cond
   ((null? steps) #t)
   ((eq? (poo-flow-cicd-alist-ref (car steps) 'status 'blocked)
         'admitted)
    (poo-flow-cicd-pipeline-run-steps-admitted? (cdr steps)))
   (else #f)))

;; : (-> Alist [Alist] Symbol)
(def (poo-flow-cicd-pipeline-run-status graph steps)
  (if (and (poo-flow-cicd-alist-ref graph 'valid? #f)
           (poo-flow-cicd-pipeline-run-steps-admitted? steps))
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
         (step-summary
          (poo-flow-cicd-pipeline-run-step-summary
           (poo-flow-cicd-check-map-checks check-map)
           graph
           profile-catalog))
         (steps
          (poo-flow-cicd-alist-ref step-summary 'steps '()))
         (blocked-steps
          (poo-flow-cicd-alist-ref step-summary 'blocked-steps '()))
         (status (poo-flow-cicd-pipeline-run-status graph steps))
         (diagnostics
          (poo-flow-cicd-pipeline-run-diagnostics
           graph
           steps
           blocked-steps)))
    (poo-flow-cicd-field-rows
     (schema +poo-flow-cicd-pipeline-run-schema+)
     (kind 'poo-flow.workflow.cicd.pipeline-run)
     (check-map (poo-flow-cicd-check-map-name check-map))
     (status status)
     (step-count (length steps))
     (steps steps)
     (ready-order
      (poo-flow-cicd-alist-ref graph 'ready-order '()))
     (blocked-steps blocked-steps)
     (diagnostics diagnostics)
     (dependency-graph graph)
     (handoff-required #t)
     (handoff-ready (and (eq? status 'admitted)
                         (null? diagnostics)))
     (valid? (null? diagnostics))
     (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
     (runtime-executed #f))))

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
    (poo-flow-cicd-field-rows
     (schema +poo-flow-cicd-pipeline-result-schema+)
     (kind 'poo-flow.workflow.cicd.pipeline-result)
     (check-map (poo-flow-cicd-alist-ref run 'check-map #f))
     (status (if handoff-ready 'handoff-ready 'blocked))
     (pipeline-run-status
      (poo-flow-cicd-alist-ref run 'status 'blocked))
     (step-count (poo-flow-cicd-alist-ref run 'step-count 0))
     (ready-order (poo-flow-cicd-alist-ref run 'ready-order '()))
     (blocked-steps blocked-steps)
     (diagnostics diagnostics)
     (valid? handoff-ready)
     (handoff-required #t)
     (handoff-ready handoff-ready)
     (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
     (runtime-executed #f))))

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
;; : (-> [PooFlowCicdCheck] [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-checks->receipts checks profile-catalog)
  (cond
   ((null? checks) '())
   (else
    (cons (poo-flow-cicd-check->receipt (car checks) profile-catalog)
          (poo-flow-cicd-checks->receipts (cdr checks)
                                          profile-catalog)))))

;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-map->receipts check-map . maybe-profile-catalog)
  (poo-flow-cicd-require "cicd receipts require a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (poo-flow-cicd-checks->receipts
     (poo-flow-cicd-check-map-checks check-map)
     profile-catalog)))

;;; Runtime readiness uses the same ordered sequence-map as receipts so every
;;; check has exactly one handoff row and no runtime side effect is introduced.
;; : (-> [PooFlowCicdCheck] [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-checks->runtime-manifest-readiness checks
                                                       profile-catalog)
  (cond
   ((null? checks) '())
   (else
    (cons (poo-flow-cicd-check->runtime-manifest-readiness
           (car checks)
           profile-catalog)
          (poo-flow-cicd-checks->runtime-manifest-readiness
           (cdr checks)
           profile-catalog)))))

;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->runtime-manifest-readiness check-map
                                                              . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime manifest readiness requires a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (poo-flow-cicd-field-rows
     (schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
     (kind 'poo-flow.workflow.cicd.runtime-manifest-ready-map)
     (check-map (poo-flow-cicd-check-map-name check-map))
     (runtime-executed #f)
     (handoff-required #t)
     (dependency-graph
      (poo-flow-cicd-check-map->dependency-graph check-map))
     (checks
      (poo-flow-cicd-checks->runtime-manifest-readiness
       (poo-flow-cicd-check-map-checks check-map)
       profile-catalog)))))

;;; Check-map manifest projection keeps CI/CD orchestration declarative: each
;;; check contributes one runtime command manifest, and the wrapper records that
;;; this is still report-only handoff data, not an execution result.
;; : (-> [PooFlowCicdCheck] [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-checks->runtime-command-manifests checks profile-catalog)
  (cond
   ((null? checks) '())
   (else
    (cons (poo-flow-cicd-check->runtime-command-manifest
           (car checks)
           profile-catalog)
          (poo-flow-cicd-checks->runtime-command-manifests
           (cdr checks)
           profile-catalog)))))

;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check-map->runtime-command-manifests check-map
                                                          . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime command manifests require a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (poo-flow-cicd-field-rows
     (schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
     (kind 'poo-flow.workflow.cicd.runtime-command-manifest-map)
     (check-map (poo-flow-cicd-check-map-name check-map))
     (runtime-executed #f)
     (handoff-required #t)
     (dependency-graph
      (poo-flow-cicd-check-map->dependency-graph check-map))
     (manifests
      (poo-flow-cicd-checks->runtime-command-manifests
       (poo-flow-cicd-check-map-checks check-map)
       profile-catalog)))))

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
  (poo-flow-cicd-field-rows
   (kind 'poo-flow.workflow.cicd.marlin-runtime-handoff-entry)
   (schema +poo-flow-cicd-marlin-runtime-handoff-abi-schema+)
   (request-schema
    (poo-flow-cicd-alist-ref manifest 'request-schema #f))
   (operation
    (poo-flow-cicd-alist-ref manifest 'operation #f))
   (request-id
    (poo-flow-cicd-alist-ref manifest 'request-id #f))
   (artifact-handle
    (poo-flow-cicd-alist-ref manifest 'artifact-handle #f))
   (argv
    (poo-flow-cicd-alist-ref manifest 'argv '()))
   (request
    (poo-flow-cicd-alist-ref manifest 'request '()))
   (policy
    (poo-flow-cicd-alist-ref manifest 'policy '()))
   (plan-id
    (poo-flow-cicd-alist-ref manifest 'plan-id #f))
   (node-id
    (poo-flow-cicd-alist-ref manifest 'node-id #f))
   (frontier
    (poo-flow-cicd-alist-ref manifest 'frontier '()))
   (metadata
    (poo-flow-cicd-alist-ref manifest 'metadata '()))
   (durable-task-id
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'durable-task-id
     #f))
   (action-class
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'action-class
     #f))
   (artifact-refs
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'artifact-refs
     '()))
   (artifact-provenance
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'artifact-provenance
     '()))
   (artifact-retention
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'artifact-retention
     #f))
   (sandbox-refs
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'sandbox-refs
     '()))
   (checkpoint-ref
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'checkpoint-ref
     #f))
   (compensation-refs
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'compensation-refs
     '()))
   (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
   (handoff-required
    (poo-flow-cicd-runtime-command-manifest-policy-ref
     manifest
     'handoff-required
     #t))
   (runtime-executed #f)
   (runtime-parses-scheme-source #f)
   (scheme-manufactures-runtime-handlers #f)))

;;; Entry projection is a one-to-one map over command manifests. Keeping it a
;;; map preserves order and prevents the ABI layer from inventing scheduler data.
;; : (-> [Alist] [Alist])
(def (poo-flow-cicd-runtime-command-manifests->marlin-handoff-entries
      manifests)
  (cond
   ((null? manifests) '())
   (else
    (cons (poo-flow-cicd-runtime-command-manifest->marlin-handoff-entry
           (car manifests))
          (poo-flow-cicd-runtime-command-manifests->marlin-handoff-entries
           (cdr manifests))))))

;;; The ABI map is the Marlin-facing workflow payload. It keeps the full
;;; dependency graph and per-check command entries, but still records that no
;;; runtime has executed in Scheme.
;; : (-> Alist Alist)
(def (poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
      manifest-map)
  (let ((manifests (poo-flow-cicd-alist-ref manifest-map 'manifests '())))
    (poo-flow-cicd-field-rows
     (schema +poo-flow-cicd-marlin-runtime-handoff-abi-schema+)
     (kind 'poo-flow.workflow.cicd.marlin-runtime-handoff-abi)
     (check-map
      (poo-flow-cicd-alist-ref manifest-map 'check-map #f))
     (runtime-owner +poo-flow-cicd-marlin-runtime-owner+)
     (runtime-executed #f)
     (runtime-parses-scheme-source #f)
     (scheme-manufactures-runtime-handlers #f)
     (handoff-required
      (poo-flow-cicd-alist-ref manifest-map 'handoff-required #t))
     (required-fields
      +poo-flow-cicd-marlin-runtime-handoff-abi-fields+)
     (manifest-count (length manifests))
     (dependency-graph
      (poo-flow-cicd-alist-ref manifest-map
                               'dependency-graph
                               '()))
     (entries
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
