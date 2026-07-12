(import :std/test
        :gslph/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/module-system/durable-artifact-policy
        :poo-flow/src/module-system/profile-composition)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def (clause-payload clause)
  (.ref clause 'payload))

(def (stage-clause-payload composition-stage clause-kind)
  (let loop ((clauses (poo-flow-composition-stage-clauses composition-stage)))
    (cond
     ((null? clauses) #f)
     ((eq? (.ref (car clauses) 'clause-kind) clause-kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

(def report/base
  (.o (name 'report/base)
      (scope '(tenant project workflow session publish-channel))
      (storage '(file-system))
      (analysis '(checksum))
      (publish '(human-approved))))

(def tool-output/base
  (.o (name 'tool-output/base)
      (scope '(session agent tool-call sandbox))
      (storage '(kv))
      (analysis '(checksum))
      (retention '(checkpoint-linked))))

(def research-report
  (artifact-profile research-report
    :extends report/base
    :scope (tenant project workflow session human-handoff publish-channel)
    :storage (file-system object-store vector-index checkpoint-store)
    :analysis (checksum schema provenance)
    :publish (human-approved proof-gated)
    :retention (project-retained audit-log)))

(def (with-audit-retention profile)
  (poo-flow-artifact-profile-extend
   (.ref profile 'name)
   profile
   (.o (analysis (append (.ref profile 'analysis) '(citation-trace)))
       (retention '(project-retained audit-log)))))

(def audited-report
  (artifact-profile audited-report
    :extends research-report
    :scope (tenant project workflow session human-handoff publish-channel)
    :storage (file-system object-store vector-index checkpoint-store)
    :analysis (checksum schema provenance)
    :publish (human-approved proof-gated)
    :retention (project-retained audit-log)
    :with with-audit-retention))

(def agent-artifacts
  (artifact-module
    (profile research-report
      :extends report/base
      :scope (session human-handoff publish-channel)
      :storage (file object vector)
      :analysis (checksum schema provenance)
      :publish (human-approved proof-gated))
    (profile tool-output
      :extends tool-output/base
      :scope (session agent tool-call sandbox)
      :storage (kv checkpoint-store)
      :analysis (checksum schema)
      :retention (checkpoint-linked))))

(def artifact-databases
  (database-module
    (profile turso
      :kind libsql
      :storage (file-system vector-index checkpoint-store)
      :capabilities (concurrent-writes
                     local-first-push-pull
                     ai-vector-search
                     vector-top-k))))

(def artifact-composition
  (use-composition agent-artifacts
    (use-module artifact as artifact
      (profile research-report
        :extends report/base
        :scope (session human-handoff publish-channel)
        :storage (file object vector)
        :analysis (checksum schema provenance)
        :publish (human-approved proof-gated))
      (profile tool-output
        :extends tool-output/base
        :scope (session agent tool-call sandbox)
        :storage (kv checkpoint-store)
        :analysis (checksum schema)
        :retention (checkpoint-linked))
      (profile turso
        :kind libsql
        :storage (file-system vector-index checkpoint-store)
        :capabilities (concurrent-writes
                       local-first-push-pull
                       ai-vector-search
                       vector-top-k)))
    (compose (profile artifact research-report)
             (profile artifact tool-output)
             (profile artifact turso))
    (stage production
      (graph artifact-lifecycle)
      (loop #:fuel 4 #:exit published)
      (prove artifact-scope-contained
             artifact-publish-gated
             database-capability-satisfied))))

(def inline-artifact-composition
  (use-composition inline-agent-artifacts
    (use-module artifact as artifact
      (profile research-report
        :extends report/base
        :scope (session human-handoff publish-channel)
        :storage (file object vector)
        :analysis (checksum schema provenance)
        :publish (human-approved proof-gated))
      (profile internal-report
        :extends research-report
        :publish (human-approved proof-gated internal-registry)
        :retention (project-retained audit-log)))
    (compose (profile artifact research-report)
             (profile artifact internal-report))
    (stage production
      (prove artifact-scope-contained artifact-publish-gated))))

(def report-artifact
  (durable-artifact report/artifact-1
    :kind report
    :scope (tenant project workflow session human-handoff publish-channel)
    :storage-class file-system
    :state created
    :producer agent/build
    :owner project/team
    :sandbox (sandbox/build)
    :checksum checksum/sha256
    :analysis (checksum schema provenance)
    :index vector-top-k
    :call read-only
    :publish (human-approved proof-gated)
    :retention project-retained
    :grants (actor/reviewer)))

(def invalid-artifact
  (durable-artifact report/artifact-invalid
    :kind report
    :scope (external)
    :storage-class memory-only
    :state unknown
    :producer agent/build
    :owner project/team
    :sandbox (sandbox/build)
    :checksum checksum/sha256
    :analysis (unsafe-analysis)
    :index missing-vector-capability
    :call read-only
    :publish (auto-publish)
    :retention forever
    :grants ()))

(def artifact-policy-receipt
  (poo-flow-durable-artifact-validate
   report-artifact
   research-report
   (.ref artifact-databases 'turso)))

(def artifact-manifest-receipt
  (poo-flow-durable-artifact-manifest
   report-artifact
   research-report
   (.ref artifact-databases 'turso)
   '((manifest-id . artifact-manifest/report-1)
     (metadata . ((source . scenario)
                  (case . durable-artifact-policy))))))

(def artifact-manifest-handoff
  (poo-flow-durable-artifact-manifest->marlin-handoff
   artifact-manifest-receipt))

(def invalid-artifact-policy-receipt
  (poo-flow-durable-artifact-validate
   invalid-artifact
   research-report
   (.ref artifact-databases 'turso)))

(def session-actor
  (.o (actor-ref 'actor/session)
      (scope '(project session))
      (artifact-grants '())))

(def outside-actor
  (.o (actor-ref 'actor/outside)
      (scope '(external workspace))
      (artifact-grants '())))

(def reviewer-actor
  (.o (actor-ref 'actor/reviewer)
      (scope '(external workspace))
      (artifact-grants '())))

(def granted-tool-actor
  (.o (actor-ref 'actor/tool)
      (scope '(external workspace))
      (artifact-grants '(report/artifact-1))))

(def durable-artifact-policy-test
  (test-suite "durable artifact policy"
    (test-case "artifact profile macro creates reusable POO objects"
      (check-equal? (poo-flow-artifact-profile? research-report) #t)
      (check-equal? (.ref research-report 'name) 'research-report)
      (check-equal? (.ref research-report 'kind) 'research-report)
      (check-equal? (.ref research-report 'extends) 'report/base)
      (check-equal? (.ref research-report 'scope)
                    '(tenant project workflow session human-handoff publish-channel))
      (check-equal? (.ref research-report 'storage)
                    '(file-system object-store vector-index checkpoint-store))
      (check-equal? (poo-flow-artifact-scope-contained?
                     research-report
                     '(session publish-channel))
                    #t)
      (check-equal? (poo-flow-artifact-publish-gated? research-report) #t))

    (test-case "profile hook composes native POO object extension"
      (check-equal? (poo-flow-artifact-profile? audited-report) #t)
      (check-equal? (.ref audited-report 'name) 'audited-report)
      (check-equal? (.ref audited-report 'storage)
                    '(file-system object-store vector-index checkpoint-store))
      (check-equal? (.ref audited-report 'analysis)
                    '(checksum schema provenance citation-trace))
      (check-equal? (.ref audited-report 'retention)
                    '(project-retained audit-log)))

    (test-case "durable artifact object implements policy scope"
      (check-equal? (poo-flow-durable-artifact? report-artifact) #t)
      (check-equal? (.ref report-artifact 'artifact-id) 'report/artifact-1)
      (check-equal? (.ref report-artifact 'artifact-kind) 'report)
      (check-equal? (.ref report-artifact 'storage-class) 'file-system)
      (check-equal? (.ref report-artifact 'lifecycle-state) 'created)
      (check-equal? (poo-flow-durable-artifact-visible?
                     report-artifact
                     session-actor)
                    #t)
      (check-equal? (poo-flow-durable-artifact-visible?
                     report-artifact
                     outside-actor)
                    #f)
      (check-equal? (poo-flow-durable-artifact-visible?
                     report-artifact
                     reviewer-actor)
                    #t)
      (check-equal? (poo-flow-durable-artifact-visible?
                     report-artifact
                     granted-tool-actor)
                    #t))

    (test-case "durable artifact validation emits policy receipts"
      (check-equal? (poo-flow-durable-artifact-policy-receipt?
                     artifact-policy-receipt)
                    #t)
      (check-equal? (poo-flow-durable-artifact-policy-receipt-valid?
                     artifact-policy-receipt)
                    #t)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'artifact-id)
                    'report/artifact-1)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'profile-name)
                    'research-report)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'database-name)
                    'turso)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'valid?) #t)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'runtime-executed) #f)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'source)
                    'poo-flow.durable.artifact.policy)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      artifact-policy-receipt)
                     'diagnostics)
                    '())
      (check-equal? (poo-flow-durable-artifact-policy-receipt-valid?
                     invalid-artifact-policy-receipt)
                    #f)
      (check-equal? (test-ref
                     (poo-flow-durable-artifact-policy-receipt->alist
                      invalid-artifact-policy-receipt)
                     'diagnostics)
                    '(artifact-scope-not-contained-by-profile
                      artifact-storage-not-supported-by-profile
                      artifact-analysis-not-supported-by-profile
                      artifact-publish-policy-not-gated
                      artifact-retention-not-supported-by-profile
                      artifact-lifecycle-state-invalid
                      artifact-storage-not-supported-by-database
                      artifact-database-capability-not-satisfied)))

    (test-case "durable artifact manifest projects Marlin handoff"
      (let ((manifest-row
             (poo-flow-durable-artifact-manifest-receipt->alist
              artifact-manifest-receipt)))
        (check-equal? (poo-flow-durable-artifact-manifest-receipt?
                       artifact-manifest-receipt)
                      #t)
        (check-equal? (poo-flow-durable-artifact-manifest-receipt-valid?
                       artifact-manifest-receipt)
                      #t)
        (check-equal? (test-ref manifest-row 'manifest-id)
                      'artifact-manifest/report-1)
        (check-equal? (test-ref manifest-row 'artifact-id)
                      'report/artifact-1)
        (check-equal? (test-ref manifest-row 'storage-class) 'file-system)
        (check-equal? (test-ref manifest-row 'handoff-required) #t)
        (check-equal? (test-ref manifest-row 'runtime-executed) #f)
        (check-equal? (test-ref artifact-manifest-handoff 'kind)
                      'poo-flow.durable.artifact.marlin-handoff)
        (check-equal? (test-ref artifact-manifest-handoff 'handoff-ready?) #t)
        (check-equal? (test-ref artifact-manifest-handoff
                                'runtime-executed)
                      #f)
        (check-equal? (test-ref artifact-manifest-handoff
                                'runtime-parses-scheme-source)
                      #f)
        (check-equal? (test-ref artifact-manifest-handoff
                                'scheme-manufactures-runtime-handlers)
                      #f)))

    (test-case "durable artifact lifecycle follows document edges"
      (let (stored (poo-flow-durable-artifact-transition
                    report-artifact
                    'stored))
        (check-equal? (.ref stored 'lifecycle-state) 'stored)
        (check-equal? (.ref stored 'artifact-id) 'report/artifact-1)
        (check-equal? (poo-flow-durable-artifact-lifecycle-transition-allowed?
                       'stored
                       'indexed)
                      #t)
        (check-equal? (poo-flow-durable-artifact-lifecycle-transition-allowed?
                       'created
                       'published)
                      #f)))

    (test-case "artifact and database profiles feed inline composition syntax"
      (let* ((stages (poo-flow-composition-stages artifact-composition))
             (stage (car stages))
             (compose-payload (poo-flow-composition-profiles
                               artifact-composition))
             (graph-payload (stage-clause-payload stage 'graph))
             (loop-payload (stage-clause-payload stage 'loop))
             (prove-payload (stage-clause-payload stage 'prove)))
        (check-equal? (poo-flow-composition? artifact-composition) #t)
        (check-equal? (poo-flow-composition-name artifact-composition)
                      'agent-artifacts)
        (check-equal? (length (poo-flow-composition-modules
                               artifact-composition))
                      1)
        (check-equal? (poo-flow-composition-stage-name stage)
                      'production)
        (check-equal? (map (lambda (profile) (.ref profile 'name))
                           compose-payload)
                      '(research-report tool-output turso))
        (check-equal? graph-payload '(artifact-lifecycle))
        (check-equal? (cadr loop-payload) 4)
        (check-equal? (cadddr loop-payload) 'published)
        (check-equal? prove-payload
                      '(artifact-scope-contained
                        artifact-publish-gated
                        database-capability-satisfied))))

    (test-case "inline use-module profiles expand to POO module objects"
      (let* ((modules (poo-flow-composition-modules inline-artifact-composition))
             (module-binding (car modules))
             (module-object (.ref module-binding 'module))
             (research-profile (.ref module-object 'research-report))
             (internal-profile (.ref module-object 'internal-report))
             (compose-payload (poo-flow-composition-profiles
                               inline-artifact-composition)))
        (check-equal? (poo-flow-composition? inline-artifact-composition) #t)
        (check-equal? (.ref research-profile 'name) 'research-report)
        (check-equal? (.ref research-profile 'source)
                      'poo-flow.composition.inline-profile)
        (check-equal? (.ref (.ref internal-profile 'extends) 'name)
                      'research-report)
        (check-equal? (.ref internal-profile 'retention)
                      '(project-retained audit-log))
        (check-equal? (map (lambda (profile) (.ref profile 'name))
                           compose-payload)
                      '(research-report internal-report))))))

(run-tests! durable-artifact-policy-test)
