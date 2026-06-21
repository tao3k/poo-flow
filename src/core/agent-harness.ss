;;; -*- Gerbil -*-
;;; Boundary: inert agent harness/session/run object families.
;;; Invariant: constructors and projections never execute runtime work.

(import :poo-flow/src/core/receipt)

(export +poo-flow-agent-operation-kinds+
        +poo-flow-runtime-snapshot-statuses+
        make-poo-flow-agent-profile
        poo-flow-agent-profile?
        poo-flow-agent-profile-name
        poo-flow-agent-profile-model-policy
        poo-flow-agent-profile-instructions
        poo-flow-agent-profile-tools
        poo-flow-agent-profile-skills
        poo-flow-agent-profile-sandbox-profile
        poo-flow-agent-profile-loop-policy
        poo-flow-agent-profile-compaction-policy
        poo-flow-agent-profile-budget-policy
        poo-flow-agent-profile-observability-policy
        poo-flow-agent-profile-metadata
        poo-flow-agent-profile->alist
        make-poo-flow-agent-harness
        poo-flow-agent-harness?
        poo-flow-agent-harness-id
        poo-flow-agent-harness-profile
        poo-flow-agent-harness-sandbox-profile
        poo-flow-agent-harness-runtime-adapter-intent
        poo-flow-agent-harness-capabilities
        poo-flow-agent-harness-session-namespace
        poo-flow-agent-harness-observability-sink
        poo-flow-agent-harness-runtime-executed?
        poo-flow-agent-harness-metadata
        poo-flow-agent-harness->alist
        make-poo-flow-agent-session
        poo-flow-agent-session?
        poo-flow-agent-session-name
        poo-flow-agent-session-harness-id
        poo-flow-agent-session-status
        poo-flow-agent-session-active-operation-id
        poo-flow-agent-session-conversation-state-ref
        poo-flow-agent-session-retention-policy
        poo-flow-agent-session-operation-history
        poo-flow-agent-session-metadata
        poo-flow-agent-session->alist
        make-poo-flow-agent-operation
        poo-flow-agent-operation?
        poo-flow-agent-operation-id
        poo-flow-agent-operation-kind
        poo-flow-agent-operation-parent-session
        poo-flow-agent-operation-parent-run
        poo-flow-agent-operation-request
        poo-flow-agent-operation-result-contract
        poo-flow-agent-operation-runtime-intent
        poo-flow-agent-operation-status
        poo-flow-agent-operation-receipt
        poo-flow-agent-operation-metadata
        poo-flow-agent-operation-kind?
        poo-flow-agent-operation-delegated-task?
        poo-flow-agent-operation->alist
        make-poo-flow-workflow-run
        poo-flow-workflow-run?
        poo-flow-workflow-run-run-id
        poo-flow-workflow-run-workflow-ref
        poo-flow-workflow-run-payload-ref
        poo-flow-workflow-run-status
        poo-flow-workflow-run-harness-refs
        poo-flow-workflow-run-event-stream-ref
        poo-flow-workflow-run-logs
        poo-flow-workflow-run-result
        poo-flow-workflow-run-error
        poo-flow-workflow-run-terminal-receipt
        poo-flow-workflow-run-metadata
        poo-flow-workflow-run->alist
        make-poo-flow-dispatch-receipt
        poo-flow-dispatch-receipt?
        poo-flow-dispatch-receipt-dispatch-id
        poo-flow-dispatch-receipt-target-agent
        poo-flow-dispatch-receipt-target-instance-id
        poo-flow-dispatch-receipt-target-session-id
        poo-flow-dispatch-receipt-payload-ref
        poo-flow-dispatch-receipt-accepted-at
        poo-flow-dispatch-receipt-admission-status
        poo-flow-dispatch-receipt-runtime-queue-intent
        poo-flow-dispatch-receipt-metadata
        poo-flow-dispatch-receipt->alist
        make-poo-flow-runtime-snapshot
        poo-flow-runtime-snapshot?
        poo-flow-runtime-snapshot-subject-kind
        poo-flow-runtime-snapshot-subject-id
        poo-flow-runtime-snapshot-status
        poo-flow-runtime-snapshot-last-event-index
        poo-flow-runtime-snapshot-result-summary
        poo-flow-runtime-snapshot-error-summary
        poo-flow-runtime-snapshot-presentation-trace
        poo-flow-runtime-snapshot-metadata
        poo-flow-runtime-snapshot-status?
        poo-flow-runtime-snapshot->alist
        poo-flow-receipt->workflow-run
        poo-flow-workflow-run->snapshot
        poo-flow-agent-session->snapshot
        poo-flow-dispatch-receipt->snapshot)

