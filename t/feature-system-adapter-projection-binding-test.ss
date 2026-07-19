(import :std/test
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/interface
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export feature-system-adapter-projection-binding-test)

(def adapter-projection-projector-calls (vector 0))

(def (adapter-projection-test-project value)
  (vector-set!
   adapter-projection-projector-calls
   0
   (+ 1 (vector-ref adapter-projection-projector-calls 0)))
  value)

(def (adapter-projection-test-role slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (adapter-projection-test-value? value) #t)

(def adapter-projection-base-type
  (poo-flow-case-type-contract
   'adapter-projection-base-type '() adapter-projection-test-value?))

(def adapter-projection-agent-type
  (poo-flow-case-type-contract
   'adapter-projection-agent-type
   '(adapter-projection-base-type)
   adapter-projection-test-value?))

(def adapter-projection-runtime-projection
  (poo-flow-case-projection
   'adapter-projection-runtime-view
   'adapter-projection-base-component
   'runtime-envelope-v1
   adapter-projection-test-project))

(def adapter-projection-evidence-projection
  (poo-flow-case-projection
   'adapter-projection-evidence-view
   'adapter-projection-agent-component
   'evidence-envelope-v1
   adapter-projection-test-project))

(def adapter-projection-base-component
  (poo-flow-case-component
   'adapter-projection-base-component
   1
   (adapter-projection-test-role '((adapter-projection-base-role . #t)))
   adapter-projection-base-type
   '()
   '()
   (list adapter-projection-runtime-projection)))

(def adapter-projection-agent-component
  (poo-flow-case-component
   'adapter-projection-agent-component
   1
   (adapter-projection-test-role '((adapter-projection-agent-role . #t)))
   adapter-projection-agent-type
   '()
   '()
   (list adapter-projection-evidence-projection)
   '(adapter-projection-base-component)))

(defpoo-feature-adapter-capability python-runtime-capability
  (capability-id 'python-runtime-v1)
  (provider-module-id 'poo-flow/python-runtime)
  (contract-id 'poo-flow.runtime-c)
  (contract-version 1))

(defpoo-feature-adapter-capability cedar-policy-capability
  (capability-id 'cedar-policy-v1)
  (provider-module-id 'poo-flow/cedar-adapter)
  (contract-id 'poo-flow.cedar-policy)
  (contract-version 1))

(defpoo-feature-adapter-requirement python-runtime-requirement
  (requirement-id 'python-runtime-requirement)
  (capability-id 'python-runtime-v1)
  (contract-id 'poo-flow.runtime-c)
  (contract-version 1))

(defpoo-feature-adapter-requirement cedar-policy-requirement
  (requirement-id 'cedar-policy-requirement)
  (capability-id 'cedar-policy-v1)
  (contract-id 'poo-flow.cedar-policy)
  (contract-version 1))

(defpoo-feature-projection-request runtime-projection-request
  (request-id 'runtime-projection-request)
  (projection-id 'adapter-projection-runtime-view)
  (schema-id 'runtime-envelope-v1))

(defpoo-feature-projection-request evidence-projection-request
  (request-id 'evidence-projection-request)
  (projection-id 'adapter-projection-evidence-view)
  (schema-id 'evidence-envelope-v1))

(defpoo-feature adapter-projection-base-feature
  (feature-id 'adapter-projection-base-feature)
  (owner-module-id 'feature-system-adapter-projection-binding-test)
  (components adapter-projection-base-component)
  (adapter-requirements python-runtime-requirement)
  (projections runtime-projection-request))

(defpoo-feature adapter-projection-agent-feature
  (feature-id 'adapter-projection-agent-feature)
  (owner-module-id 'feature-system-adapter-projection-binding-test)
  (requires adapter-projection-base-feature)
  (components adapter-projection-agent-component)
  (adapter-requirements cedar-policy-requirement)
  (projections evidence-projection-request))

(defpoo-feature-manifest-bundle adapter-projection-bundle
  (bundle-id 'adapter-projection-bundle)
  (features adapter-projection-agent-feature adapter-projection-base-feature))

(defpoo-feature-composition-plan adapter-projection-plan
  (from-bundle adapter-projection-bundle))

(defpoo-feature-domain-case-assembly adapter-projection-assembly
  (using-cache (poo-flow-domain-case-cache))
  (domain-case-id 'adapter-projection-case)
  (domain-case-version 1)
  (from-plan adapter-projection-plan))

(defpoo-feature-policy-strategy-binding adapter-projection-policy-binding
  (from-assembly adapter-projection-assembly))

(defpoo-feature-adapter-capability-catalog adapter-projection-catalog
  (catalog-id 'adapter-projection-test-catalog)
  (capabilities python-runtime-capability cedar-policy-capability))

(defpoo-feature-adapter-projection-binding adapter-projection-ready
  (using-catalog adapter-projection-catalog)
  (from-binding adapter-projection-policy-binding))

(def duplicate-capability-a
  (feature-adapter-capability
   (string-append "duplicate-" "capability")
   'duplicate/provider-a
   'duplicate.contract
   1))

(def duplicate-capability-b
  (feature-adapter-capability
   (string-append "duplicate" "-capability")
   'duplicate/provider-b
   'duplicate.contract
   1))

(def duplicate-capability-catalog
  (feature-adapter-capability-catalog
   'duplicate-capability-catalog
   (list duplicate-capability-a duplicate-capability-b)))

(def (adapter-projection-test-assembly adapter-requirements
                                      projection-requests)
  (let ((object (make-object)))
    (object-slots-set!
     object
     (role-constant-slots
      `((kind . feature-domain-case-assembly)
        (accepted? . #t)
        (domain-case . ,(.ref adapter-projection-assembly 'domain-case))
        (policy-contributions . ())
        (strategy-contributions . ())
        (adapter-requirements . ,adapter-requirements)
        (projection-requests . ,projection-requests)
        (projections . ,projection-requests))))
    object))

(def (adapter-projection-test-binding adapter-requirements
                                     projection-requests
                                     (catalog adapter-projection-catalog))
  (feature-adapter-projection-binding
   catalog
   (feature-policy-strategy-binding
    (adapter-projection-test-assembly
     adapter-requirements projection-requests))))

(def missing-adapter-requirement
  (feature-adapter-requirement
   'missing-adapter-requirement
   'missing-adapter-capability
   'missing.contract
   1))

(def mismatched-adapter-requirement
  (feature-adapter-requirement
   'mismatched-adapter-requirement
   'python-runtime-v1
   'poo-flow.runtime-c
   2))

(def duplicate-adapter-requirement-a
  (feature-adapter-requirement
   (string-append "duplicate-" "requirement")
   'python-runtime-v1
   'poo-flow.runtime-c
   1))

(def duplicate-adapter-requirement-b
  (feature-adapter-requirement
   (string-append "duplicate" "-requirement")
   'cedar-policy-v1
   'poo-flow.cedar-policy
   1))

(def missing-projection-request
  (feature-projection-request
   'missing-projection-request
   'missing-domain-case-projection
   'missing-envelope-v1))

(def mismatched-projection-request
  (feature-projection-request
   'mismatched-projection-request
   'adapter-projection-runtime-view
   'runtime-envelope-v2))

(def duplicate-projection-request-a
  (feature-projection-request
   (string-append "duplicate-" "projection-request")
   'adapter-projection-runtime-view
   'runtime-envelope-v1))

(def duplicate-projection-request-b
  (feature-projection-request
   (string-append "duplicate" "-projection-request")
   'adapter-projection-evidence-view
   'evidence-envelope-v1))

(def raw-adapter-rejected
  (adapter-projection-test-binding '(raw-adapter-requirement) '()))

(def missing-adapter-rejected
  (adapter-projection-test-binding (list missing-adapter-requirement) '()))

(def mismatched-adapter-rejected
  (adapter-projection-test-binding
   (list mismatched-adapter-requirement) '()))

(def duplicate-adapter-rejected
  (adapter-projection-test-binding
   (list duplicate-adapter-requirement-a
         duplicate-adapter-requirement-b)
   '()))

(def raw-projection-rejected
  (adapter-projection-test-binding '() '(raw-projection-request)))

(def missing-projection-rejected
  (adapter-projection-test-binding '() (list missing-projection-request)))

(def mismatched-projection-rejected
  (adapter-projection-test-binding
   '() (list mismatched-projection-request)))

(def duplicate-projection-rejected
  (adapter-projection-test-binding
   '()
   (list duplicate-projection-request-a
         duplicate-projection-request-b)))

(def rejected-catalog-binding
  (adapter-projection-test-binding '() '() duplicate-capability-catalog))

(def rejected-upstream-binding
  (feature-adapter-projection-binding
   adapter-projection-catalog
   (feature-policy-strategy-binding 'not-an-assembly)))

(def (adapter-projection-diagnostic-codes binding)
  (poo-flow-map
   (lambda (diagnostic) (.ref diagnostic 'code))
   (.ref binding 'diagnostics)))

(def (adapter-projection-stress-id prefix index)
  (string->symbol (string-append prefix (number->string index))))

(def (adapter-projection-stress-entries count)
  (let loop ((index 0) (entries []))
    (if (= index count)
      (reverse entries)
      (let* ((capability-id
              (adapter-projection-stress-id "adapter-capability-" index))
             (contract-id
              (adapter-projection-stress-id "adapter-contract-" index))
             (projection-id
              (adapter-projection-stress-id "case-projection-" index))
             (schema-id
              (adapter-projection-stress-id "projection-schema-" index))
             (entry
              (list
               (feature-adapter-capability
                capability-id
                (adapter-projection-stress-id "provider-module-" index)
                contract-id
                1)
               (feature-adapter-requirement
                (adapter-projection-stress-id "adapter-requirement-" index)
                capability-id
                contract-id
                1)
               (feature-projection-request
                (adapter-projection-stress-id "projection-request-" index)
                projection-id
                schema-id)
               (poo-flow-case-projection
                projection-id
                'adapter-projection-stress-component
                schema-id
                adapter-projection-test-project))))
        (loop (+ index 1) (cons entry entries))))))

(def (adapter-projection-stress-descriptors entries component)
  (let loop ((remaining entries)
             (index 0)
             (previous-descriptor #f)
             (descriptors []))
    (if (null? remaining)
      (reverse descriptors)
      (let* ((entry (car remaining))
             (base
              (feature-descriptor-base
               (adapter-projection-stress-id "adapter-feature-" index)
               'feature-adapter-projection-binding-stress))
             (adapter-requirement (feature-adapter-requirements (cadr entry)))
             (projection-request (feature-projections (caddr entry)))
             (spec
              (if previous-descriptor
                (feature-spec-compose
                 base
                 (feature-required-features previous-descriptor)
                 adapter-requirement
                 projection-request)
                (feature-spec-compose
                 base
                 (feature-components component)
                 adapter-requirement
                 projection-request)))
             (descriptor (feature-descriptor spec)))
        (loop (cdr remaining)
              (+ index 1)
              descriptor
              (cons descriptor descriptors))))))

(def feature-system-adapter-projection-binding-test
  (test-suite "Feature adapter capability and projection binding"
    (test-case "accepted chain binds adapters and closed Case projections"
      (let* ((adapter-bindings
              (.ref adapter-projection-ready 'adapter-bindings))
             (projection-bindings
              (.ref adapter-projection-ready 'projection-bindings))
             (domain-case (.ref adapter-projection-ready 'domain-case)))
        (check (.ref adapter-projection-assembly 'accepted?) => #t)
        (check (.ref adapter-projection-assembly 'selected-projection-ids)
               => '(adapter-projection-runtime-view
                    adapter-projection-evidence-view))
        (check (length (.ref domain-case 'projection-catalog)) => 2)
        (check (.ref adapter-projection-policy-binding 'accepted?) => #t)
        (check (.ref adapter-projection-catalog 'status) => 'ready)
        (check (.ref adapter-projection-catalog 'size) => 2)
        (check (eq? (feature-adapter-capability-catalog-ref
                     adapter-projection-catalog 'python-runtime-v1)
                    python-runtime-capability)
               => #t)
        (check (.ref adapter-projection-ready 'status) => 'ready)
        (check (.ref adapter-projection-ready 'accepted?) => #t)
        (check (length adapter-bindings) => 2)
        (check (poo-flow-map
                (lambda (binding) (.ref binding 'requirement-id))
                adapter-bindings)
               => '(python-runtime-requirement cedar-policy-requirement))
        (check (poo-flow-map
                (lambda (binding) (.ref binding 'provider-module-id))
                adapter-bindings)
               => '(poo-flow/python-runtime poo-flow/cedar-adapter))
        (check (length projection-bindings) => 2)
        (check (eq? (.ref (car projection-bindings) 'projection)
                    adapter-projection-runtime-projection)
               => #t)
        (check (eq? (.ref (cadr projection-bindings) 'projection)
                    adapter-projection-evidence-projection)
               => #t)
        (check (vector-ref adapter-projection-projector-calls 0) => 0)))

    (test-case "catalog rejects invalid and duplicate capabilities"
      (check (.ref duplicate-capability-catalog 'accepted?) => #f)
      (check (.ref duplicate-capability-catalog 'capability-index) => #f)
      (check (memq 'duplicate-adapter-capability-id
                   (adapter-projection-diagnostic-codes
                    duplicate-capability-catalog))
             ? values))

    (test-case "adapter requirements reject raw, missing, mismatched and duplicate values"
      (check (memq 'invalid-adapter-requirement
                   (adapter-projection-diagnostic-codes raw-adapter-rejected))
             ? values)
      (check (memq 'missing-adapter-capability
                   (adapter-projection-diagnostic-codes missing-adapter-rejected))
             ? values)
      (check (memq 'adapter-contract-mismatch
                   (adapter-projection-diagnostic-codes
                    mismatched-adapter-rejected))
             ? values)
      (check (memq 'duplicate-adapter-requirement-id
                   (adapter-projection-diagnostic-codes
                    duplicate-adapter-rejected))
             ? values))

    (test-case "projection requests bind only to the closed catalog"
      (check (memq 'invalid-feature-projection-request
                   (adapter-projection-diagnostic-codes
                    raw-projection-rejected))
             ? values)
      (check (memq 'missing-domain-case-projection
                   (adapter-projection-diagnostic-codes
                    missing-projection-rejected))
             ? values)
      (check (memq 'projection-schema-mismatch
                   (adapter-projection-diagnostic-codes
                    mismatched-projection-rejected))
             ? values)
      (check (memq 'duplicate-projection-request-id
                   (adapter-projection-diagnostic-codes
                    duplicate-projection-rejected))
             ? values)
      (check (vector-ref adapter-projection-projector-calls 0) => 0))

    (test-case "rejected upstream binding or catalog stops resolution"
      (check (.ref rejected-catalog-binding 'accepted?) => #f)
      (check (memq 'adapter-capability-catalog-rejected
                   (adapter-projection-diagnostic-codes
                    rejected-catalog-binding))
             ? values)
      (check (.ref rejected-upstream-binding 'accepted?) => #f)
      (check (memq 'feature-policy-strategy-binding-rejected
                   (adapter-projection-diagnostic-codes
                    rejected-upstream-binding))
             ? values))

    (test-case "256 requirements and projections resolve with indexed owners"
      (let* ((entries (adapter-projection-stress-entries 256))
             (projections (poo-flow-map cadddr entries))
             (capabilities (poo-flow-map car entries))
             (component
              (poo-flow-case-component
               'adapter-projection-stress-component
               1
               (adapter-projection-test-role
                '((adapter-projection-stress-role . #t)))
               (poo-flow-case-type-contract
                'adapter-projection-stress-type
                '()
                adapter-projection-test-value?)
               '()
               '()
               projections))
             (descriptors
              (adapter-projection-stress-descriptors entries component))
             (bundle
              (feature-manifest-bundle
               'feature-adapter-projection-binding-stress descriptors))
             (plan (feature-composition-plan bundle))
             (assembly
              (feature-domain-case-assembly
               (poo-flow-domain-case-cache)
               'feature-adapter-projection-binding-stress
               1
               plan))
             (policy-binding
              (feature-policy-strategy-binding assembly))
             (catalog
              (feature-adapter-capability-catalog
               'feature-adapter-projection-binding-stress capabilities))
             (binding
              (feature-adapter-projection-binding catalog policy-binding))
             (adapter-bindings (.ref binding 'adapter-bindings))
             (projection-bindings (.ref binding 'projection-bindings)))
        (check (.ref assembly 'accepted?) => #t)
        (check (length (.ref
                        (.ref assembly 'domain-case)
                        'projection-catalog))
               => 256)
        (check (.ref binding 'accepted?) => #t)
        (check (length adapter-bindings) => 256)
        (check (length projection-bindings) => 256)
        (check (.ref (car adapter-bindings) 'requirement-id)
               => 'adapter-requirement-0)
        (check (.ref (car (reverse projection-bindings)) 'request-id)
               => 'projection-request-255)
        (check (vector-ref adapter-projection-projector-calls 0) => 0)))))
