;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime handoff projection for module-system config.
;;; Invariant: this owner emits Marlin handoff data and never executes runtime work.

(import (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-agent-harness
                 make-poo-flow-agent-operation
                 make-poo-flow-agent-profile
                 make-poo-flow-agent-session
                 make-poo-flow-dispatch-receipt
                 make-poo-flow-runtime-snapshot
                 make-poo-flow-workflow-run
                 poo-flow-agent-harness->alist
                 poo-flow-agent-operation->alist
                 poo-flow-agent-profile->alist
                 poo-flow-agent-session->alist
                 poo-flow-dispatch-receipt->alist
                 poo-flow-runtime-snapshot->alist
                 poo-flow-workflow-run->alist)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-stdout-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-workflow-agreement)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-result-contract)

(export poo-flow-user-module-selection-loop-engine-intent
        poo-flow-user-loop-engine-primary-agent
        poo-flow-user-loop-engine-intent-status
        poo-flow-user-loop-engine-intent-operation-kind
        poo-flow-user-loop-engine-intent-result-contract
        poo-flow-user-loop-engine-result-contract-valid?
        poo-flow-user-loop-engine-result-contract-diagnostics
        poo-flow-user-loop-engine-intent-role-result-contract
        poo-flow-user-loop-engine-intent-operation-result-contract
        poo-flow-user-loop-engine-intent-agent-profiles
        poo-flow-user-loop-engine-intent-agent-harnesses
        poo-flow-user-loop-engine-intent-agent-sessions
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-delegated-operation
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-intent-workflow-agreement
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intents-field-values
        poo-flow-user-config-loop-engine-intents
        poo-flow-user-loop-engine-intent-runtime-intent
        poo-flow-user-loop-engine-intent-policy
        poo-flow-user-loop-engine-intent-runtime-projections
        poo-flow-user-config-loop-engine-intents/add)

