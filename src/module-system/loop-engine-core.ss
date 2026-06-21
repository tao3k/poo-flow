;;; -*- Gerbil -*-
;;; Boundary: loop-engine declaration helpers and shared runtime vocabulary.
;;; Invariant: this owner normalizes user rows but never builds command manifests.

(import (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-runtime-summary)
        :poo-flow/src/module-system/base)

(export poo-flow-user-loop-engine-section
        +poo-flow-user-loop-engine-runtime-command-arguments+
        +poo-flow-user-loop-engine-runtime-command-contract+
        +poo-flow-user-loop-engine-runtime-command-executable+
        +poo-flow-user-loop-engine-runtime-command-name+
        +poo-flow-user-loop-engine-runtime-object-families+
        +poo-flow-user-loop-engine-result-contract+
        +poo-flow-user-loop-engine-default-result-contract+
        +poo-flow-user-loop-engine-result-contract-roles+
        +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+
        +poo-flow-user-loop-engine-handoff-contracts+
        poo-flow-user-loop-engine-intent-ref
        poo-flow-user-loop-engine-section-ref
        poo-flow-user-loop-engine-use-case-name
        poo-flow-user-loop-engine-intent-use-case-name
        poo-flow-user-loop-engine-use-case-names/add
        poo-flow-user-loop-engine-use-case-names
        poo-flow-user-loop-engine-use-case-name?
        poo-flow-user-loop-engine-sandbox-entry-profile-ref
        poo-flow-user-loop-engine-profile-ref-member?
        poo-flow-user-loop-engine-profile-ref-add
        poo-flow-user-loop-engine-sandbox-profile-refs/add
        poo-flow-user-loop-engine-sandbox-profile-refs
        poo-flow-user-loop-engine-sandbox-profile-ref->profile
        poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
        poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
        poo-flow-user-loop-engine-sandbox-runtime-summaries
        poo-flow-user-loop-engine-sandbox-handoff-summaries
        poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
        poo-flow-user-loop-engine-sandbox-handoff-agreement
        poo-flow-user-loop-engine-runtime-id
        poo-flow-user-loop-engine-intent-workflow-ref)

