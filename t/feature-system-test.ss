(import :std/test
        :clan/poo/object
        :poo-flow/src/feature-system/interface
        :poo-flow/src/utilities/functional)

(export feature-system-test)

(def (test-feature feature-id
                   (requires '())
                   (optional-requires '())
                   (conflicts '()))
  (feature-descriptor
   (feature-spec-compose
    (feature-descriptor-base feature-id 'poo-flow-test-feature-owner)
    (feature-schema-version 1)
    (feature-category 'test)
    (apply feature-required-dependencies requires)
    (apply feature-optional-dependencies optional-requires)
    (apply feature-conflicts-with conflicts))))

(def (select-feature descriptor)
  (feature-selection descriptor))

(def (test-profile profile-id descriptors)
  (feature-profile profile-id (poo-flow-map select-feature descriptors)))

(def (plan-has-diagnostic? plan code)
  (and
   (poo-flow-find
    (lambda (diagnostic)
      (eq? (.ref diagnostic 'code) code))
    (.ref plan 'diagnostics))
   #t))

(def (linear-test-features count)
  (let loop ((index 0)
             (previous-id #f)
             (features '()))
    (if (= index count)
      (reverse features)
      (let* ((feature-id
              (string->symbol
               (string-append "feature-" (number->string index))))
             (requires (if previous-id (list previous-id) '())))
        (loop
         (+ index 1)
         feature-id
         (cons (test-feature feature-id requires) features))))))

(def feature-system-test
  (test-suite "POO-native Feature system"
    (test-case "descriptor is an immutable module-owned POO value"
      (let ((descriptor (test-feature 'memory-core)))
        (check (.ref descriptor 'kind) => 'feature-descriptor)
        (check (.ref descriptor 'feature-id) => 'memory-core)
        (check (.ref descriptor 'owner-module-id)
               => 'poo-flow-test-feature-owner)))

    (test-case "resolver orders required Features before dependents"
      (let* ((memory (test-feature 'memory-core))
             (session (test-feature 'session-core '(memory-core)))
             (profile (test-profile 'default-agent (list session memory)))
             (plan (resolve-feature-profile profile)))
        (check (.ref plan 'status) => 'ready)
        (check (.ref plan 'feature-ids) => '(memory-core session-core))))

    (test-case "two profiles share one module-owned descriptor"
      (let* ((memory (test-feature 'memory-core))
             (first (resolve-feature-profile
                     (test-profile 'first (list memory))))
             (second (resolve-feature-profile
                      (test-profile 'second (list memory)))))
        (check (.ref first 'profile-id) => 'first)
        (check (.ref second 'profile-id) => 'second)
        (check (eq? memory
                    (.ref (car (.ref first 'ordered-selections))
                          'descriptor))
               => #t)
        (check (eq? memory
                    (.ref (car (.ref second 'ordered-selections))
                          'descriptor))
               => #t)))

    (test-case "missing dependency rejects the plan"
      (let* ((session (test-feature 'session-core '(memory-core)))
             (plan (resolve-feature-profile
                    (test-profile 'missing-memory (list session)))))
        (check (.ref plan 'status) => 'rejected)
        (check (plan-has-diagnostic? plan 'missing-dependency) => #t)))

    (test-case "unselected optional dependency is ignored"
      (let* ((session
              (test-feature 'session-core '() '(telemetry-core)))
             (plan (resolve-feature-profile
                    (test-profile 'without-telemetry (list session)))))
        (check (.ref plan 'status) => 'ready)
        (check (.ref plan 'feature-ids) => '(session-core))))

    (test-case "selected optional dependency is ordered first"
      (let* ((telemetry (test-feature 'telemetry-core))
             (session
              (test-feature 'session-core '() '(telemetry-core)))
             (plan (resolve-feature-profile
                    (test-profile
                     'with-telemetry
                     (list session telemetry)))))
        (check (.ref plan 'status) => 'ready)
        (check (.ref plan 'feature-ids)
               => '(telemetry-core session-core))))

    (test-case "duplicate selection rejects the plan"
      (let* ((memory (test-feature 'memory-core))
             (plan (resolve-feature-profile
                    (test-profile 'duplicate (list memory memory)))))
        (check (.ref plan 'status) => 'rejected)
        (check (plan-has-diagnostic? plan 'duplicate-selection) => #t)))

    (test-case "Feature conflict rejects the plan"
      (let* ((local-memory
              (test-feature 'local-memory '() '() '(remote-memory)))
             (remote-memory (test-feature 'remote-memory))
             (plan (resolve-feature-profile
                    (test-profile
                     'conflicting-memory
                     (list local-memory remote-memory)))))
        (check (.ref plan 'status) => 'rejected)
        (check (plan-has-diagnostic? plan 'feature-conflict) => #t)))

    (test-case "dependency cycle rejects the plan"
      (let* ((feature-a (test-feature 'feature-a '(feature-b)))
             (feature-b (test-feature 'feature-b '(feature-a)))
             (plan (resolve-feature-profile
                    (test-profile 'cyclic (list feature-a feature-b)))))
        (check (.ref plan 'status) => 'rejected)
        (check (plan-has-diagnostic? plan 'dependency-cycle) => #t)))

    (test-case "256-Feature graph reuses constant-slot construction"
      (let* ((features (linear-test-features 256))
             (plan (resolve-feature-profile
                    (test-profile 'linear-256 (reverse features))))
             (feature-ids (.ref plan 'feature-ids)))
        (check (.ref plan 'status) => 'ready)
        (check (length feature-ids) => 256)
        (check (car feature-ids) => 'feature-0)
        (check (car (reverse feature-ids)) => 'feature-255)))))