;;; Operation kind names are stable user/agent-facing vocabulary. Runtime
;;; adapters may lower them differently, but projections keep these symbols.
(def +poo-flow-agent-operation-kinds+
  '(prompt skill task shell fs-read fs-write compact governor-judge human-audit))

;;; Snapshots are shallow UI/CLI projections over richer receipts and runtime
;;; objects. They are not the canonical execution state.
(def +poo-flow-runtime-snapshot-statuses+
  '(idle admitted connecting running blocked waiting-human completed errored disconnected))

;; : (-> Symbol Boolean)
(def (poo-flow-agent-operation-kind? kind)
  (and (member kind +poo-flow-agent-operation-kinds+) #t))

;; : (-> Symbol Boolean)
(def (poo-flow-runtime-snapshot-status? status)
  (and (member status +poo-flow-runtime-snapshot-statuses+) #t))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-agent-harness-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;;; Profiles are reusable policy objects. The fields are deliberately shallow:
;;; concrete model, tool, skill, sandbox, and loop details are references that
;;; later layers validate and lower.
;; : PooFlowAgentProfile
(defstruct poo-flow-agent-profile
  (name
   model-policy
   instructions
   tools
   skills
   sandbox-profile
   loop-policy
   compaction-policy
   budget-policy
   observability-policy
   metadata)
  transparent: #t)

;; : PooFlowAgentHarness
(defstruct poo-flow-agent-harness
  (id
   profile
   sandbox-profile
   runtime-adapter-intent
   capabilities
   session-namespace
   observability-sink
   runtime-executed?
   metadata)
  transparent: #t)

;; : PooFlowAgentSession
(defstruct poo-flow-agent-session
  (name
   harness-id
   status
   active-operation-id
   conversation-state-ref
   retention-policy
   operation-history
   metadata)
  transparent: #t)

;; : PooFlowAgentOperation
(defstruct poo-flow-agent-operation
  (id
   kind
   parent-session
   parent-run
   request
   result-contract
   runtime-intent
   status
   receipt
   metadata)
  transparent: #t)

;; : PooFlowWorkflowRun
(defstruct poo-flow-workflow-run
  (run-id
   workflow-ref
   payload-ref
   status
   harness-refs
   event-stream-ref
   logs
   result
   error
   terminal-receipt
   metadata)
  transparent: #t)

;;; Dispatch admission is separate from workflow run completion. It records
;;; that input was accepted for a continuing agent/session.
;; : PooFlowDispatchReceipt
(defstruct poo-flow-dispatch-receipt
  (dispatch-id
   target-agent
   target-instance-id
   target-session-id
   payload-ref
   accepted-at
   admission-status
   runtime-queue-intent
   metadata)
  transparent: #t)

;; : PooFlowRuntimeSnapshot
(defstruct poo-flow-runtime-snapshot
  (subject-kind
   subject-id
   status
   last-event-index
   result-summary
   error-summary
   presentation-trace
   metadata)
  transparent: #t)

;; : (-> PooFlowAgentProfile Alist)
(def (poo-flow-agent-profile->alist profile)
  (list (cons 'kind 'agent-profile)
        (cons 'name (poo-flow-agent-profile-name profile))
        (cons 'model-policy (poo-flow-agent-profile-model-policy profile))
        (cons 'instructions (poo-flow-agent-profile-instructions profile))
        (cons 'tools (poo-flow-agent-profile-tools profile))
        (cons 'skills (poo-flow-agent-profile-skills profile))
        (cons 'sandbox-profile (poo-flow-agent-profile-sandbox-profile profile))
        (cons 'loop-policy (poo-flow-agent-profile-loop-policy profile))
        (cons 'compaction-policy (poo-flow-agent-profile-compaction-policy profile))
        (cons 'budget-policy (poo-flow-agent-profile-budget-policy profile))
        (cons 'observability-policy (poo-flow-agent-profile-observability-policy profile))
        (cons 'metadata (poo-flow-agent-profile-metadata profile))
        (cons 'runtime-executed #f)))

;; : (-> PooFlowAgentHarness Alist)
(def (poo-flow-agent-harness->alist harness)
  (list (cons 'kind 'agent-harness)
        (cons 'id (poo-flow-agent-harness-id harness))
        (cons 'profile (poo-flow-agent-harness-profile harness))
        (cons 'sandbox-profile (poo-flow-agent-harness-sandbox-profile harness))
        (cons 'runtime-adapter-intent
              (poo-flow-agent-harness-runtime-adapter-intent harness))
        (cons 'capabilities (poo-flow-agent-harness-capabilities harness))
        (cons 'session-namespace
              (poo-flow-agent-harness-session-namespace harness))
        (cons 'observability-sink
              (poo-flow-agent-harness-observability-sink harness))
        (cons 'runtime-executed
              (poo-flow-agent-harness-runtime-executed? harness))
        (cons 'metadata (poo-flow-agent-harness-metadata harness))))

;; : (-> PooFlowAgentSession Alist)
(def (poo-flow-agent-session->alist session)
  (list (cons 'kind 'agent-session)
        (cons 'name (poo-flow-agent-session-name session))
        (cons 'harness-id (poo-flow-agent-session-harness-id session))
        (cons 'status (poo-flow-agent-session-status session))
        (cons 'active-operation-id
              (poo-flow-agent-session-active-operation-id session))
        (cons 'conversation-state-ref
              (poo-flow-agent-session-conversation-state-ref session))
        (cons 'retention-policy
              (poo-flow-agent-session-retention-policy session))
        (cons 'operation-history
              (poo-flow-agent-session-operation-history session))
        (cons 'metadata (poo-flow-agent-session-metadata session))
        (cons 'workflow-run? #f)))

;; : (-> PooFlowAgentOperation Boolean)
(def (poo-flow-agent-operation-delegated-task? operation)
  (eq? (poo-flow-agent-operation-kind operation) 'task))

;; : (-> PooFlowAgentOperation Alist)
(def (poo-flow-agent-operation->alist operation)
  (list (cons 'kind 'agent-operation)
        (cons 'operation-kind (poo-flow-agent-operation-kind operation))
        (cons 'id (poo-flow-agent-operation-id operation))
        (cons 'parent-session
              (poo-flow-agent-operation-parent-session operation))
        (cons 'parent-run (poo-flow-agent-operation-parent-run operation))
        (cons 'request (poo-flow-agent-operation-request operation))
        (cons 'result-contract
              (poo-flow-agent-operation-result-contract operation))
        (cons 'runtime-intent
              (poo-flow-agent-operation-runtime-intent operation))
        (cons 'status (poo-flow-agent-operation-status operation))
        (cons 'receipt (poo-flow-agent-operation-receipt operation))
        (cons 'delegated-task?
              (poo-flow-agent-operation-delegated-task? operation))
        (cons 'metadata (poo-flow-agent-operation-metadata operation))))

;; : (-> PooFlowWorkflowRun Alist)
(def (poo-flow-workflow-run->alist run)
  (list (cons 'kind 'workflow-run)
        (cons 'run-id (poo-flow-workflow-run-run-id run))
        (cons 'workflow-ref (poo-flow-workflow-run-workflow-ref run))
        (cons 'payload-ref (poo-flow-workflow-run-payload-ref run))
        (cons 'status (poo-flow-workflow-run-status run))
        (cons 'harness-refs (poo-flow-workflow-run-harness-refs run))
        (cons 'event-stream-ref
              (poo-flow-workflow-run-event-stream-ref run))
        (cons 'logs (poo-flow-workflow-run-logs run))
        (cons 'result (poo-flow-workflow-run-result run))
        (cons 'error (poo-flow-workflow-run-error run))
        (cons 'terminal-receipt
              (poo-flow-workflow-run-terminal-receipt run))
        (cons 'metadata (poo-flow-workflow-run-metadata run))))

;; : (-> PooFlowDispatchReceipt Alist)
(def (poo-flow-dispatch-receipt->alist receipt)
  (list (cons 'kind 'dispatch-receipt)
        (cons 'dispatch-id (poo-flow-dispatch-receipt-dispatch-id receipt))
        (cons 'target-agent (poo-flow-dispatch-receipt-target-agent receipt))
        (cons 'target-instance-id
              (poo-flow-dispatch-receipt-target-instance-id receipt))
        (cons 'target-session-id
              (poo-flow-dispatch-receipt-target-session-id receipt))
        (cons 'payload-ref (poo-flow-dispatch-receipt-payload-ref receipt))
        (cons 'accepted-at (poo-flow-dispatch-receipt-accepted-at receipt))
        (cons 'admission-status
              (poo-flow-dispatch-receipt-admission-status receipt))
        (cons 'runtime-queue-intent
              (poo-flow-dispatch-receipt-runtime-queue-intent receipt))
        (cons 'workflow-run-id #f)
        (cons 'metadata (poo-flow-dispatch-receipt-metadata receipt))))

;; : (-> PooFlowRuntimeSnapshot Alist)
(def (poo-flow-runtime-snapshot->alist snapshot)
  (list (cons 'kind 'runtime-snapshot)
        (cons 'subject-kind (poo-flow-runtime-snapshot-subject-kind snapshot))
        (cons 'subject-id (poo-flow-runtime-snapshot-subject-id snapshot))
        (cons 'status (poo-flow-runtime-snapshot-status snapshot))
        (cons 'last-event-index
              (poo-flow-runtime-snapshot-last-event-index snapshot))
        (cons 'result-summary
              (poo-flow-runtime-snapshot-result-summary snapshot))
        (cons 'error-summary
              (poo-flow-runtime-snapshot-error-summary snapshot))
        (cons 'presentation-trace
              (poo-flow-runtime-snapshot-presentation-trace snapshot))
        (cons 'metadata (poo-flow-runtime-snapshot-metadata snapshot))))

;; : (-> Symbol Symbol)
(def (poo-flow-receipt-workflow-status status)
  (cond
   ((eq? status 'ok) 'completed)
   ((eq? status 'failed) 'errored)
   (else status)))

;;; Existing runner receipts can be projected into the new workflow-run object
;;; family without making the runner import this module. The caller supplies the
;;; run id because durable id ownership belongs to the admission/runtime layer.
;; : (-> Receipt RunId PooFlowWorkflowRun)
(def (poo-flow-receipt->workflow-run receipt run-id)
  (make-poo-flow-workflow-run
   run-id
   (receipt-flow receipt)
   (receipt-input receipt)
   (poo-flow-receipt-workflow-status (receipt-status receipt))
   '()
   (list 'receipt-events run-id)
   '()
   (receipt-output receipt)
   (receipt-error receipt)
   receipt
   (list (cons 'source 'receipt)
         (cons 'strategy (receipt-strategy receipt))
         (cons 'policy (receipt-policy receipt))
         (cons 'frontier (receipt-frontier receipt))
         (cons 'event-count (receipt-event-count receipt))
         (cons 'adapter-request-count
               (receipt-adapter-request-count receipt)))))

;; : (-> PooFlowWorkflowRun PooFlowRuntimeSnapshot)
(def (poo-flow-workflow-run->snapshot run)
  (make-poo-flow-runtime-snapshot
   'workflow-run
   (poo-flow-workflow-run-run-id run)
   (poo-flow-workflow-run-status run)
   (poo-flow-agent-harness-alist-ref
    (poo-flow-workflow-run-metadata run)
    'last-event-index
    #f)
   (poo-flow-workflow-run-result run)
   (poo-flow-workflow-run-error run)
   '((stage . workflow-run->snapshot)
     (runtime-executed . #f))
   (list (cons 'workflow-ref (poo-flow-workflow-run-workflow-ref run))
         (cons 'event-stream-ref
               (poo-flow-workflow-run-event-stream-ref run)))))

;; : (-> PooFlowAgentSession PooFlowRuntimeSnapshot)
(def (poo-flow-agent-session->snapshot session)
  (make-poo-flow-runtime-snapshot
   'agent-session
   (poo-flow-agent-session-name session)
   (poo-flow-agent-session-status session)
   (length (poo-flow-agent-session-operation-history session))
   #f
   #f
   '((stage . agent-session->snapshot)
     (runtime-executed . #f))
   (list (cons 'harness-id (poo-flow-agent-session-harness-id session))
         (cons 'active-operation-id
               (poo-flow-agent-session-active-operation-id session)))))

;; : (-> PooFlowDispatchReceipt PooFlowRuntimeSnapshot)
(def (poo-flow-dispatch-receipt->snapshot receipt)
  (make-poo-flow-runtime-snapshot
   'dispatch-receipt
   (poo-flow-dispatch-receipt-dispatch-id receipt)
   (poo-flow-dispatch-receipt-admission-status receipt)
   #f
   #f
   #f
   '((stage . dispatch-receipt->snapshot)
     (runtime-executed . #f))
   (list (cons 'target-agent
               (poo-flow-dispatch-receipt-target-agent receipt))
         (cons 'target-session-id
               (poo-flow-dispatch-receipt-target-session-id receipt)))))
