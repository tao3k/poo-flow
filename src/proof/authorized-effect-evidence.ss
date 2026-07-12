;;; Boundary: bounded AC-08 proof projection; proofs never invent observations.
(import :clan/poo/object)

(export poo-flow-authorized-effect-proof-facts
        poo-flow-authorized-effect-proof-claim-level
        poo-flow-authorized-effect-proof-facts->ffi-wire)

(def (poo-flow-authorized-effect-proof-claim-level facts)
  (cond
   ((and (.ref facts 'l2-ready?)
         (.ref facts 'durable-evidence-reference)
         (.ref facts 'kernel-signature)
         (.ref facts 'signature-verified?)
         (.ref facts 'inclusion-proof-verified?)) 'l3-verified)
   ((.ref facts 'l2-ready?) 'l2-evidenced)
   ((and (.ref facts 'decision-permit?)
         (.ref facts 'semantic-root-bound?)
         (.ref facts 'token-consumed?)) 'l1-mediated)
   (else 'unverified)))

(def (poo-flow-authorized-effect-proof-facts
      identity decision-permit semantic-bound token-consumed root-linked
      adapter-observed effect-outcome durability-profile evidence-reference
      kernel-attestation signature-verified inclusion-proof-verified)
  (let (l2-ready
        (and decision-permit semantic-bound token-consumed root-linked
             adapter-observed (eq? effect-outcome 'committed)
             (memq durability-profile '(strict batched))))
    (.o (kind 'poo-flow-authorized-effect-proof-facts)
        (schema 'poo-flow.proof.authorized-effect.draft.1)
        (fact-id identity)
        (decision-permit? decision-permit)
        (semantic-root-bound? semantic-bound)
        (token-consumed? token-consumed)
        (execution-root-linked? root-linked)
        (adapter-observed? adapter-observed)
        (outcome effect-outcome)
        (durability durability-profile)
        (durable-evidence-reference evidence-reference)
        (kernel-signature kernel-attestation)
        (signature-verified? signature-verified)
        (inclusion-proof-verified? inclusion-proof-verified)
        (l2-ready? l2-ready))))

(def (poo-flow-authorized-effect-proof-facts->ffi-wire facts)
  (let (claim-level (poo-flow-authorized-effect-proof-claim-level facts))
    (list (cons 'schema 'poo-flow.proof.authorized-effect.ffi-wire)
          (cons 'version 1)
          (cons 'fact-id (.ref facts 'fact-id))
          (cons 'claim-level claim-level)
          (cons 'accepted? (memq claim-level '(l2-evidenced l3-verified)))
          (cons 'decision-permit? (.ref facts 'decision-permit?))
          (cons 'semantic-root-bound? (.ref facts 'semantic-root-bound?))
          (cons 'token-consumed? (.ref facts 'token-consumed?))
          (cons 'execution-root-linked? (.ref facts 'execution-root-linked?))
          (cons 'adapter-observed? (.ref facts 'adapter-observed?))
          (cons 'outcome (.ref facts 'outcome))
          (cons 'durability (.ref facts 'durability))
          (cons 'durable-evidence-reference
                (.ref facts 'durable-evidence-reference))
          (cons 'kernel-signature (.ref facts 'kernel-signature))
          (cons 'signature-verified? (.ref facts 'signature-verified?))
          (cons 'inclusion-proof-verified?
                (.ref facts 'inclusion-proof-verified?)))))
