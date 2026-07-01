;;; -*- Gerbil -*-
;;; Owner: Tutorial2 custom task alignment lives in this module.
;;; Boundary: core provides descriptor, strategy, runner, and adapter protocols.
;;; Import contract: users opt in through =:poo-flow/src/modules/custom-task= exports.
;;; Runtime contract: this module emits Tutorial2 task data only.
;;; Runtime contract: repeat-task interpretation stays behind the local adapter.
;;; Runtime contract: scheduler and plan semantics stay out of this extension.
;;; Policy evidence: tests should assert registry, task shape, and interpreter result.

(import :poo-flow/src/core/api
        :poo-flow/src/core/projection-syntax)

(export custom-task-family-descriptor
        make-custom-task-family-registry
        custom-enable-strategy
        make-custom-enabled-strategy
        make-custom-run-config
        make-custom-repeat-spec
        custom-repeat-spec?
        custom-repeat-spec-text
        custom-repeat-spec-count
        make-custom-repeat-task
        task-custom-operation
        task-custom-payload
        task-custom-repeat?
        custom-repeat-flow)

;; : (-> Unit TaskFamilyDescriptor)
(def custom-task-family-descriptor
  (make-task-family-descriptor 'custom 'custom 'local 'gerbil #f))

;;; Boundary:
;;; - Registry module extension is immutable.
;;; - Callers may pass a base registry or use the core default.
;; : (-> [TaskFamilyRegistry] TaskFamilyRegistry)
(def (make-custom-task-family-registry . maybe-registry)
  (task-family-registry-extend
   (if (null? maybe-registry) default-task-family-registry (car maybe-registry))
   custom-task-family-descriptor))

;;; Invariant:
;;; - Capability lists stay set-like.
;;; - Existing capabilities keep their original order.
;; : (forall (a) (-> [a] [a] [a]))
(def (custom-task-values/tail values tail)
  (let loop ((remaining-values values)
             (values-rev '()))
    (if (null? remaining-values)
      (let restore ((remaining-rev values-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-values)
            (cons (car remaining-values) values-rev)))))

;; : (-> [Symbol] Symbol [Symbol])
(def (capabilities-with capability-set capability)
  (if (memq capability capability-set)
    capability-set
    (custom-task-values/tail capability-set (list capability))))

;;; Boundary:
;;; - Custom capability is opt-in at the extension edge.
;;; - Core strategies stay unaware of Tutorial2 task semantics.
;; : (-> Strategy Strategy)
(def (custom-enable-strategy strategy)
  (make-strategy (strategy-name strategy)
                 (capabilities-with (strategy-capabilities strategy) 'custom)
                 (strategy-cache-policy strategy)
                 (strategy-failure-policy strategy)
                 (strategy-planner strategy)))

;;; Boundary:
;;; - Default custom strategy starts from core local eager policy.
;;; - Extension capability is added only through =custom-enable-strategy=.
;; : (-> Unit Strategy)
(def (make-custom-enabled-strategy)
  (custom-enable-strategy (make-local-eager-strategy)))

;;; Boundary:
;;; - Run config installs the custom registry for local interpretation.
;;; - Runtime adapters remain placeholders because this task family is local.
;; : (-> [Alist] RunConfig)
(def (make-custom-run-config . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (make-run-config 'custom-local
                     (make-custom-enabled-strategy)
                     (make-request-only-adapter)
                     (poo-flow-core-field-rows/tail
                      options
                      (runtime 'gerbil)
                      (extension 'custom-task))
                     (make-custom-task-family-registry)
                     default-flow-declaration-registry)))

;; : (-> String Nat CustomRepeatSpec)
(defstruct custom-repeat-spec
  (text
   count)
  transparent: #t)

;;; Invariant:
;;; - Non-positive repeat counts return an empty suffix.
;;; - Tutorial2 custom task behavior stays local and deterministic.
;; : (-> String Nat String)
(def (repeat-string text count)
  (if (<= count 0)
    ""
    (string-append text (repeat-string text (- count 1)))))

;;; Boundary:
;;; - Operation access is limited to custom tasks.
;;; - Non-custom tasks project to =#f= instead of raising.
;; : (-> Task (U Symbol #f))
(def (task-custom-operation task)
  (if (eq? (task-kind task) 'custom)
    (task-request-operation task)
    #f))

;;; Boundary:
;;; - Payload access is limited to custom tasks.
;;; - Non-custom tasks project to =#f= for descriptor probes.
;; : (-> Task (U Payload #f))
(def (task-custom-payload task)
  (if (eq? (task-kind task) 'custom)
    (task-request-payload task)
    #f))

;;; Boundary:
;;; - Repeat detection is descriptor-level policy.
;;; - Execution still belongs to the custom repeat task executor.
;; : (-> Task Boolean)
(def (task-custom-repeat? task)
  (eq? (task-custom-operation task) 'repeat))

;;; Boundary:
;;; - Custom task declarations remain request data.
;;; - This extension owns the Tutorial2 interpreter weave point.
;; : (-> Symbol String Nat Contract Contract Task)
(def (make-custom-repeat-task name text count input-contract output-contract)
  (let (spec (make-custom-repeat-spec text count))
    (make-task name
               'custom
               (list 'custom 'repeat spec)
               input-contract
               output-contract
               (lambda (input)
                 (string-append input
                                (repeat-string
                                 (custom-repeat-spec-text spec)
                                 (custom-repeat-spec-count spec)))))))

;;; Boundary:
;;; - Public users construct a flow, not the raw custom task.
;;; - The task descriptor remains inspectable through =flow-steps=.
;; : (-> Symbol String Nat Contract Contract Flow)
(def (custom-repeat-flow name text count input-contract output-contract)
  (task-flow name
             (make-custom-repeat-task name
                                      text
                                      count
                                      input-contract
                                      output-contract)))
