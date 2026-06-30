;;; -*- Gerbil -*-
;;; Boundary: shared durable policy POO capability objects.
;;; Invariant: this layer validates and projects durable intent only; Rust or
;;; Marlin owns fact logs, checkpoints, indexes, leases, replay, and repair.

(import (only-in :clan/poo/object .o .ref .slot? object? object<-alist))

(export +poo-flow-durable-policy-kind+
        +poo-flow-durable-policy-schema+
        +poo-flow-durable-policy-diagnostic-schema+
        +poo-flow-durable-policy-receipt-schema+
        +poo-flow-durable-action-classes+
        +poo-flow-durable-repair-modes+
        make-poo-flow-durable-policy-receipt
        poo-flow-durable-policy-receipt?
        poo-flow-durable-policy-receipt-policy-id
        poo-flow-durable-policy-receipt-project-id
        poo-flow-durable-policy-receipt-root-session-id
        poo-flow-durable-policy-receipt-session-id
        poo-flow-durable-policy-receipt-parent-session-id
        poo-flow-durable-policy-receipt-loop-run-id
        poo-flow-durable-policy-receipt-checkpoint-policy-ref
        poo-flow-durable-policy-receipt-journal-policy-ref
        poo-flow-durable-policy-receipt-index-policy-ref
        poo-flow-durable-policy-receipt-resume-policy-ref
        poo-flow-durable-policy-receipt-repair-policy-ref
        poo-flow-durable-policy-receipt-journal-owner
        poo-flow-durable-policy-receipt-checkpoint-store
        poo-flow-durable-policy-receipt-resume-identity
        poo-flow-durable-policy-receipt-repair-mode
        poo-flow-durable-policy-receipt-action-classes
        poo-flow-durable-policy-receipt-runtime-owner
        poo-flow-durable-policy-receipt-valid?
        poo-flow-durable-policy-receipt-diagnostics
        poo-flow-durable-policy-receipt-metadata
        poo-flow-durable-policy
        poo-flow-durable-policy/default
        poo-flow-durable-policy?
        poo-flow-durable-policy-name
        poo-flow-durable-policy-scope-ref
        poo-flow-durable-policy-diagnostic
        poo-flow-durable-policy-diagnostic?
        poo-flow-durable-policy-diagnostic->alist
        poo-flow-durable-policy-diagnostics
        poo-flow-durable-policy-valid?
        poo-flow-durable-policy->receipt
        poo-flow-durable-policies->receipts
        poo-flow-durable-policy-receipt->alist
        poo-flow-durable-policy-receipts->alists)

