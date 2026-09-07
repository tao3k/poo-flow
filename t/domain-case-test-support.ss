(import :std/test
        :asp-gerbil-scheme/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/core/object-syntax
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/module-system/domain-case-syntax)


(export #t)

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