(def (poo-flow-user-loop-engine-section selection section)
  (let (entry (poo-flow-user-module-selection-flag-entry selection section))
    (cond
     ((and entry (pair? entry)) (cdr entry))
     (entry (list entry))
     (else '()))))

;;; Runtime handoff contracts are names, not function pointers. Scheme exposes
;;; the command shape that Rust or another runtime can implement later.
;; : [Symbol]
(def +poo-flow-user-loop-engine-handoff-contracts+
  '(start-workflow-run
    admit-dispatch
    open-agent-session
    execute-agent-operation
    stream-events
    read-runtime-snapshot))

;;; The runtime command contract is a schema identifier shared with Marlin. It
;;; must stay data-only so Scheme never claims runtime implementation ownership.
;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-contract+
  'poo-flow.loop-governor.runtime-command-manifest.v1)

;;; Result contracts are schema identifiers for reviewer output. They stay
;;; separate from the runtime-command manifest so agents can audit structured
;;; result expectations before Marlin executes an operation.
;; : Symbol
(def +poo-flow-user-loop-engine-result-contract+
  'poo-flow.loop-governor.result-contract.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-default-result-contract+
  'poo-flow.loop-governor.node-result.v1)

;; : [Symbol]
(def +poo-flow-user-loop-engine-result-contract-roles+
  '(default auditor verifier reviewer governor human-audit))

;;; Sandbox handoff agreement is the loop-engine receipt that compares declared
;;; refs, runtime summaries, and bridge-ready handoff summaries without raising.
;; : Symbol
(def +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+
  'poo-flow.loop-engine.sandbox-handoff-agreement.v1)

;;; The command name is stable receipt vocabulary for handoff manifests, not an
;;; executable selector or shell command.
;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-name+
  'loop-engine-runtime-handoff)

;; : String
(def +poo-flow-user-loop-engine-runtime-command-executable+
  "marlin-agent-core")

;; : [String]
(def +poo-flow-user-loop-engine-runtime-command-arguments+
  '("poo-flow" "runtime" "loop-engine-handoff"))

;;; Object family names document which control-plane projections the runtime
;;; must understand when it consumes a loop-engine handoff.
;; : [Symbol]
(def +poo-flow-user-loop-engine-runtime-object-families+
  '(agent-profile
    agent-harness
    agent-session
    workflow-run
    dispatch-receipt
    agent-operation
    runtime-snapshot))

;;; Intent lookup is total because partial loop declarations still need a
;;; presentable handoff report and unresolved sandbox diagnostics.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-loop-engine-intent-ref intent key default-value)
  (let (entry (assoc key intent))
    (if entry (cdr entry) default-value)))

;;; Section lookup supports the Doom-style nested config rows where section
;;; names are carried as association keys inside init declarations.
;; : (-> [Value] Symbol Value Value)
(def (poo-flow-user-loop-engine-section-ref entries key default-value)
  (cond
   ((null? entries) default-value)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-loop-engine-section-ref (cdr entries) key default-value))))

;;; Use-case names become runtime ids, so this normalizer accepts an explicit
;;; single use-case row, then falls back to the first declared use-case list row.
;; : (-> Value [Value] Symbol)
(def (poo-flow-user-loop-engine-use-case-name use-case use-cases)
  (cond
   ((and (pair? use-case) (symbol? (car use-case))) (car use-case))
   ((and (pair? use-cases)
         (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (caar use-cases))
   (else 'loop-engine)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-use-case-name intent)
  (poo-flow-user-loop-engine-use-case-name
   (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
   (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))

;;; Use-case accumulation preserves declaration order while ignoring malformed
;;; rows that cannot produce stable runtime identifiers.
;; : (-> [Value] [Symbol])
(def (poo-flow-user-loop-engine-use-case-names/add use-cases)
  (cond
   ((null? use-cases) '())
   ((and (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (cons (caar use-cases)
          (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases))))
   (else
    (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases)))))

;;; The use-case set is intentionally empty when no explicit rows exist. The
;;; runtime workflow ref still falls back through the single-use-case path.
;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-use-case-names intent)
  (let ((use-case
         (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
        (use-cases
         (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
    (append
     (if (and (pair? use-case) (symbol? (car use-case)))
       (list (car use-case))
       '())
     (poo-flow-user-loop-engine-use-case-names/add use-cases))))

;;; Use-case membership is Boolean-normalized for sandbox rows that use
;;; `(case . profile)` shorthand.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-use-case-name? value use-case-names)
  (and (member value use-case-names) #t))

;;; Sandbox entries accept profile rows and per-use-case shorthand. Returning
;;; `#f` keeps malformed rows visible to unresolved-ref diagnostics.
;; : (-> Value [Symbol] MaybeSymbol)
(def (poo-flow-user-loop-engine-sandbox-entry-profile-ref entry use-case-names)
  (cond
   ((symbol? entry) entry)
   ((and (pair? entry)
         (eq? (car entry) 'profile)
         (symbol? (cdr entry)))
    (cdr entry))
   ((and (pair? entry)
         (symbol? (car entry))
         (poo-flow-user-loop-engine-use-case-name? (car entry)
                                                   use-case-names)
         (symbol? (cdr entry)))
    (cdr entry))
   (else #f)))

;;; Profile ref membership is Boolean-normalized for deterministic duplicate
;;; filtering in profile-ref accumulation.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-profile-ref-member? value refs)
  (and (member value refs) #t))

;;; Profile refs preserve first declaration order. Later duplicates do not
;;; change the runtime handoff order.
;; : (-> MaybeSymbol [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-profile-ref-add value refs)
  (if (and value
           (not (poo-flow-user-loop-engine-profile-ref-member? value refs)))
    (append refs (list value))
    refs))

;;; Sandbox profile refs are collected from user rows without resolving the
;;; profile catalog so missing refs can be reported separately.
;; : (-> [Value] [Symbol] [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs/add entries
                                                         use-case-names
                                                         refs)
  (cond
   ((null? entries) refs)
   (else
    (poo-flow-user-loop-engine-sandbox-profile-refs/add
     (cdr entries)
     use-case-names
     (poo-flow-user-loop-engine-profile-ref-add
      (poo-flow-user-loop-engine-sandbox-entry-profile-ref
       (car entries)
       use-case-names)
      refs)))))

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs intent)
  (poo-flow-user-loop-engine-sandbox-profile-refs/add
   (poo-flow-user-loop-engine-intent-ref intent 'sandbox '())
   (poo-flow-user-loop-engine-use-case-names intent)
   '()))

;;; Sandbox profile lookup is intentionally catalog-only here; loop-engine
;;; projection must not construct or repair profiles during presentation.
;; : (-> Symbol [PooSandboxProfile] MaybePooSandboxProfile)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->profile profile-ref
                                                             profile-catalog)
  (poo-flow-sandbox-profile-by-name profile-catalog profile-ref))

;;; Runtime summaries are optional evidence rows. Missing profiles are surfaced
;;; by the unresolved-ref scan instead of throwing inside this lookup.
;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
      profile-ref
      profile-catalog)
  (let (profile
        (poo-flow-user-loop-engine-sandbox-profile-ref->profile
         profile-ref
         profile-catalog))
    (and profile (poo-flow-sandbox-profile-runtime-summary profile))))

;;; Handoff summaries follow the same optional lookup path as runtime summaries
;;; so presentation can report partial profile catalogs deterministically.
;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
      profile-ref
      profile-catalog)
  (let* ((profile
          (poo-flow-user-loop-engine-sandbox-profile-ref->profile
           profile-ref
           profile-catalog))
         (runtime-summary
          (and profile (poo-flow-sandbox-profile-runtime-summary profile))))
    (and profile
         (poo-flow-user-loop-engine-intent-ref
          runtime-summary
          'valid?
          #f)
         (poo-flow-sandbox-profile-handoff-summary profile))))

;;; Runtime summary collection preserves reference order and skips missing
;;; profiles; unresolved refs are recorded by a sibling diagnostic pass.
;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-runtime-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-runtime-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-runtime-summaries
     (cdr refs)
     profile-catalog))))

;;; Handoff summary collection mirrors runtime summary collection so the two
;;; projections stay comparable in tests and presentation traces.
;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-handoff-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-handoff-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-handoff-summaries
     (cdr refs)
     profile-catalog))))

;;; Unresolved refs are the safety channel for profile catalog holes. This keeps
;;; runtime handoff pure while still rejecting fake completeness in tests.
;; : (-> [Symbol] [PooSandboxProfile] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs refs
                                                                profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->profile
     (car refs)
     profile-catalog)
    (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
     (cdr refs)
     profile-catalog))
   (else
    (cons (car refs)
          (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
           (cdr refs)
           profile-catalog)))))

;;; Invalid runtime summaries stay reportable facts. They are not filtered out
;;; of the intent because doctor and handoff agreement need the validation rows.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries summaries)
  (cond
   ((null? summaries) '())
   ((poo-flow-user-loop-engine-intent-ref (car summaries) 'valid? #f)
    (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
     (cdr summaries)))
   (else
    (cons
     (car summaries)
     (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
      (cdr summaries))))))

;;; Agreement diagnostics are aggregate rows so profile doctor can present one
;;; actionable sandbox issue per loop intent instead of one row per mount.
;; : (-> [Symbol] [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-loop-engine-sandbox-handoff-agreement-diagnostics
      refs
      runtime-summaries
      handoff-summaries
      unresolved-refs)
  (let ((invalid-runtime-summaries
         (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
          runtime-summaries)))
    (append
     (if (null? unresolved-refs)
       '()
       (list
        (list (cons 'field 'sandbox-profile-refs)
              (cons 'code 'unresolved-sandbox-profile-refs)
              (cons 'profile-refs unresolved-refs))))
     (if (null? invalid-runtime-summaries)
       '()
       (list
        (list (cons 'field 'sandbox-runtime-summaries)
              (cons 'code 'invalid-sandbox-runtime-summaries)
              (cons 'summary-count (length invalid-runtime-summaries))
              (cons 'summaries invalid-runtime-summaries))))
     (if (= (length refs)
            (+ (length handoff-summaries)
               (length unresolved-refs)
               (length invalid-runtime-summaries)))
       '()
       (list
        (list (cons 'field 'sandbox-handoff-summaries)
              (cons 'code 'sandbox-handoff-summary-count-mismatch)
              (cons 'profile-ref-count (length refs))
              (cons 'handoff-summary-count (length handoff-summaries))
              (cons 'unresolved-profile-ref-count
                    (length unresolved-refs))
              (cons 'invalid-runtime-summary-count
                    (length invalid-runtime-summaries))))))))

;;; The agreement is the stable loop-engine view over sandbox readiness. It is
;;; report-only and total; invalid profiles become diagnostics instead of throws.
;; : (-> [Symbol] [Alist] [Alist] [Symbol] Alist)
(def (poo-flow-user-loop-engine-sandbox-handoff-agreement
      refs
      runtime-summaries
      handoff-summaries
      unresolved-refs)
  (let* ((invalid-runtime-summaries
          (poo-flow-user-loop-engine-invalid-sandbox-runtime-summaries
           runtime-summaries))
         (diagnostics
          (poo-flow-user-loop-engine-sandbox-handoff-agreement-diagnostics
           refs
           runtime-summaries
           handoff-summaries
           unresolved-refs)))
    (list
     (cons 'kind 'loop-engine-sandbox-handoff-agreement)
     (cons 'contract
           +poo-flow-user-loop-engine-sandbox-handoff-agreement-contract+)
     (cons 'profile-refs refs)
     (cons 'profile-ref-count (length refs))
     (cons 'runtime-summary-count (length runtime-summaries))
     (cons 'handoff-summary-count (length handoff-summaries))
     (cons 'unresolved-profile-refs unresolved-refs)
     (cons 'unresolved-profile-ref-count (length unresolved-refs))
     (cons 'invalid-runtime-summaries invalid-runtime-summaries)
     (cons 'invalid-runtime-summary-count
           (length invalid-runtime-summaries))
     (cons 'diagnostic-count (length diagnostics))
     (cons 'diagnostics diagnostics)
     (cons 'valid? (null? diagnostics))
     (cons 'handoff-ready? (null? diagnostics))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;; : (-> Symbol String Symbol)
(def (poo-flow-user-loop-engine-runtime-id use-case-name suffix)
  (string->symbol
   (string-append "loop-engine/"
                  (symbol->string use-case-name)
                  "/"
                  suffix)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-workflow-ref intent)
  (let ((workflow-ref
         (poo-flow-user-loop-engine-section-ref
          (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
          'workflow
          #f)))
    (if workflow-ref workflow-ref 'loop-engine)))
