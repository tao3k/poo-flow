;;; -*- Gerbil -*-
;;; Boundary: runtime helpers used by user-facing composition macros.
;;; Invariant: keep POO object construction and hook normalization outside
;;; macro parser modules so macro expansion remains shallow and reusable.

(import (only-in :clan/poo/object .all-slots .o .ref object<-alist)
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
  (let ((base-slots (.all-slots base))
        (profile-slots (.all-slots profile)))
    (object<-alist
     (list
      (cons 'name
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'name
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'name 'profile)))
      (cons 'extends
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'extends
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'extends #f)))
      (cons 'kind
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'kind
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'kind 'profile)))
      (cons 'scope
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'scope
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'scope '())))
      (cons 'storage
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'storage
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'storage '())))
      (cons 'analysis
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'analysis
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'analysis '())))
      (cons 'publish
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'publish
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'publish '())))
      (cons 'retention
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'retention
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'retention '())))
      (cons 'capabilities
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'capabilities
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'capabilities '())))
      (cons 'hooks
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'hooks
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'hooks '())))
      (cons 'runtime-executed
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'runtime-executed
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'runtime-executed #f)))
      (cons 'source
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'source
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'source
              'poo-flow.composition.inline-profile)))))))

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
         (hooks (poo-flow-composition-inline-alist-ref sections 'hooks '()))
         (profile
          (if base
            (object<-alist
             (list
              (cons ':extends base)
              (cons 'name profile-name)
              (cons 'extends base)
              (cons 'kind
                    (poo-flow-composition-inline-profile-field
                     sections base 'kind profile-name))
              (cons 'scope
                    (poo-flow-composition-inline-profile-field
                     sections base 'scope '()))
              (cons 'storage
                    (poo-flow-composition-inline-profile-field
                     sections base 'storage '()))
              (cons 'analysis
                    (poo-flow-composition-inline-profile-field
                     sections base 'analysis '()))
              (cons 'publish
                    (poo-flow-composition-inline-profile-field
                     sections base 'publish '()))
              (cons 'retention
                    (poo-flow-composition-inline-profile-field
                     sections base 'retention '()))
              (cons 'capabilities
                    (poo-flow-composition-inline-profile-field
                     sections base 'capabilities '()))
              (cons 'hooks hooks)
              (cons 'runtime-executed #f)
              (cons 'source 'poo-flow.composition.inline-profile)))
            (object<-alist
             (list
              (cons 'name profile-name)
              (cons 'extends #f)
              (cons 'kind
                    (poo-flow-composition-inline-alist-ref
                     sections 'kind profile-name))
              (cons 'scope
                    (poo-flow-composition-inline-alist-ref
                     sections 'scope '()))
              (cons 'storage
                    (poo-flow-composition-inline-alist-ref
                     sections 'storage '()))
              (cons 'analysis
                    (poo-flow-composition-inline-alist-ref
                     sections 'analysis '()))
              (cons 'publish
                    (poo-flow-composition-inline-alist-ref
                     sections 'publish '()))
              (cons 'retention
                    (poo-flow-composition-inline-alist-ref
                     sections 'retention '()))
              (cons 'capabilities
                    (poo-flow-composition-inline-alist-ref
                     sections 'capabilities '()))
              (cons 'hooks hooks)
              (cons 'runtime-executed #f)
              (cons 'source 'poo-flow.composition.inline-profile))))))
    (poo-flow-composition-inline-apply-hooks profile hooks)))

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

(def (composition-plan-stage-targets stage stages bindings)
  (let loop ((rest (composition-plan-stage-clauses stage)) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((clause (car rest))
             (kind (composition-plan-clause-kind clause)))
        (if (not (composition-plan-target-clause? kind))
          (loop (cdr rest) out)
          (let (payload (composition-plan-clause-payload clause))
            (unless (and (pair? payload)
                         (null? (cdr payload))
                         (symbol? (car payload)))
              (error "POO-FLOW-PLAN-E101 target requires one symbol"
                     (composition-plan-stage-name stage) kind payload))
            (let (target (car payload))
              (cond
               ((composition-plan-stage-by-name stages target)
                (loop (cdr rest) (cons (list 'case target kind) out)))
               ((composition-plan-binding-by-name bindings target)
                (loop (cdr rest) (cons (list 'profile target kind) out)))
               (else
                (error "POO-FLOW-PLAN-E102 unknown Case or Profile target"
                       (composition-plan-stage-name stage) kind target))))))))))

(def (composition-plan-explicit-edges stage)
  (let clause-loop ((rest (composition-plan-stage-clauses stage)) (out '()))
    (if (null? rest)
      (reverse out)
      (let (clause (car rest))
        (if (not (eq? (composition-plan-clause-kind clause) 'edges))
          (clause-loop (cdr rest) out)
          (let edge-loop
              ((edges (composition-plan-clause-payload clause)) (next out))
            (if (null? edges)
              (clause-loop (cdr rest) next)
              (let (edge (car edges))
                (unless (and (pair? edge)
                             (pair? (cdr edge))
                             (null? (cddr edge))
                             (symbol? (car edge))
                             (symbol? (cadr edge)))
                  (error "POO-FLOW-PLAN-E103 edge requires two symbols"
                         (composition-plan-stage-name stage) edge))
                (edge-loop (cdr edges)
                           (cons (list (car edge) (cadr edge)) next))))))))))

(def (composition-plan-case-target-names stage stages bindings)
  (let loop
      ((rest (composition-plan-stage-targets stage stages bindings)) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((eq? (caar rest) 'case)
      (loop (cdr rest) (cons (cadar rest) out)))
     (else (loop (cdr rest) out)))))

(def (composition-plan-referenced-case-names stages bindings)
  (let stage-loop ((rest stages) (out '()))
    (if (null? rest)
      out
      (let target-loop
          ((targets
            (composition-plan-case-target-names (car rest) stages bindings))
           (next out))
        (if (null? targets)
          (stage-loop (cdr rest) next)
          (target-loop
           (cdr targets)
           (if (memq (car targets) next)
             next
             (cons (car targets) next))))))))

(def (composition-plan-root-stage-names stages bindings)
  (let ((referenced
         (composition-plan-referenced-case-names stages bindings)))
    (let loop ((rest stages) (out '()))
      (cond
       ((null? rest) (reverse out))
       ((memq (composition-plan-stage-name (car rest)) referenced)
        (loop (cdr rest) out))
       (else
        (loop (cdr rest)
              (cons (composition-plan-stage-name (car rest)) out)))))))

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
  (let loop ((rest targets))
    (cond
     ((null? rest) #f)
     ((eq? (cadar rest) name) (car rest))
     (else (loop (cdr rest))))))

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

(def (composition-plan-build-case
      stage-name path parent-key stages bindings active)
  (when (memq stage-name active)
    (error "POO-FLOW-PLAN-E105 recursive Case cycle"
           (reverse (cons stage-name active))))
  (let* ((stage (composition-plan-stage-by-name stages stage-name))
         (key (composition-plan-case-key path))
         (targets (composition-plan-stage-targets stage stages bindings))
         (descriptor (composition-plan-descriptor key stage-name 'case stage)))
    (let loop
        ((rest targets)
         (descriptors (list descriptor))
         (edges (if parent-key (list (list parent-key key)) '())))
      (if (null? rest)
        (values descriptors
                (append edges
                        (composition-plan-stage-edges stage path targets)))
        (let* ((target (car rest))
               (target-kind (car target))
               (target-name (cadr target)))
          (if (eq? target-kind 'case)
            (let (child-path (composition-plan-path-child path target-name))
              (let-values
                  (((child-descriptors child-edges)
                    (composition-plan-build-case
                     target-name child-path key stages bindings
                     (cons stage-name active))))
                (loop (cdr rest)
                      (append descriptors child-descriptors)
                      (append edges child-edges))))
            (let* ((binding
                    (composition-plan-binding-by-name bindings target-name))
                   (profile-key
                    (composition-plan-profile-key path target-name))
                   (profile-descriptor
                    (composition-plan-descriptor
                     profile-key target-name 'profile-instance binding)))
              (loop (cdr rest)
                    (append descriptors (list profile-descriptor))
                    (append edges (list (list key profile-key)))))))))))

(def (composition-plan-descriptor-by-key descriptors key)
  (let loop ((rest descriptors))
    (cond
     ((null? rest) #f)
     ((equal? (composition-plan-descriptor-key (car rest)) key) (car rest))
     (else (loop (cdr rest))))))

(def (composition-plan-descriptor-ordinal descriptors key)
  (let loop ((rest descriptors) (ordinal 1))
    (cond
     ((null? rest) #f)
     ((equal? (composition-plan-descriptor-key (car rest)) key) ordinal)
     (else (loop (cdr rest) (+ ordinal 1))))))

(def (composition-plan-node-id flow-name descriptors key)
  (let* ((descriptor (composition-plan-descriptor-by-key descriptors key))
         (ordinal (composition-plan-descriptor-ordinal descriptors key)))
    (unless descriptor
      (error "POO-FLOW-PLAN-E106 unresolved descriptor" key))
    (list 'node flow-name ordinal
          (composition-plan-descriptor-kind descriptor)
          (composition-plan-descriptor-name descriptor))))

(def (composition-plan-dependencies flow-name descriptors edges target-key)
  (let loop ((rest edges) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((equal? (cadar rest) target-key)
      (loop (cdr rest)
            (cons (composition-plan-node-id
                   flow-name descriptors (caar rest))
                  out)))
     (else (loop (cdr rest) out)))))

(def (composition-plan-make-nodes flow-name descriptors edges)
  (let loop ((rest descriptors) (ordinal 1) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((descriptor (car rest))
             (key (composition-plan-descriptor-key descriptor))
             (node
              (make-plan-node
               (composition-plan-node-id flow-name descriptors key)
               ordinal
               (composition-plan-descriptor-source descriptor)
               (composition-plan-descriptor-kind descriptor)
               (composition-plan-descriptor-name descriptor)
               (composition-plan-dependencies
                flow-name descriptors edges key))))
        (loop (cdr rest) (+ ordinal 1) (cons node out))))))

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
    (let loop
        ((rest roots) (descriptors (list root-descriptor)) (edges '()))
      (if (null? rest)
        (make-execution-plan
         name
         (composition-plan-make-nodes name descriptors edges)
         #f
         #f)
        (let* ((root-name (car rest))
               (root-path (symbol->string root-name)))
          (let-values
              (((case-descriptors case-edges)
                (composition-plan-build-case
                 root-name root-path root-key stages bindings '())))
            (loop (cdr rest)
                  (append descriptors case-descriptors)
                  (append edges case-edges))))))))
