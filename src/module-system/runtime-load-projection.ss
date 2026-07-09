;;; -*- Gerbil -*-
;;; Boundary: runtime-facing projection for user-interface module fragments.
;;; Invariant: runtime adapters load user fragments through the same
;;; `use-module` surface; module-specific projection remains behind this
;;; module-system boundary.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-flags
                 poo-flow-user-module-selection-key)
        (only-in :poo-flow/src/module-system/profile-composition-accessors
                 poo-flow-composition?
                 poo-flow-composition-name
                 poo-flow-composition-profiles
                 poo-flow-composition-stage-clauses
                 poo-flow-composition-stage-name
                 poo-flow-composition-stages)
        (only-in :poo-flow/src/modules/funflow/config
                 funflow-plan
                 poo-flow-funflow-plan->runtime-projection))

(export poo-flow-runtime-load-projection
        poo-flow-runtime-load-write!)

;; : (-> Alist Symbol Object)
(def (poo-flow-runtime-load-flag-ref flags key)
  (cond
   ((null? flags) #f)
   ((and (pair? (car flags))
         (eq? (caar flags) key))
    (cdar flags))
   (else
    (poo-flow-runtime-load-flag-ref (cdr flags) key))))

;; : (-> [PooObject] PooObject)
(def (poo-flow-runtime-load-first-selection selections)
  (if (pair? selections)
    (car selections)
    (error "runtime load expected use-module selection list" selections)))

;; : (-> Object Boolean)
(def (poo-flow-runtime-load-composition? value)
  (and (object? value)
       (.slot? value 'kind)
       (poo-flow-composition? value)))

;; : (-> Object Boolean)
(def (poo-flow-runtime-load-funflow-profile? profile)
  (and (object? profile)
       (.slot? profile 'module)
       (eq? (.ref profile 'module) 'funflow)))

;; : (-> [PooObject] Boolean)
(def (poo-flow-runtime-load-has-funflow-profile? profiles)
  (cond
   ((null? profiles) #f)
   ((poo-flow-runtime-load-funflow-profile? (car profiles)) #t)
   (else
    (poo-flow-runtime-load-has-funflow-profile? (cdr profiles)))))

;; : (-> PooObject Symbol)
(def (poo-flow-runtime-load-step-clause-name clause)
  (let ((payload (.ref clause 'payload)))
    (if (and (pair? payload)
             (symbol? (car payload)))
      (car payload)
      (error "runtime load expected step clause payload" payload))))

;; : (-> PooObject [Symbol])
(def (poo-flow-runtime-load-clause-step-names clause)
  (if (eq? (.ref clause 'clause-kind) 'step)
    (list (poo-flow-runtime-load-step-clause-name clause))
    '()))

;; : (-> [PooObject] [Symbol])
(def (poo-flow-runtime-load-clause-list-step-names clauses)
  (cond
   ((null? clauses) '())
   (else
    (append (poo-flow-runtime-load-clause-step-names (car clauses))
            (poo-flow-runtime-load-clause-list-step-names (cdr clauses))))))

;; : (-> PooObject [Symbol])
(def (poo-flow-runtime-load-stage-step-names stage)
  (poo-flow-runtime-load-clause-list-step-names
   (poo-flow-composition-stage-clauses stage)))

;; : (-> [PooObject] [Symbol])
(def (poo-flow-runtime-load-composition-step-names stages)
  (cond
   ((null? stages) '())
   (else
    (append (poo-flow-runtime-load-stage-step-names (car stages))
            (poo-flow-runtime-load-composition-step-names (cdr stages))))))

;; : (-> Symbol Alist)
(def (poo-flow-runtime-load-node-row node)
  (list (cons 'name node)
        (cons 'kind 'funflow-step)
        (cons 'runtime-executed #f)))

;; : (-> [Symbol] [Alist])
(def (poo-flow-runtime-load-node-rows nodes)
  (cond
   ((null? nodes) '())
   (else
    (cons (poo-flow-runtime-load-node-row (car nodes))
          (poo-flow-runtime-load-node-rows (cdr nodes))))))

;; : (-> [Object] Alist)
(def (poo-flow-runtime-load-edge-row edge)
  (if (and (pair? edge)
           (pair? (cdr edge))
           (pair? (cddr edge))
           (null? (cdddr edge))
           (eq? (cadr edge) '->)
           (symbol? (car edge))
           (symbol? (caddr edge)))
    (list (cons 'kind 'poo-flow.funflow.dag-edge)
          (cons 'from (car edge))
          (cons 'to (caddr edge))
          (cons 'runtime-executed #f))
    (error "runtime load expected edge payload shaped as (from -> to)" edge)))

;; : (-> [Object] [Alist])
(def (poo-flow-runtime-load-edge-rows edges)
  (cond
   ((null? edges) '())
   (else
    (cons (poo-flow-runtime-load-edge-row (car edges))
          (poo-flow-runtime-load-edge-rows (cdr edges))))))

;; : (-> PooObject [Alist])
(def (poo-flow-runtime-load-clause-edge-rows clause)
  (if (eq? (.ref clause 'clause-kind) 'edges)
    (poo-flow-runtime-load-edge-rows (.ref clause 'payload))
    '()))

;; : (-> [PooObject] [Alist])
(def (poo-flow-runtime-load-clause-list-edge-rows clauses)
  (cond
   ((null? clauses) '())
   (else
    (append (poo-flow-runtime-load-clause-edge-rows (car clauses))
            (poo-flow-runtime-load-clause-list-edge-rows (cdr clauses))))))

;; : (-> PooObject [Alist])
(def (poo-flow-runtime-load-stage-edge-rows stage)
  (poo-flow-runtime-load-clause-list-edge-rows
   (poo-flow-composition-stage-clauses stage)))

;; : (-> [PooObject] [Alist])
(def (poo-flow-runtime-load-composition-edge-rows stages)
  (cond
   ((null? stages) '())
   (else
    (append (poo-flow-runtime-load-stage-edge-rows (car stages))
            (poo-flow-runtime-load-composition-edge-rows (cdr stages))))))

;; : (-> Symbol Symbol Symbol Alist)
(def (poo-flow-runtime-load-source-map-row composition-name stage-name step-name)
  (list (cons 'stage step-name)
        (cons 'source 'use-composition-funflow)
        (cons 'path
              (list 'use-composition 'funflow composition-name stage-name step-name))))

;; : (-> Symbol Symbol [Symbol] [Alist])
(def (poo-flow-runtime-load-source-map-stage-rows composition-name stage-name nodes)
  (cond
   ((null? nodes) '())
   (else
    (cons (poo-flow-runtime-load-source-map-row
           composition-name
           stage-name
           (car nodes))
          (poo-flow-runtime-load-source-map-stage-rows
           composition-name
           stage-name
           (cdr nodes))))))

;; : (-> PooObject PooObject [Alist])
(def (poo-flow-runtime-load-stage-source-map-rows composition stage)
  (poo-flow-runtime-load-source-map-stage-rows
   (poo-flow-composition-name composition)
   (poo-flow-composition-stage-name stage)
   (poo-flow-runtime-load-stage-step-names stage)))

;; : (-> PooObject [PooObject] [Alist])
(def (poo-flow-runtime-load-composition-source-map-rows composition stages)
  (cond
   ((null? stages) '())
   (else
    (append (poo-flow-runtime-load-stage-source-map-rows composition
                                                         (car stages))
            (poo-flow-runtime-load-composition-source-map-rows composition
                                                               (cdr stages))))))

;; : (-> PooObject PooObject)
(def (poo-flow-runtime-load-composition->funflow-plan composition)
  (let* ((profiles (poo-flow-composition-profiles composition))
         (_funflow-profile
          (if (poo-flow-runtime-load-has-funflow-profile? profiles)
            #t
            (error "runtime load expected a composed funflow profile"
                   profiles)))
         (stages (poo-flow-composition-stages composition))
         (nodes (poo-flow-runtime-load-composition-step-names stages))
         (edge-rows (poo-flow-runtime-load-composition-edge-rows stages))
         (source-map
          (poo-flow-runtime-load-composition-source-map-rows composition
                                                            stages)))
    (object<-alist
     (list
      (cons 'kind (.ref funflow-plan 'kind))
      (cons 'schema 'poo-flow.modules.funflow.plan.v1)
      (cons 'name (poo-flow-composition-name composition))
      (cons 'version 1)
      (cons 'origin 'use-composition-funflow)
      (cons 'normalized-flow (poo-flow-composition-name composition))
      (cons 'node-table
            (list->vector (poo-flow-runtime-load-node-rows nodes)))
      (cons 'edge-table (list->vector edge-rows))
      (cons 'policy-table
            (vector
             (list (cons 'policy-family 'funflow)
                   (cons 'profiles
                         (map (lambda (profile) (.ref profile 'name))
                              profiles)))))
      (cons 'effect-table '#())
      (cons 'runtime-contract 'poo-flow.anyio.v1)
      (cons 'source-map source-map)
      (cons 'diagnostics '())
      (cons 'valid? #t)
      (cons 'runtime-owner "python-anyio")
      (cons 'runtime-executed #f)))))

;; : (-> PooObject Alist)
(def (poo-flow-runtime-load-composition-projection composition)
  (poo-flow-funflow-plan->runtime-projection
   (poo-flow-runtime-load-composition->funflow-plan composition)))

;; : (-> [PooObject] Alist)
(def (poo-flow-runtime-load-selection-projection selections)
  (let* ((selection (poo-flow-runtime-load-first-selection selections))
         (key (poo-flow-user-module-selection-key selection))
         (flags (poo-flow-user-module-selection-flags selection))
         (funflow-plan (poo-flow-runtime-load-flag-ref flags ':funflow-plan)))
    (cond
     (funflow-plan
      (poo-flow-funflow-plan->runtime-projection funflow-plan))
     (else
      (error "runtime load does not have a projection for module" key)))))

;; : (-> Object Alist)
(def (poo-flow-runtime-load-projection value)
  (cond
   ((poo-flow-runtime-load-composition? value)
    (poo-flow-runtime-load-composition-projection value))
   (else
    (poo-flow-runtime-load-selection-projection value))))

;; : (-> [PooObject] Void)
(def (poo-flow-runtime-load-write! selections)
  (write (poo-flow-runtime-load-projection selections))
  (newline))
