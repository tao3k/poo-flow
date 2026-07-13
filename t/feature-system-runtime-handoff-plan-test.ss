(import :std/test
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/interface
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export feature-system-runtime-handoff-plan-test)

(def runtime-handoff-projector-calls (vector 0))

(def (runtime-handoff-test-project value)
  (vector-set!
   runtime-handoff-projector-calls
   0
   (+ 1 (vector-ref runtime-handoff-projector-calls 0)))
  value)

(def (runtime-handoff-test-role)
  (let ((object (make-object)))
    (object-slots-set!
     object
     (role-constant-slots '((runtime-handoff-test-role . #t))))
    object))

(def (runtime-handoff-test-value? value) #t)

(def runtime-bundle-projection
  (poo-flow-case-projection
   'runtime-bundle-projection
   'runtime-handoff-component
   'runtime-bundle-schema-v1
   runtime-handoff-test-project))

(def cedar-input-projection
  (poo-flow-case-projection
   'cedar-input-projection
   'runtime-handoff-component
   'cedar-input-schema-v1
   runtime-handoff-test-project))

(def evidence-obligation-projection
  (poo-flow-case-projection
   'evidence-obligation-projection
   'runtime-handoff-component
   'lean-evidence-schema-v1
   runtime-handoff-test-project))

(def runtime-handoff-component
  (poo-flow-case-component
   'runtime-handoff-component
   1
   (runtime-handoff-test-role)
   (poo-flow-case-type-contract
    'runtime-handoff-type '() runtime-handoff-test-value?)
   '()
   '()
   (list runtime-bundle-projection
         cedar-input-projection
         evidence-obligation-projection)))

(defpoo-feature-adapter-capability runtime-bundle-capability
  (capability-id 'runtime-bundle-capability)
  (provider-module-id 'poo-flow/python-runtime-cffi)
  (contract-id 'poo-flow.runtime-c.bundle)
  (contract-version +feature-runtime-c-bundle-version+))

(defpoo-feature-adapter-capability cedar-input-capability
  (capability-id 'cedar-input-capability)
  (provider-module-id 'poo-flow/cedar-adapter)
  (contract-id 'poo-flow.cedar-input)
  (contract-version 1))

(defpoo-feature-adapter-capability lean-evidence-capability
  (capability-id 'lean-evidence-capability)
  (provider-module-id 'poo-flow/lean-evidence-adapter)
  (contract-id 'poo-flow.lean-evidence)
  (contract-version 1))

(defpoo-feature-adapter-requirement runtime-bundle-requirement
  (requirement-id 'runtime-bundle-requirement)
  (capability-id 'runtime-bundle-capability)
  (contract-id 'poo-flow.runtime-c.bundle)
  (contract-version +feature-runtime-c-bundle-version+))

(defpoo-feature-adapter-requirement cedar-input-requirement
  (requirement-id 'cedar-input-requirement)
  (capability-id 'cedar-input-capability)
  (contract-id 'poo-flow.cedar-input)
  (contract-version 1))

(defpoo-feature-adapter-requirement lean-evidence-requirement
  (requirement-id 'lean-evidence-requirement)
  (capability-id 'lean-evidence-capability)
  (contract-id 'poo-flow.lean-evidence)
  (contract-version 1))

(defpoo-feature-projection-request runtime-bundle-request
  (request-id 'runtime-bundle-request)
  (projection-id 'runtime-bundle-projection)
  (schema-id 'runtime-bundle-schema-v1))

(defpoo-feature-projection-request cedar-input-request
  (request-id 'cedar-input-request)
  (projection-id 'cedar-input-projection)
  (schema-id 'cedar-input-schema-v1))

(defpoo-feature-projection-request evidence-obligation-request
  (request-id 'evidence-obligation-request)
  (projection-id 'evidence-obligation-projection)
  (schema-id 'lean-evidence-schema-v1))

(defpoo-feature runtime-handoff-feature
  (feature-id 'runtime-handoff-feature)
  (owner-module-id 'feature-system-runtime-handoff-plan-test)
  (components runtime-handoff-component)
  (adapter-requirements
   runtime-bundle-requirement
   cedar-input-requirement
   lean-evidence-requirement)
  (projections
   runtime-bundle-request
   cedar-input-request
   evidence-obligation-request))

(defpoo-feature-manifest-bundle runtime-handoff-feature-bundle
  (bundle-id 'runtime-handoff-feature-bundle)
  (features runtime-handoff-feature))

(defpoo-feature-composition-plan runtime-handoff-composition-plan
  (from-bundle runtime-handoff-feature-bundle))

(defpoo-feature-domain-case-assembly runtime-handoff-assembly
  (using-cache (poo-flow-domain-case-cache))
  (domain-case-id 'runtime-handoff-case)
  (domain-case-version 1)
  (from-plan runtime-handoff-composition-plan))

(defpoo-feature-policy-strategy-binding runtime-handoff-policy-binding
  (from-assembly runtime-handoff-assembly))

(defpoo-feature-adapter-capability-catalog runtime-handoff-capability-catalog
  (catalog-id 'runtime-handoff-capability-catalog)
  (capabilities
   runtime-bundle-capability
   cedar-input-capability
   lean-evidence-capability))

(defpoo-feature-adapter-projection-binding runtime-handoff-adapter-binding
  (using-catalog runtime-handoff-capability-catalog)
  (from-binding runtime-handoff-policy-binding))

(defpoo-feature-runtime-bundle-handoff runtime-bundle-handoff
  (handoff-id 'runtime-bundle-handoff)
  (adapter-requirement-id 'runtime-bundle-requirement)
  (projection-request-id 'runtime-bundle-request)
  (bundle-contract-id 'poo-flow.runtime-c.bundle)
  (bundle-version +feature-runtime-c-bundle-version+)
  (schema-id 'runtime-bundle-schema-v1))

(defpoo-feature-cedar-input-handoff cedar-policy-input-handoff
  (handoff-id 'cedar-policy-input-handoff)
  (adapter-requirement-id 'cedar-input-requirement)
  (projection-request-id 'cedar-input-request)
  (input-contract-id 'poo-flow.cedar-input)
  (input-contract-version 1)
  (schema-id 'cedar-input-schema-v1))

(defpoo-feature-evidence-obligation lean-evidence-obligation
  (handoff-id 'lean-evidence-obligation)
  (adapter-requirement-id 'lean-evidence-requirement)
  (projection-request-id 'evidence-obligation-request)
  (evidence-contract-id 'poo-flow.lean-evidence)
  (evidence-contract-version 1)
  (schema-id 'lean-evidence-schema-v1))

(defpoo-feature-runtime-handoff-manifest runtime-handoff-manifest
  (manifest-id 'runtime-handoff-manifest)
  (handoffs
   runtime-bundle-handoff
   cedar-policy-input-handoff
   lean-evidence-obligation))

(defpoo-feature-runtime-handoff-plan runtime-handoff-ready-plan
  (from-binding runtime-handoff-adapter-binding)
  (using-manifest runtime-handoff-manifest))

(def duplicate-runtime-handoff-a
  (feature-runtime-bundle-handoff
   (string-append "duplicate-" "handoff")
   'runtime-bundle-requirement
   'runtime-bundle-request
   'poo-flow.runtime-c.bundle
   1
   'runtime-bundle-schema-v1))

(def duplicate-runtime-handoff-b
  (feature-runtime-bundle-handoff
   (string-append "duplicate" "-handoff")
   'runtime-bundle-requirement
   'runtime-bundle-request
   'poo-flow.runtime-c.bundle
   1
   'runtime-bundle-schema-v1))

(def invalid-runtime-handoff-manifest
  (feature-runtime-handoff-manifest
   'invalid-runtime-handoff-manifest
   '(raw-runtime-handoff)))

(def duplicate-runtime-handoff-manifest
  (feature-runtime-handoff-manifest
   'duplicate-runtime-handoff-manifest
   (list duplicate-runtime-handoff-a duplicate-runtime-handoff-b)))

(def missing-runtime-handoff
  (feature-runtime-bundle-handoff
   'missing-runtime-handoff
   'missing-adapter-requirement
   'missing-projection-request
   'poo-flow.runtime-c.bundle
   1
   'runtime-bundle-schema-v1))

(def mismatched-contract-handoff
  (feature-runtime-bundle-handoff
   'mismatched-contract-handoff
   'runtime-bundle-requirement
   'runtime-bundle-request
   'poo-flow.runtime-c.bundle
   2
   'runtime-bundle-schema-v1))

(def mismatched-schema-handoff
  (feature-runtime-bundle-handoff
   'mismatched-schema-handoff
   'runtime-bundle-requirement
   'runtime-bundle-request
   'poo-flow.runtime-c.bundle
   1
   'runtime-bundle-schema-v2))

(def missing-runtime-handoff-plan
  (feature-runtime-handoff-plan
   runtime-handoff-adapter-binding
   (feature-runtime-handoff-manifest
    'missing-runtime-handoff-manifest
    (list missing-runtime-handoff))))

(def mismatched-contract-plan
  (feature-runtime-handoff-plan
   runtime-handoff-adapter-binding
   (feature-runtime-handoff-manifest
    'mismatched-contract-manifest
    (list mismatched-contract-handoff))))

(def mismatched-schema-plan
  (feature-runtime-handoff-plan
   runtime-handoff-adapter-binding
   (feature-runtime-handoff-manifest
    'mismatched-schema-manifest
    (list mismatched-schema-handoff))))

(def rejected-runtime-handoff-upstream-binding
  (feature-adapter-projection-binding
   runtime-handoff-capability-catalog
   (feature-policy-strategy-binding 'invalid-assembly)))

(def rejected-runtime-handoff-upstream-plan
  (feature-runtime-handoff-plan
   rejected-runtime-handoff-upstream-binding
   runtime-handoff-manifest))

(def rejected-runtime-handoff-manifest-plan
  (feature-runtime-handoff-plan
   runtime-handoff-adapter-binding
   duplicate-runtime-handoff-manifest))

(def (runtime-handoff-diagnostic-codes value)
  (poo-flow-map
   (lambda (diagnostic) (.ref diagnostic 'code))
   (.ref value 'diagnostics)))

(def (runtime-handoff-stress-id index)
  (string->symbol
   (string-append "runtime-handoff-stress-" (number->string index))))

(def (runtime-handoff-stress-values count)
  (let loop ((index 0) (handoffs []))
    (if (= index count)
      (reverse handoffs)
      (loop
       (+ index 1)
       (cons
        (feature-runtime-bundle-handoff
         (runtime-handoff-stress-id index)
         'runtime-bundle-requirement
         'runtime-bundle-request
         'poo-flow.runtime-c.bundle
         +feature-runtime-c-bundle-version+
         'runtime-bundle-schema-v1)
        handoffs)))))

(def feature-system-runtime-handoff-plan-test
  (test-suite "Feature runtime handoff planning"
    (test-case "Bundle v1, Cedar and Evidence resolve as native POO references"
      (let ((resolved (.ref runtime-handoff-ready-plan 'resolved-handoffs)))
        (check +feature-runtime-c-bundle-version+ => 1)
        (check (.ref runtime-handoff-adapter-binding 'accepted?) => #t)
        (check (.ref runtime-handoff-manifest 'accepted?) => #t)
        (check (.ref runtime-handoff-ready-plan 'kind)
               => 'feature-runtime-handoff-plan)
        (check (.ref runtime-handoff-ready-plan 'status) => 'ready)
        (check (.ref runtime-handoff-ready-plan 'accepted?) => #t)
        (check (length resolved) => 3)
        (check (poo-flow-map
                (lambda (handoff) (.ref handoff 'handoff-id))
                resolved)
               => '(runtime-bundle-handoff
                    cedar-policy-input-handoff
                    lean-evidence-obligation))
        (check (poo-flow-map
                (lambda (handoff) (.ref handoff 'provider-module-id))
                resolved)
               => '(poo-flow/python-runtime-cffi
                    poo-flow/cedar-adapter
                    poo-flow/lean-evidence-adapter))
        (check (.ref (car resolved) 'contract-version) => 1)
        (check (.ref (cadr resolved) 'projection-schema-id)
               => 'cedar-input-schema-v1)
        (check (eq? (.ref (car resolved) 'adapter-binding)
                    (car (.ref runtime-handoff-adapter-binding
                               'adapter-bindings)))
               => #t)
        (check (eq? (.ref (car resolved) 'projection-binding)
                    (car (.ref runtime-handoff-adapter-binding
                               'projection-bindings)))
               => #t)
        (check (vector-ref runtime-handoff-projector-calls 0) => 0)))

    (test-case "manifest rejects raw and semantic duplicate declarations"
      (check (.ref invalid-runtime-handoff-manifest 'accepted?) => #f)
      (check (memq 'invalid-runtime-handoff
                   (runtime-handoff-diagnostic-codes
                    invalid-runtime-handoff-manifest))
             ? values)
      (check (.ref duplicate-runtime-handoff-manifest 'accepted?) => #f)
      (check (.ref duplicate-runtime-handoff-manifest 'handoff-index) => #f)
      (check (memq 'duplicate-runtime-handoff-id
                   (runtime-handoff-diagnostic-codes
                    duplicate-runtime-handoff-manifest))
             ? values))

    (test-case "missing bindings, contract mismatch and schema mismatch stay distinct"
      (check (.ref missing-runtime-handoff-plan 'accepted?) => #f)
      (check (memq 'missing-handoff-adapter-requirement
                   (runtime-handoff-diagnostic-codes
                    missing-runtime-handoff-plan))
             ? values)
      (check (memq 'missing-handoff-projection-request
                   (runtime-handoff-diagnostic-codes
                    missing-runtime-handoff-plan))
             ? values)
      (check (memq 'runtime-handoff-contract-mismatch
                   (runtime-handoff-diagnostic-codes
                    mismatched-contract-plan))
             ? values)
      (check (memq 'runtime-handoff-schema-mismatch
                   (runtime-handoff-diagnostic-codes
                    mismatched-schema-plan))
             ? values)
      (check (vector-ref runtime-handoff-projector-calls 0) => 0))

    (test-case "rejected upstream binding or manifest stops handoff planning"
      (check (.ref rejected-runtime-handoff-upstream-plan 'accepted?) => #f)
      (check (memq 'feature-adapter-projection-binding-rejected
                   (runtime-handoff-diagnostic-codes
                    rejected-runtime-handoff-upstream-plan))
             ? values)
      (check (.ref rejected-runtime-handoff-manifest-plan 'accepted?) => #f)
      (check (memq 'feature-runtime-handoff-manifest-rejected
                   (runtime-handoff-diagnostic-codes
                    rejected-runtime-handoff-manifest-plan))
             ? values))

    (test-case "1024 handoffs resolve through indexed native bindings"
      (let* ((handoffs (runtime-handoff-stress-values 1024))
             (manifest
              (feature-runtime-handoff-manifest
               'runtime-handoff-stress-manifest handoffs))
             (plan
              (feature-runtime-handoff-plan
               runtime-handoff-adapter-binding manifest))
             (resolved (.ref plan 'resolved-handoffs)))
        (check (.ref manifest 'accepted?) => #t)
        (check (.ref plan 'accepted?) => #t)
        (check (length resolved) => 1024)
        (check (.ref (car resolved) 'handoff-id)
               => 'runtime-handoff-stress-0)
        (check (.ref (car (reverse resolved)) 'handoff-id)
               => 'runtime-handoff-stress-1023)
        (check (vector-ref runtime-handoff-projector-calls 0) => 0)))))
