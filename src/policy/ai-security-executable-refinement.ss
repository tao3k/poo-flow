;;; Provider-neutral AI-security executable refinement.
;;;
;;; Boundary: provider adapters normalize logs into the POO-native envelope.
;;; This module owns only pure policy transition and versioned proof receipts.

(import (only-in :clan/poo/object .def .mix .o .ref)
        (only-in :std/srfi/1 every filter-map)
        (only-in :std/crypto/digest sha256)
        (only-in :std/text/hex hex-encode))

(export poo-flow-agent-action-evidence-envelope
        poo-flow-agent-action-evidence-envelope->projection
        poo-flow-ai-security-transition-policy
        poo-flow-ai-security-transition-prototype
        poo-flow-ai-security-transition-engine
        poo-flow-ai-security-reference-transition
        poo-flow-ai-security-transition-replay-valid?)

(def action-evidence-envelope-schema
  'poo-flow.ai-security.action-evidence-envelope.v1)

(def executable-transition-receipt-schema
  'poo-flow.ai-security.executable-transition-receipt.v1)

;; : (-> Object String)
(def (canonical-digest value)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (call-with-output-string
      (lambda (port) (write value port)))))))

;; : (forall (a) (-> (List a) (List a) Boolean))
;; : (-> List List Boolean)
(def (set-subset? requested allowed)
  (every (lambda (value) (if (member value allowed) #t #f)) requested))

;; : (-> Symbol MaybeSymbol Symbol Symbol Symbol Symbol Symbol Symbol String String [Symbol] [Symbol] PooAgentActionEvidenceEnvelope)
(def (poo-flow-agent-action-evidence-envelope
      action-id parent-action-id observation-event-id recovery-decision-id
      actor-identity tool-identity capability-id effect-domain evidence-root
      trace-parent-root requested-effects allowed-effects)
  (.o (kind 'poo-flow-agent-action-evidence-envelope)
      (schema action-evidence-envelope-schema)
      (schema-version "1")
      (action-id action-id)
      (parent-action-id parent-action-id)
      (observation-event-id observation-event-id)
      (recovery-decision-id recovery-decision-id)
      (actor-identity actor-identity)
      (tool-identity tool-identity)
      (capability-id capability-id)
      (effect-domain effect-domain)
      (evidence-root evidence-root)
      (trace-parent-root trace-parent-root)
      (requested-effects requested-effects)
      (allowed-effects allowed-effects)))

;; : (-> PooAgentActionEvidenceEnvelope Alist)
(def (poo-flow-agent-action-evidence-envelope->projection envelope)
  (unless (eq? (.ref envelope 'kind)
               'poo-flow-agent-action-evidence-envelope)
    (error "projection requires AgentActionEvidenceEnvelope" envelope))
  (list
   (cons 'schemaId (.ref envelope 'schema))
   (cons 'schemaVersion (.ref envelope 'schema-version))
   (cons 'actionId (.ref envelope 'action-id))
   (cons 'parentActionId (.ref envelope 'parent-action-id))
   (cons 'observationEventId (.ref envelope 'observation-event-id))
   (cons 'recoveryDecisionId (.ref envelope 'recovery-decision-id))
   (cons 'actorIdentity (.ref envelope 'actor-identity))
   (cons 'toolIdentity (.ref envelope 'tool-identity))
   (cons 'capabilityId (.ref envelope 'capability-id))
   (cons 'effectDomain (.ref envelope 'effect-domain))
   (cons 'evidenceRoot (.ref envelope 'evidence-root))
   (cons 'traceParentRoot (.ref envelope 'trace-parent-root))
   (cons 'requestedEffects (.ref envelope 'requested-effects))
   (cons 'allowedEffects (.ref envelope 'allowed-effects))))

