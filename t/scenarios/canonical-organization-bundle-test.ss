(import :clan/poo/object
        :std/test
        :poo-flow/src/contract/organization-bundle
        :poo-flow/src/semantic/organization-bundle)

(def (canonical-bundle . reverse-order?)
  (let* ((parent-principal (poo-flow-organization-principal 'principal-parent))
         (child-principal (poo-flow-organization-principal 'principal-child))
         (parent-role (poo-flow-organization-role 'role-parent))
         (child-role (poo-flow-organization-role 'role-child))
         (parent (poo-flow-organization-agent
                  'agent-parent 'principal-parent 'role-parent #f
                  '(write search) '(public private)))
         (child (poo-flow-organization-agent
                 'agent-child 'principal-child 'role-child 'agent-parent
                 '(search) '(public)))
         (search-capability
          (poo-flow-organization-capability 'search #t))
         (write-capability
          (poo-flow-organization-capability 'write #t))
         (delegation
          (poo-flow-organization-delegation
           'agent-parent 'agent-child 'search))
         (context
          (poo-flow-organization-context-projection 'agent-child '(public)))
         (effect
          (poo-flow-organization-tool-effect
           'search-tool 'search 'external-tool)))
    (if (pair? reverse-order?)
      (poo-flow-organization-bundle
       7
       (list child-principal parent-principal)
       (list child-role parent-role)
       (list child parent)
       (list write-capability search-capability)
       (list delegation)
       (list context)
       (list effect))
      (poo-flow-organization-bundle
       7
       (list parent-principal child-principal)
       (list parent-role child-role)
       (list parent child)
       (list search-capability write-capability)
       (list delegation)
       (list context)
       (list effect)))))

(def (diagnostic-codes receipt)
  (map (lambda (entry) (cdr (assq 'code entry)))
       (poo-flow-organization-validation-diagnostics receipt)))

(def canonical-organization-bundle-test
  (test-suite
   "canonical organization Bundle vertical slice"

   (test-case "normalization and digest are construction-order invariant"
     (let* ((left (canonical-bundle))
            (right (canonical-bundle #t))
            (left-canonical (poo-flow-organization-bundle-normalize left))
            (right-canonical (poo-flow-organization-bundle-normalize right))
            (left-id (poo-flow-organization-bundle-identity left))
            (right-id (poo-flow-organization-bundle-identity right)))
       (check-equal? left-canonical right-canonical)
       (check-equal? (poo-flow-organization-bundle-normalize left-canonical)
                     left-canonical)
       (check-equal? (.ref left-id 'algorithm) 'sha256)
       (check-equal? (.ref left-id 'digest) (.ref right-id 'digest))
       (check-equal? (string-length (.ref left-id 'digest)) 64)))

   (test-case "frozen parent child tool slice validates"
     (let* ((bundle (canonical-bundle))
            (receipt (poo-flow-organization-bundle-validate bundle))
            (contract (poo-flow-organization-bundle->contract bundle)))
       (check-equal? (poo-flow-organization-validation-accepted? receipt) #t)
       (check-equal? (poo-flow-organization-validation-diagnostics receipt) '())
       (check-equal? (poo-flow-organization-bundle-contract-ref contract 'canonical)
                     (poo-flow-organization-bundle-normalize bundle))
       (check-equal? (.ref (poo-flow-organization-bundle-contract-ref
                            contract 'identity)
                           'digest)
                     (.ref (poo-flow-organization-bundle-identity bundle) 'digest))))

   (test-case "semantic mutation changes digest"
     (let* ((bundle (canonical-bundle))
            (mutated
             (poo-flow-organization-bundle
              8
              (.ref bundle 'principals)
              (.ref bundle 'roles)
              (.ref bundle 'agents)
              (.ref bundle 'capabilities)
              (.ref bundle 'delegations)
              (.ref bundle 'context-projections)
              (.ref bundle 'tool-effects))))
       (check (equal? (.ref (poo-flow-organization-bundle-identity bundle) 'digest)
                      (.ref (poo-flow-organization-bundle-identity mutated) 'digest))
              => #f)))

   (test-case "authority equality is rejected"
     (let* ((base (canonical-bundle))
            (parent (car (.ref base 'agents)))
            (child (cadr (.ref base 'agents)))
            (invalid-child
             (poo-flow-organization-agent
              (.ref child 'id) (.ref child 'principal-id) (.ref child 'role-id)
              (.ref child 'parent-id) '(write search) '(public)))
            (invalid
             (poo-flow-organization-bundle
              (.ref base 'epoch) (.ref base 'principals) (.ref base 'roles)
              (list parent invalid-child) (.ref base 'capabilities)
              (.ref base 'delegations) (.ref base 'context-projections)
              (.ref base 'tool-effects)))
            (receipt (poo-flow-organization-bundle-validate invalid)))
       (check (not (not (member 'authority-not-strict-subset
                                (diagnostic-codes receipt))))
              => #t)))

   (test-case "context leakage and identity mismatch are rejected"
     (let* ((base (canonical-bundle))
            (leaked-context
             (poo-flow-organization-context-projection
              'agent-child '(public secret)))
            (invalid
             (poo-flow-organization-bundle
              (.ref base 'epoch) (.ref base 'principals) (.ref base 'roles)
              (.ref base 'agents) (.ref base 'capabilities)
              (.ref base 'delegations) (list leaked-context)
              (.ref base 'tool-effects)))
            (wrong-identity
             (.o (kind 'poo-flow.organization-bundle.identity.v1)
                 (algorithm 'sha256) (digest "00") (epoch 7)))
            (receipt
             (poo-flow-organization-bundle-validate invalid wrong-identity))
            (codes (diagnostic-codes receipt)))
       (check (not (not (member 'context-visibility-leak codes))) => #t)
       (check (not (not (member 'bundle-identity-mismatch codes))) => #t)))

   (test-case "undeclared effect and invalid epoch are rejected"
     (let* ((base (canonical-bundle))
            (effect
             (poo-flow-organization-tool-effect
              'unknown-tool 'unknown 'external-tool))
            (invalid
             (poo-flow-organization-bundle
              -1 (.ref base 'principals) (.ref base 'roles)
              (.ref base 'agents) (.ref base 'capabilities)
              (.ref base 'delegations) (.ref base 'context-projections)
              (list effect)))
            (codes
             (diagnostic-codes
              (poo-flow-organization-bundle-validate invalid))))
       (check (not (not (member 'invalid-epoch codes))) => #t)
       (check (not (not (member 'undeclared-tool-effect codes))) => #t)))

   (test-case "duplicate and missing semantic identities are rejected"
     (let* ((base (canonical-bundle))
            (principal (car (.ref base 'principals)))
            (invalid
             (poo-flow-organization-bundle
              (.ref base 'epoch)
              (list principal principal)
              '()
              (.ref base 'agents)
              (.ref base 'capabilities)
              (.ref base 'delegations)
              (.ref base 'context-projections)
              (.ref base 'tool-effects)))
            (codes
             (diagnostic-codes
              (poo-flow-organization-bundle-validate invalid))))
       (check (not (not (member 'duplicate-identity codes))) => #t)
       (check (not (not (member 'missing-members codes))) => #t)
       (check (not (not (member 'missing-role codes))) => #t)))

   (test-case "unstable semantic values fail closed"
     (let* ((base (canonical-bundle))
            (parent (car (.ref base 'agents)))
            (child (cadr (.ref base 'agents)))
            (unstable-child
             (poo-flow-organization-agent
              (.ref child 'id) (.ref child 'principal-id) (.ref child 'role-id)
              (.ref child 'parent-id) (vector 'search) '(public)))
            (invalid
             (poo-flow-organization-bundle
              (.ref base 'epoch) (.ref base 'principals) (.ref base 'roles)
              (list parent unstable-child) (.ref base 'capabilities)
              (.ref base 'delegations) (.ref base 'context-projections)
              (.ref base 'tool-effects)))
            (receipt (poo-flow-organization-bundle-validate invalid)))
       (check-equal? (poo-flow-organization-validation-accepted? receipt) #f)
       (check-equal? (diagnostic-codes receipt) '(unstable-semantic-value))))))

(run-tests! canonical-organization-bundle-test)
