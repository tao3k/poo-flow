;;; -*- Gerbil -*-
;;; Boundary: durable recovery scenario receipts for crash/replay/repair tests.
;;; Invariant: Scheme composes bounded handoff rows only; Rust/Marlin owns
;;; event persistence, replay, repair jobs, leases, and side effects.

(import :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/module-system/durable-runtime-store)

(export +poo-flow-durable-recovery-scenario-kind+
        +poo-flow-durable-recovery-scenario-schema+
        +poo-flow-durable-recovery-scenario-diagnostic-schema+
        +poo-flow-durable-recovery-observability-schema+
        +poo-flow-durable-recovery-stages+
        make-poo-flow-durable-recovery-scenario-receipt
        poo-flow-durable-recovery-scenario-receipt?
        poo-flow-durable-recovery-scenario-receipt-scenario-id
        poo-flow-durable-recovery-scenario-receipt-project-id
        poo-flow-durable-recovery-scenario-receipt-root-session-id
        poo-flow-durable-recovery-scenario-receipt-session-id
        poo-flow-durable-recovery-scenario-receipt-failure-kind
        poo-flow-durable-recovery-scenario-receipt-recovery-mode
        poo-flow-durable-recovery-scenario-receipt-runtime-store-row
        poo-flow-durable-recovery-scenario-receipt-session-graph-row
        poo-flow-durable-recovery-scenario-receipt-communication-rows
        poo-flow-durable-recovery-scenario-receipt-memory-job-rows
        poo-flow-durable-recovery-scenario-receipt-workflow-task-rows
        poo-flow-durable-recovery-scenario-receipt-sandbox-refs
        poo-flow-durable-recovery-scenario-receipt-checkpoint-ref
        poo-flow-durable-recovery-scenario-receipt-repair-policy-ref
        poo-flow-durable-recovery-scenario-receipt-event-log-ref
        poo-flow-durable-recovery-scenario-receipt-derived-index-ref
        poo-flow-durable-recovery-scenario-receipt-job-lease-ref
        poo-flow-durable-recovery-scenario-receipt-repair-journal-ref
        poo-flow-durable-recovery-scenario-receipt-deterministic-replay?
        poo-flow-durable-recovery-scenario-receipt-observability-rows
        poo-flow-durable-recovery-scenario-receipt-valid?
        poo-flow-durable-recovery-scenario-receipt-diagnostics
        poo-flow-durable-recovery-scenario-receipt-metadata
        poo-flow-durable-recovery-scenario
        poo-flow-durable-recovery-scenario->alist
        poo-flow-durable-recovery-scenarios->alists)

