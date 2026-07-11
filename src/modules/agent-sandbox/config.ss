;;; -*- Gerbil -*-
;;; Boundary: user-facing agent sandbox profile declarations.
;;; Invariant: profiles are inert data until a runtime bridge consumes them.

(import (only-in :clan/poo/object .o .ref object? object<-alist)
        :poo-flow/src/modules/agent-sandbox/profile
        :poo-flow/src/modules/agent-sandbox/projection-syntax
        :poo-flow/src/modules/sandbox-core/profile-support/policy
        :poo-flow/src/module-system/projection-syntax)

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
        poo-flow-sandbox-profile-backend-capability/registry
        poo-flow-sandbox-profile-backend-capability
        poo-flow-sandbox-profile-policy-validation-receipt/registry
        poo-flow-sandbox-profile-policy-validation-receipt
        poo-flow-sandbox-profile-policy-projection-receipt/registry
        poo-flow-sandbox-profile-policy-projection-receipt
        poo-flow-sandbox-profile-policy-projections-valid?
        poo-flow-sandbox-profile-policy-presentation-diagnostics
        poo-flow-sandbox-profile-runtime-intent/registry
        poo-flow-sandbox-profile-runtime-intent
        poo-flow-sandbox-profile-runtime-summary
        poo-flow-sandbox-profile-handoff-summary
        poo-flow-sandbox-profile-names
        poo-flow-sandbox-profile-alists
        poo-flow-sandbox-profile-by-name
        poo-flow-default-sandbox-profiles
        poo-flow-default-sandbox-profile-names
        poo-flow-default-sandbox-profile-presentation
        pooFlowSandboxProfilesPresentation/registry
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
;; : (-> [SandboxProfileForm] (Values Symbol Symbol))
(def (poo-flow-sandbox-profile-backend-values forms)
  (let* ((backend-form
          (poo-flow-sandbox-profile-form 'backend
                                         forms
                                         '(backend nono nono-sandbox)))
         (backend-payload (poo-flow-sandbox-profile-tail backend-form))
         (backend-kind (if (null? backend-payload)
                         'nono
                         (car backend-payload)))
         (backend-ref (if (or (null? backend-payload)
                              (null? (cdr backend-payload)))
                        backend-kind
                        (cadr backend-payload))))
    (values backend-kind backend-ref)))

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
  (call-with-values
    (lambda () (poo-flow-sandbox-profile-backend-values forms))
    (lambda (backend-kind-value backend-ref-value)
      (.o kind: poo-flow-sandbox-profile-kind
          name: name-value
          backend-kind: backend-kind-value
          backend-ref: backend-ref-value
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
          metadata: (agent-sandbox-field-rows/tail
                     (poo-flow-sandbox-profile-list-form
                      'metadata
                      forms
                      '())
                     (declared-by 'poo-flow-user-interface)
                     (runtime-executed #f))))))

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
    (resources (filesystem
                (scope . project-workspace)
                (paths
                 ((role . project-workspace)
                  (source . ".")
                  (project-marker . "gerbil.pkg")
                  (target . "/workspace/project")
                  (mode . read-write)))
                (access . read-write))
               (cpu . 2)
               (memory . "4Gi")
               (timeout-ms . 300000))
    (metadata (intent . coding-agent) (risk . high-demand)))
   (agent/cube
    (backend cube cube-local)
    (network allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read cache-mount)
    (resources (filesystem
                (scope . snapshot)
                (snapshot . clone)
                (access . read-only))
               (cpu . 4)
               (memory . "8Gi")
               (timeout-ms . 600000))
    (metadata (intent . ci-agent) (risk . hermetic)))
   (agent/docker
    (backend docker docker-local)
    (network allowlisted "ghcr.io" "docker.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (filesystem
                (scope . volume)
                (materialized-by . runtime)
                (mounts . runtime)
                (access . read-write))
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

;;; Runtime summaries must be report-only: they project enough profile shape for
;;; validation diagnostics without raising the strict handoff failure path.
;; : (-> PooSandboxProfile AgentSandboxProfile)
(def (poo-flow-sandbox-profile->unchecked-profile profile)
  (make-agent-sandbox-backend-profile
   (poo-flow-sandbox-profile-backend-kind profile)
   (poo-flow-sandbox-profile-backend-ref profile)
   (poo-flow-sandbox-profile-network-policy profile)
   (poo-flow-sandbox-profile-capabilities profile)
   (poo-flow-sandbox-profile-resource-policy profile)
   (poo-flow-sandbox-profile-metadata profile)))

;;; Alist conversion is presentation-only. Keeping it separate from the POO
;;; recipe avoids flattening the extension point that nono/cubeSandbox can use.
;; : (-> PooSandboxProfile Alist)
(defpoo-module-final-projection
  poo-flow-sandbox-profile->alist (profile)
  (bindings ())
  (fields ((kind poo-flow-sandbox-profile-kind)
           (name (poo-flow-sandbox-profile-name profile))
           (backend-kind (poo-flow-sandbox-profile-backend-kind profile))
           (backend-ref (poo-flow-sandbox-profile-backend-ref profile))
           (network-policy (poo-flow-sandbox-profile-network-policy profile))
           (capabilities (poo-flow-sandbox-profile-capabilities profile))
           (resource-policy (poo-flow-sandbox-profile-resource-policy profile))
           (metadata (poo-flow-sandbox-profile-metadata profile)))))

;;; Backend capability receipts are static control-plane facts. They make
;;; OpenRath-style capability boundaries visible without selecting a runtime.
;; : (-> PooSandboxProfile PooSandboxBackendCapabilityRegistry PooSandboxBackendCapability)
(def (poo-flow-sandbox-profile-backend-capability/registry profile registry)
  (poo-flow-sandbox-backend-capability-registry-ref
   registry
   (poo-flow-sandbox-profile-backend-kind profile)))

;; : (-> PooSandboxProfile PooSandboxBackendCapability)
(def (poo-flow-sandbox-profile-backend-capability profile)
  (poo-flow-sandbox-profile-backend-capability/registry
   profile
   poo-flow-sandbox-backend-capability-registry/default))

;;; Policy validation is report-only for public user profiles. Backend profile
;;; objects can hard-gate resolution, while presentation keeps diagnostics
;;; visible for users and agents.
;; : (-> PooSandboxProfile PooSandboxProfilePolicyValidation)
(def (poo-flow-sandbox-profile-policy-validation-receipt/registry profile
                                                                   registry)
  (poo-flow-sandbox-profile-policy-validation
   (poo-flow-sandbox-profile-name profile)
   (poo-flow-sandbox-profile-backend-kind profile)
   (poo-flow-sandbox-profile-backend-ref profile)
   (poo-flow-sandbox-profile-backend-capability/registry profile registry)
   poo-flow-sandbox-profile-policy/default
   (poo-flow-sandbox-profile-capabilities profile)
   (poo-flow-sandbox-profile-resource-policy profile)))

;; : (-> PooSandboxProfile PooSandboxProfilePolicyValidation)
(def (poo-flow-sandbox-profile-policy-validation-receipt profile)
  (poo-flow-sandbox-profile-policy-validation-receipt/registry
   profile
   poo-flow-sandbox-backend-capability-registry/default))

;; : (-> PooSandboxProfile PooSandboxProfilePolicyProjection)
(def (poo-flow-sandbox-profile-policy-projection-receipt/registry profile
                                                                   registry)
  (poo-flow-sandbox-profile-policy-projection
   (poo-flow-sandbox-profile-name profile)
   (poo-flow-sandbox-profile-backend-kind profile)
   (poo-flow-sandbox-profile-backend-ref profile)
   (poo-flow-sandbox-profile-backend-capability/registry profile registry)
   poo-flow-sandbox-profile-policy/default
   (poo-flow-sandbox-profile-capabilities profile)
   (poo-flow-sandbox-profile-resource-policy profile)))

;; : (-> PooSandboxProfile PooSandboxProfilePolicyProjection)
(def (poo-flow-sandbox-profile-policy-projection-receipt profile)
  (poo-flow-sandbox-profile-policy-projection-receipt/registry
   profile
   poo-flow-sandbox-backend-capability-registry/default))

;; : (-> [PooSandboxProfilePolicyProjection] Boolean)
(def (poo-flow-sandbox-profile-policy-projections-valid? projections)
  (cond
   ((null? projections) #t)
   ((poo-flow-sandbox-profile-policy-projection-valid? (car projections))
    (poo-flow-sandbox-profile-policy-projections-valid? (cdr projections)))
   (else #f)))

;; : (-> [PooSandboxProfilePolicyProjection] [PooSandboxProfilePolicyDiagnostic])

;; : (forall (p d) (-> [p] [d] [d]))
;; poo-flow-sandbox-profile-policy-presentation-diagnostics-rev
;; : (-> (List SandboxPolicyProjection)
;;        (List SandboxDiagnosticRow)
;;        (List SandboxDiagnosticRow))
;; | doc m%
;; Accumulates presentation diagnostics in reverse order while preserving the
;; policy projection order at the public boundary.
;; # Examples
;; ```scheme
;; (poo-flow-sandbox-profile-policy-presentation-diagnostics-rev '() '())
;; => '()
;; ```
;; Optimization boundary: the recursive branch accumulates reversed rows so the
;; public projection pays one final reverse instead of appending per projection.
(def (poo-flow-sandbox-profile-policy-presentation-diagnostics-rev
      projections
      diagnostics-rev)
  (if (null? projections)
    diagnostics-rev
    (poo-flow-sandbox-profile-policy-presentation-diagnostics-rev
     (cdr projections)
     (agent-sandbox-rows-into/rev
      (poo-flow-sandbox-profile-policy-projection-diagnostics
       (car projections))
      diagnostics-rev))))

;; : (forall (p d) (-> [p] [d]))
;; poo-flow-sandbox-profile-policy-presentation-diagnostics
;; : (-> (List SandboxPolicyProjection) (List SandboxDiagnosticRow))
;; | doc m%
;; Produces stable presentation diagnostics from sandbox policy projections.
;; # Examples
;; ```scheme
;; (poo-flow-sandbox-profile-policy-presentation-diagnostics '())
;; => '()
;; ```
(def (poo-flow-sandbox-profile-policy-presentation-diagnostics projections)
  (reverse
   (poo-flow-sandbox-profile-policy-presentation-diagnostics-rev
    projections
    '())))

;;; Runtime intent is a receipt shape for agents and CLI tooling. It names the
;;; backend handoff target without manufacturing a runtime command in Scheme.
;; : (-> PooSandboxProfile PooSandboxBackendCapabilityRegistry Alist)
(def (poo-flow-sandbox-profile-runtime-intent/registry profile registry)
  (let ((policy-projection
         (poo-flow-sandbox-profile-policy-projection-receipt/registry
          profile
          registry)))
    (agent-sandbox-field-rows
     (profile-name (poo-flow-sandbox-profile-name profile))
     (backend-kind (poo-flow-sandbox-profile-backend-kind profile))
     (backend-ref (poo-flow-sandbox-profile-backend-ref profile))
     (network-policy
      (poo-flow-sandbox-profile-network-policy profile))
     (capabilities (poo-flow-sandbox-profile-capabilities profile))
     (resource-policy
      (poo-flow-sandbox-profile-resource-policy profile))
     (policy-projection policy-projection)
     (policy-valid?
      (poo-flow-sandbox-profile-policy-projection-valid?
       policy-projection))
     (durable-policy-ref
      (.ref policy-projection 'durable-policy-ref))
     (durable-policy-summary
      (.ref policy-projection 'durable-policy-summary))
     (durable-valid?
      (.ref policy-projection 'durable-valid?))
     (sandbox-handle-class
      (.ref policy-projection 'sandbox-handle-class))
     (runtime-owner "marlin-agent-core")
     (descriptor-realized? #f)
     (runtime-executed #f))))

;; : (-> PooSandboxProfile Alist)
(def (poo-flow-sandbox-profile-runtime-intent profile)
  (poo-flow-sandbox-profile-runtime-intent/registry
   profile
   poo-flow-sandbox-backend-capability-registry/default))

;;; Runtime summaries deliberately cross the validation boundary: callers get
;;; the sandbox-owned summary of the realized agent profile, while the public
;;; POO profile name remains visible for user-interface projections.
;; : (-> PooSandboxProfile Alist)
;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)]))
;; poo-flow-sandbox-profile-runtime-summary
;; : (-> SandboxProfile (List FieldRow))
;; | doc m%
;; Preserves the generic field-row extension law through
;; agent-sandbox-field-rows/tail, then projects a sandbox profile through the
;; unchecked runtime boundary for a runtime consumer.
;; # Examples
;; ```scheme
;; (poo-flow-sandbox-profile-runtime-summary
;;  (car poo-flow-default-sandbox-profiles))
;; => '((profile-name . agent/nono) (descriptor-realized? . #t) ...)
;; ```
(def (poo-flow-sandbox-profile-runtime-summary profile)
  (agent-sandbox-field-rows/tail
   (agent-sandbox-profile-runtime-summary
    (poo-flow-sandbox-profile->unchecked-profile profile))
   (profile-name (poo-flow-sandbox-profile-name profile))
   (descriptor-realized? #t)))

;;; Handoff summaries are the stricter bridge-facing form. Invalid profile rows
;;; fail at the sandbox profile owner before workflow code sees them.
;; : (-> PooSandboxProfile Alist)
;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)]))
;; poo-flow-sandbox-profile-handoff-summary
;; : (-> SandboxProfile (List FieldRow))
;; | doc m%
;; Preserves the generic field-row extension law through
;; agent-sandbox-field-rows/tail, then projects a sandbox profile through the
;; checked handoff boundary for a downstream runtime consumer.
;; # Examples
;; ```scheme
;; (poo-flow-sandbox-profile-handoff-summary
;;  (car poo-flow-default-sandbox-profiles))
;; => '((profile-name . agent/nono) (descriptor-realized? . #t) ...)
;; ```
(def (poo-flow-sandbox-profile-handoff-summary profile)
  (agent-sandbox-field-rows/tail
   (agent-sandbox-profile-handoff-summary
    (poo-flow-sandbox-profile->profile profile))
   (profile-name (poo-flow-sandbox-profile-name profile))
   (descriptor-realized? #t)))

;;; Name projection is kept separate from alist projection so tools can inspect
;;; selectable profiles without forcing full descriptor conversion.
;; : (-> [PooSandboxProfile] [Symbol])
(def (poo-flow-sandbox-profile-names profile-list)
  (map poo-flow-sandbox-profile-name profile-list))

;;; Alist lists are presentation receipts only; runtime bridges consume
;;; descriptors or profile objects instead.
;; : (-> [PooSandboxProfile] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-sandbox-profile-alists (profile-list)
  (projector poo-flow-sandbox-profile->alist)
  (error-message "sandbox profile alist presentation requires a list"))

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
;; : (-> [PooSandboxProfile] PooSandboxBackendCapabilityRegistry [Alist] [Alist] [Alist] [Alist] List)
(def (poo-flow-sandbox-profile-presentation-bundle/rev profile-list
                                                        registry
                                                        policies-rev
                                                        intents-rev
                                                        summaries-rev
                                                        handoffs-rev)
  (if (null? profile-list)
    (list (reverse policies-rev)
          (reverse intents-rev)
          (reverse summaries-rev)
          (reverse handoffs-rev))
    (let (profile (car profile-list))
      (poo-flow-sandbox-profile-presentation-bundle/rev
       (cdr profile-list)
       registry
       (cons (poo-flow-sandbox-profile-policy-projection-receipt/registry
              profile
              registry)
             policies-rev)
       (cons (poo-flow-sandbox-profile-runtime-intent/registry
              profile
              registry)
             intents-rev)
       (cons (poo-flow-sandbox-profile-runtime-summary profile)
             summaries-rev)
       (cons (poo-flow-sandbox-profile-handoff-summary profile)
             handoffs-rev)))))

;; : (-> [PooSandboxProfile] PooSandboxBackendCapabilityRegistry List)
(def (poo-flow-sandbox-profile-presentation-bundle profile-list registry)
  (poo-flow-sandbox-profile-presentation-bundle/rev
   profile-list
   registry
   '()
   '()
   '()
   '()))

;; : (-> [PooSandboxProfile] PooSandboxBackendCapabilityRegistry POOObject)
(def (pooFlowSandboxProfilesPresentation/registry profile-list registry)
  (let* ((presentation-bundle
          (poo-flow-sandbox-profile-presentation-bundle profile-list registry))
         (policy-projections (car presentation-bundle))
         (runtime-intents (cadr presentation-bundle))
         (runtime-summaries (caddr presentation-bundle))
         (handoff-summaries (cadddr presentation-bundle)))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-profiles-presentation-kind)
      (cons 'profile-count (length profile-list))
      (cons 'profile-names (poo-flow-sandbox-profile-names profile-list))
      (cons 'profiles (poo-flow-sandbox-profile-alists profile-list))
      (cons 'runtime-intents runtime-intents)
      (cons 'runtime-summaries runtime-summaries)
      (cons 'handoff-summaries handoff-summaries)
      (cons 'policy-projections policy-projections)
      (cons 'policy-valid?
            (poo-flow-sandbox-profile-policy-projections-valid?
             policy-projections))
      (cons 'policy-diagnostics
            (poo-flow-sandbox-profile-policy-presentation-diagnostics
             policy-projections))
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'package-management? #f)
      (cons 'dependency-installation? #f)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'replayable #t)))))

;; : (-> [PooSandboxProfile] POOObject)
(def (pooFlowSandboxProfilesPresentation profile-list)
  (pooFlowSandboxProfilesPresentation/registry
   profile-list
   poo-flow-sandbox-backend-capability-registry/default))

;; : [Symbol]
(def poo-flow-default-sandbox-profile-names
  (poo-flow-sandbox-profile-names poo-flow-default-sandbox-profiles))

;;; Default profile presentation is a stable upstream receipt for downstream
;;; user interfaces that should not duplicate nono/cube policy recipes.
;; : (-> Unit POOObject)
(def (poo-flow-default-sandbox-profile-presentation)
  (pooFlowSandboxProfilesPresentation poo-flow-default-sandbox-profiles))
