;;; -*- Gerbil -*-
;;; Boundary: runtime helpers used by user-facing composition macros.
;;; Invariant: keep POO object construction and hook normalization outside
;;; macro parser modules so macro expansion remains shallow and reusable.

(import (only-in :clan/poo/object .all-slots .mix .o .ref object<-alist)
        (only-in :std/srfi/1 append-map filter-map find fold)
        :poo-flow/src/core/plan)

(export poo-flow-composition-inline-section-slot
        poo-flow-composition-inline-alist-ref
        poo-flow-composition-inline-profile-field
        poo-flow-composition-inline-profile-ref/default
        poo-flow-composition-inline-profile-normalize
        poo-flow-composition-inline-apply-hooks
        poo-flow-composition-inline-imported-profile
        poo-flow-composition-inline-module
        poo-flow-composition-inline-profile
        poo-flow-composition->execution-plan)

;; : (-> Symbol Symbol)
(def (poo-flow-composition-inline-section-slot key)
  (case key
    ((:extends extends) 'extends)
    ((:kind kind) 'kind)
    ((:scope scope) 'scope)
    ((:storage storage) 'storage)
    ((:analysis analysis) 'analysis)
    ((:publish publish) 'publish)
    ((:retention retention) 'retention)
    ((:capabilities capabilities) 'capabilities)
    ((:guard guard) 'guard)
    ((:with with) 'hooks)
    (else key)))

;; : (-> Alist Symbol Datum Datum)
(def (poo-flow-composition-inline-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default)))

;; : (-> PooProfile Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-ref/default profile key default)
  (poo-flow-composition-inline-profile-ref/default*
   profile
   (.all-slots profile)
   key
   default))

;; : (-> PooProfile [Symbol] Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-ref/default*
      profile
      slots
      key
      default)
  (if (memq key slots)
    (.ref profile key)
    default))

;; : (-> Alist Datum Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-field sections base key default)
  (poo-flow-composition-inline-alist-ref
   sections
   key
   (if base
     (poo-flow-composition-inline-profile-ref/default base key default)
     default)))

;;; Boundary: inline profile normalization keeps authoring-time profile values
;;; deterministic before composition stages inherit or extend them.
;; : (-> PooProfile PooProfile PooProfile)
(def (poo-flow-composition-inline-profile-normalize base profile)
  (.mix profile base))

;; : (-> PooProfile [(-> PooProfile PooProfile)] PooProfile)
(def (poo-flow-composition-inline-apply-hooks profile hooks)
  (foldl
   (lambda (hook out)
     (poo-flow-composition-inline-profile-normalize out (hook out)))
   profile
   hooks))

;; : (-> Symbol Symbol PooProfile)
(def (poo-flow-composition-inline-imported-profile module-name profile-name)
  (.o (kind 'poo-flow.composition.imported-profile)
      (name profile-name)
      (module module-name)
      (profile profile-name)
      (guard #f)
      (source (list 'use-module module-name))
      (runtime-executed #f)))

;; : (-> List List Object)
;; | doc m%
;; Builds the runtime POO module object for inline profile composition.
;; `profile-names` and `profile-values` must have the same length; each name is
;; installed through one POO object construction boundary, so composed profile
;; objects remain reusable by `.ref` lookup after construction.
;;
;; # Examples
;;   (poo-flow-composition-inline-module '(default) (list profile))
;;   ;; result: (.ref module 'default) returns `profile`.
(def (poo-flow-composition-inline-module profile-names profile-values)
  (unless (= (length profile-names) (length profile-values))
    (error "inline composition module name/value arity mismatch"
           profile-names
           profile-values))
  (object<-alist (map cons profile-names profile-values)))

;;; Boundary: inline profile construction is the runtime value edge for
;;; use-composition macro output and must preserve POO-native profile objects.
;; : (-> Symbol Alist PooProfile)
(def (poo-flow-composition-inline-profile profile-name sections)
  (let* ((base (poo-flow-composition-inline-alist-ref sections 'extends #f))
         (hook-values
          (poo-flow-composition-inline-alist-ref sections 'hooks '()))
         (profile
          (if base
            (.o (:: @ base)
                (:extends base)
                name: profile-name
                extends: base
                kind:
                (poo-flow-composition-inline-profile-field
                 sections base 'kind profile-name)
                scope:
                (poo-flow-composition-inline-profile-field
                 sections base 'scope '())
                storage:
                (poo-flow-composition-inline-profile-field
                 sections base 'storage '())
                analysis:
                (poo-flow-composition-inline-profile-field
                 sections base 'analysis '())
                publish:
                (poo-flow-composition-inline-profile-field
                 sections base 'publish '())
                retention:
                (poo-flow-composition-inline-profile-field
                 sections base 'retention '())
                capabilities:
                (poo-flow-composition-inline-profile-field
                 sections base 'capabilities '())
                guard:
                (poo-flow-composition-inline-profile-field
                 sections base 'guard #f)
                hooks: hook-values
                runtime-executed: #f
                source: 'poo-flow.composition.inline-profile)
            (.o name: profile-name
                extends: #f
                kind:
                (poo-flow-composition-inline-alist-ref
                 sections 'kind profile-name)
                scope:
                (poo-flow-composition-inline-alist-ref
                 sections 'scope '())
                storage:
                (poo-flow-composition-inline-alist-ref
                 sections 'storage '())
                analysis:
                (poo-flow-composition-inline-alist-ref
                 sections 'analysis '())
                publish:
                (poo-flow-composition-inline-alist-ref
                 sections 'publish '())
                retention:
                (poo-flow-composition-inline-alist-ref
                 sections 'retention '())
                capabilities:
                (poo-flow-composition-inline-alist-ref
                 sections 'capabilities '())
                guard:
                (poo-flow-composition-inline-alist-ref
                 sections 'guard #f)
                hooks: hook-values
                runtime-executed: #f
                source: 'poo-flow.composition.inline-profile))))
    (poo-flow-composition-inline-apply-hooks profile hook-values)))

;;; Boundary: a composition lowers into the canonical execution-plan before
;;; any consumer observes it. Bundle/WASM and future projections consume the
;;; same dependency graph rather than reinterpreting composition clauses.

(def (composition-plan-stage-name stage) (.ref stage 'name))
(def (composition-plan-stage-clauses stage) (.ref stage 'clauses))
(def (composition-plan-clause-kind clause) (.ref clause 'clause-kind))
(def (composition-plan-clause-payload clause) (.ref clause 'payload))

(def (composition-plan-stage-by-name stages name)
  (let loop ((rest stages))
    (cond
     ((null? rest) #f)
     ((eq? (composition-plan-stage-name (car rest)) name) (car rest))
     (else (loop (cdr rest))))))

(def (composition-plan-binding-by-name bindings name)
  (let loop ((rest bindings))
    (cond
     ((null? rest) #f)
     ((eq? (.ref (car rest) 'slot) name) (car rest))
     (else (loop (cdr rest))))))

(def (composition-plan-target-clause? kind)
  (or (eq? kind 'step) (eq? kind 'handoff)))

;; : (-> PooCompositionClause PooCompositionStage [PooCompositionStage] [PooProfileBinding] MaybeTarget)
(def (composition-plan-stage-target clause stage stages bindings)
  (let (kind (composition-plan-clause-kind clause))
    (if (not (composition-plan-target-clause? kind))
      #f
      (let (payload (composition-plan-clause-payload clause))
        (unless (and (pair? payload)
                     (null? (cdr payload))
                     (symbol? (car payload)))
          (error "POO-FLOW-PLAN-E101 target requires one symbol"
                 (composition-plan-stage-name stage) kind payload))
        (let (target (car payload))
          (cond
           ((composition-plan-stage-by-name stages target)
            (list 'case target kind))
           ((composition-plan-binding-by-name bindings target)
            (list 'profile target kind))
           (else
            (error "POO-FLOW-PLAN-E102 unknown Case or Profile target"
                   (composition-plan-stage-name stage) kind target))))))))

(def (composition-plan-stage-targets stage stages bindings)
  (filter-map
   (lambda (clause)
     (composition-plan-stage-target clause stage stages bindings))
   (composition-plan-stage-clauses stage)))

(def (composition-plan-explicit-edges stage)
  (append-map
   (lambda (clause)
     (if (not (eq? (composition-plan-clause-kind clause) 'edges))
       '()
       (map
        (lambda (edge)
          (unless (and (pair? edge)
                       (pair? (cdr edge))
                       (null? (cddr edge))
                       (symbol? (car edge))
                       (symbol? (cadr edge)))
            (error "POO-FLOW-PLAN-E103 edge requires two symbols"
                   (composition-plan-stage-name stage) edge))
          (list (car edge) (cadr edge)))
        (composition-plan-clause-payload clause))))
   (composition-plan-stage-clauses stage)))

(def (composition-plan-case-target-names stage stages bindings)
  (filter-map
   (lambda (target)
     (and (eq? (car target) 'case)
          (cadr target)))
   (composition-plan-stage-targets stage stages bindings)))

(def (composition-plan-referenced-case-names stages bindings)
  (fold
   (lambda (stage names)
     (fold
      (lambda (name next)
        (if (memq name next) next (cons name next)))
      names
      (composition-plan-case-target-names stage stages bindings)))
   '()
   stages))

(def (composition-plan-root-stage-names stages bindings)
  (let ((referenced
         (composition-plan-referenced-case-names stages bindings)))
    (filter-map
     (lambda (stage)
       (let (name (composition-plan-stage-name stage))
         (and (not (memq name referenced)) name)))
     stages)))

;; Descriptor = (key name kind source)
(def (composition-plan-descriptor key name kind source)
  (list key name kind source))
(def (composition-plan-descriptor-key descriptor) (car descriptor))
(def (composition-plan-descriptor-name descriptor) (cadr descriptor))
(def (composition-plan-descriptor-kind descriptor) (caddr descriptor))
(def (composition-plan-descriptor-source descriptor) (cadddr descriptor))

(def (composition-plan-path-child path name)
  (string-append path "/" (symbol->string name)))
(def (composition-plan-case-key path) (string-append "case:" path))
(def (composition-plan-profile-key path name)
  (string-append "profile:" (composition-plan-path-child path name)))

(def (composition-plan-target-by-name targets name)
  (find (lambda (target) (eq? (cadr target) name)) targets))

(def (composition-plan-target-key path targets name stage-name)
  (let (target (composition-plan-target-by-name targets name))
    (unless target
      (error "POO-FLOW-PLAN-E104 edge endpoint is not a direct target"
             stage-name name))
    (if (eq? (car target) 'case)
      (composition-plan-case-key (composition-plan-path-child path name))
      (composition-plan-profile-key path name))))

(def (composition-plan-stage-edges stage path targets)
  (map
   (lambda (edge)
     (list
      (composition-plan-target-key
       path targets (car edge) (composition-plan-stage-name stage))
      (composition-plan-target-key
       path targets (cadr edge) (composition-plan-stage-name stage))))
   (composition-plan-explicit-edges stage)))

;; Prepend a forward-ordered chunk to reversed accumulated state.  The final
;; boundary performs one reverse, avoiding quadratic append growth while
;; preserving the source traversal order.
;; : (forall (a) (-> [a] [a] [a]))
;; : (-> List List List)
(def (composition-plan-accumulate chunk reversed)
  (fold cons reversed chunk))

(def (composition-plan-build-case
      stage-name path parent-key stages bindings active)
  (when (memq stage-name active)
    (error "POO-FLOW-PLAN-E105 recursive Case cycle"
           (reverse (cons stage-name active))))
  (let* ((stage (composition-plan-stage-by-name stages stage-name))
         (key (composition-plan-case-key path))
         (targets (composition-plan-stage-targets stage stages bindings))
         (descriptor (composition-plan-descriptor key stage-name 'case stage)))
    (let (descriptors+edges
          (fold
           (lambda (target state)
             (let ((descriptors (car state))
                   (edges (cadr state))
                   (target-kind (car target))
                   (target-name (cadr target)))
               (if (eq? target-kind 'case)
                 (let (child-path
                       (composition-plan-path-child path target-name))
                   (let-values
                       (((child-descriptors child-edges)
                         (composition-plan-build-case
                          target-name child-path key stages bindings
                          (cons stage-name active))))
                     (list
                      (composition-plan-accumulate
                       child-descriptors descriptors)
                      (composition-plan-accumulate child-edges edges))))
                 (let* ((binding
                         (composition-plan-binding-by-name
                          bindings target-name))
                        (profile-key
                         (composition-plan-profile-key path target-name))
                        (profile-descriptor
                         (composition-plan-descriptor
                          profile-key target-name 'profile-instance binding)))
                   (list (cons profile-descriptor descriptors)
                         (cons (list key profile-key) edges))))))
           (list (list descriptor)
                 (if parent-key (list (list parent-key key)) '()))
           targets))
      (values
       (reverse (car descriptors+edges))
       (reverse
        (composition-plan-accumulate
         (composition-plan-stage-edges stage path targets)
         (cadr descriptors+edges)))))))

;; : (-> [CompositionPlanDescriptor] HashTable)
(def (composition-plan-descriptor-index descriptors)
  (let (index (make-hash-table))
    (let loop ((rest descriptors) (ordinal 1))
      (unless (null? rest)
        (let (descriptor (car rest))
          (hash-put! index
                     (composition-plan-descriptor-key descriptor)
                     (cons ordinal descriptor)))
        (loop (cdr rest) (+ ordinal 1))))
    index))

;; : (-> [CompositionPlanEdge] HashTable)
(def (composition-plan-incoming-index edges)
  (let (index (make-hash-table))
    (for-each
     (lambda (edge)
       (let ((source-key (car edge))
             (target-key (cadr edge)))
         (hash-put! index target-key
                    (cons source-key (or (hash-get index target-key) '())))))
     edges)
    index))

;; : (-> Symbol HashTable String PlanNodeId)
(def (composition-plan-node-id flow-name descriptor-index key)
  (let (entry (hash-get descriptor-index key))
    (unless entry
      (error "POO-FLOW-PLAN-E106 unresolved descriptor" key))
    (let ((ordinal (car entry))
          (descriptor (cdr entry)))
      (list 'node flow-name ordinal
          (composition-plan-descriptor-kind descriptor)
          (composition-plan-descriptor-name descriptor)))))

;; : (-> Symbol HashTable HashTable String [PlanNodeId])
(def (composition-plan-dependencies
      flow-name descriptor-index incoming-index target-key)
  (map (lambda (source-key)
         (composition-plan-node-id flow-name descriptor-index source-key))
       (reverse (or (hash-get incoming-index target-key) '()))))

;; : (-> Symbol [CompositionPlanDescriptor] [CompositionPlanEdge] [PlanNode])
(def (composition-plan-make-nodes flow-name descriptors edges)
  (let ((descriptor-index (composition-plan-descriptor-index descriptors))
        (incoming-index (composition-plan-incoming-index edges)))
    (reverse
     (cdr
      (fold
       (lambda (descriptor ordinal+nodes)
         (let ((ordinal (car ordinal+nodes))
               (key (composition-plan-descriptor-key descriptor)))
           (cons
            (+ ordinal 1)
            (cons
             (make-plan-node
              (composition-plan-node-id flow-name descriptor-index key)
              ordinal
              (composition-plan-descriptor-source descriptor)
              (composition-plan-descriptor-kind descriptor)
              (composition-plan-descriptor-name descriptor)
              (composition-plan-dependencies
               flow-name descriptor-index incoming-index key))
             (cdr ordinal+nodes)))))
       (cons 1 '())
       descriptors)))))

;; : (-> PooFlowComposition ExecutionPlan)
(def (poo-flow-composition->execution-plan composition)
  (unless (eq? (.ref composition 'kind) 'poo-flow.composition)
    (error "POO-FLOW-PLAN-E100 expected poo-flow.composition" composition))
  (let* ((name (.ref composition 'name))
         (stages (.ref composition 'stages))
         (bindings (.ref composition 'profile-bindings))
         (root-key (string-append "composition:" (symbol->string name)))
         (root-descriptor
          (composition-plan-descriptor root-key name 'composition composition))
         (roots (composition-plan-root-stage-names stages bindings)))
    (when (null? roots)
      (error "POO-FLOW-PLAN-E107 composition has no acyclic root Case" name))
    (let (descriptors+edges
          (fold
           (lambda (root-name state)
             (let (root-path (symbol->string root-name))
               (let-values
                   (((case-descriptors case-edges)
                     (composition-plan-build-case
                      root-name root-path root-key stages bindings '())))
                 (list
                  (composition-plan-accumulate case-descriptors (car state))
                  (composition-plan-accumulate case-edges (cadr state))))))
           (list (list root-descriptor) '())
           roots))
      (make-execution-plan
       name
       (composition-plan-make-nodes
        name
        (reverse (car descriptors+edges))
        (reverse (cadr descriptors+edges)))
       #f
       #f))))
