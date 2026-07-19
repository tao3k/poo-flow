(import :std/test
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/interface
        :poo-flow/src/utilities/functional)

(export feature-system-composition-test)

(def (composition-test-component component-id)
  (let ((object (make-object)))
    (object-slots-set!
     object
     (role-constant-slots
      `((kind . feature-test-component)
        (component-id . ,component-id))))
    object))

(def composition-base-component
  (composition-test-component 'composition-base-component))

(def composition-agent-component
  (composition-test-component 'composition-agent-component))

(defpoo-feature composition-base-feature
  (feature-id 'composition-base)
  (owner-module-id 'feature-system-composition-test)
  (components composition-base-component)
  (policy-contributions 'composition-base-policy-a
                        'composition-base-policy-b)
  (strategy-contributions 'composition-base-strategy)
  (adapter-requirements 'python-runtime-v1)
  (projections 'runtime-v1))

(defpoo-feature composition-agent-feature
  (feature-id 'composition-agent)
  (owner-module-id 'feature-system-composition-test)
  (requires composition-base-feature)
  (components composition-agent-component)
  (policy-contributions 'composition-agent-policy)
  (strategy-contributions 'composition-agent-strategy-a
                          'composition-agent-strategy-b)
  (adapter-requirements 'cedar-policy-adapter)
  (projections 'evidence-v1))

;; Declaration order is intentionally the reverse of dependency order.
(defpoo-feature-manifest-bundle composition-bundle
  (bundle-id 'composition-bundle)
  (features composition-agent-feature composition-base-feature))

(defpoo-feature-composition-plan composition-plan
  (from-bundle composition-bundle))

(defpoo-feature-manifest-bundle composition-empty-bundle
  (bundle-id 'composition-empty-bundle)
  (features))

(defpoo-feature-composition-plan composition-empty-plan
  (from-bundle composition-empty-bundle))

(def (composition-manifest-feature-ids plan)
  (poo-flow-map (lambda (manifest) (.ref manifest 'feature-id))
                (.ref plan 'manifests)))

(def (composition-stress-id prefix index)
  (string->symbol
   (string-append prefix (number->string index))))

(def (composition-stress-descriptors count)
  (let loop ((index 0)
             (previous #f)
             (descriptors []))
    (if (= index count)
      (reverse descriptors)
      (let* ((feature-id
              (composition-stress-id "composition-feature-" index))
             (base
              (feature-descriptor-base
               feature-id 'feature-system-composition-stress))
             (components
              (feature-components
               (composition-stress-id "component-" index)))
             (policies
              (feature-policy-contributions
               (composition-stress-id "policy-" index)))
             (strategies
              (feature-strategy-contributions
               (composition-stress-id "strategy-" index)))
             (adapters
              (feature-adapter-requirements
               (composition-stress-id "adapter-" index)))
             (projections
              (feature-projections
               (composition-stress-id "projection-" index)))
             (spec
              (if previous
                (feature-spec-compose
                 base
                 (feature-required-features previous)
                 components
                 policies
                 strategies
                 adapters
                 projections)
                (feature-spec-compose
                 base
                 components
                 policies
                 strategies
                 adapters
                 projections)))
             (descriptor (feature-descriptor spec)))
        (loop (+ index 1)
              descriptor
              (cons descriptor descriptors))))))

(def feature-system-composition-test
  (test-suite "POO-native Feature composition plan"
    (test-case "composition follows resolver order, not declaration order"
      (check (.ref composition-plan 'kind) => 'feature-composition-plan)
      (check (.ref composition-plan 'schema-version) => 1)
      (check (.ref composition-plan 'bundle-id) => 'composition-bundle)
      (check (.ref composition-plan 'status) => 'ready)
      (check (.ref composition-plan 'accepted?) => #t)
      (check (eq? (.ref composition-plan 'bundle) composition-bundle) => #t)
      (check (.ref composition-plan 'feature-ids)
             => '(composition-base composition-agent))
      (check (composition-manifest-feature-ids composition-plan)
             => '(composition-base composition-agent)))

    (test-case "composition preserves POO values and contribution order"
      (let ((components (.ref composition-plan 'components)))
        (check (length components) => 2)
        (check (eq? (car components) composition-base-component) => #t)
        (check (eq? (cadr components) composition-agent-component) => #t))
      (check (.ref composition-plan 'policy-contributions)
             => '(composition-base-policy-a
                  composition-base-policy-b
                  composition-agent-policy))
      (check (.ref composition-plan 'strategy-contributions)
             => '(composition-base-strategy
                  composition-agent-strategy-a
                  composition-agent-strategy-b))
      (check (.ref composition-plan 'adapter-requirements)
             => '(python-runtime-v1 cedar-policy-adapter))
      (check (.ref composition-plan 'projections)
             => '(runtime-v1 evidence-v1)))

    (test-case "empty bundle produces the identity composition"
      (check (.ref composition-empty-plan 'feature-ids) => '())
      (check (.ref composition-empty-plan 'manifests) => '())
      (check (.ref composition-empty-plan 'components) => '())
      (check (.ref composition-empty-plan 'policy-contributions) => '())
      (check (.ref composition-empty-plan 'strategy-contributions) => '())
      (check (.ref composition-empty-plan 'adapter-requirements) => '())
      (check (.ref composition-empty-plan 'projections) => '()))

    (test-case "1024-Feature composition remains ordered and linear"
      (let* ((descriptors (composition-stress-descriptors 1024))
             (bundle (feature-manifest-bundle
                      'composition-stress-bundle descriptors))
             (plan (feature-composition-plan bundle)))
        (check (.ref plan 'status) => 'ready)
        (check (length (.ref plan 'feature-ids)) => 1024)
        (check (length (.ref plan 'manifests)) => 1024)
        (check (length (.ref plan 'components)) => 1024)
        (check (length (.ref plan 'policy-contributions)) => 1024)
        (check (length (.ref plan 'strategy-contributions)) => 1024)
        (check (length (.ref plan 'adapter-requirements)) => 1024)
        (check (length (.ref plan 'projections)) => 1024)
        (check (car (.ref plan 'components)) => 'component-0)
        (check (car (reverse (.ref plan 'components)))
               => 'component-1023)))))