(def +poo-flow-durable-policy-kind+
  'poo-flow.durable.policy)

(def +poo-flow-durable-policy-schema+
  'poo-flow.module-system.durable-policy.v1)

(def +poo-flow-durable-policy-diagnostic-schema+
  'poo-flow.module-system.durable-policy.diagnostic.v1)

(def +poo-flow-durable-policy-receipt-schema+
  'poo-flow.module-system.durable-policy.receipt.v1)

(def +poo-flow-durable-action-classes+
  '(replayable idempotent compensatable terminal manual))

(def +poo-flow-durable-repair-modes+
  '(fail-closed retry rebuild compensate quarantine manual))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-durable-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;; : (forall (a) (-> String Boolean a a))
(def (poo-flow-durable-require message condition value)
  (if condition
    value
    (error message value)))

;; : (-> Procedure List Boolean)
(def (poo-flow-durable-every? predicate values)
  (cond
   ((null? values) #t)
   ((predicate (car values))
    (poo-flow-durable-every? predicate (cdr values)))
   (else #f)))

;; : (-> Any [Any] Boolean)
(def (poo-flow-durable-member? value values)
  (if (member value values) #t #f))

;; : (-> [Any] Boolean)
(def (poo-flow-durable-symbol-list? values)
  (and (list? values)
       (poo-flow-durable-every? symbol? values)))

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-durable-slot object key default-value)
  (if (and (object? object) (.slot? object key))
    (.ref object key)
    default-value))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-durable-identity-ref identity key default-value)
  (let (entry (assoc key identity))
    (if entry (cdr entry) default-value)))

;; : (-> Symbol Symbol Symbol Alist POOObject)
(def (poo-flow-durable-policy-diagnostic code slot severity payload)
  (object<-alist
   (append
    (list (cons 'kind +poo-flow-durable-policy-diagnostic-schema+)
          (cons 'schema +poo-flow-durable-policy-diagnostic-schema+)
          (cons 'code code)
          (cons 'phase 'durable-policy)
          (cons 'slot slot)
          (cons 'severity severity)
          (cons 'payload payload))
    payload)))

;; : (-> Value Boolean)
(def (poo-flow-durable-policy-diagnostic? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +poo-flow-durable-policy-diagnostic-schema+)))

;; : (-> PooDurablePolicyDiagnostic Alist)
(def (poo-flow-durable-policy-diagnostic->alist diagnostic)
  (list
   (cons 'kind (poo-flow-durable-slot diagnostic 'kind #f))
   (cons 'schema (poo-flow-durable-slot diagnostic 'schema #f))
   (cons 'code (poo-flow-durable-slot diagnostic 'code #f))
   (cons 'phase (poo-flow-durable-slot diagnostic 'phase #f))
   (cons 'slot (poo-flow-durable-slot diagnostic 'slot #f))
   (cons 'severity (poo-flow-durable-slot diagnostic 'severity #f))
   (cons 'payload (poo-flow-durable-slot diagnostic 'payload '()))
   (cons 'recoverable?
         (poo-flow-durable-slot diagnostic 'recoverable? #t))))

;; : (-> [PooDurablePolicyDiagnostic] [Alist])
(def (poo-flow-durable-policy-diagnostics->alist diagnostics)
  (map poo-flow-durable-policy-diagnostic->alist diagnostics))

;; : (-> Symbol Symbol [Alist] POOObject)
(def (poo-flow-durable-policy policy-name scope-ref . maybe-options)
  (poo-flow-durable-require "durable policy name must be a symbol"
                            (symbol? policy-name)
                            policy-name)
  (poo-flow-durable-require "durable policy scope ref must be a symbol"
                            (symbol? scope-ref)
                            scope-ref)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (policy-name-value policy-name)
         (scope-ref-value scope-ref)
         (checkpoint-policy-ref-value
          (poo-flow-durable-option options
                                   'checkpoint-policy-ref
                                   'checkpoint/default))
         (journal-policy-ref-value
          (poo-flow-durable-option options
                                   'journal-policy-ref
                                   'journal/default))
         (index-policy-ref-value
          (poo-flow-durable-option options
                                   'index-policy-ref
                                   'index/default))
         (resume-policy-ref-value
          (poo-flow-durable-option options
                                   'resume-policy-ref
                                   'resume/default))
         (repair-policy-ref-value
          (poo-flow-durable-option options
                                   'repair-policy-ref
                                   'repair/fail-closed))
         (journal-owner-value
          (poo-flow-durable-option options 'journal-owner 'runtime/fact-log))
         (checkpoint-store-value
          (poo-flow-durable-option options
                                   'checkpoint-store
                                   'runtime/checkpoint-store))
         (resume-identity-value
          (poo-flow-durable-option options 'resume-identity 'session-id))
         (repair-mode-value
          (poo-flow-durable-option options 'repair-mode 'fail-closed))
         (action-classes-value
          (poo-flow-durable-option options
                                   'action-classes
                                   +poo-flow-durable-action-classes+))
         (runtime-owner-value
          (poo-flow-durable-option options
                                   'runtime-owner
                                   "marlin-agent-core"))
         (metadata-value
          (poo-flow-durable-option options 'metadata '())))
    (.o durable-kind: +poo-flow-durable-policy-kind+
        durable-schema: +poo-flow-durable-policy-schema+
        durable-policy-name: policy-name-value
        durable-scope-ref: scope-ref-value
        checkpoint-policy-ref: checkpoint-policy-ref-value
        journal-policy-ref: journal-policy-ref-value
        index-policy-ref: index-policy-ref-value
        resume-policy-ref: resume-policy-ref-value
        repair-policy-ref: repair-policy-ref-value
        journal-owner: journal-owner-value
        checkpoint-store: checkpoint-store-value
        resume-identity: resume-identity-value
        repair-mode: repair-mode-value
        action-classes: action-classes-value
        runtime-owner: runtime-owner-value
        durable-metadata: metadata-value
        durable-runtime-executed: #f)))

(def poo-flow-durable-policy/default
  (poo-flow-durable-policy
   'durable/default
   'objects.shared.durable
   '((metadata . ((scope . shared)
                  (runtime-executed . #f))))))

;; : (-> Value Boolean)
(def (poo-flow-durable-policy? value)
  (and (object? value)
       (.slot? value 'durable-kind)
       (eq? (.ref value 'durable-kind)
            +poo-flow-durable-policy-kind+)))

;; : (-> PooDurablePolicy Symbol)
(def (poo-flow-durable-policy-name policy)
  (poo-flow-durable-slot policy 'durable-policy-name #f))

;; : (-> PooDurablePolicy Symbol)
(def (poo-flow-durable-policy-scope-ref policy)
  (poo-flow-durable-slot policy 'durable-scope-ref #f))

;; : (-> PooDurablePolicy Symbol Symbol Value [PooDurablePolicyDiagnostic])
(def (poo-flow-durable-policy-required-symbol-diagnostics policy
                                                           slot
                                                           code
                                                           value)
  (cond
   ((not value)
    (list
     (poo-flow-durable-policy-diagnostic
      code
      slot
      'error
      (list (cons 'policy (poo-flow-durable-policy-name policy))
            (cons 'expected 'symbol)
            (cons 'recoverable? #t)))))
   ((symbol? value) '())
   (else
    (list
     (poo-flow-durable-policy-diagnostic
      code
      slot
      'error
      (list (cons 'policy (poo-flow-durable-policy-name policy))
            (cons 'value value)
            (cons 'expected 'symbol)
            (cons 'recoverable? #t)))))))

;; : (-> PooDurablePolicy [PooDurablePolicyDiagnostic])
(def (poo-flow-durable-policy-action-class-diagnostics policy)
  (let (action-classes
        (poo-flow-durable-slot policy 'action-classes #f))
    (cond
     ((not (poo-flow-durable-symbol-list? action-classes))
      (list
       (poo-flow-durable-policy-diagnostic
        'invalid-action-classes
        'action-classes
        'error
        (list (cons 'policy (poo-flow-durable-policy-name policy))
              (cons 'value action-classes)
              (cons 'expected 'symbol-list)
              (cons 'allowed +poo-flow-durable-action-classes+)
              (cons 'recoverable? #t)))))
     ((poo-flow-durable-every?
       (lambda (action-class)
         (poo-flow-durable-member?
          action-class
          +poo-flow-durable-action-classes+))
       action-classes)
      '())
     (else
      (list
       (poo-flow-durable-policy-diagnostic
        'unsupported-action-class
        'action-classes
        'error
        (list (cons 'policy (poo-flow-durable-policy-name policy))
              (cons 'value action-classes)
              (cons 'allowed +poo-flow-durable-action-classes+)
              (cons 'recoverable? #t))))))))

;; : (-> PooDurablePolicy [PooDurablePolicyDiagnostic])
(def (poo-flow-durable-policy-repair-mode-diagnostics policy)
  (let (repair-mode (poo-flow-durable-slot policy 'repair-mode #f))
    (cond
     ((not repair-mode)
      (list
       (poo-flow-durable-policy-diagnostic
        'missing-repair-mode
        'repair-mode
        'error
        (list (cons 'policy (poo-flow-durable-policy-name policy))
              (cons 'allowed +poo-flow-durable-repair-modes+)
              (cons 'recoverable? #t)))))
     ((poo-flow-durable-member? repair-mode +poo-flow-durable-repair-modes+)
      '())
     (else
      (list
       (poo-flow-durable-policy-diagnostic
        'unsupported-repair-mode
        'repair-mode
        'error
        (list (cons 'policy (poo-flow-durable-policy-name policy))
              (cons 'value repair-mode)
              (cons 'allowed +poo-flow-durable-repair-modes+)
              (cons 'recoverable? #t))))))))

;; : (-> PooDurablePolicy [PooDurablePolicyDiagnostic])
(def (poo-flow-durable-policy-runtime-owner-diagnostics policy)
  (let (runtime-owner (poo-flow-durable-slot policy 'runtime-owner #f))
    (if (string? runtime-owner)
      '()
      (list
       (poo-flow-durable-policy-diagnostic
        'invalid-runtime-owner
        'runtime-owner
        'error
        (list (cons 'policy (poo-flow-durable-policy-name policy))
              (cons 'value runtime-owner)
              (cons 'expected 'string)
              (cons 'recoverable? #t)))))))

;; : (-> PooDurablePolicy [PooDurablePolicyDiagnostic])
(def (poo-flow-durable-policy-diagnostics policy)
  (if (poo-flow-durable-policy? policy)
    (append
     (poo-flow-durable-policy-required-symbol-diagnostics
      policy
      'durable-policy-name
      'missing-durable-policy-name
      (poo-flow-durable-slot policy 'durable-policy-name #f))
     (poo-flow-durable-policy-required-symbol-diagnostics
      policy
      'durable-scope-ref
      'missing-durable-scope-ref
      (poo-flow-durable-slot policy 'durable-scope-ref #f))
     (poo-flow-durable-policy-required-symbol-diagnostics
      policy
      'journal-owner
      'missing-journal-owner
      (poo-flow-durable-slot policy 'journal-owner #f))
     (poo-flow-durable-policy-required-symbol-diagnostics
      policy
      'checkpoint-store
      'missing-checkpoint-store
      (poo-flow-durable-slot policy 'checkpoint-store #f))
     (poo-flow-durable-policy-required-symbol-diagnostics
      policy
      'resume-identity
      'missing-resume-identity
      (poo-flow-durable-slot policy 'resume-identity #f))
     (poo-flow-durable-policy-repair-mode-diagnostics policy)
     (poo-flow-durable-policy-action-class-diagnostics policy)
     (poo-flow-durable-policy-runtime-owner-diagnostics policy))
    (list
     (poo-flow-durable-policy-diagnostic
      'invalid-durable-policy
      'durable-policy
      'error
      (list (cons 'value policy)
            (cons 'recoverable? #t))))))

;; : (-> PooDurablePolicy Boolean)
(def (poo-flow-durable-policy-valid? policy)
  (null? (poo-flow-durable-policy-diagnostics policy)))

;; : PooDurablePolicyReceipt
(defstruct poo-flow-durable-policy-receipt
  (policy-id
   project-id
   root-session-id
   session-id
   parent-session-id
   loop-run-id
   checkpoint-policy-ref
   journal-policy-ref
   index-policy-ref
   resume-policy-ref
   repair-policy-ref
   journal-owner
   checkpoint-store
   resume-identity
   repair-mode
   action-classes
   runtime-owner
   valid?
   diagnostics
   metadata)
  transparent: #t)

;; : (-> PooDurablePolicy [Alist] PooDurablePolicyReceipt)
(def (poo-flow-durable-policy->receipt policy . maybe-identity)
  (poo-flow-durable-require "durable policy receipt requires a durable policy"
                            (poo-flow-durable-policy? policy)
                            policy)
  (let* ((identity (if (null? maybe-identity) '() (car maybe-identity)))
         (diagnostics
          (poo-flow-durable-policy-diagnostics policy))
         (valid? (null? diagnostics)))
    (make-poo-flow-durable-policy-receipt
     (poo-flow-durable-policy-name policy)
     (poo-flow-durable-identity-ref identity 'project-id #f)
     (poo-flow-durable-identity-ref identity 'root-session-id #f)
     (poo-flow-durable-identity-ref identity 'session-id #f)
     (poo-flow-durable-identity-ref identity 'parent-session-id #f)
     (poo-flow-durable-identity-ref identity 'loop-run-id #f)
     (poo-flow-durable-slot policy 'checkpoint-policy-ref #f)
     (poo-flow-durable-slot policy 'journal-policy-ref #f)
     (poo-flow-durable-slot policy 'index-policy-ref #f)
     (poo-flow-durable-slot policy 'resume-policy-ref #f)
     (poo-flow-durable-slot policy 'repair-policy-ref #f)
     (poo-flow-durable-slot policy 'journal-owner #f)
     (poo-flow-durable-slot policy 'checkpoint-store #f)
     (poo-flow-durable-slot policy 'resume-identity #f)
     (poo-flow-durable-slot policy 'repair-mode #f)
     (poo-flow-durable-slot policy 'action-classes '())
     (poo-flow-durable-slot policy 'runtime-owner #f)
     valid?
     (poo-flow-durable-policy-diagnostics->alist diagnostics)
     (poo-flow-durable-slot policy 'durable-metadata '()))))

;; : (-> [PooDurablePolicy] [PooDurablePolicyReceipt])
(def (poo-flow-durable-policies->receipts policies)
  (cond
   ((null? policies) '())
   ((pair? policies)
    (cons (poo-flow-durable-policy->receipt (car policies))
          (poo-flow-durable-policies->receipts (cdr policies))))
   (else
    (error "durable policy batch projection requires a list" policies))))

;; : (-> PooDurablePolicyReceipt Alist)
(def (poo-flow-durable-policy-receipt->alist receipt)
  (list
   (cons 'kind 'poo-flow.durable.policy-receipt)
   (cons 'schema +poo-flow-durable-policy-receipt-schema+)
   (cons 'policy-id (poo-flow-durable-policy-receipt-policy-id receipt))
   (cons 'project-id (poo-flow-durable-policy-receipt-project-id receipt))
   (cons 'root-session-id
         (poo-flow-durable-policy-receipt-root-session-id receipt))
   (cons 'session-id (poo-flow-durable-policy-receipt-session-id receipt))
   (cons 'parent-session-id
         (poo-flow-durable-policy-receipt-parent-session-id receipt))
   (cons 'loop-run-id (poo-flow-durable-policy-receipt-loop-run-id receipt))
   (cons 'checkpoint-policy-ref
         (poo-flow-durable-policy-receipt-checkpoint-policy-ref receipt))
   (cons 'journal-policy-ref
         (poo-flow-durable-policy-receipt-journal-policy-ref receipt))
   (cons 'index-policy-ref
         (poo-flow-durable-policy-receipt-index-policy-ref receipt))
   (cons 'resume-policy-ref
         (poo-flow-durable-policy-receipt-resume-policy-ref receipt))
   (cons 'repair-policy-ref
         (poo-flow-durable-policy-receipt-repair-policy-ref receipt))
   (cons 'journal-owner
         (poo-flow-durable-policy-receipt-journal-owner receipt))
   (cons 'checkpoint-store
         (poo-flow-durable-policy-receipt-checkpoint-store receipt))
   (cons 'resume-identity
         (poo-flow-durable-policy-receipt-resume-identity receipt))
   (cons 'repair-mode
         (poo-flow-durable-policy-receipt-repair-mode receipt))
   (cons 'action-classes
         (poo-flow-durable-policy-receipt-action-classes receipt))
   (cons 'runtime-owner
         (poo-flow-durable-policy-receipt-runtime-owner receipt))
   (cons 'valid? (poo-flow-durable-policy-receipt-valid? receipt))
   (cons 'diagnostics
         (poo-flow-durable-policy-receipt-diagnostics receipt))
   (cons 'diagnostic-count
         (length (poo-flow-durable-policy-receipt-diagnostics receipt)))
   (cons 'metadata (poo-flow-durable-policy-receipt-metadata receipt))
   (cons 'runtime-executed #f)))

;; : (-> [PooDurablePolicyReceipt] [Alist])
(def (poo-flow-durable-policy-receipts->alists receipts)
  (cond
   ((null? receipts) '())
   ((pair? receipts)
    (cons (poo-flow-durable-policy-receipt->alist (car receipts))
          (poo-flow-durable-policy-receipts->alists (cdr receipts))))
   (else
    (error "durable policy receipt serialization requires a list" receipts))))
