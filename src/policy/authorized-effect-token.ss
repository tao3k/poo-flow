;;; Boundary: Scheme POO owns semantic roots and one-shot effect capabilities.
;;; Invariant: validation and consumption are pure immutable transitions.
(import :clan/poo/object
        :std/crypto/digest
        :std/text/hex)

(export poo-flow-semantic-root
        poo-flow-effect-binding
        poo-flow-effect-binding-digest
        poo-flow-token-validity
        poo-flow-authorized-effect-token
        poo-flow-authorized-effect-token-digest
        poo-flow-token-validation-context
        poo-flow-authorized-effect-token-validate
        poo-flow-authorized-effect-token-consume)

(def (canonical-digest value)
  (hex-encode (sha256 (call-with-output-string (lambda (port) (write value port))))))

(def (poo-flow-effect-binding-digest binding-object)
  (unless (eq? (.ref binding-object 'kind) 'poo-flow-effect-binding)
    (error "effect binding digest requires EffectBinding" binding-object))
  (canonical-digest binding-object))

(def (poo-flow-authorized-effect-token-digest token-object)
  (unless (eq? (.ref token-object 'kind) 'poo-flow-authorized-effect-token)
    (error "token digest requires AuthorizedEffectToken" token-object))
  (canonical-digest token-object))

(def (poo-flow-semantic-root b-digest p-digest e-digest d-digest i-digest)
  (let (canonical
        (list 'poo-flow.semantic-root.draft.1 b-digest p-digest
              e-digest d-digest i-digest))
    (.o (kind 'poo-flow-semantic-root)
        (schema 'poo-flow.semantic-root.draft.1)
        (bundle-digest b-digest) (policy-digest p-digest)
        (entity-digest e-digest) (decision-digest d-digest)
        (intent-digest i-digest)
        (digest (canonical-digest canonical)))))

(def (poo-flow-effect-binding b-digest b-epoch p-digest e-digest d-digest i-digest
                              attempt effect runtime session seq-start seq-end
                              arena arena-gen offset length pld-digest lease)
  (.o (kind 'poo-flow-effect-binding)
      (bundle-digest b-digest) (bundle-epoch b-epoch)
      (policy-digest p-digest) (entity-digest e-digest)
      (decision-digest d-digest) (intent-digest i-digest)
      (attempt-id attempt) (effect-kind effect)
      (runtime-id runtime) (session-id session)
      (sequence-start seq-start) (sequence-end seq-end)
      (arena-id arena) (arena-generation arena-gen)
      (payload-offset offset) (payload-length length)
      (payload-digest pld-digest) (lease-id lease)))

(def (poo-flow-token-validity issued not-before-time expiry-time revocation)
  (.o (kind 'poo-flow-token-validity)
      (issued-at issued) (not-before not-before-time) (expiry expiry-time)
      (revocation-epoch revocation)))

(def (poo-flow-authorized-effect-token identity token-nonce root effect-binding
                                       token-validity profile evidence-bits
                                       issuer token-signature)
  (.o (kind 'poo-flow-authorized-effect-token)
      (schema 'poo-flow.authorized-effect-token.draft.1)
      (token-id identity) (nonce token-nonce) (semantic-root root)
      (binding effect-binding) (validity token-validity) (durability profile)
      (required-evidence-bits evidence-bits)
      (issuer-id issuer) (signature token-signature)))

(def (poo-flow-token-validation-context root expected-binding current-time
                                         current-revocation spent-nonces)
  (.o (kind 'poo-flow-token-validation-context)
      (semantic-root root) (binding expected-binding) (now current-time)
      (revocation-epoch current-revocation) (consumed-nonces spent-nonces)))

(def (binding-projection binding)
  (list (.ref binding 'bundle-digest) (.ref binding 'bundle-epoch)
        (.ref binding 'policy-digest) (.ref binding 'entity-digest)
        (.ref binding 'decision-digest) (.ref binding 'intent-digest)
        (.ref binding 'attempt-id) (.ref binding 'effect-kind)
        (.ref binding 'runtime-id) (.ref binding 'session-id)
        (.ref binding 'sequence-start) (.ref binding 'sequence-end)
        (.ref binding 'arena-id) (.ref binding 'arena-generation)
        (.ref binding 'payload-offset) (.ref binding 'payload-length)
        (.ref binding 'payload-digest) (.ref binding 'lease-id)))

(def (binding-equal? left right)
  (equal? (binding-projection left) (binding-projection right)))

(def (rejection-code token context)
  (let ((validity (.ref token 'validity))
        (nonce (.ref token 'nonce)))
    (cond
     ((not (equal? (.ref (.ref token 'semantic-root) 'digest)
                   (.ref (.ref context 'semantic-root) 'digest)))
      'semantic-root-mismatch)
     ((not (binding-equal? (.ref token 'binding) (.ref context 'binding)))
      'binding-substitution)
     ((member nonce (.ref context 'consumed-nonces)) 'token-reuse)
     ((< (.ref context 'now) (.ref validity 'not-before)) 'token-not-yet-valid)
     ((> (.ref context 'now) (.ref validity 'expiry)) 'token-expired)
     ((not (= (.ref validity 'revocation-epoch)
              (.ref context 'revocation-epoch))) 'stale-revocation-epoch)
     ((eq? (.ref token 'durability) 'diagnostic) 'diagnostic-cannot-execute)
     (else #f))))

(def (poo-flow-authorized-effect-token-validate token context)
  (let (rejection (rejection-code token context))
    (.o (kind 'poo-flow-token-validation-receipt)
        (accepted? (not rejection)) (code (or rejection 'token-reserved))
        (token-id (.ref token 'token-id)) (nonce (.ref token 'nonce))
        (semantic-root (.ref token 'semantic-root))
        (binding (.ref token 'binding))
        (durability (.ref token 'durability)))))

(def (poo-flow-authorized-effect-token-consume token validation
                                               prior-root observation)
  (unless (.ref validation 'accepted?)
    (error "cannot consume rejected AuthorizedEffectToken"))
  (let* ((leaf (list 'poo-flow.execution-leaf.draft.1
                     prior-root (.ref token 'nonce)
                     (.ref (.ref token 'semantic-root) 'digest)
                     observation))
         (next-root (canonical-digest leaf)))
    (.o (kind 'poo-flow-token-consumption-receipt)
        (outcome 'committed) (token-id (.ref token 'token-id))
        (nonce (.ref token 'nonce))
        (semantic-root (.ref token 'semantic-root))
        (previous-execution-root prior-root)
        (observation-digest observation)
        (execution-root next-root)
        (durability (.ref token 'durability)))))
