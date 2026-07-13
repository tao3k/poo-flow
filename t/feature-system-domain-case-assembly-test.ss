(import :std/test
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/interface
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export feature-system-domain-case-assembly-test)

(def (domain-case-test-role slot-id)
  (let ((object (make-object)))
    (object-slots-set!
     object
     (role-constant-slots (list (cons slot-id #t))))
    object))

(def (domain-case-test-value? value) #t)

(def domain-case-base-type
  (poo-flow-case-type-contract
   'domain-case-base-type '() domain-case-test-value?))

(def domain-case-agent-type
  (poo-flow-case-type-contract
   'domain-case-agent-type
   '(domain-case-base-type)
   domain-case-test-value?))

(def domain-case-base-component
  (poo-flow-case-component
   'domain-case-base-component
   1
   (domain-case-test-role 'domain-case-base-slot)
   domain-case-base-type
   '()
   '()
   '()))

(def domain-case-agent-component
  (poo-flow-case-component
   'domain-case-agent-component
   1
   (domain-case-test-role 'domain-case-agent-slot)
   domain-case-agent-type
   '()
   '()
   '()
   '(domain-case-base-component)))

(defpoo-feature domain-case-base-feature
  (feature-id 'domain-case-base-feature)
  (owner-module-id 'feature-system-domain-case-assembly-test)
  (components domain-case-base-component)
  (policy-contributions 'domain-case-base-policy)
  (adapter-requirements 'python-runtime-v1)
  (projections 'runtime-v1))

(defpoo-feature domain-case-agent-feature
  (feature-id 'domain-case-agent-feature)
  (owner-module-id 'feature-system-domain-case-assembly-test)
  (requires domain-case-base-feature)
  (components domain-case-agent-component)
  (policy-contributions 'domain-case-agent-policy)
  (strategy-contributions 'domain-case-agent-strategy)
  (adapter-requirements 'cedar-policy-adapter)
  (projections 'evidence-v1))

(defpoo-feature-manifest-bundle domain-case-feature-bundle
  (bundle-id 'domain-case-feature-bundle)
  (features domain-case-agent-feature domain-case-base-feature))

(defpoo-feature-composition-plan domain-case-composition-plan
  (from-bundle domain-case-feature-bundle))

(def domain-case-feature-cache
  (poo-flow-domain-case-cache))

(defpoo-feature-domain-case-assembly domain-case-feature-assembly
  (using-cache domain-case-feature-cache)
  (domain-case-id 'feature-agent-case)
  (domain-case-version 1)
  (from-plan domain-case-composition-plan))

(def domain-case-feature-cache-hit-assembly
  (feature-domain-case-assembly
   domain-case-feature-cache
   'feature-agent-case
   1
   domain-case-composition-plan))

;; These descriptors deliberately omit the Feature dependency edge.  Their
;; component inheritance is therefore presented child-first and must be rejected
;; by the existing Domain Case closure owner.
(defpoo-feature domain-case-unordered-base-feature
  (feature-id 'domain-case-unordered-base-feature)
  (owner-module-id 'feature-system-domain-case-assembly-test)
  (components domain-case-base-component))

(defpoo-feature domain-case-unordered-agent-feature
  (feature-id 'domain-case-unordered-agent-feature)
  (owner-module-id 'feature-system-domain-case-assembly-test)
  (components domain-case-agent-component))

(defpoo-feature-manifest-bundle domain-case-unordered-bundle
  (bundle-id 'domain-case-unordered-bundle)
  (features domain-case-unordered-agent-feature
            domain-case-unordered-base-feature))

(defpoo-feature-composition-plan domain-case-unordered-plan
  (from-bundle domain-case-unordered-bundle))

(defpoo-feature-domain-case-assembly domain-case-unordered-assembly
  (using-cache domain-case-feature-cache)
  (domain-case-id 'feature-agent-case-unordered)
  (domain-case-version 1)
  (from-plan domain-case-unordered-plan))

(def (domain-case-assembly-diagnostic-codes assembly)
  (poo-flow-map (lambda (diagnostic) (.ref diagnostic 'code))
                (.ref assembly 'diagnostics)))

(def (domain-case-stress-id prefix index)
  (string->symbol
   (string-append prefix (number->string index))))

(def (domain-case-stress-descriptors count)
  (let loop ((index 0)
             (previous-descriptor #f)
             (previous-component-id #f)
             (previous-type-id #f)
             (descriptors []))
    (if (= index count)
      (reverse descriptors)
      (let* ((feature-id
              (domain-case-stress-id "case-feature-" index))
             (component-id
              (domain-case-stress-id "case-component-" index))
             (type-id
              (domain-case-stress-id "case-type-" index))
             (type-contract
              (poo-flow-case-type-contract
               type-id
               (if previous-type-id (list previous-type-id) '())
               domain-case-test-value?))
             (component
              (poo-flow-case-component
               component-id
               1
               (domain-case-test-role
                (domain-case-stress-id "case-slot-" index))
               type-contract
               '()
               '()
               '()
               (if previous-component-id
                 (list previous-component-id)
                 '())))
             (base
              (feature-descriptor-base
               feature-id 'feature-domain-case-stress))
             (components (feature-components component))
             (spec
              (if previous-descriptor
                (feature-spec-compose
                 base
                 (feature-required-features previous-descriptor)
                 components)
                (feature-spec-compose base components)))
             (descriptor (feature-descriptor spec)))
        (loop (+ index 1)
              descriptor
              component-id
              type-id
              (cons descriptor descriptors))))))

(def feature-system-domain-case-assembly-test
  (test-suite "Feature composition to existing Domain Case algebra"
    (test-case "accepted plan closes through the existing Domain Case owner"
      (let ((closure (.ref domain-case-feature-assembly 'closure-receipt))
            (domain-case (.ref domain-case-feature-assembly 'domain-case)))
        (check (.ref domain-case-feature-assembly 'kind)
               => 'feature-domain-case-assembly)
        (check (.ref domain-case-feature-assembly 'status) => 'ready)
        (check (.ref domain-case-feature-assembly 'accepted?) => #t)
        (check (.ref closure 'accepted?) => #t)
        (check (.ref closure 'cache-hit?) => #f)
        (check (.ref domain-case 'kind) => +poo-flow-domain-case-kind+)
        (check (.ref domain-case 'closed?) => #t)
        (check (length (.ref domain-case 'type-contracts)) => 2)
        (check (.ref domain-case-feature-assembly 'components)
               => (list domain-case-base-component
                        domain-case-agent-component))
        (check (.ref domain-case-agent-component 'parent-component-ids)
               => '(domain-case-base-component))))

    (test-case "contract inheritance stays separate from policy and adapters"
      (let ((domain-case (.ref domain-case-feature-assembly 'domain-case)))
        (check (.ref domain-case 'policy-algebra) => #f)
        (check (.ref domain-case 'strategy-algebra) => #f))
      (check (.ref domain-case-feature-assembly 'policy-contributions)
             => '(domain-case-base-policy domain-case-agent-policy))
      (check (.ref domain-case-feature-assembly 'strategy-contributions)
             => '(domain-case-agent-strategy))
      (check (.ref domain-case-feature-assembly 'adapter-requirements)
             => '(python-runtime-v1 cedar-policy-adapter))
      (check (.ref domain-case-feature-assembly 'projections)
             => '(runtime-v1 evidence-v1)))

    (test-case "module-owned Domain Case cache reuses the closure"
      (let ((first-domain-case
             (.ref domain-case-feature-assembly 'domain-case))
            (second-domain-case
             (.ref domain-case-feature-cache-hit-assembly 'domain-case))
            (second-closure
             (.ref domain-case-feature-cache-hit-assembly 'closure-receipt)))
        (check (.ref second-closure 'cache-hit?) => #t)
        (check (eq? first-domain-case second-domain-case) => #t)
        (check (.ref domain-case-feature-cache-hit-assembly 'key)
               => (.ref domain-case-feature-assembly 'key))))

    (test-case "missing Feature dependency leaves inheritance child-first"
      (check (.ref domain-case-unordered-assembly 'status) => 'rejected)
      (check (.ref domain-case-unordered-assembly 'accepted?) => #f)
      (check (.ref domain-case-unordered-assembly 'domain-case) => #f)
      (check (memq 'missing-or-forward-parent-component
                   (domain-case-assembly-diagnostic-codes
                    domain-case-unordered-assembly))
             ? values)
      (check (memq 'missing-or-forward-parent-type
                   (domain-case-assembly-diagnostic-codes
                    domain-case-unordered-assembly))
             ? values))

    (test-case "256-Feature inheritance chain closes under the memory guard"
      (let* ((descriptors (domain-case-stress-descriptors 256))
             (bundle (feature-manifest-bundle
                      'feature-domain-case-stress descriptors))
             (plan (feature-composition-plan bundle))
             (assembly
              (feature-domain-case-assembly
               (poo-flow-domain-case-cache)
               'feature-domain-case-stress
               1
               plan))
             (domain-case (.ref assembly 'domain-case))
             (components (.ref assembly 'components)))
        (check (.ref assembly 'status) => 'ready)
        (check (.ref assembly 'accepted?) => #t)
        (check (length components) => 256)
        (check (.ref (car components) 'component-id)
               => 'case-component-0)
        (check (.ref (car (reverse components)) 'component-id)
               => 'case-component-255)
        (check (.ref domain-case 'closed?) => #t)
        (check (length (.ref domain-case 'type-contracts)) => 256)))))
