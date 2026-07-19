(import :std/test
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/interface
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export feature-system-policy-strategy-binding-test)

(def (binding-test-role slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (binding-test-value? value) #t)

(def binding-base-type
  (poo-flow-case-type-contract
   'binding-base-type '() binding-test-value?))

(def binding-agent-type
  (poo-flow-case-type-contract
   'binding-agent-type '(binding-base-type) binding-test-value?))

(def binding-base-component
  (poo-flow-case-component
   'binding-base-component
   1
   (binding-test-role '((binding-base-role . #t)))
   binding-base-type
   '()
   '()
   '()
   '()
   'agent-policy-algebra
   'agent-strategy-algebra))

(def binding-agent-component
  (poo-flow-case-component
   'binding-agent-component
   1
   (binding-test-role '((binding-agent-role . #t)))
   binding-agent-type
   '()
   '()
   '()
   '(binding-base-component)
   'agent-policy-algebra
   'agent-strategy-algebra))

(defpoo-feature-policy-contribution binding-base-policy-contribution
  (contribution-id 'binding-base-policy)
  (algebra-id 'agent-policy-algebra)
  (prototype
   (binding-test-role
    '((policy-decision . base)
      (binding-base-policy . #t)))))

(defpoo-feature-policy-contribution binding-agent-policy-contribution
  (contribution-id 'binding-agent-policy)
  (algebra-id 'agent-policy-algebra)
  (prototype
   (binding-test-role
    '((policy-decision . agent)
      (binding-agent-policy . #t)))))

(defpoo-feature-strategy-contribution binding-base-strategy-contribution
  (contribution-id 'binding-base-strategy)
  (algebra-id 'agent-strategy-algebra)
  (prototype
   (binding-test-role
    '((strategy-decision . base)
      (binding-base-strategy . #t)))))

(defpoo-feature-strategy-contribution binding-agent-strategy-contribution
  (contribution-id 'binding-agent-strategy)
  (algebra-id 'agent-strategy-algebra)
  (prototype
   (binding-test-role
    '((strategy-decision . agent)
      (binding-agent-strategy . #t)))))

(defpoo-feature binding-base-feature
  (feature-id 'binding-base-feature)
  (owner-module-id 'feature-system-policy-strategy-binding-test)
  (components binding-base-component)
  (policy-contributions binding-base-policy-contribution)
  (strategy-contributions binding-base-strategy-contribution))

(defpoo-feature binding-agent-feature
  (feature-id 'binding-agent-feature)
  (owner-module-id 'feature-system-policy-strategy-binding-test)
  (requires binding-base-feature)
  (components binding-agent-component)
  (policy-contributions binding-agent-policy-contribution)
  (strategy-contributions binding-agent-strategy-contribution))

(defpoo-feature-manifest-bundle binding-feature-bundle
  (bundle-id 'binding-feature-bundle)
  (features binding-agent-feature binding-base-feature))

(defpoo-feature-composition-plan binding-composition-plan
  (from-bundle binding-feature-bundle))

(def binding-domain-case-cache (poo-flow-domain-case-cache))

(defpoo-feature-domain-case-assembly binding-domain-case-assembly
  (using-cache binding-domain-case-cache)
  (domain-case-id 'binding-agent-case)
  (domain-case-version 1)
  (from-plan binding-composition-plan))

(defpoo-feature-policy-strategy-binding binding-ready
  (from-assembly binding-domain-case-assembly))

(def (binding-test-assembly domain-case policy-contributions
                            strategy-contributions)
  (let ((object (make-object)))
    (object-slots-set!
     object
     (role-constant-slots
      `((kind . feature-domain-case-assembly)
        (accepted? . #t)
        (domain-case . ,domain-case)
        (policy-contributions . ,policy-contributions)
        (strategy-contributions . ,strategy-contributions))))
    object))

(def binding-wrong-policy-contribution
  (feature-policy-contribution
   'binding-wrong-policy
   'other-policy-algebra
   (binding-test-role '((binding-wrong-policy . #t)))))

(def binding-invalid-prototype-contribution
  (feature-policy-contribution
   'binding-invalid-prototype
   'agent-policy-algebra
   'not-a-role-prototype))

(def binding-duplicate-policy-contribution-a
  (feature-policy-contribution
   (string-append "binding-duplicate-" "policy")
   'agent-policy-algebra
   (binding-test-role '((binding-duplicate-policy-a . #t)))))

(def binding-duplicate-policy-contribution-b
  (feature-policy-contribution
   (string-append "binding" "-duplicate-policy")
   'agent-policy-algebra
   (binding-test-role '((binding-duplicate-policy-b . #t)))))

(def binding-domain-case
  (.ref binding-domain-case-assembly 'domain-case))

(def binding-raw-policy-rejected
  (feature-policy-strategy-binding
   (binding-test-assembly
    binding-domain-case '(raw-policy-contribution) '())))

(def binding-mismatch-rejected
  (feature-policy-strategy-binding
   (binding-test-assembly
    binding-domain-case (list binding-wrong-policy-contribution) '())))

(def binding-duplicate-rejected
  (feature-policy-strategy-binding
   (binding-test-assembly
    binding-domain-case
    (list binding-duplicate-policy-contribution-a
          binding-duplicate-policy-contribution-b)
    '())))

(def binding-composition-rejected
  (feature-policy-strategy-binding
   (binding-test-assembly
    binding-domain-case (list binding-invalid-prototype-contribution) '())))

(def binding-no-algebra-component
  (poo-flow-case-component
   'binding-no-algebra-component
   1
   (binding-test-role '((binding-no-algebra-role . #t)))
   (poo-flow-case-type-contract
    'binding-no-algebra-type '() binding-test-value?)
   '()
   '()
   '()))

(defpoo-feature binding-no-algebra-feature
  (feature-id 'binding-no-algebra-feature)
  (owner-module-id 'feature-system-policy-strategy-binding-test)
  (components binding-no-algebra-component)
  (policy-contributions binding-base-policy-contribution))

(defpoo-feature-manifest-bundle binding-no-algebra-bundle
  (bundle-id 'binding-no-algebra-bundle)
  (features binding-no-algebra-feature))

(defpoo-feature-composition-plan binding-no-algebra-plan
  (from-bundle binding-no-algebra-bundle))

(defpoo-feature-domain-case-assembly binding-no-algebra-assembly
  (using-cache binding-domain-case-cache)
  (domain-case-id 'binding-no-algebra-case)
  (domain-case-version 1)
  (from-plan binding-no-algebra-plan))

(defpoo-feature-policy-strategy-binding binding-no-algebra-rejected
  (from-assembly binding-no-algebra-assembly))

(defpoo-feature binding-invalid-component-feature
  (feature-id 'binding-invalid-component-feature)
  (owner-module-id 'feature-system-policy-strategy-binding-test)
  (components 'not-a-case-component))

(defpoo-feature-manifest-bundle binding-invalid-component-bundle
  (bundle-id 'binding-invalid-component-bundle)
  (features binding-invalid-component-feature))

(defpoo-feature-composition-plan binding-invalid-component-plan
  (from-bundle binding-invalid-component-bundle))

(defpoo-feature-domain-case-assembly binding-invalid-component-assembly
  (using-cache binding-domain-case-cache)
  (domain-case-id 'binding-invalid-component-case)
  (domain-case-version 1)
  (from-plan binding-invalid-component-plan))

(defpoo-feature-policy-strategy-binding binding-invalid-assembly-rejected
  (from-assembly binding-invalid-component-assembly))

(def (binding-diagnostic-codes binding)
  (poo-flow-map
   (lambda (diagnostic) (.ref diagnostic 'code))
   (.ref binding 'diagnostics)))

(def (binding-stress-id prefix index)
  (string->symbol (string-append prefix (number->string index))))

(def (binding-stress-descriptors count)
  (let loop ((index 0)
             (previous-descriptor #f)
             (descriptors []))
    (if (= index count)
      (reverse descriptors)
      (let* ((feature-id (binding-stress-id "binding-feature-" index))
             (contribution-id
              (binding-stress-id "binding-contribution-" index))
             (slot-id (binding-stress-id "binding-slot-" index))
             (contribution
              (feature-policy-contribution
               contribution-id
               'agent-policy-algebra
               (binding-test-role (list (cons slot-id index)))))
             (base
              (feature-descriptor-base
               feature-id 'feature-policy-strategy-binding-stress))
             (policy-contributions
              (feature-policy-contributions contribution))
             (spec
              (cond
               ((and (zero? index) previous-descriptor)
                (error "unreachable binding stress state"))
               ((zero? index)
                (feature-spec-compose
                 base
                 (feature-components binding-base-component)
                 policy-contributions))
               (else
                (feature-spec-compose
                 base
                 (feature-required-features previous-descriptor)
                 policy-contributions))))
             (descriptor (feature-descriptor spec)))
        (loop (+ index 1)
              descriptor
              (cons descriptor descriptors))))))

(def feature-system-policy-strategy-binding-test
  (test-suite "Feature policy/strategy algebra binding"
    (test-case "accepted assembly binds ordered POO role contributions"
      (let* ((policy-binding (.ref binding-ready 'policy-binding))
             (strategy-binding (.ref binding-ready 'strategy-binding))
             (policy-prototype (.ref policy-binding 'prototype))
             (strategy-prototype (.ref strategy-binding 'prototype)))
        (check (.ref binding-ready 'kind)
               => 'feature-policy-strategy-binding)
        (check (.ref binding-ready 'status) => 'ready)
        (check (.ref binding-ready 'accepted?) => #t)
        (check (feature-policy-contribution?
                binding-base-policy-contribution)
               => #t)
        (check (feature-strategy-contribution?
                binding-base-strategy-contribution)
               => #t)
        (check (feature-strategy-contribution?
                binding-base-policy-contribution)
               => #f)
        (check (.ref policy-binding 'algebra-id)
               => 'agent-policy-algebra)
        (check (.ref strategy-binding 'algebra-id)
               => 'agent-strategy-algebra)
        (check (.ref policy-binding 'contribution-count) => 2)
        (check (.ref strategy-binding 'contribution-count) => 2)
        (check (.ref policy-prototype 'policy-decision) => 'agent)
        (check (.ref policy-prototype 'binding-base-policy) => #t)
        (check (.ref policy-prototype 'binding-agent-policy) => #t)
        (check (.ref strategy-prototype 'strategy-decision) => 'agent)
        (check (.ref strategy-prototype 'binding-base-strategy) => #t)
        (check (.ref strategy-prototype 'binding-agent-strategy) => #t)))

    (test-case "invalid contribution shapes and algebra conflicts reject"
      (check (.ref binding-raw-policy-rejected 'status) => 'rejected)
      (check (memq 'invalid-policy-contribution
                   (binding-diagnostic-codes binding-raw-policy-rejected))
             ? values)
      (check (memq 'policy-algebra-mismatch
                   (binding-diagnostic-codes binding-mismatch-rejected))
             ? values)
      (check (memq 'duplicate-policy-contribution-id
                   (binding-diagnostic-codes binding-duplicate-rejected))
             ? values)
      (check (memq 'invalid-policy-contribution
                   (binding-diagnostic-codes binding-composition-rejected))
             ? values))

    (test-case "contributions require an algebra declared by the Domain Case"
      (check (.ref binding-no-algebra-assembly 'accepted?) => #t)
      (check (.ref binding-no-algebra-rejected 'accepted?) => #f)
      (check (memq 'missing-policy-algebra
                   (binding-diagnostic-codes binding-no-algebra-rejected))
             ? values))

    (test-case "a rejected Domain Case assembly cannot reach binding"
      (check (.ref binding-invalid-component-assembly 'accepted?) => #f)
      (check (.ref binding-invalid-assembly-rejected 'accepted?) => #f)
      (check (.ref binding-invalid-assembly-rejected 'policy-binding) => #f)
      (check (memq 'domain-case-assembly-rejected
                   (binding-diagnostic-codes
                    binding-invalid-assembly-rejected))
             ? values))

    (test-case "256 Feature contributions bind in resolver order"
      (let* ((descriptors (binding-stress-descriptors 256))
             (bundle
              (feature-manifest-bundle
               'feature-policy-strategy-binding-stress descriptors))
             (plan (feature-composition-plan bundle))
             (assembly
              (feature-domain-case-assembly
               (poo-flow-domain-case-cache)
               'feature-policy-strategy-binding-stress
               1
               plan))
             (binding (feature-policy-strategy-binding assembly))
             (policy-binding (.ref binding 'policy-binding))
             (prototype (.ref policy-binding 'prototype)))
        (check (.ref assembly 'accepted?) => #t)
        (check (.ref binding 'accepted?) => #t)
        (check (.ref policy-binding 'contribution-count) => 256)
        (check (.ref prototype 'binding-slot-0) => 0)
        (check (.ref prototype 'binding-slot-255) => 255)))))
