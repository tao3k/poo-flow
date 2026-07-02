;;; -*- Gerbil -*-
;;; Boundary: dependency graph and reachability diagnostics for CI/CD checks.

(import :poo-flow/src/modules/workflow/cicd-core
        :poo-flow/src/modules/workflow/cicd-projection-syntax
        :poo-flow/src/modules/workflow/cicd-sandbox)

(export poo-flow-cicd-checks-names
        poo-flow-cicd-duplicate-symbols/fold
        poo-flow-cicd-duplicate-symbols
        poo-flow-cicd-check-unresolved-dependency-refs/rev
        poo-flow-cicd-unresolved-dependency-refs
        poo-flow-cicd-check-dependency-edges/rev
        poo-flow-cicd-dependency-edges
        poo-flow-cicd-check-by-name
        poo-flow-cicd-dependency-refs-reach?
        poo-flow-cicd-check-reaches?
        poo-flow-cicd-cycle-nodes
        poo-flow-cicd-dependency-graph-diagnostics
        poo-flow-cicd-unordered-nodes
        poo-flow-cicd-check-map->dependency-graph)

;; Node names are kept in declaration order so diagnostics line up with the
;; user-authored pipeline instead of a derived scheduler order.
;; : (-> [PooFlowCicdCheck] [Symbol])
(def (poo-flow-cicd-checks-names checks)
  (cond
   ((null? checks) '())
   (else
    (cons (poo-flow-cicd-check-name (car checks))
          (poo-flow-cicd-checks-names (cdr checks))))))

;; Duplicate names make dependency refs ambiguous, so the graph reports them
;; before any downstream scheduler tries to interpret edges.
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

;; Unresolved dependency refs are graph diagnostics, not constructor errors.
;; Keeping this local to one check lets the map-level report aggregate every
;; missing edge before a backend scheduler sees the pipeline.
;; : (-> PooFlowCicdCheck [Symbol] [Symbol] [Symbol])
(def (poo-flow-cicd-check-unresolved-dependency-refs/rev check
                                                            check-names
                                                            refs-rev)
  (foldl (lambda (ref refs)
           (if (poo-flow-cicd-symbol-member? ref check-names)
             refs
             (cons ref refs)))
         refs-rev
         (poo-flow-cicd-check-dependency-refs check)))

;; : (-> [PooFlowCicdCheck] [Symbol] [Symbol])
(def (poo-flow-cicd-unresolved-dependency-refs checks check-names)
  (reverse
   (foldl (lambda (check refs-rev)
            (poo-flow-cicd-check-unresolved-dependency-refs/rev
             check
             check-names
             refs-rev))
          '()
          checks)))

;; Dependency edges are emitted as inert `from` and `to` facts. The runtime
;; scheduler can choose its own execution plan from the graph report later.
;; : (-> PooFlowCicdCheck [Alist] [Alist])
(def (poo-flow-cicd-check-dependency-edges/rev check edges-rev)
  (let ((check-name (poo-flow-cicd-check-name check)))
    (foldl (lambda (dependency-ref edges)
             (cons (poo-flow-cicd-field-rows
                    (from dependency-ref)
                    (to check-name))
                   edges))
           edges-rev
           (poo-flow-cicd-check-dependency-refs check))))

;; : (-> [PooFlowCicdCheck] [Alist])
(def (poo-flow-cicd-dependency-edges checks)
  (reverse
   (foldl (lambda (check edges-rev)
            (poo-flow-cicd-check-dependency-edges/rev check edges-rev))
          '()
          checks)))

;; Lookup is intentionally first-match because duplicate names are reported as
;; diagnostics; graph projection should remain total even for invalid input.
;; : (-> [PooFlowCicdCheck] Symbol MaybePooFlowCicdCheck)
(def (poo-flow-cicd-check-by-name checks name)
  (cond
   ((null? checks) #f)
   ((eq? (poo-flow-cicd-check-name (car checks)) name)
    (car checks))
   (else
    (poo-flow-cicd-check-by-name (cdr checks) name))))

;; DFS follows declared dependency refs only. Missing refs are not fatal here;
;; they are reported separately as unresolved dependency diagnostics.
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

;; Cycle detection reports participating node names only.
;; Ordering and topological sort remain backend policy, not Scheme execution behavior.
;; : (-> Symbol PooFlowCicdCheck [PooFlowCicdCheck] [Symbol] Boolean)
(def (poo-flow-cicd-check-reaches? target check checks visited)
  (poo-flow-cicd-dependency-refs-reach?
   target
   (poo-flow-cicd-check-dependency-refs check)
   checks
   (poo-flow-cicd-symbol-add (poo-flow-cicd-check-name check) visited)))

;; Cycle nodes are returned in check declaration order to keep reports stable
;; across runs and independent of backend scheduling policy.
;; : (-> [PooFlowCicdCheck] [Symbol])
(def (poo-flow-cicd-cycle-nodes checks)
  (reverse
   (foldl (lambda (check nodes-rev)
            (if (poo-flow-cicd-check-reaches?
                 (poo-flow-cicd-check-name check)
                 check
                 checks
                 '())
              (cons (poo-flow-cicd-check-name check) nodes-rev)
              nodes-rev))
          '()
          checks)))

;; Diagnostics are coarse policy classes. Detailed data stays in sibling
;; fields so downstream presenters can choose their own wording.
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

;; The dependency graph is a declarative DAG handoff. It reports nodes, edges,
;; and unresolved refs but deliberately does not sort or schedule the checks.
;; : (-> PooFlowCicdCheckMap Alist)
(def (poo-flow-cicd-check-map->dependency-graph check-map)
  (poo-flow-cicd-require "cicd dependency graph requires a cicd check-map"
                         (poo-flow-cicd-check-map? check-map)
                         check-map)
  (let ((check-order-ready?
         (lambda (check ready-order)
            (poo-flow-cicd-every?
             (lambda (dependency-ref)
              (poo-flow-cicd-symbol-member? dependency-ref ready-order))
            (poo-flow-cicd-check-dependency-refs check)))))
    (letrec ((ready-order-scan
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
                  (ready-order-scan (cdr checks) ready-order))))))
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
           (ready-order
            (let ready-order/fix ((ready-order (if (null? duplicate-nodes) '() '())))
              (let ((next-ready-order (ready-order-scan checks ready-order)))
                (if (= (length next-ready-order) (length ready-order))
                    ready-order
                    (ready-order/fix next-ready-order)))))
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
        (runtime-executed #f))))))
