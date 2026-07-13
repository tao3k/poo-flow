(import :std/test
        :gslph/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/core/object-syntax
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/module-system/domain-case-syntax)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def (slot/default value slot default)
  (with-catch (lambda (_failure) default)
              (lambda () (.ref value slot))))

(def versioned-role
  (poo-core-role-object
   (slots ((qualification/versioned? #t)))
   (supers)))

(def revision-bound-role
  (poo-core-role-object
   (slots ((qualification/revision-bound? #t)))
   (supers)))

(def policy-role
  (poo-core-role-object
   (slots ((qualification/policy? #t)))
   (supers)))

(def versioned-type
  (poo-flow-case-type-contract
   'Versioned '()
   (lambda (value)
     (and (slot/default value 'qualification/versioned? #f)
          (symbol? (slot/default value 'schema-id #f))
          (let (version (slot/default value 'schema-version #f))
            (and (exact-integer? version) (> version 0)))))))

(def revision-type
  (poo-flow-case-type-contract
   'RevisionBound '()
   (lambda (value)
     (and (slot/default value 'qualification/revision-bound? #f)
          (let (revision (slot/default value 'source-revision #f))
            (and (string? revision) (> (string-length revision) 0)))))))

(def policy-type
  (poo-flow-case-type-contract
   'Policy '()
   (lambda (value) (slot/default value 'qualification/policy? #f))))

(def schema-id-slot
  (poo-flow-case-slot-contract
   'schema-id 'versioned 'symbol 'required 'replace '() #f symbol?))

(def schema-version-slot
  (poo-flow-case-slot-contract
   'schema-version 'versioned 'positive-integer 'required 'replace '() #f
   (lambda (value) (and (exact-integer? value) (> value 0)))))

(def revision-slot
  (poo-flow-case-slot-contract
   'source-revision 'revision-bound 'nonempty-string 'required 'replace '() #f
   (lambda (value) (and (string? value) (> (string-length value) 0)))))

(def versioned-contract
  (poo-flow-case-method-contract
   'versioned-state 'versioned 'versioned-state 'state 'Versioned
   'versioned-input 'versioned-output
   (lambda (value)
     (equal? (slot/default value 'schema-id #f) 'agent.case.v1))))

(def revision-contract
  (poo-flow-case-method-contract
   'revision-state 'revision-bound 'revision-state 'state 'RevisionBound
   'revision-input 'revision-output
   (lambda (value)
     (not (equal? (slot/default value 'source-revision #f) "blocked")))))

(def runtime-projection
  (poo-flow-case-projection
   'runtime 'versioned 'agent.runtime-projection.v1
   (lambda (value)
     (list (cons 'agent-id (.ref value 'agent-id))
           (cons 'source-revision (.ref value 'source-revision))))))

(defpoo-case-component versioned-component versioned 1
  (role versioned-role)
  (type versioned-type)
  (slots schema-id-slot schema-version-slot)
  (contracts versioned-contract)
  (projections runtime-projection)
  (parents)
  (policy-algebra #f)
  (strategy-algebra #f))

(defpoo-case-component revision-component revision-bound 1
  (role revision-bound-role)
  (type revision-type)
  (slots revision-slot)
  (contracts revision-contract)
  (projections)
  (parents)
  (policy-algebra #f)
  (strategy-algebra #f))

(def (agent-role id revision (version 1))
  (poo-core-role-object
   (slots ((agent-id id)
           (schema-id 'agent.case.v1)
           (schema-version version)
           (source-revision revision)))
   (supers)))

(def (diagnostic-codes receipt)
  (map (lambda (diagnostic) (.ref diagnostic 'code))
       (.ref receipt 'diagnostics)))

(def (close-base cache)
  (poo-flow-domain-case-close
   cache 'agent.case.v1 1
   (list versioned-component revision-component)
   '() '(runtime)))

(def (role-variant-component index)
  (let (id
        (string->symbol (string-append "role-" (number->string index))))
    (poo-flow-case-component
     id 1 policy-role policy-type '() '() '()
     '(versioned revision-bound) 'deny-overrides 'route-first-match)))

(def (exercise-sparse-fleet unique-count)
  (let ((cache (poo-flow-domain-case-cache))
        (components (make-vector unique-count))
        (cases (make-vector unique-count))
        (all-closures-accepted? #t)
        (all-warm-hits? #t)
        (all-instances-accepted? #t)
        (all-case-bindings-correct? #t))
    (let loop ((index 0))
      (when (< index unique-count)
        (let* ((component (role-variant-component index))
               (receipt
                (poo-flow-domain-case-close
                 cache 'agent.case.v1 1
                 (list versioned-component revision-component component)
                 '() '(runtime))))
          (vector-set! components index component)
          (vector-set! cases index (.ref receipt 'domain-case))
          (set! all-closures-accepted?
                (and all-closures-accepted? (.ref receipt 'accepted?)))
          (loop (+ index 1)))))
    (let loop ((index 0))
      (when (< index unique-count)
        (let (receipt
              (poo-flow-domain-case-close
               cache 'agent.case.v1 1
               (list versioned-component revision-component
                     (vector-ref components index))
               '() '(runtime)))
          (set! all-warm-hits?
                (and all-warm-hits?
                     (.ref receipt 'accepted?)
                     (.ref receipt 'cache-hit?)))
          (loop (+ index 1)))))
    (let loop ((index 0))
      (when (< index 1000)
        (let* ((case-value (vector-ref cases (modulo index unique-count)))
               (id
                (string->symbol
                 (string-append "sparse-agent-" (number->string index))))
               (receipt
                (poo-flow-domain-case-instantiate
                 case-value (agent-role id "revision-sparse")))
               (instance (.ref receipt 'instance)))
          (set! all-instances-accepted?
                (and all-instances-accepted? (.ref receipt 'accepted?)))
          (set! all-case-bindings-correct?
                (and all-case-bindings-correct?
                     (eq? (.ref instance 'domain-case/ref) case-value)))
          (loop (+ index 1)))))
    (let* ((instance-mix-count
            (let loop ((index 0) (total 0))
              (if (= index unique-count)
                  total
                  (loop (+ index 1)
                        (+ total
                           (poo-flow-domain-case-instance-mix-count
                            (vector-ref cases index)))))))
           (instance-overlay-count
            (let loop ((index 0) (total 0))
              (if (= index unique-count)
                  total
                  (loop (+ index 1)
                        (+ total
                           (poo-flow-domain-case-instance-overlay-count
                            (vector-ref cases index))))))))
      (poo-core-role-object
       (slots ((kind 'poo-flow.sparse-domain-case-scale-receipt.v1)
               (agent-count 1000)
               (unique-case-count unique-count)
               (all-closures-accepted? all-closures-accepted?)
               (all-warm-hits? all-warm-hits?)
               (all-instances-accepted? all-instances-accepted?)
               (all-case-bindings-correct? all-case-bindings-correct?)
               (closure-count
                (poo-flow-domain-case-cache-closure-count cache))
               (cache-hit-count
                (poo-flow-domain-case-cache-hit-count cache))
               (instance-mix-count instance-mix-count)
               (instance-overlay-count instance-overlay-count)))
       (supers)))))

(def domain-case-test
  (test-suite "POO CaseComponent and DomainCase closure"
    (test-case "object, type, and contract close into one cached DomainCase"
      (let* ((cache (poo-flow-domain-case-cache))
             (cold (close-base cache))
             (warm (close-base cache))
             (left-receipt
              (poo-flow-domain-case-instantiate
               (.ref cold 'domain-case) (agent-role 'agent-1 "revision-1")))
             (right-receipt
              (poo-flow-domain-case-instantiate
               (.ref cold 'domain-case) (agent-role 'agent-2 "revision-2")))
             (left (.ref left-receipt 'instance))
             (right (.ref right-receipt 'instance)))
        (check (.ref cold 'accepted?) => #t)
        (check (.ref cold 'cache-hit?) => #f)
        (check (.ref warm 'accepted?) => #t)
        (check (.ref warm 'cache-hit?) => #t)
        (check (eq? (.ref cold 'domain-case) (.ref warm 'domain-case)) => #t)
        (check (eq? (.ref (.ref cold 'domain-case) 'shared-prototype)
                    (.ref (.ref warm 'domain-case) 'shared-prototype)) => #t)
        (check (poo-flow-domain-case-cache-closure-count cache) => 1)
        (check (poo-flow-domain-case-cache-hit-count cache) => 1)
        (check (poo-flow-domain-case-instance-mix-count
                (.ref cold 'domain-case))
               => 0)
        (check (poo-flow-domain-case-instance-overlay-count
                (.ref cold 'domain-case))
               => 2)
        (check (.ref left-receipt 'accepted?) => #t)
        (check (.ref right-receipt 'accepted?) => #t)
        (check (.ref left 'agent-id) => 'agent-1)
        (check (.ref right 'agent-id) => 'agent-2)
        (check (.ref left 'source-revision) => "revision-1")
        (check (.ref right 'source-revision) => "revision-2")
        (check (eq? (.ref left 'domain-case/ref) (.ref cold 'domain-case))
               => #t)
        (check (.ref left 'domain-case/instance-overlay-kind)
               => 'poo-flow.role-instance-overlay.v1)
        (check (.ref left 'domain-case/instance-composition-kind)
               => 'poo-flow.role-instance-overlay.v1)
        (check (.ref left 'domain-case/instance-overlay-resolver-depth) => 1)
        (check (.ref left 'qualification/versioned?) => #t)
        (check (.ref left 'qualification/revision-bound?) => #t)))

    (test-case "instance overlay preserves marker, local, and shared precedence"
      (let* ((case-value
              (.ref (close-base (poo-flow-domain-case-cache)) 'domain-case))
             (local-role
              (poo-core-role-object
               (slots ((agent-id 'overlay-agent)
                       (schema-id 'agent.case.v1)
                       (schema-version 1)
                       (source-revision "overlay-revision")
                       (qualification/versioned? 'local-override)
                       (domain-case/ref #f)
                       (domain-case/key 'spoofed-key)))
               (supers)))
             (receipt
              (poo-flow-domain-case-instantiate case-value local-role))
             (instance (.ref receipt 'instance)))
        (check (.ref receipt 'accepted?) => #t)
        (check (.ref instance 'qualification/versioned?) => 'local-override)
        (check (.ref instance 'qualification/revision-bound?) => #t)
        (check (eq? (.ref instance 'domain-case/ref) case-value) => #t)
        (check (.ref instance 'domain-case/key) => (.ref case-value 'key))
        (check (poo-flow-domain-case-instance-mix-count case-value) => 0)
        (check (poo-flow-domain-case-instance-overlay-count case-value) => 1)))

    (test-case "computed POO slots retain native mix semantics"
      (let* ((case-value
              (.ref (close-base (poo-flow-domain-case-cache)) 'domain-case))
             (computed-local-role
              (.o (agent-id 'computed-agent)
                  (schema-id 'agent.case.v1)
                  (schema-version 1)
                  (source-revision "computed-revision")))
             (receipt
              (poo-flow-domain-case-instantiate
               case-value computed-local-role))
             (instance (.ref receipt 'instance)))
        (check (.ref receipt 'accepted?) => #t)
        (check (.ref instance 'agent-id) => 'computed-agent)
        (check (.ref instance 'qualification/versioned?) => #t)
        (check (.ref instance 'domain-case/instance-overlay-kind) => #f)
        (check (.ref instance 'domain-case/instance-composition-kind)
               => 'poo-flow.role-compose-mix.v1)
        (check (.ref instance 'domain-case/instance-overlay-resolver-depth)
               => #f)
        (check (poo-flow-domain-case-instance-mix-count case-value) => 1)
        (check (poo-flow-domain-case-instance-overlay-count case-value) => 0)))

    (test-case "canonical key is deterministic and excludes procedures"
      (let* ((left
              (poo-flow-domain-case-canonical-descriptor
               'agent.case.v1 1
               (list versioned-component revision-component) '() '(runtime)))
             (right
              (poo-flow-domain-case-canonical-descriptor
               'agent.case.v1 1
               (list versioned-component revision-component) '() '(runtime)))
             (reversed
              (poo-flow-domain-case-canonical-descriptor
               'agent.case.v1 1
               (list revision-component versioned-component) '() '(runtime)))
             (left-key (poo-flow-domain-case-canonical-key left))
             (right-key (poo-flow-domain-case-canonical-key right))
             (reversed-key (poo-flow-domain-case-canonical-key reversed)))
        (check left => right)
        (check left-key => right-key)
        (check (equal? left-key reversed-key) => #f)
        (check
         (poo-flow-domain-case-canonical-descriptor
          'agent.case.v1 1 (list versioned-component revision-component)
          '() '(runtime audit))
         =>
         (poo-flow-domain-case-canonical-descriptor
          'agent.case.v1 1 (list versioned-component revision-component)
          '() '(audit runtime)))
        (check (string-contains
                (call-with-output-string (lambda (port) (write left port)))
                "procedure")
               => #f)))

    (test-case "same canonical identity cannot alias different component objects"
      (let* ((cache (poo-flow-domain-case-cache))
             (cold (close-base cache))
             (versioned-clone
              (poo-flow-case-component
               'versioned 1 versioned-role versioned-type
               (list schema-id-slot schema-version-slot)
               (list versioned-contract)
               (list runtime-projection)))
             (alias
              (poo-flow-domain-case-close
               cache 'agent.case.v1 1
               (list versioned-clone revision-component) '() '(runtime))))
        (check (.ref cold 'accepted?) => #t)
        (check (.ref alias 'accepted?) => #f)
        (check (diagnostic-codes alias) => '(module-owner-identity-alias))
        (check (poo-flow-domain-case-cache-closure-count cache) => 1)))

    (test-case "duplicate, parent, and projection declarations fail closure"
      (let* ((cache (poo-flow-domain-case-cache))
             (missing-parent
              (poo-flow-case-component
               'child 1 policy-role policy-type '() '() '()
               '(not-declared)))
             (duplicate
              (poo-flow-domain-case-close
               cache 'duplicate.case.v1 1
               (list versioned-component versioned-component)))
             (parent
              (poo-flow-domain-case-close
               cache 'parent.case.v1 1 (list missing-parent)))
             (projection
              (poo-flow-domain-case-close
               cache 'projection-selection.case.v1 1
               (list versioned-component) '() '(runtime runtime))))
        (check (diagnostic-codes duplicate)
               => '(duplicate-component-id projection-name-conflict))
        (check (diagnostic-codes parent)
               => '(missing-or-forward-parent-component))
        (check (diagnostic-codes projection)
               => '(duplicate-projection-selection))
        (check (poo-flow-domain-case-cache-closure-count cache) => 0)))

    (test-case "type identity and parent membership close before composition"
      (let* ((cache (poo-flow-domain-case-cache))
             (parent-role
              (poo-core-role-object (slots ((mode 'parent))) (supers)))
             (child-role
              (poo-core-role-object (slots ((mode 'child))) (supers)))
             (parent-type
              (poo-flow-case-type-contract 'ParentMode '() (lambda (_) #t)))
             (child-type
              (poo-flow-case-type-contract
               'ChildMode '(ParentMode) (lambda (_) #t)))
             (parent-component
              (poo-flow-case-component
               'parent-mode 1 parent-role parent-type '() '() '()))
             (child-component
              (poo-flow-case-component
               'child-mode 1 child-role child-type '() '() '()
               '(parent-mode)))
             (closed
              (poo-flow-domain-case-close
               cache 'precedence.case.v1 1
               (list parent-component child-component)))
             (local-role
              (poo-core-role-object (slots ((instance/local? #t))) (supers)))
             (instance
              (.ref (poo-flow-domain-case-instantiate
                     (.ref closed 'domain-case) local-role)
                    'instance))
             (missing-type-component
              (poo-flow-case-component
               'missing-type 1 policy-role
               (poo-flow-case-type-contract
                'MissingTypeChild '(NotDeclared) (lambda (_) #t))
               '() '() '()))
             (missing-type
              (poo-flow-domain-case-close
               cache 'missing-type.case.v1 1
               (list missing-type-component)))
             (conflicting-type-component
              (poo-flow-case-component
               'conflicting-type 1 policy-role
               (poo-flow-case-type-contract
                'ParentMode '() (lambda (_) #t))
               '() '() '()))
             (conflicting-type
              (poo-flow-domain-case-close
               cache 'conflicting-type.case.v1 1
               (list parent-component conflicting-type-component))))
        (check (.ref closed 'accepted?) => #t)
        (check (.ref instance 'mode) => 'child)
        (check (diagnostic-codes missing-type)
               => '(missing-or-forward-parent-type))
        (check (diagnostic-codes conflicting-type)
               => '(type-identity-conflict))))

    (test-case "slot conflict rejects and explicit witnessed override closes"
      (let* ((cache (poo-flow-domain-case-cache))
             (foreign-role
              (poo-core-role-object
               (slots ((foreign/status #t)))
               (supers)))
             (foreign-type
              (poo-flow-case-type-contract 'Foreign '() (lambda (_) #t)))
             (foreign-slot
              (poo-flow-case-slot-contract
               'schema-version 'foreign 'boolean 'false 'replace '() #f
               boolean?))
             (foreign-component
              (poo-flow-case-component
               'foreign 1 foreign-role foreign-type
               (list foreign-slot) '() '()))
             (rejected
              (poo-flow-domain-case-close
               cache 'conflict.case.v1 1
               (list versioned-component foreign-component)))
             (override
              (poo-flow-case-slot-contract
               'schema-version 'conflict.case.v1 'positive-integer
               'required 'replace '(versioned foreign)
               'schema-version-compatibility-v1
               (lambda (value) (and (exact-integer? value) (> value 0)))))
             (accepted
              (poo-flow-domain-case-close
               cache 'override.case.v1 1
               (list versioned-component foreign-component)
               (list override))))
        (check (.ref rejected 'accepted?) => #f)
        (check (diagnostic-codes rejected) => '(slot-contract-conflict))
        (check (.ref accepted 'accepted?) => #t)))

    (test-case "method contract refinement requires an explicit witness"
      (let* ((cache (poo-flow-domain-case-cache))
             (base-contract
              (poo-flow-case-method-contract
               'run-base 'base 'run 'method 'Run
               'any-agent 'receipt (lambda (_) #t)))
             (strict-contract
              (poo-flow-case-method-contract
               'run-strict 'strict 'run 'method 'Run
               'admin-agent 'receipt+evidence (lambda (_) #t)))
             (witnessed-contract
              (poo-flow-case-method-contract
               'run-witnessed 'strict 'run 'method 'Run
               'any-agent 'receipt+evidence
               (lambda (context) (slot/default context 'allowed? #f))
               '(run-base) 'run-contract-refinement-v1
               (lambda (candidate inherited)
                 (and (equal? (.ref candidate 'domain-id)
                              (.ref inherited 'domain-id))
                      (equal? (.ref candidate 'precondition-id)
                              (.ref inherited 'precondition-id))))))
             (false-witness-contract
              (poo-flow-case-method-contract
               'run-false-witness 'strict 'run 'method 'Run
               'any-agent 'receipt+evidence (lambda (_) #t)
               '(run-base) 'run-false-refinement-v1
               (lambda (_candidate _inherited) #f)))
             (base
              (poo-flow-case-component
               'base 1 policy-role policy-type '()
               (list base-contract) '()))
             (strict
              (poo-flow-case-component
               'strict 1 policy-role policy-type '()
               (list strict-contract) '()))
             (witnessed
              (poo-flow-case-component
               'witnessed 1 policy-role policy-type '()
               (list witnessed-contract) '()))
             (false-witness
              (poo-flow-case-component
               'false-witness 1 policy-role policy-type '()
               (list false-witness-contract) '()))
             (rejected
              (poo-flow-domain-case-close
               cache 'contract.case.v1 1 (list base strict)))
             (accepted
              (poo-flow-domain-case-close
               cache 'contract.witnessed.case.v1 1 (list base witnessed)))
             (false-witness-rejected
              (poo-flow-domain-case-close
               cache 'contract.false-witness.case.v1 1
               (list base false-witness)))
             (allowed-context
              (poo-core-role-object (slots ((allowed? #t))) (supers)))
             (denied-context
              (poo-core-role-object (slots ((allowed? #f))) (supers)))
             (method-accepted
              (poo-flow-domain-case-check-method
               (.ref accepted 'domain-case) 'run allowed-context))
             (method-rejected
              (poo-flow-domain-case-check-method
               (.ref accepted 'domain-case) 'run denied-context))
             (method-unknown
              (poo-flow-domain-case-check-method
               (.ref accepted 'domain-case) 'unknown allowed-context)))
        (check (.ref rejected 'accepted?) => #f)
        (check (diagnostic-codes rejected)
               => '(contract-refinement-conflict))
        (check (.ref accepted 'accepted?) => #t)
        (check (diagnostic-codes false-witness-rejected)
               => '(contract-refinement-conflict))
        (check (.ref method-accepted 'accepted?) => #t)
        (check (.ref method-accepted 'contract-id) => 'run-witnessed)
        (check (.ref method-rejected 'accepted?) => #f)
        (check (diagnostic-codes method-rejected)
               => '(method-contract-rejected))
        (check (diagnostic-codes method-unknown)
               => '(unknown-method-contract))))

    (test-case "projection and policy algebra conflicts fail before caching"
      (let* ((cache (poo-flow-domain-case-cache))
             (other-projection
              (poo-flow-case-projection
               'runtime 'other 'other.runtime.v1 (lambda (_) '(other))))
             (other-component
              (poo-flow-case-component
               'other 1 policy-role policy-type '() '()
               (list other-projection) '() 'permit-overrides))
             (policy-component
              (poo-flow-case-component
               'policy 1 policy-role policy-type '() '() '()
               '() 'deny-overrides))
             (same-projection-component
              (poo-flow-case-component
               'same-projection 1 policy-role policy-type '() '()
               (list runtime-projection)))
             (same-projection
              (poo-flow-domain-case-close
               cache 'same-projection.case.v1 1
               (list versioned-component same-projection-component)
               '() '(runtime)))
             (receipt
              (poo-flow-domain-case-close
               cache 'projection.case.v1 1
               (list versioned-component other-component policy-component)
               '() '(runtime))))
        (check (.ref receipt 'accepted?) => #f)
        (check (diagnostic-codes receipt)
               => '(projection-name-conflict policy-algebra-conflict))
        (check (diagnostic-codes same-projection)
               => '(projection-name-conflict))
        (check (poo-flow-domain-case-cache-closure-count cache) => 0)))

    (test-case "slot, type, and state contracts fail at instance boundary"
      (let* ((cache (poo-flow-domain-case-cache))
             (case-value (.ref (close-base cache) 'domain-case))
             (invalid-type
              (poo-flow-domain-case-instantiate
               case-value (agent-role 'agent-invalid "revision-1" 0)))
             (invalid-state
              (poo-flow-domain-case-instantiate
               case-value (agent-role 'agent-blocked "blocked")))
             (missing-slot-role
              (poo-core-role-object
               (slots ((agent-id 'agent-missing)
                       (schema-id 'agent.case.v1)
                       (schema-version 1)))
               (supers)))
             (missing-slot
              (poo-flow-domain-case-instantiate
               case-value missing-slot-role)))
        (check (.ref invalid-type 'accepted?) => #f)
        (check (diagnostic-codes invalid-type)
               => '(slot-contract-rejected type-contract-rejected))
        (check (.ref invalid-state 'accepted?) => #f)
        (check (diagnostic-codes invalid-state)
               => '(state-contract-rejected))
        (check (.ref missing-slot 'accepted?) => #f)
        (check (diagnostic-codes missing-slot)
               => '(required-slot-missing type-contract-rejected))))

    (test-case "only selected projections cross the DomainCase boundary"
      (let* ((cache (poo-flow-domain-case-cache))
             (case-value (.ref (close-base cache) 'domain-case))
             (instance
              (.ref (poo-flow-domain-case-instantiate
                     case-value (agent-role 'agent-1 "revision-1"))
                    'instance))
             (selected
              (poo-flow-domain-case-project case-value 'runtime instance))
             (private
              (poo-flow-domain-case-project case-value 'private instance)))
        (check (.ref selected 'accepted?) => #t)
        (check (.ref selected 'schema-id) => 'agent.runtime-projection.v1)
        (check (.ref selected 'payload)
               => '((agent-id . agent-1)
                    (source-revision . "revision-1")))
        (check (.ref private 'accepted?) => #f)
        (check (diagnostic-codes private) => '(projection-not-selected))))

    (test-case "1000 Agents share one closed case and remain isolated"
      (let* ((cache (poo-flow-domain-case-cache))
             (closure (close-base cache))
             (case-value (.ref closure 'domain-case))
             (shared (.ref case-value 'shared-prototype)))
        (let loop ((index 0)
                   (all-accepted? #t)
                   (all-isolated? #t)
                   (all-case-bound? #t)
                   (shared-stable? #t))
          (if (= index 1000)
              (begin
                (check all-accepted? => #t)
                (check all-isolated? => #t)
                (check all-case-bound? => #t)
                (check shared-stable? => #t))
              (let* ((id
                      (string->symbol
                       (string-append "agent-" (number->string index))))
                     (receipt
                      (poo-flow-domain-case-instantiate
                       case-value (agent-role id "revision-fleet")))
                     (instance (.ref receipt 'instance)))
                (loop (+ index 1)
                      (and all-accepted? (.ref receipt 'accepted?))
                      (and all-isolated? (eq? (.ref instance 'agent-id) id))
                      (and all-case-bound?
                           (eq? (.ref instance 'domain-case/ref) case-value))
                      (and shared-stable?
                           (eq? (.ref case-value 'shared-prototype)
                                shared))))))
        (check (poo-flow-domain-case-cache-closure-count cache) => 1)
        (check (poo-flow-domain-case-instance-mix-count case-value) => 0)
        (check (poo-flow-domain-case-instance-overlay-count case-value) => 1000)
        (check (.ref closure 'cache-hit?) => #f)))

    (test-case "1000 Agents use sparse U=8/32/64 role-policy-strategy cases"
      (for-each
       (lambda (unique-count)
         (let (receipt (exercise-sparse-fleet unique-count))
           (check (.ref receipt 'agent-count) => 1000)
           (check (.ref receipt 'unique-case-count) => unique-count)
           (check (.ref receipt 'all-closures-accepted?) => #t)
           (check (.ref receipt 'all-warm-hits?) => #t)
           (check (.ref receipt 'all-instances-accepted?) => #t)
           (check (.ref receipt 'all-case-bindings-correct?) => #t)
           (check (.ref receipt 'closure-count) => unique-count)
           (check (.ref receipt 'cache-hit-count) => unique-count)
           (check (.ref receipt 'instance-mix-count) => 0)
           (check (.ref receipt 'instance-overlay-count) => 1000)))
       '(8 32 64)))))

(run-tests! domain-case-test)