;;; The first configured judge is the default runtime target so simple
;;; single-agent loops do not need an explicit governor role.
;; : (-> List Symbol)
(def (poo-flow-user-loop-engine-primary-agent agent-judges)
  (cond
   ((null? agent-judges) 'loop-governor-agent)
   ((and (pair? (car agent-judges))
         (pair? (cdr (car agent-judges))))
    (cadr (car agent-judges)))
   ((pair? (car agent-judges)) (cdr (car agent-judges)))
   (else (car agent-judges))))

;;; Human-audit declarations change admission state before any backend runtime
;;; receives the request; Scheme only records the waiting state.
;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-status intent)
  (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
    'admitted
    'waiting-human))

;;; Operation kind mirrors the same human gate so downstream receipts can be
;;; audited without inspecting the raw user module sections.
;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-operation-kind intent)
  (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
    'governor-judge
    'human-audit))

;;; Judge rows come from user flags, not a validated schema, so role lookup has
;;; to accept both list-shaped and dotted entries while keeping defaults stable.
;; : (-> [Value] Symbol Value Value)
(def (poo-flow-user-loop-engine-agent-judge-ref agent-judges role default-value)
  (cond
   ((null? agent-judges) default-value)
   ((and (pair? (car agent-judges))
         (equal? (caar agent-judges) role))
    (let (row (car agent-judges))
      (cond
       ((null? (cdr row)) default-value)
       ((pair? (cdr row)) (cadr row))
       (else (cdr row)))))
   (else
    (poo-flow-user-loop-engine-agent-judge-ref
     (cdr agent-judges)
     role
     default-value))))

;;; Role/name normalization is shared by profile, harness, and session
;;; projection so every downstream row receives the same naming decision.
;; : (-> Value MaybePair)
(def (poo-flow-user-loop-engine-agent-judge-pair row)
  (cond
   ((not (pair? row)) #f)
   ((not (symbol? (car row))) #f)
   ((null? (cdr row)) #f)
   ((pair? (cdr row)) (cons (car row) (cadr row)))
   (else (cons (car row) (cdr row)))))

;;; Invalid judge rows are skipped rather than repaired; malformed user config
;;; should stay visible in the original intent while projections remain total.
;; : (-> [Value] [Pair])
(def (poo-flow-user-loop-engine-agent-judge-pairs agent-judges)
  (cond
   ((null? agent-judges) '())
   ((poo-flow-user-loop-engine-agent-judge-pair (car agent-judges))
    => (lambda (role-ref)
         (cons role-ref
               (poo-flow-user-loop-engine-agent-judge-pairs
                (cdr agent-judges)))))
   (else
    (poo-flow-user-loop-engine-agent-judge-pairs (cdr agent-judges)))))

;;; Loop-engine agent boundaries use the first declared sandbox profile as a
;;; policy reference only. Actual sandbox realization remains backend-owned.
;; : (-> Alist MaybeSymbol)
(def (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
  (let (refs (poo-flow-user-loop-engine-intent-ref
              intent
              'sandbox-profile-refs
              '()))
    (if (null? refs) #f (car refs))))

;;; Human audit is modeled as a named profile beside machine judges so agents
;;; can inspect the same profile/harness/session graph for both reviewer types.
;; : (-> Alist [Pair])
(def (poo-flow-user-loop-engine-intent-agent-profile-refs intent)
  (append
   (poo-flow-user-loop-engine-agent-judge-pairs
    (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
   (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
     '()
     (list (cons 'human-audit 'human-audit)))))

;;; The operation-level adapter is the only result-contract function that needs
;;; operation-kind. The full contract packet lives in loop-engine-result-contract.
;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-operation-result-contract intent)
  (if (eq? (poo-flow-user-loop-engine-intent-operation-kind intent)
           'human-audit)
    (poo-flow-user-loop-engine-intent-role-result-contract
     intent
     'human-audit)
    (poo-flow-user-loop-engine-intent-role-result-contract
     intent
     'governor)))

;;; Workflow agreement is Funflow-owned data cached on the intent. The fallback
;;; keeps older loop-engine rows presentable while still using Funflow's rules.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-workflow-agreement intent)
  (poo-flow-user-loop-engine-intent-ref
   intent
   'workflow-agreement
    (poo-flow-funflow-workflow-agreement
     (poo-flow-user-loop-engine-intent-workflow-ref intent)
     '())))

;;; Runtime intent is the compact policy pointer embedded in profiles,
;;; harnesses, receipts, and operations before a backend materializes them.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-intent intent)
  (list
   (cons 'runtime-handoff
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-handoff
          'loop-governor-marlin-runtime-manifest))
   (cons 'runtime-owner
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-owner
          "marlin-agent-core"))
   (cons 'handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-command-contract
         +poo-flow-user-loop-engine-runtime-command-contract+)
   (cons 'result-contract
         (poo-flow-user-loop-engine-intent-result-contract intent))
   (cons 'object-families
         +poo-flow-user-loop-engine-runtime-object-families+)
   (cons 'workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent))
   (cons 'workflow-agreement
         (poo-flow-user-loop-engine-intent-workflow-agreement intent))
   (cons 'executes-runtime #f)))

;;; Policy projection is the loop-engine guardrail packet. It keeps governor,
;;; human audit, sandbox, budget, and observability rows together so Marlin sees
;;; one coherent handoff policy instead of scattered presentation fields.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-policy intent)
  (list
   (cons 'governor
         (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
   (cons 'human-audit
         (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
   (cons 'sandbox
         (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
   (cons 'sandbox-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-profile-refs
          '()))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
        (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-handoff-agreement
         (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
          intent))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'workflow-agreement
         (poo-flow-user-loop-engine-intent-workflow-agreement intent))
   (cons 'budget
         (poo-flow-user-loop-engine-intent-ref intent 'budget '()))
   (cons 'observability
         (poo-flow-user-loop-engine-intent-ref intent 'observability '()))
   (cons 'runtime-executed #f)))

;;; Runtime envelopes are the largest loop-engine handoff object. They carry
;;; workflow, sandbox, and operation facts as inert request data for Marlin.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-envelope intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent)))
    (list
     (cons 'schema +runtime-request-schema+)
     (cons 'runtime 'manifest)
     (cons 'operation 'loop-engine-handoff)
     (cons 'request-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "request"))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-runtime-id use-case-name "artifact"))
     (cons 'request
           (list
            (cons 'kind 'loop-engine-runtime-handoff-request)
            (cons 'contract
                  +poo-flow-user-loop-engine-runtime-command-contract+)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'object-families
                  +poo-flow-user-loop-engine-runtime-object-families+)
            (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '()))
            (cons 'workflow-agreement
                  (poo-flow-user-loop-engine-intent-workflow-agreement
                   intent))
            (cons 'result-contract
                  (poo-flow-user-loop-engine-intent-result-contract intent))
            (cons 'agent-profiles
                  (poo-flow-user-loop-engine-intent-agent-profiles intent))
            (cons 'agent-harnesses
                  (poo-flow-user-loop-engine-intent-agent-harnesses intent))
            (cons 'agent-sessions
                  (poo-flow-user-loop-engine-intent-agent-sessions intent))
            (cons 'workflow-run
                  (poo-flow-user-loop-engine-intent-workflow-run intent))
            (cons 'dispatch-receipt
                  (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
            (cons 'agent-operation
                  (poo-flow-user-loop-engine-intent-agent-operation intent))
            (cons 'delegated-operation
                  (poo-flow-user-loop-engine-intent-delegated-operation
                   intent))
            (cons 'runtime-snapshot
                  (poo-flow-user-loop-engine-intent-runtime-snapshot intent))
            (cons 'sandbox-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-profile-refs
                   '()))
            (cons 'sandbox-runtime-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-runtime-summaries
                   '()))
            (cons 'sandbox-handoff-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-handoff-summaries
                   '()))
            (cons 'sandbox-handoff-agreement
                  (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
                   intent))
            (cons 'sandbox-unresolved-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-unresolved-profile-refs
                   '()))
            (cons 'runtime-executed #f)))
     (cons 'policy
           (poo-flow-user-loop-engine-intent-policy intent))
     (cons 'plan-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "plan"))
     (cons 'node-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "node"))
     (cons 'frontier
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())))))

;;; The command manifest is inert stdout adapter data; it serializes the whole
;;; loop-engine envelope without launching Marlin from Scheme.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)
  (runtime-command-descriptor->manifest
   (make-stdout-runtime-command-descriptor
    +poo-flow-user-loop-engine-runtime-command-name+
    +poo-flow-user-loop-engine-runtime-command-executable+
    +poo-flow-user-loop-engine-runtime-command-arguments+
    (list
     (cons 'source 'user-config-loop-engine)
     (cons 'contract
           +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'runtime-executed #f)))
   (poo-flow-user-loop-engine-intent-runtime-envelope intent)))

;;; Summaries keep presentation tables small while retaining the descriptor ids
;;; that let agents correlate the full manifest when needed.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary intent)
  (let ((manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)))
    (list
     (cons 'kind 'runtime-command-manifest-summary)
     (cons 'contract +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'schema
           (poo-flow-user-loop-engine-intent-ref manifest 'schema #f))
     (cons 'request-schema
           (poo-flow-user-loop-engine-intent-ref manifest 'request-schema #f))
     (cons 'operation
           (poo-flow-user-loop-engine-intent-ref manifest 'operation #f))
     (cons 'request-id
           (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-intent-ref manifest 'artifact-handle #f))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'argv
           (poo-flow-user-loop-engine-intent-ref manifest 'argv '()))
     (cons 'runtime-executed #f))))

;;; Agent profiles are shallow policy rows. They name the selected reviewer or
;;; governor role but leave model choice, tool execution, and sandbox startup to
;;; the runtime handoff.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-profile intent role-ref)
  (let ((role (car role-ref))
        (profile-name (cdr role-ref)))
    (poo-flow-agent-profile->alist
     (make-poo-flow-agent-profile
      profile-name
      'runtime-selected
      (list 'loop-engine role)
      '()
      '(loop-engine)
      (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
      (list (cons 'role role)
            (cons 'governor
                  (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
            (cons 'result-contract
                  (poo-flow-user-loop-engine-intent-role-result-contract
                   intent
                   role))
            (cons 'human-audit
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'human-audit
                   '())))
      '()
      (poo-flow-user-loop-engine-intent-ref intent 'budget '())
      (poo-flow-user-loop-engine-intent-ref intent 'observability '())
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Profile projection preserves user declaration order so presentation output
;;; and runtime manifests can be compared without sorting.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-profiles intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-profile intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;;; Harness rows describe an initialized-agent boundary without constructing
;;; it. They carry runtime intent and sandbox policy references as receipt data.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-harness intent role-ref)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (profile-name (cdr role-ref))
         (harness-id
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-harness"))))
    (poo-flow-agent-harness->alist
     (make-poo-flow-agent-harness
      harness-id
      profile-name
      (poo-flow-user-loop-engine-intent-primary-sandbox-profile intent)
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      '(execute-agent-operation stream-events read-runtime-snapshot)
      (list 'loop-engine use-case-name role)
      (poo-flow-user-loop-engine-intent-ref intent 'observability '())
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Harness projection is one row per named profile so multi-agent governor
;;; configurations remain explicit in the handoff packet.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-harnesses intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-harness intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;;; Session rows keep delegated work separate from workflow runs. The active
;;; operation ref points at the control-plane operation, not an executed turn.
;; : (-> Alist Pair Alist)
(def (poo-flow-user-loop-engine-intent-agent-session intent role-ref)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (role (car role-ref))
         (session-name
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-session")))
         (harness-id
          (poo-flow-user-loop-engine-runtime-id
           use-case-name
           (string-append (symbol->string role) "-harness")))
         (operation-id
          (poo-flow-user-loop-engine-runtime-id use-case-name "operation")))
    (poo-flow-agent-session->alist
     (make-poo-flow-agent-session
      session-name
      harness-id
      (poo-flow-user-loop-engine-intent-status intent)
      operation-id
      (list 'loop-engine-conversation use-case-name role)
      '((retention . parent-owned))
      (list operation-id)
      (list (cons 'source 'user-config-loop-engine)
            (cons 'profile-role role)
            (cons 'workflow-run-ref
                  (poo-flow-user-loop-engine-runtime-id
                   use-case-name
                   "workflow-run"))
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Session projection gives every named profile a stable namespace that agents
;;; can audit before a backend opens durable conversation state.
;; : (-> Alist [Alist])
(def (poo-flow-user-loop-engine-intent-agent-sessions intent)
  (map (lambda (role-ref)
         (poo-flow-user-loop-engine-intent-agent-session intent role-ref))
       (poo-flow-user-loop-engine-intent-agent-profile-refs intent)))

;;; The workflow-run projection is an admission plan for runtime lowering. It
;;; is not evidence that a workflow has started.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-workflow-run intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (run-id
          (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")))
    (poo-flow-workflow-run->alist
     (make-poo-flow-workflow-run
      run-id
      (poo-flow-user-loop-engine-intent-workflow-ref intent)
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
      (poo-flow-user-loop-engine-intent-status intent)
      (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())
      (list 'loop-engine-events use-case-name)
      '()
      #f
      #f
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Dispatch receipts are projected separately from workflow runs so async
;;; agent input does not pretend to be a terminal workflow result.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-dispatch-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (target-agent
          (poo-flow-user-loop-engine-primary-agent
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))))
    (poo-flow-dispatch-receipt->alist
     (make-poo-flow-dispatch-receipt
      (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch")
      target-agent
      (poo-flow-user-loop-engine-runtime-id use-case-name "runtime-instance")
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (list 'loop-engine-payload use-case-name)
      #f
      'admitted
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Agent operations capture the node-level action: governor judge by default,
;;; or human-audit when the user declares a manual loop gate.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-agent-operation intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (operation-kind
          (poo-flow-user-loop-engine-intent-operation-kind intent)))
    (poo-flow-agent-operation->alist
     (make-poo-flow-agent-operation
      (poo-flow-user-loop-engine-runtime-id use-case-name "operation")
      operation-kind
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'governor
                  (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
            (cons 'agent-judges
                  (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
            (cons 'human-audit
                  (poo-flow-user-loop-engine-intent-ref intent 'human-audit '())))
      (poo-flow-user-loop-engine-intent-operation-result-contract intent)
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Delegated operations are the Flue-style readable view over the canonical
;;; agent-operation row. They name the governor, reviewer, and human audit gate
;;; without claiming Scheme has executed the node.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-delegated-operation intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (agent-judges
          (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
         (governor-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'governor
           'loop-governor-agent))
         (explicit-reviewer-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'reviewer
           #f))
         (reviewer-agent
          (if explicit-reviewer-agent
            explicit-reviewer-agent
            (poo-flow-user-loop-engine-agent-judge-ref
             agent-judges
             'verifier
             (poo-flow-user-loop-engine-agent-judge-ref
              agent-judges
              'auditor
              'loop-reviewer-agent))))
         (auditor-agent
          (poo-flow-user-loop-engine-agent-judge-ref
           agent-judges
           'auditor
           reviewer-agent))
         (human-audit
          (poo-flow-user-loop-engine-intent-ref intent 'human-audit '())))
    (list
     (cons 'kind 'delegated-operation)
     (cons 'contract 'poo-flow.loop-engine.delegated-operation.v1)
     (cons 'source 'user-config-loop-engine)
     (cons 'object-family 'agent-operation)
     (cons 'operation-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "operation"))
     (cons 'operation-kind
           (poo-flow-user-loop-engine-intent-operation-kind intent))
     (cons 'workflow-run-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run"))
     (cons 'session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'child-session-ref
           (poo-flow-user-loop-engine-runtime-id
            use-case-name
            "delegate-session"))
     (cons 'workflow-ref
           (poo-flow-user-loop-engine-intent-workflow-ref intent))
     (cons 'governor-agent governor-agent)
     (cons 'reviewer-agent reviewer-agent)
     (cons 'reviewer-role
           (if explicit-reviewer-agent 'reviewer 'verifier))
     (cons 'auditor-agent auditor-agent)
     (cons 'human-audit human-audit)
     (cons 'human-audit-profile
           (if (null? human-audit) #f 'human-audit))
     (cons 'human-audit-required?
           (not (null? human-audit)))
     (cons 'result-contract
           (poo-flow-user-loop-engine-intent-result-contract intent))
     (cons 'structured-result-contract
           (poo-flow-user-loop-engine-intent-operation-result-contract
            intent))
     (cons 'runtime-intent
           (poo-flow-user-loop-engine-intent-runtime-intent intent))
     (cons 'status
           (poo-flow-user-loop-engine-intent-status intent))
     (cons 'descriptor-realized? #f)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Runtime consumers may receive older intent rows without the agreement slot;
;;; this accessor makes sandbox readiness total and keeps snapshot/handoff code
;;; from re-encoding agreement shape in multiple places.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement intent)
  (poo-flow-user-loop-engine-intent-ref
   intent
   'sandbox-handoff-agreement
   (poo-flow-user-loop-engine-sandbox-handoff-agreement
    (poo-flow-user-loop-engine-intent-ref
     intent
     'sandbox-profile-refs
     '())
    (poo-flow-user-loop-engine-intent-ref
     intent
     'sandbox-runtime-summaries
     '())
    (poo-flow-user-loop-engine-intent-ref
     intent
     'sandbox-handoff-summaries
     '())
    (poo-flow-user-loop-engine-intent-ref
     intent
     'sandbox-unresolved-profile-refs
     '()))))

;;; Runtime snapshots expose the sandbox agreement as the handoff readiness
;;; source of truth. This prevents a loop from looking ready when a sandbox
;;; profile is unresolved or only available as an invalid runtime summary.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-snapshot intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (workflow-ref
          (poo-flow-user-loop-engine-intent-workflow-ref intent))
         (workflow-agreement
          (poo-flow-user-loop-engine-intent-workflow-agreement intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
           intent))
         (handoff-ready?
          (and
           (poo-flow-user-loop-engine-intent-ref
            sandbox-agreement
            'handoff-ready?
            #f)
           (poo-flow-user-loop-engine-intent-ref
            workflow-agreement
            'valid?
            #f)))
         (handoff-summary
          (list (cons 'workflow-ref workflow-ref)
                (cons 'handoff-ready? handoff-ready?)
                (cons 'workflow-agreement workflow-agreement)
                (cons 'sandbox-handoff-agreement sandbox-agreement)
                (cons 'runtime-executed #f))))
    (poo-flow-runtime-snapshot->alist
     (make-poo-flow-runtime-snapshot
      'loop-engine
      use-case-name
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      handoff-summary
      #f
      '((stage . user-config-loop-engine-runtime-snapshot)
        (runtime-executed . #f))
      (append
       handoff-summary
       (list (cons 'contract 'poo-flow.loop-governor.v1)
             (cons 'runtime-owner "marlin-agent-core")))))))

;;; Handoff facts are the single report row tying loop-engine policy,
;;; workflow-run projections, sandbox evidence, and runtime command manifests.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent)
  (list
   (cons 'kind 'loop-engine-runtime-handoff)
   (cons 'contract 'poo-flow.loop-governor.runtime-handoff.v1)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-handoff
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-handoff
          'loop-governor-marlin-runtime-manifest))
   (cons 'handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-command-contract
         +poo-flow-user-loop-engine-runtime-command-contract+)
   (cons 'object-families
         +poo-flow-user-loop-engine-runtime-object-families+)
   (cons 'workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent))
   (cons 'workflow-agreement
         (poo-flow-user-loop-engine-intent-workflow-agreement intent))
   (cons 'result-contract
         (poo-flow-user-loop-engine-intent-result-contract intent))
   (cons 'agent-profiles
         (poo-flow-user-loop-engine-intent-agent-profiles intent))
   (cons 'agent-harnesses
         (poo-flow-user-loop-engine-intent-agent-harnesses intent))
   (cons 'agent-sessions
         (poo-flow-user-loop-engine-intent-agent-sessions intent))
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'sandbox
         (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
   (cons 'sandbox-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-profile-refs
          '()))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-handoff-agreement
         (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
          intent))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'runtime
         (poo-flow-user-loop-engine-intent-ref intent 'runtime '()))
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

;;; Runtime projections are the bundled receipt surface for one loop intent.
;;; Keeping these rows together prevents presentation code from recomputing
;;; workflow, dispatch, operation, manifest, and snapshot facts independently.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-projections intent)
  (list
   (cons 'runtime-handoff-contracts
         +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-handoff-facts
         (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent))
   (cons 'workflow-agreement
         (poo-flow-user-loop-engine-intent-workflow-agreement intent))
   (cons 'result-contract
         (poo-flow-user-loop-engine-intent-result-contract intent))
   (cons 'agent-profiles
         (poo-flow-user-loop-engine-intent-agent-profiles intent))
   (cons 'agent-harnesses
         (poo-flow-user-loop-engine-intent-agent-harnesses intent))
   (cons 'agent-sessions
         (poo-flow-user-loop-engine-intent-agent-sessions intent))
   (cons 'workflow-run
         (poo-flow-user-loop-engine-intent-workflow-run intent))
   (cons 'dispatch-receipt
         (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
   (cons 'agent-operation
         (poo-flow-user-loop-engine-intent-agent-operation intent))
   (cons 'delegated-operation
         (poo-flow-user-loop-engine-intent-delegated-operation intent))
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-handoff-agreement
         (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
          intent))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'runtime-snapshot
         (poo-flow-user-loop-engine-intent-runtime-snapshot intent))))

;;; Presentation modules use this extractor to expose repeated loop-engine
;;; slots without learning the shape of each runtime projection row.
;; : (-> [Alist] Symbol [Value])
(def (poo-flow-user-loop-engine-intents-field-values intents field)
  (cond
   ((null? intents) '())
   (else
    (cons
     (poo-flow-user-loop-engine-intent-ref (car intents) field #f)
     (poo-flow-user-loop-engine-intents-field-values (cdr intents) field)))))

;;; Loop-engine intents are the workflow-facing surface for configuring the
;;; governor node graph from init.ss. The result is report-only contract data.
;; : (-> PooUserModuleSelection [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-module-selection-loop-engine-intent selection
                                                       . maybe-context)
  (if (equal? (poo-flow-user-module-selection-key selection)
              '(flow . loop-engine))
    (let* ((profile-catalog
            (if (null? maybe-context)
              poo-flow-default-sandbox-profiles
              (car maybe-context)))
           (workflow-check-maps
            (if (or (null? maybe-context)
                    (null? (cdr maybe-context)))
              '()
              (cadr maybe-context)))
           (base-intent
            (list (cons 'key (poo-flow-user-module-selection-key selection))
                  (cons 'feature '+loop-engine)
                  (cons 'workflow-owned? #t)
                  (cons 'governor-derived? #t)
                  (cons 'use-case
                        (poo-flow-user-loop-engine-section selection '+use-case))
                  (cons 'use-cases
                        (poo-flow-user-loop-engine-section selection '+use-cases))
                  (cons 'governor
                        (poo-flow-user-loop-engine-section selection '+governor))
                  (cons 'agent-judges
                        (poo-flow-user-loop-engine-section selection '+agent-judges))
                  (cons 'human-audit
                        (poo-flow-user-loop-engine-section selection '+human-audit))
                  (cons 'schedule
                        (poo-flow-user-loop-engine-section selection '+schedule))
                  (cons 'state
                        (poo-flow-user-loop-engine-section selection '+state))
                  (cons 'sandbox
                        (poo-flow-user-loop-engine-section selection '+sandbox))
                  (cons 'budget
                        (poo-flow-user-loop-engine-section selection '+budget))
                  (cons 'observability
                        (poo-flow-user-loop-engine-section selection '+observability))
                  (cons 'result
                        (poo-flow-user-loop-engine-section selection '+result))
                  (cons 'runtime
                        (poo-flow-user-loop-engine-section selection '+runtime))
                  (cons 'contract 'poo-flow.loop-governor.v1)
                  (cons 'node-contract 'poo-flow.loop-governor.node.v1)
                  (cons 'runtime-handoff 'loop-governor-marlin-runtime-manifest)
                  (cons 'runtime-owner "marlin-agent-core")
                  (cons 'descriptor-realized? #f)
                  (cons 'runtime-executed #f)))
           (sandbox-profile-refs
            (poo-flow-user-loop-engine-sandbox-profile-refs base-intent))
           (sandbox-runtime-summaries
            (poo-flow-user-loop-engine-sandbox-runtime-summaries
             sandbox-profile-refs
             profile-catalog))
           (sandbox-handoff-summaries
            (poo-flow-user-loop-engine-sandbox-handoff-summaries
             sandbox-profile-refs
             profile-catalog))
           (sandbox-unresolved-profile-refs
            (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
             sandbox-profile-refs
             profile-catalog))
           (sandbox-handoff-agreement
            (poo-flow-user-loop-engine-sandbox-handoff-agreement
             sandbox-profile-refs
             sandbox-runtime-summaries
             sandbox-handoff-summaries
             sandbox-unresolved-profile-refs))
           (workflow-agreement
            (poo-flow-funflow-workflow-agreement
             (poo-flow-user-loop-engine-intent-workflow-ref base-intent)
             workflow-check-maps))
           (intent
            (append
             base-intent
             (list
              (cons 'workflow-agreement workflow-agreement)
              (cons 'sandbox-profile-refs sandbox-profile-refs)
              (cons 'sandbox-runtime-summaries
                    sandbox-runtime-summaries)
              (cons 'sandbox-handoff-summaries
                    sandbox-handoff-summaries)
              (cons 'sandbox-handoff-agreement
                    sandbox-handoff-agreement)
              (cons 'sandbox-unresolved-profile-refs
                    sandbox-unresolved-profile-refs)))))
      (append intent
              (poo-flow-user-loop-engine-intent-runtime-projections intent)))
    #f))

;;; Loop engine intents are collected with a recursive add/fold shape so module
;;; selection order becomes the handoff order for later runtime descriptors.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile] [PooFlowCicdCheckMap] [Alist])
(def (poo-flow-user-config-loop-engine-intents/add selected-modules
                                                   profile-catalog
                                                   . maybe-workflow-check-maps)
  (let ((workflow-check-maps
         (if (null? maybe-workflow-check-maps)
           '()
           (car maybe-workflow-check-maps))))
  (cond
   ((null? selected-modules) '())
   ((poo-flow-user-module-selection-loop-engine-intent (car selected-modules)
                                                       profile-catalog
                                                       workflow-check-maps)
    => (lambda (intent)
         (cons intent
               (poo-flow-user-config-loop-engine-intents/add
                (cdr selected-modules)
                profile-catalog
                workflow-check-maps))))
   (else
    (poo-flow-user-config-loop-engine-intents/add
     (cdr selected-modules)
     profile-catalog
     workflow-check-maps)))))

;;; Config-level loop-engine intents let workflow docs and tests show the real
;;; governor configuration result from `:workflow` without starting a loop.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-loop-engine-intents config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules))
         (workflow-check-maps
          (poo-flow-user-config-workflow-cicd-check-maps config)))
    (poo-flow-user-config-loop-engine-intents/add
     selected-modules
     profile-catalog
     workflow-check-maps)))
