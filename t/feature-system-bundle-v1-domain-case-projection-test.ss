(export feature-system-bundle-v1-domain-case-projection-test)

(import :std/test
        :clan/poo/object
        :poo-flow/src/utilities/functional
        :poo-flow/src/feature-system/interface
        "./fixtures/bundle-v1-domain-case-projection.ss")

(def ready-runtime-handoff-plan
  (make-bundle-v1-domain-case-runtime-handoff-plan 2 1 1 #f))

(def duplicate-runtime-handoff-plan
  (make-bundle-v1-domain-case-runtime-handoff-plan 2 1 1 #t))

(def (projection-diagnostic-code projection)
  (.ref (car (.ref projection 'diagnostics)) 'code))

(def feature-system-bundle-v1-domain-case-projection-test
  (test-suite
   "Bundle v1 projection from accepted Domain Case owners"

   (test-case
    "accepted runtime handoff projects components, inheritance and evidence"
    (let* ((projection
            (feature-bundle-v1-project-domain-case
             9 ready-runtime-handoff-plan))
           (components (.ref projection 'components))
           (edges (.ref projection 'edges))
           (evidence (.ref projection 'evidence-obligations))
           (lowering (.ref projection 'lowering-plan))
           (descriptor (.ref lowering 'descriptor))
           (base
            (poo-flow-find
             (lambda (component)
               (eq? (.ref component 'component-id)
                    'bundle-component-0))
             components))
           (child
            (poo-flow-find
             (lambda (component)
               (eq? (.ref component 'component-id)
                    'bundle-component-1))
             components)))
      (check (.ref ready-runtime-handoff-plan 'accepted?) => #t)
      (check (feature-bundle-v1-domain-case-projection? projection) => #t)
      (check (.ref projection 'accepted?) => #t)
      (check (.ref projection 'status) => 'ready)
      (check (eq? (require-feature-bundle-v1-domain-case-projection projection)
                  projection)
             => #t)
      (check (.ref projection 'bundle-id)
             => 'bundle-domain-case-feature-bundle)
      (check (.ref projection 'bundle-epoch) => 9)
      (check (length components) => 2)
      (check (length edges) => 1)
      (check (length evidence) => 1)
      (check (.ref base 'capability-id) => 'bundle-runtime-capability-0)
      (check (.ref base 'adapter-id) => 'poo-flow/python-runtime-cffi)
      (check (.ref base 'projection-id) => 'bundle-runtime-projection-0)
      (check (.ref child 'capability-id)
             => +feature-bundle-v1-no-capability-id+)
      (check (.ref child 'adapter-id)
             => +feature-bundle-v1-no-adapter-id+)
      (check (.ref child 'projection-id)
             => +feature-bundle-v1-no-projection-id+)
      (check (.ref base 'policy-id) => +feature-bundle-v1-no-policy-id+)
      (check (.ref base 'strategy-id) => +feature-bundle-v1-no-strategy-id+)
      (check (.ref (car edges) 'source-component-id)
             => 'bundle-component-1)
      (check (.ref (car edges) 'target-component-id)
             => 'bundle-component-0)
      (check (.ref (car evidence) 'obligation-id)
             => 'bundle-evidence-obligation-0)
      (check (.ref (car evidence) 'evidence-type-id)
             => 'bundle-evidence-schema-0)
      (check (.ref (car evidence) 'proof-system-id)
             => 'poo-flow/lean-evidence-adapter)
      (check (.ref lowering 'accepted?) => #t)
      (check (.ref descriptor 'arena-bytes) => 576)))

   (test-case
    "duplicate Runtime Bundle handoffs for one component fail closed"
    (let ((projection
           (feature-bundle-v1-project-domain-case
            1 duplicate-runtime-handoff-plan)))
      (check (.ref duplicate-runtime-handoff-plan 'accepted?) => #t)
      (check (.ref projection 'accepted?) => #f)
      (check (eq? (.ref projection 'runtime-handoff-plan)
                  duplicate-runtime-handoff-plan)
             => #t)
      (check (projection-diagnostic-code projection)
             => 'duplicate-runtime-bundle-handoff-owner)))

   (test-case
    "rejected upstream and invalid epoch never reach a native receipt"
    (let ((upstream-rejected
           (feature-bundle-v1-project-domain-case 1 '()))
          (invalid-epoch
           (feature-bundle-v1-project-domain-case
            -1 ready-runtime-handoff-plan)))
      (check (.ref upstream-rejected 'accepted?) => #f)
      (check (projection-diagnostic-code upstream-rejected)
             => 'runtime-handoff-plan-rejected)
      (check (.ref invalid-epoch 'accepted?) => #f)
      (check (object? (.ref invalid-epoch 'lowering-plan)) => #t)
      (check (.ref (.ref invalid-epoch 'lowering-plan) 'accepted?) => #f)
      (check (projection-diagnostic-code invalid-epoch)
             => 'bundle-v1-lowering-rejected)))))