;; : (-> [Symbol] Symbol [Symbol] MaybeSymbol String PooAiSecurityTransitionPolicy)
(def (poo-flow-ai-security-transition-policy
      granted-capabilities expected-tool-identity allowed-effect-domains
      expected-parent-action-id expected-trace-parent-root)
  (.o (kind 'poo-flow-ai-security-transition-policy)
      (schema 'poo-flow.ai-security.transition-policy.v1)
      (schema-version "1")
      (granted-capabilities granted-capabilities)
      (expected-tool-identity expected-tool-identity)
      (allowed-effect-domains allowed-effect-domains)
      (expected-parent-action-id expected-parent-action-id)
      (expected-trace-parent-root expected-trace-parent-root)))

;; : (-> PooAgentActionEvidenceEnvelope List)
(def (envelope-identity envelope)
  (list action-evidence-envelope-schema
        "1"
        (.ref envelope 'action-id)
        (.ref envelope 'parent-action-id)
        (.ref envelope 'observation-event-id)
        (.ref envelope 'recovery-decision-id)
        (.ref envelope 'actor-identity)
        (.ref envelope 'tool-identity)
        (.ref envelope 'capability-id)
        (.ref envelope 'effect-domain)
        (.ref envelope 'evidence-root)
        (.ref envelope 'trace-parent-root)
        (.ref envelope 'requested-effects)
        (.ref envelope 'allowed-effects)))

;; : (-> Symbol Boolean String PooAiSecurityInvariantEvidence)
(def (invariant-receipt name satisfied reason)
  (.o (kind 'poo-flow-ai-security-invariant-evidence)
      (invariant name)
      (satisfied? satisfied)
      (reason reason)))

;; : (-> PooAiSecurityInvariantEvidence List)
(def (invariant-identity invariant)
  (list (.ref invariant 'invariant)
        (.ref invariant 'satisfied?)
        (.ref invariant 'reason)))

;; : (-> [PooAiSecurityInvariantEvidence] [Symbol])
(def (failed-invariants invariants)
  (filter-map
   (lambda (invariant)
     (and (not (.ref invariant 'satisfied?))
          (.ref invariant 'invariant)))
   invariants))

;; : (-> Symbol Boolean String String POOObject)
(def (described-invariant name accepted? accepted-reason rejected-reason)
  (invariant-receipt name
                     accepted?
                     (if accepted? accepted-reason rejected-reason)))

;;; Reference transition: evaluate the full invariant set and return an auditable denial or acceptance receipt.
;; : (-> PooAgentActionEvidenceEnvelope PooAiSecurityTransitionPolicy PooAiSecurityTransitionReceipt)
(def (poo-flow-ai-security-reference-transition envelope policy)
  (unless (eq? (.ref envelope 'kind)
               'poo-flow-agent-action-evidence-envelope)
    (error "reference transition requires AgentActionEvidenceEnvelope" envelope))
  (unless (eq? (.ref policy 'kind)
               'poo-flow-ai-security-transition-policy)
    (error "reference transition requires TransitionPolicy" policy))
  (let* ((capability-ok
          (and (member (.ref envelope 'capability-id)
                       (.ref policy 'granted-capabilities))
               #t))
         (tool-ok
          (equal? (.ref envelope 'tool-identity)
                  (.ref policy 'expected-tool-identity)))
         (effect-ok
          (and (member (.ref envelope 'effect-domain)
                       (.ref policy 'allowed-effect-domains))
               (set-subset? (.ref envelope 'requested-effects)
                            (.ref envelope 'allowed-effects))))
         (causal-ok
          (and (equal? (.ref envelope 'parent-action-id)
                       (.ref policy 'expected-parent-action-id))
               (equal? (.ref envelope 'trace-parent-root)
                       (.ref policy 'expected-trace-parent-root))))
         (invariants
          (list
           (described-invariant
            'capability-confinement capability-ok
            "capability is explicitly granted"
            "capability is outside the granted set")
           (described-invariant
            'tool-identity tool-ok
            "tool identity matches policy"
            "tool identity does not match policy")
           (described-invariant
            'effect-containment effect-ok
            "effect domain and requested effects are contained"
            "effect domain or requested effects escape containment")
           (described-invariant
            'causal-continuity causal-ok
            "parent action and trace root are continuous"
            "parent action or trace root breaks causal continuity")))
         (failures (failed-invariants invariants))
         (decision (if (null? failures) 'accepted 'fail-closed))
         (envelope-digest (canonical-digest (envelope-identity envelope)))
         (output-identity
          (list decision (map invariant-identity invariants) failures))
         (output-digest (canonical-digest output-identity))
         (trace-root
          (canonical-digest
           (list envelope-digest output-digest
                 (.ref envelope 'evidence-root)
                 (.ref envelope 'trace-parent-root)))))
    (.o (kind 'poo-flow-ai-security-executable-transition-receipt)
        (schema executable-transition-receipt-schema)
        (schema-version "1")
        (envelope-digest envelope-digest)
        (decision decision)
        (invariants invariants)
        (escalation-reasons failures)
        (output-digest output-digest)
        (trace-root trace-root))))

;; : (-> PooAiSecurityTransitionReceipt List)
(def (receipt-identity receipt)
  (list (.ref receipt 'schema)
        (.ref receipt 'schema-version)
        (.ref receipt 'envelope-digest)
        (.ref receipt 'decision)
        (map invariant-identity (.ref receipt 'invariants))
        (.ref receipt 'escalation-reasons)
        (.ref receipt 'output-digest)
        (.ref receipt 'trace-root)))

;; : (-> PooAgentActionEvidenceEnvelope PooAiSecurityTransitionPolicy PooAiSecurityTransitionReceipt Boolean)
(def (poo-flow-ai-security-transition-replay-valid? envelope policy receipt)
  (equal? (receipt-identity
           (poo-flow-ai-security-reference-transition envelope policy))
          (receipt-identity receipt)))

;;; The public extension point is an ordinary POO prototype.  Downstream policy
;;; modules compose it with `.mix`; the execution slot remains a pure function.
(.def poo-flow-ai-security-transition-prototype
  (kind 'poo-flow-ai-security-transition-engine)
  (schema 'poo-flow.ai-security.transition-engine.v1)
  (schema-version "1")
  (execute poo-flow-ai-security-reference-transition)
  (replay-valid? poo-flow-ai-security-transition-replay-valid?))

;; : (-> [POOObject] PooAiSecurityTransitionEngine)
(def (poo-flow-ai-security-transition-engine . policy-prototypes)
  (.mix policy-prototypes poo-flow-ai-security-transition-prototype))