(def +poo-flow-durable-recovery-scenario-kind+
  'poo-flow.durable.recovery-scenario)

(def +poo-flow-durable-recovery-scenario-schema+
  'poo-flow.module-system.durable-recovery-scenario.v1)

(def +poo-flow-durable-recovery-scenario-diagnostic-schema+
  'poo-flow.module-system.durable-recovery-scenario.diagnostic.v1)

(def +poo-flow-durable-recovery-observability-schema+
  'poo-flow.module-system.durable-recovery-scenario.observability.v1)

(def +poo-flow-durable-recovery-stages+
  '(durable-event-append
    checkpoint-read
    derived-index-rebuild
    job-lease-claim
    repair-event-append
    recovery-decision))

;; : (forall (a) (-> Alist Symbol a a))
(def (poo-flow-durable-recovery-alist-ref row key default-value)
  (if (list? row)
    (let (entry (assoc key row))
      (if entry (cdr entry) default-value))
    default-value))

;; : (forall (a) (-> Alist Symbol a a))
(def (poo-flow-durable-recovery-option options key default-value)
  (poo-flow-durable-recovery-alist-ref options key default-value))

;; : (-> Procedure List Boolean)
(def (poo-flow-durable-recovery-every? predicate values)
  (cond
   ((null? values) #t)
   ((predicate (car values))
    (poo-flow-durable-recovery-every? predicate (cdr values)))
   (else #f)))

;; : (forall (a) (-> a (List a) Boolean))
(def (poo-flow-durable-recovery-member? value values)
  (if (member value values) #t #f))

;; : (-> Datum Boolean)
(def (poo-flow-durable-recovery-alist? value)
  (list? value))

;; : (-> Datum Boolean)
(def (poo-flow-durable-recovery-row-valid? row)
  (eq? (poo-flow-durable-recovery-alist-ref row 'valid? #f) #t))

;; : (-> Symbol Symbol Symbol Alist Alist)
(def (poo-flow-durable-recovery-diagnostic code slot severity payload)
  (list
   (cons 'kind +poo-flow-durable-recovery-scenario-diagnostic-schema+)
   (cons 'schema +poo-flow-durable-recovery-scenario-diagnostic-schema+)
   (cons 'code code)
   (cons 'phase 'durable-recovery-scenario)
   (cons 'slot slot)
   (cons 'severity severity)
   (cons 'payload payload)
   (cons 'recoverable?
         (poo-flow-durable-recovery-option payload 'recoverable? #t))
   (cons 'runtime-executed #f)))

;; : (-> Symbol Symbol Datum [Alist])
(def (poo-flow-durable-recovery-required-symbol-diagnostics code slot value)
  (if (symbol? value)
    '()
    (list
     (poo-flow-durable-recovery-diagnostic
      code
      slot
      'error
      (list (cons 'value value)
            (cons 'expected 'symbol)
            (cons 'recoverable? #t))))))

;; : (-> Datum Alist)
(def (poo-flow-durable-recovery-runtime-store-row runtime-store-receipt)
  (cond
   ((poo-flow-durable-runtime-store-contract-receipt?
     runtime-store-receipt)
    (poo-flow-durable-runtime-store-contract-receipt->alist
     runtime-store-receipt))
   ((list? runtime-store-receipt) runtime-store-receipt)
   (else runtime-store-receipt)))

;; : (-> Alist [Alist])
(def (poo-flow-durable-recovery-runtime-store-diagnostics runtime-store-row)
  (cond
   ((not (poo-flow-durable-recovery-alist? runtime-store-row))
    (list
     (poo-flow-durable-recovery-diagnostic
      'invalid-runtime-store-receipt
      'runtime-store-row
      'error
      (list (cons 'value runtime-store-row)
            (cons 'recoverable? #t)))))
   ((not (eq? (poo-flow-durable-recovery-alist-ref
               runtime-store-row
               'kind
               #f)
              'poo-flow.durable.runtime-store-contract-receipt))
    (list
     (poo-flow-durable-recovery-diagnostic
      'invalid-runtime-store-receipt
      'runtime-store-row
      'error
      (list (cons 'kind
                  (poo-flow-durable-recovery-alist-ref
                   runtime-store-row
                   'kind
                   #f))
            (cons 'recoverable? #t)))))
   ((poo-flow-durable-recovery-row-valid? runtime-store-row) '())
   (else
    (list
     (poo-flow-durable-recovery-diagnostic
      'runtime-store-receipt-invalid
      'runtime-store-row
      'error
      (list (cons 'diagnostics
                  (poo-flow-durable-recovery-alist-ref
                   runtime-store-row
                   'diagnostics
                   '()))
            (cons 'recoverable? #t)))))))

;; : (-> Alist Symbol Value)
(def (poo-flow-durable-recovery-runtime-store-ref runtime-store-row key)
  (poo-flow-durable-recovery-alist-ref runtime-store-row key #f))

;; : (-> Alist Boolean)
(def (poo-flow-durable-recovery-replayable-task? task-row)
  (let (action-class
        (poo-flow-durable-recovery-alist-ref
         task-row
         'action-class
         #f))
    (or (eq? action-class 'replayable)
        (eq? action-class 'idempotent))))

;; : (-> Alist Boolean)
(def (poo-flow-durable-recovery-compensated-task? task-row)
  (not
   (null?
    (poo-flow-durable-recovery-alist-ref
     task-row
     'compensation-refs
     '()))))

;; : (-> Alist Boolean)
(def (poo-flow-durable-recovery-task-has-checkpoint? task-row)
  (if (poo-flow-durable-recovery-alist-ref task-row 'checkpoint-ref #f)
    #t
    #f))

;; : (-> Symbol Symbol [Alist])
(def (poo-flow-durable-recovery-action-class-diagnostics task-id action-class)
  (if (poo-flow-durable-recovery-member?
       action-class
       +poo-flow-durable-action-classes+)
    '()
    (list
     (poo-flow-durable-recovery-diagnostic
      'unsupported-action-class
      'workflow-task-rows
      'error
      (list (cons 'task task-id)
            (cons 'action-class action-class)
            (cons 'allowed +poo-flow-durable-action-classes+)
            (cons 'recoverable? #t))))))

;; : (-> Alist Symbol Symbol [Alist])
(def (poo-flow-durable-recovery-checkpoint-diagnostics task-row
                                                        task-id
                                                        action-class)
  (if (or (eq? action-class 'idempotent)
          (poo-flow-durable-recovery-task-has-checkpoint? task-row))
    '()
    (list
     (poo-flow-durable-recovery-diagnostic
      'missing-task-checkpoint
      'workflow-task-rows
      'error
      (list (cons 'task task-id)
            (cons 'action-class action-class)
            (cons 'recoverable? #t))))))

;; : (-> Alist Symbol Symbol [Alist])
(def (poo-flow-durable-recovery-compensation-diagnostics task-row
                                                         task-id
                                                         action-class)
  (if (or (poo-flow-durable-recovery-replayable-task? task-row)
          (poo-flow-durable-recovery-compensated-task? task-row)
          (poo-flow-durable-recovery-task-has-checkpoint? task-row))
    '()
    (list
     (poo-flow-durable-recovery-diagnostic
      'non-idempotent-without-compensation
      'workflow-task-rows
      'error
      (list (cons 'task task-id)
            (cons 'action-class action-class)
            (cons 'recoverable? #t))))))

;; : (-> Alist Symbol Symbol [Alist])
(def (poo-flow-durable-recovery-manual-replay-diagnostics task-row
                                                          task-id
                                                          action-class)
  (if (or (not (poo-flow-durable-recovery-member?
                action-class
                '(terminal manual)))
          (poo-flow-durable-recovery-compensated-task? task-row))
    '()
    (list
     (poo-flow-durable-recovery-diagnostic
      'unsafe-manual-replay
      'workflow-task-rows
      'error
      (list (cons 'task task-id)
            (cons 'action-class action-class)
            (cons 'recoverable? #t))))))

;; : (-> Alist [Alist])
(def (poo-flow-durable-recovery-workflow-task-diagnostics/one task-row)
  (let ((action-class
         (poo-flow-durable-recovery-alist-ref
          task-row
          'action-class
          #f))
        (task-id
         (poo-flow-durable-recovery-alist-ref
          task-row
          'durable-task-id
          (poo-flow-durable-recovery-alist-ref task-row 'check #f))))
    (append
     (poo-flow-durable-recovery-action-class-diagnostics task-id
                                                         action-class)
     (poo-flow-durable-recovery-checkpoint-diagnostics task-row
                                                       task-id
                                                       action-class)
     (poo-flow-durable-recovery-compensation-diagnostics task-row
                                                         task-id
                                                         action-class)
     (poo-flow-durable-recovery-manual-replay-diagnostics task-row
                                                          task-id
                                                          action-class))))

;; : (-> [Alist] [Alist])
(def (poo-flow-durable-recovery-workflow-task-diagnostics task-rows)
  (cond
   ((null? task-rows) '())
   ((pair? task-rows)
    (append
     (poo-flow-durable-recovery-workflow-task-diagnostics/one
      (car task-rows))
     (poo-flow-durable-recovery-workflow-task-diagnostics
      (cdr task-rows))))
   (else
    (list
     (poo-flow-durable-recovery-diagnostic
      'invalid-workflow-task-rows
      'workflow-task-rows
      'error
      (list (cons 'value task-rows)
            (cons 'recoverable? #t)))))))

;; : (-> [Alist] [Alist])
(def (poo-flow-durable-recovery-memory-job-row-diagnostics memory-job-rows)
  (cond
   ((null? memory-job-rows) '())
   ((pair? memory-job-rows)
    (append
     (let (row (car memory-job-rows))
       (if (and (poo-flow-durable-recovery-alist? row)
                (eq? (poo-flow-durable-recovery-alist-ref row 'kind #f)
                     'poo-flow.memory-core.durable-job-receipt)
                (poo-flow-durable-recovery-row-valid? row))
         '()
         (list
          (poo-flow-durable-recovery-diagnostic
           'invalid-memory-durable-job
           'memory-job-rows
           'error
           (list (cons 'job-id
                       (poo-flow-durable-recovery-alist-ref
                        row
                        'job-id
                        #f))
                 (cons 'diagnostics
                       (poo-flow-durable-recovery-alist-ref
                        row
                        'diagnostics
                        '()))
                 (cons 'recoverable? #t))))))
     (poo-flow-durable-recovery-memory-job-row-diagnostics
      (cdr memory-job-rows))))
   (else
    (list
     (poo-flow-durable-recovery-diagnostic
      'invalid-memory-job-rows
      'memory-job-rows
      'error
      (list (cons 'value memory-job-rows)
            (cons 'recoverable? #t)))))))

;; : (-> [Alist] [Alist])
(def (poo-flow-durable-recovery-memory-job-diagnostics memory-job-rows)
  (if (null? memory-job-rows)
    (list
     (poo-flow-durable-recovery-diagnostic
      'missing-memory-durable-job
      'memory-job-rows
      'error
      (list (cons 'recoverable? #t))))
    (poo-flow-durable-recovery-memory-job-row-diagnostics memory-job-rows)))

;; : (-> Alist [Alist] [Alist])
(def (poo-flow-durable-recovery-communication-diagnostics
      runtime-store-row
      communication-rows)
  (if (and (pair? communication-rows)
           (not (poo-flow-durable-recovery-runtime-store-ref
                 runtime-store-row
                 'communication-ledger-ref)))
    (list
     (poo-flow-durable-recovery-diagnostic
      'missing-communication-ledger-ref
      'communication-rows
      'error
      (list (cons 'communication-count (length communication-rows))
            (cons 'recoverable? #t))))
    '()))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-durable-recovery-missing-refs refs declared-refs)
  (cond
   ((null? refs) '())
   ((poo-flow-durable-recovery-member? (car refs) declared-refs)
    (poo-flow-durable-recovery-missing-refs (cdr refs) declared-refs))
   (else
    (cons (car refs)
          (poo-flow-durable-recovery-missing-refs (cdr refs)
                                                  declared-refs)))))

;; : (-> [Alist] [Symbol] [Alist])
(def (poo-flow-durable-recovery-sandbox-diagnostics workflow-task-rows
                                                     sandbox-refs)
  (cond
   ((null? workflow-task-rows) '())
   ((pair? workflow-task-rows)
    (append
     (let* ((task-row (car workflow-task-rows))
            (task-refs
             (poo-flow-durable-recovery-alist-ref
              task-row
              'sandbox-refs
              '()))
            (missing-refs
             (poo-flow-durable-recovery-missing-refs task-refs sandbox-refs)))
       (if (null? missing-refs)
         '()
         (list
          (poo-flow-durable-recovery-diagnostic
           'unresolved-sandbox-ref
           'sandbox-refs
           'error
           (list (cons 'task
                       (poo-flow-durable-recovery-alist-ref
                        task-row
                        'durable-task-id
                        #f))
                 (cons 'missing-refs missing-refs)
                 (cons 'recoverable? #t))))))
     (poo-flow-durable-recovery-sandbox-diagnostics
      (cdr workflow-task-rows)
      sandbox-refs)))
   (else '())))

;; : (-> Symbol Symbol Symbol Symbol Alist [Alist] [Alist] [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-durable-recovery-diagnostics scenario-id
                                             project-id
                                             root-session-id
                                             session-id
                                             runtime-store-row
                                             communication-rows
                                             memory-job-rows
                                             workflow-task-rows
                                             sandbox-refs)
  (append
   (poo-flow-durable-recovery-required-symbol-diagnostics
    'missing-scenario-id
    'scenario-id
    scenario-id)
   (poo-flow-durable-recovery-required-symbol-diagnostics
    'missing-project-id
    'project-id
    project-id)
   (poo-flow-durable-recovery-required-symbol-diagnostics
    'missing-root-session-id
    'root-session-id
    root-session-id)
   (poo-flow-durable-recovery-required-symbol-diagnostics
    'missing-session-id
    'session-id
    session-id)
   (poo-flow-durable-recovery-runtime-store-diagnostics runtime-store-row)
   (poo-flow-durable-recovery-communication-diagnostics
    runtime-store-row
    communication-rows)
   (poo-flow-durable-recovery-memory-job-diagnostics memory-job-rows)
   (poo-flow-durable-recovery-workflow-task-diagnostics workflow-task-rows)
   (poo-flow-durable-recovery-sandbox-diagnostics workflow-task-rows
                                                   sandbox-refs)))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol String Boolean Boolean Alist)
(def (poo-flow-durable-recovery-observability-row scenario-id
                                                  stage
                                                  status
                                                  detail
                                                  runtime-owner
                                                  handoff-required
                                                  runtime-executed)
  (list
   (cons 'kind 'poo-flow.durable.recovery-observability-row)
   (cons 'schema +poo-flow-durable-recovery-observability-schema+)
   (cons 'scenario-id scenario-id)
   (cons 'stage stage)
   (cons 'status status)
   (cons 'detail detail)
   (cons 'runtime-owner runtime-owner)
   (cons 'handoff-required handoff-required)
   (cons 'runtime-executed runtime-executed)))

;; : (-> Symbol Symbol [Alist] String [Alist])
(def (poo-flow-durable-recovery-observability-rows scenario-id
                                                   status
                                                   detail
                                                   runtime-owner)
  (map (lambda (stage)
         (poo-flow-durable-recovery-observability-row scenario-id
                                                      stage
                                                      status
                                                      detail
                                                      runtime-owner
                                                      #t
                                                      #f))
       +poo-flow-durable-recovery-stages+))

;;; Recovery scenario receipts stay struct-backed; projection functions own the
;;; public alist shape consumed by tests and Marlin handoff code.
(defstruct poo-flow-durable-recovery-scenario-receipt
  (scenario-id
   project-id
   root-session-id
   session-id
   failure-kind
   recovery-mode
   runtime-store-row
   session-graph-row
   communication-rows
   memory-job-rows
   workflow-task-rows
   sandbox-refs
   checkpoint-ref
   repair-policy-ref
   event-log-ref
   derived-index-ref
   job-lease-ref
   repair-journal-ref
   deterministic-replay?
   observability-rows
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   runtime-executed)
  transparent: #t)

;;; Scenario construction folds heterogeneous durable rows into one receipt
;;; boundary so tests can cover replay and repair handoff without executing
;;; runtime side effects.
;; : (-> Symbol Symbol Symbol Symbol Datum Alist [Alist] [Alist] [Alist] [Symbol] [Alist] PooDurableRecoveryScenarioReceipt)
(def (poo-flow-durable-recovery-scenario scenario-id
                                          project-id
                                          root-session-id
                                          session-id
                                          runtime-store-receipt
                                          session-graph-row
                                          communication-rows
                                          memory-job-rows
                                          workflow-task-rows
                                          sandbox-refs
                                          . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (runtime-store-row
          (poo-flow-durable-recovery-runtime-store-row runtime-store-receipt))
         (failure-kind
          (poo-flow-durable-recovery-option
           options
           'failure-kind
           'process-crash))
         (recovery-mode
          (poo-flow-durable-recovery-option options 'recovery-mode 'replay))
         (event-log-ref
          (poo-flow-durable-recovery-option
           options
           'event-log-ref
           (poo-flow-durable-recovery-runtime-store-ref runtime-store-row
                                                        'fact-log-ref)))
         (checkpoint-ref
          (poo-flow-durable-recovery-option
           options
           'checkpoint-ref
           (poo-flow-durable-recovery-runtime-store-ref
            runtime-store-row
            'checkpoint-store-ref)))
         (derived-index-ref
          (poo-flow-durable-recovery-option
           options
           'derived-index-ref
           (poo-flow-durable-recovery-runtime-store-ref
            runtime-store-row
            'derived-index-ref)))
         (job-lease-ref
          (poo-flow-durable-recovery-option
           options
           'job-lease-ref
           (poo-flow-durable-recovery-runtime-store-ref runtime-store-row
                                                        'job-store-ref)))
         (repair-journal-ref
          (poo-flow-durable-recovery-option
           options
           'repair-journal-ref
           (poo-flow-durable-recovery-runtime-store-ref
            runtime-store-row
            'repair-journal-ref)))
         (repair-policy-ref
          (poo-flow-durable-recovery-option
           options
           'repair-policy-ref
           'repair/fail-closed))
         (metadata
          (poo-flow-durable-recovery-option options 'metadata '()))
         (runtime-owner
          (poo-flow-durable-recovery-option
           options
           'runtime-owner
           "marlin-agent-core"))
         (diagnostics
          (poo-flow-durable-recovery-diagnostics
           scenario-id
           project-id
           root-session-id
           session-id
           runtime-store-row
           communication-rows
           memory-job-rows
           workflow-task-rows
           sandbox-refs))
         (valid? (null? diagnostics))
         (observability-rows
          (poo-flow-durable-recovery-observability-rows
           scenario-id
           (if valid? 'ready 'blocked)
           (list (cons 'failure-kind failure-kind)
                 (cons 'recovery-mode recovery-mode)
                 (cons 'diagnostic-count (length diagnostics)))
           runtime-owner)))
    (make-poo-flow-durable-recovery-scenario-receipt
     scenario-id
     project-id
     root-session-id
     session-id
     failure-kind
     recovery-mode
     runtime-store-row
     session-graph-row
     communication-rows
     memory-job-rows
     workflow-task-rows
     sandbox-refs
     checkpoint-ref
     repair-policy-ref
     event-log-ref
     derived-index-ref
     job-lease-ref
     repair-journal-ref
     valid?
     observability-rows
     valid?
     diagnostics
     metadata
     runtime-owner
     #t
     #f)))

;; : (-> PooDurableRecoveryScenarioReceipt Alist)
(defpoo-module-final-projection
  poo-flow-durable-recovery-scenario->alist (receipt)
  (bindings ((diagnostics
              (poo-flow-durable-recovery-scenario-receipt-diagnostics
               receipt))))
  (fields ((kind +poo-flow-durable-recovery-scenario-kind+)
           (schema +poo-flow-durable-recovery-scenario-schema+)
           (scenario-id
            (poo-flow-durable-recovery-scenario-receipt-scenario-id receipt))
           (project-id
            (poo-flow-durable-recovery-scenario-receipt-project-id receipt))
           (root-session-id
            (poo-flow-durable-recovery-scenario-receipt-root-session-id
             receipt))
           (session-id
            (poo-flow-durable-recovery-scenario-receipt-session-id receipt))
           (failure-kind
            (poo-flow-durable-recovery-scenario-receipt-failure-kind receipt))
           (recovery-mode
            (poo-flow-durable-recovery-scenario-receipt-recovery-mode receipt))
           (runtime-store
            (poo-flow-durable-recovery-scenario-receipt-runtime-store-row
             receipt))
           (session-graph
            (poo-flow-durable-recovery-scenario-receipt-session-graph-row
             receipt))
           (communication-rows
            (poo-flow-durable-recovery-scenario-receipt-communication-rows
             receipt))
           (memory-job-rows
            (poo-flow-durable-recovery-scenario-receipt-memory-job-rows
             receipt))
           (workflow-task-rows
            (poo-flow-durable-recovery-scenario-receipt-workflow-task-rows
             receipt))
           (sandbox-refs
            (poo-flow-durable-recovery-scenario-receipt-sandbox-refs receipt))
           (checkpoint-ref
            (poo-flow-durable-recovery-scenario-receipt-checkpoint-ref
             receipt))
           (repair-policy-ref
            (poo-flow-durable-recovery-scenario-receipt-repair-policy-ref
             receipt))
           (event-log-ref
            (poo-flow-durable-recovery-scenario-receipt-event-log-ref receipt))
           (derived-index-ref
            (poo-flow-durable-recovery-scenario-receipt-derived-index-ref
             receipt))
           (job-lease-ref
            (poo-flow-durable-recovery-scenario-receipt-job-lease-ref receipt))
           (repair-journal-ref
            (poo-flow-durable-recovery-scenario-receipt-repair-journal-ref
             receipt))
           (deterministic-replay?
            (poo-flow-durable-recovery-scenario-receipt-deterministic-replay?
             receipt))
           (observability-rows
            (poo-flow-durable-recovery-scenario-receipt-observability-rows
             receipt))
           (valid?
            (poo-flow-durable-recovery-scenario-receipt-valid? receipt))
           (diagnostics diagnostics)
           (diagnostic-count (length diagnostics))
           (metadata
            (poo-flow-durable-recovery-scenario-receipt-metadata receipt))
           (runtime-owner
            (poo-flow-durable-recovery-scenario-receipt-runtime-owner receipt))
           (handoff-required
            (poo-flow-durable-recovery-scenario-receipt-handoff-required
             receipt))
           (runtime-executed
            (poo-flow-durable-recovery-scenario-receipt-runtime-executed
             receipt)))))

;; : (-> [PooDurableRecoveryScenarioReceipt] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-durable-recovery-scenarios->alists (receipts)
  (projector poo-flow-durable-recovery-scenario->alist)
  (error-message "durable recovery scenario serialization requires a list"))
