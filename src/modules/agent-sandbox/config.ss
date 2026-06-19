;;; -*- Gerbil -*-
;;; Boundary: user-facing agent sandbox profile declarations.
;;; Invariant: profiles are inert data until a runtime bridge consumes them.

(import (only-in :clan/poo/object .o .ref object?)
        :modules/agent-sandbox/profile)

(export poo-flow-sandbox-profile-kind
        poo-flow-sandbox-profiles-presentation-kind
        poo-flow-sandbox-profile
        poo-flow-sandbox-profiles
        poo-flow-sandbox-profile-config
        poo-flow-sandbox-profile?
        poo-flow-sandbox-profile-name
        poo-flow-sandbox-profile-backend-kind
        poo-flow-sandbox-profile-backend-ref
        poo-flow-sandbox-profile-network-policy
        poo-flow-sandbox-profile-capabilities
        poo-flow-sandbox-profile-resource-policy
        poo-flow-sandbox-profile-metadata
        poo-flow-sandbox-profile->descriptor
        poo-flow-sandbox-profile->profile
        poo-flow-sandbox-profile->alist
        poo-flow-sandbox-profile-runtime-intent
        poo-flow-sandbox-profile-names
        poo-flow-sandbox-profile-alists
        poo-flow-sandbox-profile-by-name
        poo-flow-default-sandbox-profiles
        poo-flow-default-sandbox-profile-names
        poo-flow-default-sandbox-profile-presentation
        pooFlowSandboxProfilesPresentation)

;;; Profile kind ids are receipt vocabulary. They are stable enough for
;;; presentation and tests, but do not select a runtime backend by themselves.
;; : PooFlowSandboxProfileKindId
;; | PooFlowSandboxProfileKindId = String
(def poo-flow-sandbox-profile-kind
  "poo-flow.agent-sandbox.user-profile.v1")

;;; The presentation kind names the shallow, non-executing view used by agents
;;; and CLI tooling before any backend descriptor is realized.
;; : PooFlowSandboxProfilesPresentationKindId
;; | PooFlowSandboxProfilesPresentationKindId = String
(def poo-flow-sandbox-profiles-presentation-kind
  "poo-flow.agent-sandbox.user-profiles.presentation.v1")

;;; Form lookup stays textual and inert: unknown rows are ignored here because
;;; runtime/profile validation happens after projection to the sandbox contract.
;; : (-> Symbol [SandboxProfileForm] SandboxProfileForm SandboxProfileForm)
(def (poo-flow-sandbox-profile-form key forms default-value)
  (cond
   ((null? forms) default-value)
   ((and (pair? (car forms))
         (eq? (caar forms) key))
    (car forms))
   (else
    (poo-flow-sandbox-profile-form key (cdr forms) default-value))))

