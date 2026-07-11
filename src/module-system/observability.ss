;;; -*- Gerbil -*-
;;; Boundary: strict observability data for module-system debugging.
;;; Invariant: observations do not use POO objects, lazy slots, or runtime adapters.
;;; Intent: make recursive presentation paths visible without participating in them.

(import (only-in :std/sugar filter)
        :poo-flow/src/module-system/projection-syntax)

(export poo-flow-module-observation-kind
        make-poo-flow-module-observation
        poo-flow-module-observation?
        poo-flow-module-observation-scope
        poo-flow-module-observation-stage
        poo-flow-module-observation-status
        poo-flow-module-observation-count
        poo-flow-module-observation-depth
        poo-flow-module-observation-path
        poo-flow-module-observation-detail
        poo-flow-module-observation-descriptor-realized?
        poo-flow-module-observation-runtime-executed?
        poo-flow-module-observation-recursive-stage?
        poo-flow-module-observation-stage-status
        poo-flow-module-observation-stage/detail
        poo-flow-module-observation-stage/alist
        poo-flow-module-observation->alist
        poo-flow-module-presentation-trace
        poo-flow-module-presentation-trace/add
        poo-flow-poo-slot-authoring-observation-kind
        make-poo-flow-poo-slot-authoring-observation
        poo-flow-poo-slot-authoring-observation?
        poo-flow-poo-slot-authoring-observation-scope
        poo-flow-poo-slot-authoring-observation-slot
        poo-flow-poo-slot-authoring-observation-initializer
        poo-flow-poo-slot-authoring-observation-status
        poo-flow-poo-slot-authoring-observation-detail
        poo-flow-poo-slot-authoring-observation-descriptor-realized?
        poo-flow-poo-slot-authoring-observation-runtime-executed?
        poo-flow-poo-slot-authoring-self-reference?
        poo-flow-poo-slot-authoring-primitive-slot?
        poo-flow-poo-slot-authoring-status
        poo-flow-poo-slot-authoring-observation/alist
        poo-flow-poo-slot-authoring-observations
        poo-flow-poo-slot-authoring-summary-kind
        poo-flow-poo-slot-authoring-observation-ok?
        poo-flow-poo-slot-authoring-statuses
        poo-flow-poo-slot-authoring-diagnostics
        poo-flow-poo-slot-authoring-summary)

;;; Observation kind ids are shared by doctor, user-config, and future CLI
;;; surfaces so tooling can recognize one trace vocabulary across projections.
;; : (-> Unit PooFlowModuleObservationKind)
(def poo-flow-module-observation-kind
  "poo-flow.modules.observation.v1")

