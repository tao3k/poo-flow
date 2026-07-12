;;; Boundary: Cedar evaluates policy; Scheme POO owns semantic/token meaning.
(import :clan/poo/object
        :std/crypto/digest
        :std/text/hex
        :poo-flow/src/policy/authorized-effect-token)

(export poo-flow-cedar-decision
        poo-flow-cedar-decision-permit?
        poo-flow-cedar-decision->semantic-root
        poo-flow-cedar-decision->authorized-effect-token)

(def (decision-digest value)
  (hex-encode
   (sha256 (call-with-output-string (lambda (port) (write value port))))))

(def (poo-flow-cedar-decision identity decision-outcome policy-identity
                              policy-hash entity-hash reason-list)
  (unless (memq decision-outcome '(permit forbid indeterminate))
    (error "unknown Cedar decision outcome" decision-outcome))
  (let* ((canonical
          (list 'poo-flow.cedar-decision.draft.1 identity decision-outcome
                policy-identity policy-hash entity-hash reason-list))
         (decision-hash (decision-digest canonical)))
    (.o (kind 'poo-flow-cedar-decision)
        (schema 'poo-flow.cedar-decision.draft.1)
        (decision-id identity)
        (outcome decision-outcome)
        (policy-id policy-identity)
        (policy-digest policy-hash)
        (entity-digest entity-hash)
        (reasons reason-list)
        (decision-digest decision-hash))))

(def (poo-flow-cedar-decision-permit? decision)
  (eq? (.ref decision 'outcome) 'permit))

(def (poo-flow-cedar-decision->semantic-root decision bundle-digest
                                              intent-digest)
  (poo-flow-semantic-root
   bundle-digest
   (.ref decision 'policy-digest)
   (.ref decision 'entity-digest)
   (.ref decision 'decision-digest)
   intent-digest))

(def (poo-flow-cedar-decision->authorized-effect-token
      decision token-id nonce semantic-root binding validity durability
      evidence-bits issuer signature)
  (unless (poo-flow-cedar-decision-permit? decision)
    (error "Cedar forbid/indeterminate cannot issue AuthorizedEffectToken"))
  (unless (and (equal? (.ref decision 'policy-digest)
                       (.ref binding 'policy-digest))
               (equal? (.ref decision 'entity-digest)
                       (.ref binding 'entity-digest))
               (equal? (.ref decision 'decision-digest)
                       (.ref binding 'decision-digest))
               (equal? (.ref semantic-root 'digest)
                       (.ref (poo-flow-cedar-decision->semantic-root
                              decision
                              (.ref binding 'bundle-digest)
                              (.ref binding 'intent-digest))
                             'digest)))
    (error "Cedar decision/binding/semantic-root mismatch"))
  (poo-flow-authorized-effect-token
   token-id nonce semantic-root binding validity durability evidence-bits
   issuer signature))