;;; Tail extraction keeps malformed optional rows harmless: non-pairs project
;;; to an empty payload and leave stricter checks to descriptor validation.
;; : (-> MaybeSandboxProfileForm [SandboxProfileForm])
(def (poo-flow-sandbox-profile-tail form)
  (if (and form (pair? form)) (cdr form) '()))

;;; A one-symbol backend row such as `(backend nono)` means both backend kind
;;; and backend ref are `nono`; explicit refs let cubeSandbox name a profile.
;; : (-> [SandboxProfileForm] Pair)
(def (poo-flow-sandbox-profile-backend-values forms)
  (let* ((backend-form
          (poo-flow-sandbox-profile-form 'backend
                                         forms
                                         '(backend nono nono-sandbox)))
         (values (poo-flow-sandbox-profile-tail backend-form))
         (backend-kind (if (null? values) 'nono (car values)))
         (backend-ref (if (or (null? values) (null? (cdr values)))
                        backend-kind
                        (cadr values))))
    (cons backend-kind backend-ref)))

;;; List-form projection preserves user order and avoids inventing defaults
;;; for rows that should remain owned by upstream sandbox policy.
;; : (-> Symbol [SandboxProfileForm] [Value] [Value])
(def (poo-flow-sandbox-profile-list-form key forms default-value)
  (let (form (poo-flow-sandbox-profile-form key forms #f))
    (if form
      (poo-flow-sandbox-profile-tail form)
      default-value)))

;;; Profile config construction keeps parsing shallow: it only projects rows
;;; into POO slots and leaves descriptor validation to the bridge boundary.
;; : (-> Symbol [SandboxProfileForm] POOObject)
(def (poo-flow-sandbox-profile-config name-value forms)
  (let (backend-values (poo-flow-sandbox-profile-backend-values forms))
    (.o kind: poo-flow-sandbox-profile-kind
        name: name-value
        backend-kind: (car backend-values)
        backend-ref: (cdr backend-values)
        network-policy: (poo-flow-sandbox-profile-list-form
                         'network
                         forms
                         '(deny-by-default))
        capabilities: (poo-flow-sandbox-profile-list-form
                       'capabilities
                       forms
                       '(process filesystem tmpdir))
        resource-policy: (poo-flow-sandbox-profile-list-form
                          'resources
                          forms
                          '())
        metadata: (append
                   '((declared-by . poo-flow-user-interface)
                     (runtime-executed . #f))
                   (poo-flow-sandbox-profile-list-form
                    'metadata
                    forms
                    '())))))

;;; Bass-style profile rows are just data recipes. The macro is deliberately a
;;; thin syntax bridge; semantic state lives in the POO profile object slots.
;; poo-flow-sandbox-profile
;;   : (-> Symbol SandboxProfileForm... PooSandboxProfile)
;;   | contract: expands one profile row into inert POO data only
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile agent/nono
;;         (backend nono)
;;         (network deny-by-default))
;;       ;; => POO profile recipe, not a runtime request
;;       ```
;;     %
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-sandbox-profile-config 'name '(form ...))))

;; poo-flow-sandbox-profiles
;;   : (-> SandboxProfileRow... [PooSandboxProfile])
;;   | contract: preserves declaration order for agent/tool presentation
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profiles
;;         (agent/nono (backend nono))
;;         (agent/cube (backend cubeSandbox cube-local)))
;;       ;; => ordered profile recipes
;;       ```
;;     %
;; : (-> SandboxProfileRow... [PooSandboxProfile])
(defrules poo-flow-sandbox-profiles ()
  ((_)
   '())
  ((_ (name form ...) profile-clause ...)
   (cons (poo-flow-sandbox-profile name form ...)
         (poo-flow-sandbox-profiles profile-clause ...))))

;;; Built-in sandbox profiles are upstream defaults, not user init content. A
;;; downstream project can select or override them later without owning backend
;;; policy recipes in its root configuration file.
;; : PooSandboxProfileList
;; | PooSandboxProfileList = [PooSandboxProfile]
(def poo-flow-default-sandbox-profiles
  (poo-flow-sandbox-profiles
   (agent/nono
    (backend nono)
    (network deny-by-default)
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (filesystem . scoped)
               (cpu . 2)
               (memory . "4Gi")
               (timeout-ms . 300000))
    (metadata (intent . coding-agent) (risk . high-demand)))
   (agent/cube
    (backend cube cube-local)
    (network allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read cache-mount)
    (resources (filesystem . snapshot)
               (cpu . 4)
               (memory . "8Gi")
               (timeout-ms . 600000))
    (metadata (intent . ci-agent) (risk . hermetic)))
   (agent/docker
    (backend docker docker-local)
    (network allowlisted "ghcr.io" "docker.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (filesystem . volume)
               (cpu . 2)
               (memory . "4Gi")
               (timeout-ms . 300000))
    (metadata (intent . container-agent) (risk . image-runtime)))))

;;; Kind guards keep downstream tools independent of constructor identity while
;;; still allowing POO slot extension behind the public recipe surface.
;; : (-> PooSandboxProfileCandidate Boolean)
;; | PooSandboxProfileCandidate = POOObject
(def (poo-flow-sandbox-profile? value)
  (and (object? value)
       (equal? (.ref value 'kind) poo-flow-sandbox-profile-kind)))

;;; Accessors stay as thin `.ref` wrappers so callers do not reach into the POO
;;; object directly or duplicate slot names across tests and runtime bridges.
;; : (-> PooSandboxProfile Symbol)
(def (poo-flow-sandbox-profile-name profile)
  (.ref profile 'name))

;; : (-> PooSandboxProfile Symbol)
(def (poo-flow-sandbox-profile-backend-kind profile)
  (.ref profile 'backend-kind))

;; : (-> PooSandboxProfile Symbol)
(def (poo-flow-sandbox-profile-backend-ref profile)
  (.ref profile 'backend-ref))

;; : (-> PooSandboxProfile [Value])
(def (poo-flow-sandbox-profile-network-policy profile)
  (.ref profile 'network-policy))

;; : (-> PooSandboxProfile [Symbol])
(def (poo-flow-sandbox-profile-capabilities profile)
  (.ref profile 'capabilities))

;; : (-> PooSandboxProfile Alist)
(def (poo-flow-sandbox-profile-resource-policy profile)
  (.ref profile 'resource-policy))

;; : (-> PooSandboxProfile Alist)
(def (poo-flow-sandbox-profile-metadata profile)
  (.ref profile 'metadata))

;;; Descriptor projection is the boundary where inert user recipes start
;;; participating in the existing sandbox profile validation contract.
;; : (-> PooSandboxProfile AgentSandboxProfileDescriptor)
(def (poo-flow-sandbox-profile->descriptor profile)
  (make-agent-sandbox-profile-descriptor
   (poo-flow-sandbox-profile-name profile)
   (poo-flow-sandbox-profile-backend-kind profile)
   (poo-flow-sandbox-profile-backend-ref profile)
   (poo-flow-sandbox-profile-network-policy profile)
   (poo-flow-sandbox-profile-capabilities profile)
   (poo-flow-sandbox-profile-resource-policy profile)
   (poo-flow-sandbox-profile-metadata profile)))

;;; Profile projection is the last Scheme-side step before the shared sandbox
;;; contract takes over validation and runtime adapter handoff.
;; : (-> PooSandboxProfile AgentSandboxProfile)
(def (poo-flow-sandbox-profile->profile profile)
  (agent-sandbox-profile-descriptor->profile
   (poo-flow-sandbox-profile->descriptor profile)))

;;; Alist conversion is presentation-only. Keeping it separate from the POO
;;; recipe avoids flattening the extension point that nono/cubeSandbox can use.
;; : (-> PooSandboxProfile Alist)
(def (poo-flow-sandbox-profile->alist profile)
  (list (cons 'kind poo-flow-sandbox-profile-kind)
        (cons 'name (poo-flow-sandbox-profile-name profile))
        (cons 'backend-kind (poo-flow-sandbox-profile-backend-kind profile))
        (cons 'backend-ref (poo-flow-sandbox-profile-backend-ref profile))
        (cons 'network-policy (poo-flow-sandbox-profile-network-policy profile))
        (cons 'capabilities (poo-flow-sandbox-profile-capabilities profile))
        (cons 'resource-policy (poo-flow-sandbox-profile-resource-policy profile))
        (cons 'metadata (poo-flow-sandbox-profile-metadata profile))))

;;; Runtime intent is a receipt shape for agents and CLI tooling. It names the
;;; backend handoff target without manufacturing a runtime command in Scheme.
;; : (-> PooSandboxProfile Alist)
(def (poo-flow-sandbox-profile-runtime-intent profile)
  (list (cons 'profile-name (poo-flow-sandbox-profile-name profile))
        (cons 'backend-kind (poo-flow-sandbox-profile-backend-kind profile))
        (cons 'backend-ref (poo-flow-sandbox-profile-backend-ref profile))
        (cons 'network-policy (poo-flow-sandbox-profile-network-policy profile))
        (cons 'capabilities (poo-flow-sandbox-profile-capabilities profile))
        (cons 'resource-policy (poo-flow-sandbox-profile-resource-policy profile))
        (cons 'runtime-owner "marlin-agent-core")
        (cons 'descriptor-realized? #f)
        (cons 'runtime-executed #f)))

;;; Name projection is kept separate from alist projection so tools can inspect
;;; selectable profiles without forcing full descriptor conversion.
;; : (-> [PooSandboxProfile] [Symbol])
(def (poo-flow-sandbox-profile-names profile-list)
  (map poo-flow-sandbox-profile-name profile-list))

;;; Alist lists are presentation receipts only; runtime bridges consume
;;; descriptors or profile objects instead.
;; : (-> [PooSandboxProfile] [Alist])
(def (poo-flow-sandbox-profile-alists profile-list)
  (map poo-flow-sandbox-profile->alist profile-list))

;;; Missing profile names are normal during agent negotiation, so lookup returns
;;; `#f` and leaves diagnostics to the caller-facing doctor/presentation path.
;; : (-> [PooSandboxProfile] Symbol MaybePooSandboxProfile)
(def (poo-flow-sandbox-profile-by-name profiles name)
  (cond
   ((null? profiles) #f)
   ((eq? (poo-flow-sandbox-profile-name (car profiles)) name)
    (car profiles))
   (else
    (poo-flow-sandbox-profile-by-name (cdr profiles) name))))

;;; Keep the parameter name distinct from the `profiles:` slot. gerbil-poo lazy
;;; slot resolution can otherwise capture the slot name and recurse on read.
;; : (-> [PooSandboxProfile] POOObject)
(def (pooFlowSandboxProfilesPresentation profile-list)
  (.o kind: poo-flow-sandbox-profiles-presentation-kind
      profile-count: (length profile-list)
      profile-names: (poo-flow-sandbox-profile-names profile-list)
      profiles: (poo-flow-sandbox-profile-alists profile-list)
      runtime-intents: (map poo-flow-sandbox-profile-runtime-intent profile-list)
      runtime-owner: "marlin-agent-core"
      package-management?: #f
      dependency-installation?: #f
      descriptor-realized?: #f
      runtime-executed: #f
      replayable: #t))

;; : [Symbol]
(def poo-flow-default-sandbox-profile-names
  (poo-flow-sandbox-profile-names poo-flow-default-sandbox-profiles))

;;; Default profile presentation is a stable upstream receipt for downstream
;;; user interfaces that should not duplicate nono/cube policy recipes.
;; : (-> Unit POOObject)
(def (poo-flow-default-sandbox-profile-presentation)
  (pooFlowSandboxProfilesPresentation poo-flow-default-sandbox-profiles))
