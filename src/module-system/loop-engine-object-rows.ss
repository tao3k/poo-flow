;;; -*- Gerbil -*-
;;; Boundary: loop-engine non-policy POO objects lowered into intent row fragments.
;;; Invariant: object rows validate declarations and stay runtime-report data.

(import (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/loop-engine-prototypes
        :poo-flow/src/module-system/loop-engine-contract
        :poo-flow/src/module-system/loop-engine-kind-contract
        :poo-flow/src/module-system/loop-engine-row-utils)

(export poo-flow-user-loop-engine-poo-use-case->row
        poo-flow-user-loop-engine-poo-use-cases->rows
        poo-flow-user-loop-engine-poo-governor->rows
        poo-flow-user-loop-engine-judge-row
        poo-flow-user-loop-engine-poo-agent-judges->rows
        poo-flow-user-loop-engine-poo-human-audit->rows
        poo-flow-user-loop-engine-poo-schedule->rows
        poo-flow-user-loop-engine-poo-state->rows
        poo-flow-user-loop-engine-poo-sandbox->rows
        poo-flow-user-loop-engine-poo-budget->rows
        poo-flow-user-loop-engine-result-role-row
        poo-flow-user-loop-engine-poo-result->rows
        poo-flow-user-loop-engine-poo-observability->rows
        poo-flow-user-loop-engine-poo-runtime->rows)

;;; Use-case rows are the named branch declarations consumed by selector,
;;; memory, and runtime handoff projections.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-use-case->row use-case)
  (poo-flow-user-loop-engine-require
   "loop-engine use-case config object must extend loop-engine-use-case"
   (poo-flow-user-loop-engine-poo-use-case? use-case)
   use-case)
  (let ((name (.ref use-case 'name))
        (level (.ref use-case 'level))
        (mode (.ref use-case 'mode))
        (goal (.ref use-case 'goal))
        (workflow (.ref use-case 'workflow))
        (metadata (.ref use-case 'metadata)))
    (poo-flow-user-loop-engine-require
     "loop-engine use-case name must be a symbol"
     (symbol? name)
     name)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'level level)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'mode mode)
    (poo-flow-user-loop-engine-require-maybe-symbol-or-string-slot
     'loop-engine-use-case 'goal goal)
    (poo-flow-user-loop-engine-require-maybe-symbol-slot
     'loop-engine-use-case 'workflow workflow)
    (poo-flow-user-loop-engine-require-alist-slot
     'loop-engine-use-case 'metadata metadata)
    (cons name
          (append
           (poo-flow-user-loop-engine-optional-row 'level level)
           (poo-flow-user-loop-engine-optional-row 'mode mode)
           (poo-flow-user-loop-engine-optional-row 'goal goal)
           (poo-flow-user-loop-engine-optional-row 'workflow workflow)
           metadata))))

;;; Use-case lists preserve declaration order because selector defaults and
;;; presentation rows use that same order downstream.
;; : (-> [PooFlowLoopEngineUseCasePrototype] [Pair])
(def (poo-flow-user-loop-engine-poo-use-cases->rows use-cases)
  (cond
   ((null? use-cases) '())
   ((pair? use-cases)
    (cons
     (poo-flow-user-loop-engine-poo-use-case->row (car use-cases))
     (poo-flow-user-loop-engine-poo-use-cases->rows (cdr use-cases))))
   (else
    (error "loop-engine profile use-cases slot must be a list" use-cases))))

;;; Governor rows describe strategy capabilities only. Runtime selection of the
;;; governor agent happens later from agent-judges.
;; : (-> PooFlowLoopEngineGovernorPrototype [PooFlowLoopEngineFlatRow])
(def (poo-flow-user-loop-engine-poo-governor->rows governor)
  (cond
   ((not governor) '())
   ((poo-flow-user-loop-engine-poo-kind?
     governor
     +poo-flow-user-loop-engine-governor-prototype-kind+)
    (let ((capabilities (.ref governor 'capabilities))
          (metadata (.ref governor 'metadata)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-governor 'capabilities capabilities)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-governor 'metadata metadata)
      (append capabilities metadata)))
   (else
    (error "loop-engine governor slot must extend loop-engine-governor"
           governor))))

;;; Judge rows use list shape to preserve the role/name distinction in alist
;;; presentation without treating agent names as executable selectors.
;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-judge-row role value)
  (if value (list (list role value)) '()))

;;; Agent-judge rows name the human and model roles that Marlin may bind later.
;;; Scheme only validates the optional symbol slots.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-agent-judges->rows agent-judges)
  (cond
   ((not agent-judges) '())
   ((poo-flow-user-loop-engine-poo-kind?
     agent-judges
     +poo-flow-user-loop-engine-agent-judges-prototype-kind+)
    (let ((auditor (.ref agent-judges 'auditor))
          (verifier (.ref agent-judges 'verifier))
          (reviewer (.ref agent-judges 'reviewer))
          (governor (.ref agent-judges 'governor))
          (metadata (.ref agent-judges 'metadata)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'auditor auditor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'verifier verifier)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'reviewer reviewer)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-agent-judges 'governor governor)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-agent-judges 'metadata metadata)
      (append
       (poo-flow-user-loop-engine-judge-row 'auditor auditor)
       (poo-flow-user-loop-engine-judge-row 'verifier verifier)
       (poo-flow-user-loop-engine-judge-row 'reviewer reviewer)
       (poo-flow-user-loop-engine-judge-row 'governor governor)
       metadata)))
   (else
    (error "loop-engine agent-judges slot must extend loop-engine-agent-judges"
           agent-judges))))

;;; Human-audit rows keep manual gate actions as policy vocabulary. They do not
;;; invoke reviewers or block execution inside Scheme.
;; : (-> PooFlowLoopEngineHumanAuditPrototype [PooFlowLoopEngineFlatRow])
(def (poo-flow-user-loop-engine-poo-human-audit->rows human-audit)
  (cond
   ((not human-audit) '())
   ((poo-flow-user-loop-engine-poo-kind?
     human-audit
     +poo-flow-user-loop-engine-human-audit-prototype-kind+)
    (let ((actions (.ref human-audit 'actions))
          (metadata (.ref human-audit 'metadata)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-human-audit 'actions actions)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-human-audit 'metadata metadata)
      (append actions metadata)))
   (else
    (error "loop-engine human-audit slot must extend loop-engine-human-audit"
           human-audit))))

;;; Schedule rows are trigger metadata only; timers and recurrence are runtime
;;; or external scheduler responsibilities.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-schedule->rows schedule)
  (cond
   ((not schedule) '())
   ((poo-flow-user-loop-engine-poo-kind?
     schedule
     +poo-flow-user-loop-engine-schedule-prototype-kind+)
    (let ((trigger (.ref schedule 'trigger))
          (cadence (.ref schedule 'cadence))
          (entries (.ref schedule 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-schedule 'trigger trigger)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-schedule 'cadence cadence)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-schedule 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'trigger trigger)
       (poo-flow-user-loop-engine-optional-row 'cadence cadence)
       entries)))
   (else
    (error "loop-engine schedule slot must extend loop-engine-schedule"
           schedule))))

;;; State rows name stores and paths as handoff facts. They do not read or
;;; mutate state files in the Scheme control plane.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-state->rows state)
  (cond
   ((not state) '())
   ((poo-flow-user-loop-engine-poo-kind?
     state
     +poo-flow-user-loop-engine-state-prototype-kind+)
    (let ((store (.ref state 'store))
          (path (.ref state 'path))
          (acting-on (.ref state 'acting-on))
          (entries (.ref state 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-state 'store store)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-state 'path path)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-state 'acting-on acting-on)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-state 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'store store)
       (poo-flow-user-loop-engine-optional-row 'path path)
       (poo-flow-user-loop-engine-optional-row 'acting-on acting-on)
       entries)))
   (else
    (error "loop-engine state slot must extend loop-engine-state" state))))

;;; Sandbox rows collect profile references and per-use-case overrides for the
;;; sandbox agreement owner; they do not start containers or processes.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-sandbox->rows sandbox)
  (cond
   ((not sandbox) '())
   ((poo-flow-user-loop-engine-poo-kind?
     sandbox
     +poo-flow-user-loop-engine-sandbox-prototype-kind+)
    (let ((profile (.ref sandbox 'profile))
          (isolation (.ref sandbox 'isolation))
          (profile-refs (.ref sandbox 'profile-refs))
          (case-profile-refs (.ref sandbox 'case-profile-refs))
          (entries (.ref sandbox 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-sandbox 'profile profile)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-sandbox 'isolation isolation)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-sandbox 'profile-refs profile-refs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-sandbox 'case-profile-refs case-profile-refs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-sandbox 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'profile profile)
       (poo-flow-user-loop-engine-optional-row 'isolation isolation)
       profile-refs
       case-profile-refs
       entries)))
   (else
    (error "loop-engine sandbox slot must extend loop-engine-sandbox"
           sandbox))))

;;; Budget rows express declarative limits for runtime enforcement. Scheme only
;;; preserves the configured numbers.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-budget->rows budget)
  (cond
   ((not budget) '())
   ((poo-flow-user-loop-engine-poo-kind?
     budget
     +poo-flow-user-loop-engine-budget-prototype-kind+)
    (let ((max-actionable (.ref budget 'max-actionable))
          (max-attempts (.ref budget 'max-attempts))
          (weekly-runs (.ref budget 'weekly-runs))
          (entries (.ref budget 'entries)))
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'max-actionable max-actionable)
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'max-attempts max-attempts)
      (poo-flow-user-loop-engine-require-maybe-integer-slot
       'loop-engine-budget 'weekly-runs weekly-runs)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-budget 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row
        'max-actionable
        max-actionable)
       (poo-flow-user-loop-engine-optional-row 'max-attempts max-attempts)
       (poo-flow-user-loop-engine-optional-row 'weekly-runs weekly-runs)
       entries)))
   (else
    (error "loop-engine budget slot must extend loop-engine-budget" budget))))

;;; Result role rows preserve role-specific result contracts while keeping a
;;; compact alist representation for downstream validators.
;; : (-> Symbol Value [Pair])
(def (poo-flow-user-loop-engine-result-role-row role value)
  (if value (list (cons role value)) '()))

;;; Result rows are schema references only. Validation of concrete result
;;; payloads remains a runtime or ABI consumer responsibility.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-result->rows result)
  (cond
   ((not result) '())
   ((poo-flow-user-loop-engine-poo-kind?
     result
     +poo-flow-user-loop-engine-result-prototype-kind+)
    (let ((default (.ref result 'default))
          (auditor (.ref result 'auditor))
          (verifier (.ref result 'verifier))
          (reviewer (.ref result 'reviewer))
          (governor (.ref result 'governor))
          (human-audit (.ref result 'human-audit))
          (format (.ref result 'format))
          (required-fields (.ref result 'required-fields))
          (entries (.ref result 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'default default)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'auditor auditor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'verifier verifier)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'reviewer reviewer)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'governor governor)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'human-audit human-audit)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-result 'format format)
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-result 'required-fields required-fields)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-result 'entries entries)
      (append
       (poo-flow-user-loop-engine-result-role-row 'default default)
       (poo-flow-user-loop-engine-result-role-row 'auditor auditor)
       (poo-flow-user-loop-engine-result-role-row 'verifier verifier)
       (poo-flow-user-loop-engine-result-role-row 'reviewer reviewer)
       (poo-flow-user-loop-engine-result-role-row 'governor governor)
       (poo-flow-user-loop-engine-result-role-row 'human-audit human-audit)
       (list (cons 'format format)
             (cons 'required-fields required-fields))
       entries)))
   (else
    (error "loop-engine result slot must extend loop-engine-result" result))))

;;; Observability rows expose receipt and run-log preferences as data so the
;;; runtime can decide how to materialize traces.
;; : (-> Value [Pair])
(def (poo-flow-user-loop-engine-poo-observability->rows observability)
  (cond
   ((not observability) '())
   ((poo-flow-user-loop-engine-poo-kind?
     observability
     +poo-flow-user-loop-engine-observability-prototype-kind+)
    (let ((receipt (.ref observability 'receipt))
          (run-log (.ref observability 'run-log))
          (entries (.ref observability 'entries)))
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-observability 'receipt receipt)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-observability 'run-log run-log)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-observability 'entries entries)
      (append
       (poo-flow-user-loop-engine-optional-row 'receipt receipt)
       (poo-flow-user-loop-engine-optional-row 'run-log run-log)
       entries)))
   (else
    (error
     "loop-engine observability slot must extend loop-engine-observability"
     observability))))

;;; Runtime rows describe handoff contract and owner selection. They do not
;;; invoke the runtime adapter or shell out.
;; : (-> PooFlowLoopEngineRuntimePrototype [PooFlowLoopEngineFlatRow])
(def (poo-flow-user-loop-engine-poo-runtime->rows runtime)
  (cond
   ((not runtime) '())
   ((poo-flow-user-loop-engine-poo-kind?
     runtime
     +poo-flow-user-loop-engine-runtime-prototype-kind+)
    (let ((capabilities (.ref runtime 'capabilities))
          (handoff (.ref runtime 'handoff))
          (owner (.ref runtime 'owner))
          (entries (.ref runtime 'entries)))
      (poo-flow-user-loop-engine-require-symbol-list-slot
       'loop-engine-runtime 'capabilities capabilities)
      (poo-flow-user-loop-engine-require-maybe-symbol-slot
       'loop-engine-runtime 'handoff handoff)
      (poo-flow-user-loop-engine-require-maybe-string-slot
       'loop-engine-runtime 'owner owner)
      (poo-flow-user-loop-engine-require-alist-slot
       'loop-engine-runtime 'entries entries)
      (append capabilities entries)))
   (else
    (error "loop-engine runtime slot must extend loop-engine-runtime"
           runtime))))