;;; Observation records are strict structs. This keeps debug data inspectable
;;; even when the problem being debugged is a lazy POO `.ref` recursion.
;; : (-> Symbol Symbol Symbol Integer Integer [Symbol] Alist Boolean Boolean PooFlowModuleObservation)
(defstruct poo-flow-module-observation
  (scope
   stage
   status
   count
   depth
   path
   detail
   descriptor-realized?
   runtime-executed?)
  transparent: #t)

;;; Recursive-stage detection is intentionally just path membership. The
;;; framework should flag suspicious projection shape without interpreting
;;; descriptor semantics or executing module loaders.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-module-observation-recursive-stage? stage active-path)
  (and (member stage active-path) #t))

;;; Stage status stays finite and symbolic so test fixtures can assert on it
;;; without parsing messages or stack traces.
;; : (-> Symbol [Symbol] Symbol)
(def (poo-flow-module-observation-stage-status stage active-path)
  (if (poo-flow-module-observation-recursive-stage? stage active-path)
    'recursive-stage
    'ok))

;;; Stage observations record the path after the stage is entered. A repeated
;;; stage therefore carries both a `recursive-stage` status and the full path
;;; needed to reproduce the problematic projection walk.
;; : (forall (a) (-> [a] [a] [a]))
(def (poo-flow-module-observation-values/tail values tail)
  (append values tail))

;; : (-> Symbol Symbol Integer [Symbol] Alist PooFlowModuleObservation)
(def (poo-flow-module-observation-stage/detail
      scope
      stage
      count
      active-path
      detail)
  (make-poo-flow-module-observation
   scope
   stage
   (poo-flow-module-observation-stage-status stage active-path)
   count
   (length active-path)
   (poo-flow-module-observation-values/tail active-path (list stage))
   detail
   #f
   #f))

;;; Alist projection is the safe edge for user-interface and doctor outputs.
;; : (-> PooFlowModuleObservation Alist)
(defpoo-module-final-projection
  poo-flow-module-observation->alist (observation)
  (bindings ())
  (fields ((kind poo-flow-module-observation-kind)
           (scope (poo-flow-module-observation-scope observation))
           (stage (poo-flow-module-observation-stage observation))
           (status (poo-flow-module-observation-status observation))
           (count (poo-flow-module-observation-count observation))
           (depth (poo-flow-module-observation-depth observation))
           (path (poo-flow-module-observation-path observation))
           (detail (poo-flow-module-observation-detail observation))
           (descriptor-realized?
            (poo-flow-module-observation-descriptor-realized? observation))
           (runtime-executed
            (poo-flow-module-observation-runtime-executed? observation)))))

;;; Stage/alist keeps the common presentation path concise while still routing
;;; every trace row through the strict observation record.
;; : (-> Symbol Symbol Integer [Symbol] Alist)
(def (poo-flow-module-observation-stage/alist scope stage count active-path)
  (poo-flow-module-observation->alist
   (poo-flow-module-observation-stage/detail
    scope
    stage
    count
    active-path
    '())))

;;; Trace construction is a simple left-to-right walk over `(stage . count)`
;;; pairs. Repeated stages stay in the output with `recursive-stage` status
;;; instead of raising while the caller is trying to inspect a broken projection.
;; : (-> Symbol [Pair] [Symbol] [Alist])
(def (poo-flow-module-presentation-trace/add scope stage-counts active-path)
  (cond
   ((null? stage-counts) '())
   (else
    (let ((entry (car stage-counts)))
      (cons (poo-flow-module-observation-stage/alist
             scope
             (car entry)
             (cdr entry)
             active-path)
            (poo-flow-module-presentation-trace/add
             scope
             (cdr stage-counts)
             (poo-flow-module-observation-values/tail
              active-path
              (list (car entry)))))))))

;;; Presentation traces are report-only data. They are safe to read before
;;; heavier slots because they do not dereference POO objects or realize modules.
;; : (-> Symbol [Pair] [Alist])
(def (poo-flow-module-presentation-trace scope stage-counts)
  (poo-flow-module-presentation-trace/add scope stage-counts '()))

;;; POO authoring observations inspect source-shaped slot bindings, not POO
;;; objects. This catches `.o slot: slot` style self references before a `.ref`
;;; path can recurse or allocate during debugging.
;; : (-> Unit PooFlowPooSlotAuthoringObservationKind)
(def poo-flow-poo-slot-authoring-observation-kind
  "poo-flow.poo-slot-authoring-observation.v1")

;; : (-> Symbol Symbol Value Symbol Alist Boolean Boolean PooFlowPooSlotAuthoringObservation)
(defstruct poo-flow-poo-slot-authoring-observation
  (scope
   slot
   initializer
   status
   detail
   descriptor-realized?
   runtime-executed?)
  transparent: #t)

;; : (-> Symbol Value Boolean)
(def (poo-flow-poo-slot-authoring-self-reference? slot initializer)
  (and (symbol? slot)
       (symbol? initializer)
       (eq? slot initializer)))

;; : [Symbol]
(def +poo-flow-poo-slot-authoring-primitive-slots+
  '(.o .def .ref .slot? object?))

;;; Boundary: poo slot authoring primitive slot predicate is the policy-visible
;;; edge for module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Symbol Boolean)
(def (poo-flow-poo-slot-authoring-primitive-slot? slot)
  (and (symbol? slot)
       (member slot +poo-flow-poo-slot-authoring-primitive-slots+)
       #t))

;;; Boundary: poo slot authoring status is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Symbol Value Symbol)
(def (poo-flow-poo-slot-authoring-status slot initializer)
  (cond
   ((poo-flow-poo-slot-authoring-self-reference? slot initializer)
    'self-referential-slot-initializer)
   ((poo-flow-poo-slot-authoring-primitive-slot? slot)
    'primitive-shadow-slot)
   (else 'ok)))

;;; Boundary: poo slot authoring detail is the policy-visible edge for module-
;;; system behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Symbol Value Alist)
(def (poo-flow-poo-slot-authoring-detail slot initializer)
  (cond
   ((poo-flow-poo-slot-authoring-self-reference? slot initializer)
    (list (cons 'code 'poo-slot-initializer-shadows-slot)
          (cons 'rule 'poo-slot-initializer-must-not-shadow-slot-name)
          (cons 'slot slot)
          (cons 'initializer initializer)
          (cons 'recommendation 'rename-local-or-wrap-in-helper)))
   ((poo-flow-poo-slot-authoring-primitive-slot? slot)
    (list (cons 'code 'poo-slot-shadows-poo-primitive)
          (cons 'rule 'poo-slot-must-not-shadow-poo-primitive)
          (cons 'slot slot)
          (cons 'initializer initializer)
          (cons 'recommendation 'rename-slot-or-use-result-prefix)))
   (else '())))

;; : (-> Symbol Symbol Value PooFlowPooSlotAuthoringObservation)
(def (poo-flow-poo-slot-authoring-observation/make scope slot initializer)
  (make-poo-flow-poo-slot-authoring-observation
   scope
   slot
   initializer
   (poo-flow-poo-slot-authoring-status slot initializer)
   (poo-flow-poo-slot-authoring-detail slot initializer)
   #f
   #f))

;; : (-> PooFlowPooSlotAuthoringObservation Alist)
(defpoo-module-final-projection
  poo-flow-poo-slot-authoring-observation->alist (observation)
  (bindings ())
  (fields ((kind poo-flow-poo-slot-authoring-observation-kind)
           (scope
            (poo-flow-poo-slot-authoring-observation-scope observation))
           (slot
            (poo-flow-poo-slot-authoring-observation-slot observation))
           (initializer
            (poo-flow-poo-slot-authoring-observation-initializer observation))
           (status
            (poo-flow-poo-slot-authoring-observation-status observation))
           (detail
            (poo-flow-poo-slot-authoring-observation-detail observation))
           (descriptor-realized?
            (poo-flow-poo-slot-authoring-observation-descriptor-realized?
             observation))
           (runtime-executed
            (poo-flow-poo-slot-authoring-observation-runtime-executed?
             observation)))))

;; : (-> Symbol Pair Alist)
(def (poo-flow-poo-slot-authoring-observation/alist scope slot-initializer)
   (poo-flow-poo-slot-authoring-observation->alist
   (poo-flow-poo-slot-authoring-observation/make
    scope
    (car slot-initializer)
    (cdr slot-initializer))))

;; : (forall (k v) (-> Symbol [(Pair k v)] [Alist]))
;; : (-> Symbol [Pair] [Alist])
(def (poo-flow-poo-slot-authoring-observations scope slot-initializers)
  (map (lambda (slot-initializer)
         (poo-flow-poo-slot-authoring-observation/alist
          scope
          slot-initializer))
       slot-initializers))

;; : (-> Unit PooFlowPooSlotAuthoringSummaryKind)
(def poo-flow-poo-slot-authoring-summary-kind
  "poo-flow.poo-slot-authoring-summary.v1")

;; : (-> Alist Boolean)
(def (poo-flow-poo-slot-authoring-observation-ok? observation)
  (eq? (cdr (assoc 'status observation)) 'ok))

;; : (forall (k v) (-> [(Pair k v)] [Symbol]))
;; : (-> [Alist] [Symbol])
(def (poo-flow-poo-slot-authoring-statuses observations)
  (map (lambda (observation)
         (cdr (assoc 'status observation)))
       observations))

;;; Boundary: poo slot authoring diagnostics is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)]))
;; : (-> [Alist] [Alist])
(def (poo-flow-poo-slot-authoring-diagnostics observations)
  (map (lambda (observation)
         (cdr (assoc 'detail observation)))
       (filter (lambda (observation)
                 (not (poo-flow-poo-slot-authoring-observation-ok?
                       observation)))
               observations)))

;; : (-> Symbol [Alist] Alist)
(defpoo-module-final-projection
  poo-flow-poo-slot-authoring-summary (scope observations)
  (bindings ((diagnostics
              (poo-flow-poo-slot-authoring-diagnostics observations))))
  (fields ((kind poo-flow-poo-slot-authoring-summary-kind)
           (scope scope)
           (observation-count (length observations))
           (statuses
            (poo-flow-poo-slot-authoring-statuses observations))
           (diagnostic-count (length diagnostics))
           (diagnostics diagnostics)
           (descriptor-realized? #f)
           (runtime-executed #f))))
