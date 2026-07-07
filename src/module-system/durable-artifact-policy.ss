(import :clan/poo/object
        (only-in :poo-flow/src/core/runtime-protocol
                 +runtime-request-schema+)
        (only-in :poo-flow/src/core/runtime-command-descriptor
                 runtime-command-fields->manifest))

(export +poo-flow-durable-artifact-profile-kind+
        +poo-flow-durable-artifact-profile-schema+
        +poo-flow-durable-artifact-database-profile-kind+
        +poo-flow-durable-artifact-database-profile-schema+
        poo-flow-artifact-profile
        poo-flow-artifact-database-profile
        poo-flow-artifact-profile-extend
        poo-flow-artifact-profile-override
        poo-flow-artifact-profile-apply-hooks
        poo-flow-artifact-profile->alist
        poo-flow-artifact-database-profile->alist
        poo-flow-artifact-profile?
        poo-flow-artifact-database-profile?
        poo-flow-artifact-scope-contained?
        poo-flow-artifact-publish-gated?
        poo-flow-durable-artifact
        poo-flow-durable-artifact?
        poo-flow-durable-artifact->alist
        poo-flow-durable-artifact-visible?
        poo-flow-durable-artifact-lifecycle-transition-allowed?
        poo-flow-durable-artifact-transition
        poo-flow-durable-artifact-validate
        poo-flow-durable-artifact-policy-receipt?
        poo-flow-durable-artifact-policy-receipt-valid?
        poo-flow-durable-artifact-policy-receipt->alist
        make-poo-flow-durable-artifact-manifest-receipt
        poo-flow-durable-artifact-manifest-receipt?
        poo-flow-durable-artifact-manifest-receipt-valid?
        poo-flow-durable-artifact-manifest-receipt-diagnostics
        poo-flow-durable-artifact-manifest
        poo-flow-durable-artifact-manifest-receipt->alist
        poo-flow-durable-artifact-manifest->marlin-handoff
        artifact-profile
        database-profile
        durable-artifact
        artifact-module
        database-module)

(def +poo-flow-durable-artifact-profile-kind+
  'poo-flow.durable.artifact.profile)

(def +poo-flow-durable-artifact-profile-schema+
  'poo-flow.durable.artifact.profile.v1)

(def +poo-flow-durable-artifact-database-profile-kind+
  'poo-flow.durable.artifact.database.profile)

(def +poo-flow-durable-artifact-database-profile-schema+
  'poo-flow.durable.artifact.database.profile.v1)

(def +poo-flow-artifact-profile-fields+
  '(artifact-profile-kind
    artifact-profile-schema
    name
    extends
    kind
    scope
    storage
    analysis
    publish
    retention
    lifecycle
    database
    hooks
    runtime-executed
    source))

(def +poo-flow-artifact-database-profile-fields+
  '(artifact-database-profile-kind
    artifact-database-profile-schema
    name
    extends
    classes
    capabilities
    storage
    source))

(def (poo-flow-artifact-section-slot key)
  (case key
    ((:extends extends) 'extends)
    ((:kind kind) 'kind)
    ((:scope scope) 'scope)
    ((:storage storage) 'storage)
    ((:analysis analysis) 'analysis)
    ((:publish publish) 'publish)
    ((:retention retention) 'retention)
    ((:lifecycle lifecycle) 'lifecycle)
    ((:database database) 'database)
    ((:with with) 'hooks)
    ((:classes classes) 'classes)
    ((:capabilities capabilities) 'capabilities)
    (else key)))

(def (poo-flow-artifact-sections->alist sections)
  (let loop ((rest sections) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((null? (cdr rest))
      (error "artifact profile section requires a value" (car rest)))
     (else
      (loop (cddr rest)
            (cons (cons (poo-flow-artifact-section-slot (car rest))
                        (cadr rest))
                  out))))))

(def (poo-flow-artifact-alist-ref alist key default-value)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default-value)))

(def (poo-flow-artifact-profile/direct profile-name
                                       extends-value
                                       kind-value
                                       scope-value
                                       storage-value
                                       analysis-value
                                       publish-value
                                       retention-value
                                       lifecycle-value
                                       database-value
                                       hooks-value)
  (.o (artifact-profile-kind +poo-flow-durable-artifact-profile-kind+)
      (artifact-profile-schema +poo-flow-durable-artifact-profile-schema+)
      (name profile-name)
      (extends extends-value)
      (kind kind-value)
      (scope scope-value)
      (storage storage-value)
      (analysis analysis-value)
      (publish publish-value)
      (retention retention-value)
      (lifecycle lifecycle-value)
      (database database-value)
      (hooks hooks-value)
      (runtime-executed #f)
      (source 'poo-flow.durable.artifact.policy)))

(def (poo-flow-artifact-database-profile/direct profile-name
                                                extends-value
                                                classes-value
                                                capabilities-value
                                                storage-value)
  (.o (artifact-database-profile-kind
       +poo-flow-durable-artifact-database-profile-kind+)
      (artifact-database-profile-schema
       +poo-flow-durable-artifact-database-profile-schema+)
      (name profile-name)
      (extends extends-value)
      (classes classes-value)
      (capabilities capabilities-value)
      (storage storage-value)
      (source 'poo-flow.durable.artifact.database)))

(def (poo-flow-artifact-profile-from-alist profile-name fields)
  (poo-flow-artifact-profile/direct
   profile-name
   (poo-flow-artifact-alist-ref fields 'extends #f)
   (poo-flow-artifact-alist-ref fields 'kind profile-name)
   (poo-flow-artifact-alist-ref fields 'scope '())
   (poo-flow-artifact-alist-ref fields 'storage '())
   (poo-flow-artifact-alist-ref fields 'analysis '())
   (poo-flow-artifact-alist-ref fields 'publish '())
   (poo-flow-artifact-alist-ref fields 'retention '())
   (poo-flow-artifact-alist-ref fields 'lifecycle '(created stored retained))
   (poo-flow-artifact-alist-ref fields 'database '())
   (poo-flow-artifact-alist-ref fields 'hooks '())))

(def (poo-flow-artifact-database-profile-from-alist profile-name fields)
  (poo-flow-artifact-database-profile/direct
   profile-name
   (poo-flow-artifact-alist-ref fields 'extends #f)
   (poo-flow-artifact-alist-ref fields 'classes '())
   (poo-flow-artifact-alist-ref fields 'capabilities '())
   (poo-flow-artifact-alist-ref fields 'storage '())))

(def (poo-flow-artifact-profile name sections)
  (poo-flow-artifact-profile-from-alist
   name
   (poo-flow-artifact-sections->alist sections)))

(def (poo-flow-artifact-database-profile name sections)
  (poo-flow-artifact-database-profile-from-alist
   name
   (poo-flow-artifact-sections->alist sections)))

(def (poo-flow-artifact-profile->alist profile)
  (map (lambda (field) (cons field (.ref profile field)))
       +poo-flow-artifact-profile-fields+))

(def (poo-flow-artifact-database-profile->alist profile)
  (map (lambda (field) (cons field (.ref profile field)))
       +poo-flow-artifact-database-profile-fields+))

(def (poo-flow-artifact-object-ref/default object field default)
  (if (.slot? object field)
    (.ref object field)
    default))

(def (poo-flow-artifact-profile-override profile-name base override)
  (poo-flow-artifact-profile/direct
   profile-name
   (poo-flow-artifact-object-ref/default override 'extends (.ref base 'extends))
   (poo-flow-artifact-object-ref/default override 'kind (.ref base 'kind))
   (poo-flow-artifact-object-ref/default override 'scope (.ref base 'scope))
   (poo-flow-artifact-object-ref/default override 'storage (.ref base 'storage))
   (poo-flow-artifact-object-ref/default override 'analysis (.ref base 'analysis))
   (poo-flow-artifact-object-ref/default override 'publish (.ref base 'publish))
   (poo-flow-artifact-object-ref/default override 'retention (.ref base 'retention))
   (poo-flow-artifact-object-ref/default override 'lifecycle (.ref base 'lifecycle))
   (poo-flow-artifact-object-ref/default override 'database (.ref base 'database))
   (poo-flow-artifact-object-ref/default override 'hooks (.ref base 'hooks))))

(def (poo-flow-artifact-profile-extend name base override)
  (poo-flow-artifact-profile-override name base override))

(def (poo-flow-artifact-profile-apply-hooks profile hooks)
  (let loop ((current profile) (rest hooks))
    (if (null? rest)
      current
      (loop ((car rest) current) (cdr rest)))))

(def (poo-flow-artifact-profile? profile)
  (and (object? profile)
       (.slot? profile 'artifact-profile-kind)
       (eq? (.ref profile 'artifact-profile-kind)
            +poo-flow-durable-artifact-profile-kind+)))

(def (poo-flow-artifact-database-profile? profile)
  (and (object? profile)
       (.slot? profile 'artifact-database-profile-kind)
       (eq? (.ref profile 'artifact-database-profile-kind)
            +poo-flow-durable-artifact-database-profile-kind+)))

(def (poo-flow-artifact-scope-contained? profile required-scope)
  (let (scope (.ref profile 'scope))
    (andmap (lambda (scope-id) (memq scope-id scope)) required-scope)))

(def (poo-flow-artifact-publish-gated? profile)
  (let (publish (.ref profile 'publish))
    (or (null? publish)
        (and (memq 'human-approved publish)
             (memq 'proof-gated publish)
             #t))))

(def +poo-flow-durable-artifact-kind+
  'poo-flow.durable.artifact)

(def +poo-flow-durable-artifact-schema+
  'poo-flow.durable.artifact.v1)

(def +poo-flow-durable-artifact-fields+
  '(durable-artifact-kind
    durable-artifact-schema
    artifact-id
    artifact-kind
    artifact-scope
    storage-class
    lifecycle-state
    producer-ref
    owner-ref
    sandbox-scope
    checksum-policy
    analysis-policy
    index-policy
    call-policy
    publish-policy
    retention-policy
    explicit-grants
    runtime-executed
    source))

(def +poo-flow-durable-artifact-lifecycle-edges+
  '((created . stored)
    (stored . indexed)
    (indexed . analyzed)
    (analyzed . callable)
    (callable . publish-approved)
    (publish-approved . published)
    (published . retained)
    (published . expired)
    (published . archived)
    (published . revoked)))

(def (poo-flow-durable-artifact-section-slot key)
  (case key
    ((:artifact-kind artifact-kind :kind kind) 'artifact-kind)
    ((:artifact-scope artifact-scope :scope scope) 'artifact-scope)
    ((:storage-class storage-class :storage storage) 'storage-class)
    ((:lifecycle-state lifecycle-state :state state) 'lifecycle-state)
    ((:producer-ref producer-ref :producer producer) 'producer-ref)
    ((:owner-ref owner-ref :owner owner) 'owner-ref)
    ((:sandbox-scope sandbox-scope :sandbox sandbox) 'sandbox-scope)
    ((:checksum-policy checksum-policy :checksum checksum) 'checksum-policy)
    ((:analysis-policy analysis-policy :analysis analysis) 'analysis-policy)
    ((:index-policy index-policy :index index) 'index-policy)
    ((:call-policy call-policy :call call) 'call-policy)
    ((:publish-policy publish-policy :publish publish) 'publish-policy)
    ((:retention-policy retention-policy :retention retention) 'retention-policy)
    ((:explicit-grants explicit-grants :grants grants) 'explicit-grants)
    (else key)))

(def (poo-flow-durable-artifact-sections->alist sections)
  (let loop ((rest sections) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((null? (cdr rest))
      (error "durable artifact section requires a value" (car rest)))
     (else
      (loop (cddr rest)
            (cons (cons (poo-flow-durable-artifact-section-slot (car rest))
                        (cadr rest))
                  out))))))

(def (poo-flow-durable-artifact/direct artifact-id-value
                                       artifact-kind-value
                                       artifact-scope-value
                                       storage-class-value
                                       lifecycle-state-value
                                       producer-ref-value
                                       owner-ref-value
                                       sandbox-scope-value
                                       checksum-policy-value
                                       analysis-policy-value
                                       index-policy-value
                                       call-policy-value
                                       publish-policy-value
                                       retention-policy-value
                                       explicit-grants-value)
  (.o (durable-artifact-kind +poo-flow-durable-artifact-kind+)
      (durable-artifact-schema +poo-flow-durable-artifact-schema+)
      (artifact-id artifact-id-value)
      (artifact-kind artifact-kind-value)
      (artifact-scope artifact-scope-value)
      (storage-class storage-class-value)
      (lifecycle-state lifecycle-state-value)
      (producer-ref producer-ref-value)
      (owner-ref owner-ref-value)
      (sandbox-scope sandbox-scope-value)
      (checksum-policy checksum-policy-value)
      (analysis-policy analysis-policy-value)
      (index-policy index-policy-value)
      (call-policy call-policy-value)
      (publish-policy publish-policy-value)
      (retention-policy retention-policy-value)
      (explicit-grants explicit-grants-value)
      (runtime-executed #f)
      (source 'poo-flow.durable.artifact.policy)))

(def (poo-flow-durable-artifact artifact-id-value sections)
  (let (fields (poo-flow-durable-artifact-sections->alist sections))
    (poo-flow-durable-artifact/direct
     artifact-id-value
     (poo-flow-artifact-alist-ref fields 'artifact-kind artifact-id-value)
     (poo-flow-artifact-alist-ref fields 'artifact-scope '())
     (poo-flow-artifact-alist-ref fields 'storage-class '())
     (poo-flow-artifact-alist-ref fields 'lifecycle-state 'created)
     (poo-flow-artifact-alist-ref fields 'producer-ref #f)
     (poo-flow-artifact-alist-ref fields 'owner-ref #f)
     (poo-flow-artifact-alist-ref fields 'sandbox-scope '())
     (poo-flow-artifact-alist-ref fields 'checksum-policy '())
     (poo-flow-artifact-alist-ref fields 'analysis-policy '())
     (poo-flow-artifact-alist-ref fields 'index-policy '())
     (poo-flow-artifact-alist-ref fields 'call-policy '())
     (poo-flow-artifact-alist-ref fields 'publish-policy '())
     (poo-flow-artifact-alist-ref fields 'retention-policy '())
     (poo-flow-artifact-alist-ref fields 'explicit-grants '()))))

(def (poo-flow-durable-artifact? artifact)
  (and (object? artifact)
       (.slot? artifact 'durable-artifact-kind)
       (eq? (.ref artifact 'durable-artifact-kind)
            +poo-flow-durable-artifact-kind+)))

(def (poo-flow-durable-artifact->alist artifact)
  (map (lambda (field) (cons field (.ref artifact field)))
       +poo-flow-durable-artifact-fields+))

(def (poo-flow-artifact-list-has? items value)
  (let loop ((rest items))
    (cond
     ((null? rest) #f)
     ((equal? (car rest) value) #t)
     (else (loop (cdr rest))))))

(def (poo-flow-artifact-scope-subset? actor-scope artifact-scope)
  (let loop ((rest actor-scope))
    (cond
     ((null? rest) #t)
     ((poo-flow-artifact-list-has? artifact-scope (car rest))
      (loop (cdr rest)))
     (else #f))))

(def (poo-flow-durable-artifact-explicit-grant? artifact actor)
  (let ((artifact-id (.ref artifact 'artifact-id))
        (actor-ref (and (object? actor)
                        (.slot? actor 'actor-ref)
                        (.ref actor 'actor-ref))))
    (or (and (object? actor)
             (.slot? actor 'artifact-grants)
             (poo-flow-artifact-list-has? (.ref actor 'artifact-grants)
                                          artifact-id))
        (and actor-ref
             (poo-flow-artifact-list-has? (.ref artifact 'explicit-grants)
                                          actor-ref)))))

(def (poo-flow-durable-artifact-visible? artifact actor)
  (let ((actor-scope (if (and (object? actor) (.slot? actor 'scope))
                       (.ref actor 'scope)
                       '()))
        (artifact-scope (.ref artifact 'artifact-scope)))
    (or (poo-flow-artifact-scope-subset? actor-scope artifact-scope)
        (poo-flow-durable-artifact-explicit-grant? artifact actor))))

(def (poo-flow-durable-artifact-lifecycle-transition-allowed? from-state to-state)
  (poo-flow-artifact-list-has?
   +poo-flow-durable-artifact-lifecycle-edges+
   (cons from-state to-state)))

(def (poo-flow-durable-artifact-transition artifact to-state)
  (let (from-state (.ref artifact 'lifecycle-state))
    (if (poo-flow-durable-artifact-lifecycle-transition-allowed?
         from-state
         to-state)
      (poo-flow-durable-artifact/direct
       (.ref artifact 'artifact-id)
       (.ref artifact 'artifact-kind)
       (.ref artifact 'artifact-scope)
       (.ref artifact 'storage-class)
       to-state
       (.ref artifact 'producer-ref)
       (.ref artifact 'owner-ref)
       (.ref artifact 'sandbox-scope)
       (.ref artifact 'checksum-policy)
       (.ref artifact 'analysis-policy)
       (.ref artifact 'index-policy)
       (.ref artifact 'call-policy)
       (.ref artifact 'publish-policy)
       (.ref artifact 'retention-policy)
       (.ref artifact 'explicit-grants))
      (error "durable artifact lifecycle transition is not allowed"
             from-state
             to-state))))

(def +poo-flow-durable-artifact-policy-receipt-kind+
  'poo-flow.durable.artifact.policy-receipt)

(def +poo-flow-durable-artifact-policy-receipt-schema+
  'poo-flow.durable.artifact.policy-receipt.v1)

(def +poo-flow-durable-artifact-policy-receipt-fields+
  '(artifact-policy-receipt-kind
    artifact-policy-receipt-schema
    artifact-id
    profile-name
    database-name
    valid?
    scope-contained?
    storage-supported?
    analysis-supported?
    publish-gated?
    retention-supported?
    lifecycle-state-valid?
    database-storage-supported?
    database-capability-satisfied?
    diagnostics
    runtime-executed
    source))

(def +poo-flow-durable-artifact-lifecycle-states+
  '(created
    stored
    indexed
    analyzed
    callable
    publish-approved
    published
    retained
    expired
    archived
    revoked))

(def (poo-flow-artifact-value->list value)
  (cond
   ((null? value) '())
   ((pair? value) value)
   (else (list value))))

(def (poo-flow-artifact-values-contained? required allowed)
  (poo-flow-artifact-scope-subset?
   (poo-flow-artifact-value->list required)
   (poo-flow-artifact-value->list allowed)))

(def (poo-flow-artifact-diagnostic diagnostics ok? code)
  (if ok?
    diagnostics
    (cons code diagnostics)))

(def (poo-flow-durable-artifact-lifecycle-state-valid? state)
  (poo-flow-artifact-list-has?
   +poo-flow-durable-artifact-lifecycle-states+
   state))

(def (poo-flow-durable-artifact-policy-receipt/direct
      artifact-id-value
      profile-name-value
      database-name-value
      valid-value
      scope-contained-value
      storage-supported-value
      analysis-supported-value
      publish-gated-value
      retention-supported-value
      lifecycle-state-valid-value
      database-storage-supported-value
      database-capability-satisfied-value
      diagnostics-value)
  (.o (artifact-policy-receipt-kind
       +poo-flow-durable-artifact-policy-receipt-kind+)
      (artifact-policy-receipt-schema
       +poo-flow-durable-artifact-policy-receipt-schema+)
      (artifact-id artifact-id-value)
      (profile-name profile-name-value)
      (database-name database-name-value)
      (valid? valid-value)
      (scope-contained? scope-contained-value)
      (storage-supported? storage-supported-value)
      (analysis-supported? analysis-supported-value)
      (publish-gated? publish-gated-value)
      (retention-supported? retention-supported-value)
      (lifecycle-state-valid? lifecycle-state-valid-value)
      (database-storage-supported? database-storage-supported-value)
      (database-capability-satisfied? database-capability-satisfied-value)
      (diagnostics diagnostics-value)
      (runtime-executed #f)
      (source 'poo-flow.durable.artifact.policy)))

(def (poo-flow-durable-artifact-validate artifact profile database-profile)
  (let* ((artifact-id-value (.ref artifact 'artifact-id))
         (profile-name-value (.ref profile 'name))
         (database-name-value (.ref database-profile 'name))
         (scope-contained-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'artifact-scope)
           (.ref profile 'scope)))
         (storage-supported-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'storage-class)
           (.ref profile 'storage)))
         (analysis-supported-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'analysis-policy)
           (.ref profile 'analysis)))
         (publish-gated-value
          (and (poo-flow-artifact-values-contained?
                (.ref artifact 'publish-policy)
                (.ref profile 'publish))
               (poo-flow-artifact-publish-gated? profile)
               #t))
         (retention-supported-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'retention-policy)
           (.ref profile 'retention)))
         (lifecycle-state-valid-value
          (poo-flow-durable-artifact-lifecycle-state-valid?
           (.ref artifact 'lifecycle-state)))
         (database-storage-supported-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'storage-class)
           (.ref database-profile 'storage)))
         (database-capability-satisfied-value
          (poo-flow-artifact-values-contained?
           (.ref artifact 'index-policy)
           (.ref database-profile 'capabilities)))
         (diagnostics
          (reverse
           (poo-flow-artifact-diagnostic
            (poo-flow-artifact-diagnostic
             (poo-flow-artifact-diagnostic
              (poo-flow-artifact-diagnostic
               (poo-flow-artifact-diagnostic
                (poo-flow-artifact-diagnostic
                 (poo-flow-artifact-diagnostic
                  (poo-flow-artifact-diagnostic
                   '()
                   scope-contained-value
                   'artifact-scope-not-contained-by-profile)
                  storage-supported-value
                  'artifact-storage-not-supported-by-profile)
                 analysis-supported-value
                 'artifact-analysis-not-supported-by-profile)
                publish-gated-value
                'artifact-publish-policy-not-gated)
               retention-supported-value
               'artifact-retention-not-supported-by-profile)
              lifecycle-state-valid-value
              'artifact-lifecycle-state-invalid)
             database-storage-supported-value
             'artifact-storage-not-supported-by-database)
            database-capability-satisfied-value
            'artifact-database-capability-not-satisfied)))
         (valid-value (and scope-contained-value
                           storage-supported-value
                           analysis-supported-value
                           publish-gated-value
                           retention-supported-value
                           lifecycle-state-valid-value
                           database-storage-supported-value
                           database-capability-satisfied-value
                           #t)))
    (poo-flow-durable-artifact-policy-receipt/direct
     artifact-id-value
     profile-name-value
     database-name-value
     valid-value
     scope-contained-value
     storage-supported-value
     analysis-supported-value
     publish-gated-value
     retention-supported-value
     lifecycle-state-valid-value
     database-storage-supported-value
     database-capability-satisfied-value
     diagnostics)))

(def (poo-flow-durable-artifact-policy-receipt? receipt)
  (and (object? receipt)
       (.slot? receipt 'artifact-policy-receipt-kind)
       (eq? (.ref receipt 'artifact-policy-receipt-kind)
            +poo-flow-durable-artifact-policy-receipt-kind+)))

(def (poo-flow-durable-artifact-policy-receipt-valid? receipt)
  (.ref receipt 'valid?))

(def (poo-flow-durable-artifact-policy-receipt->alist receipt)
  (map (lambda (field) (cons field (.ref receipt field)))
       +poo-flow-durable-artifact-policy-receipt-fields+))

(def +poo-flow-durable-artifact-manifest-receipt-kind+
  'poo-flow.durable.artifact.manifest-receipt)

(def +poo-flow-durable-artifact-manifest-receipt-schema+
  'poo-flow.durable.artifact.manifest-receipt.v1)

(def +poo-flow-durable-artifact-manifest-handoff-schema+
  'poo-flow.durable.artifact.marlin-handoff.v1)

(defstruct poo-flow-durable-artifact-manifest-receipt
  (manifest-id
   artifact-id
   artifact-kind
   storage-class
   lifecycle-state
   producer-ref
   owner-ref
   sandbox-scope
   policy-receipt
   artifact-row
   profile-row
   database-row
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   runtime-executed)
  transparent: #t)

(def (poo-flow-artifact-option-ref options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

(def (poo-flow-artifact-manifest-diagnostics manifest-id policy-row)
  (append
   (if (symbol? manifest-id)
     '()
     (list 'artifact-manifest-id-must-be-symbol))
   (if (eq? (poo-flow-artifact-alist-ref policy-row 'valid? #f) #t)
     '()
     (list 'artifact-policy-receipt-invalid))))

(def (poo-flow-durable-artifact-manifest artifact
                                         profile
                                         database-profile
                                         . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (policy-receipt
          (poo-flow-durable-artifact-validate artifact
                                              profile
                                              database-profile))
         (policy-row
          (poo-flow-durable-artifact-policy-receipt->alist policy-receipt))
         (manifest-id
          (poo-flow-artifact-option-ref
           options
           'manifest-id
           (list 'artifact-manifest (.ref artifact 'artifact-id))))
         (metadata
          (poo-flow-artifact-option-ref options 'metadata '()))
         (runtime-owner
          (poo-flow-artifact-option-ref options
                                        'runtime-owner
                                        "marlin-agent-core"))
         (diagnostics
          (poo-flow-artifact-manifest-diagnostics manifest-id policy-row))
         (valid-value
          (and (null? diagnostics)
               (eq? (poo-flow-artifact-alist-ref policy-row 'valid? #f) #t)
               #t)))
    (make-poo-flow-durable-artifact-manifest-receipt
     manifest-id
     (.ref artifact 'artifact-id)
     (.ref artifact 'artifact-kind)
     (.ref artifact 'storage-class)
     (.ref artifact 'lifecycle-state)
     (.ref artifact 'producer-ref)
     (.ref artifact 'owner-ref)
     (.ref artifact 'sandbox-scope)
     policy-row
     (poo-flow-durable-artifact->alist artifact)
     (poo-flow-artifact-profile->alist profile)
     (poo-flow-artifact-database-profile->alist database-profile)
     valid-value
     diagnostics
     metadata
     runtime-owner
     #t
     #f)))

(def (poo-flow-durable-artifact-manifest-receipt->alist receipt)
  (list
   (cons 'kind +poo-flow-durable-artifact-manifest-receipt-kind+)
   (cons 'schema +poo-flow-durable-artifact-manifest-receipt-schema+)
   (cons 'manifest-id
         (poo-flow-durable-artifact-manifest-receipt-manifest-id receipt))
   (cons 'artifact-id
         (poo-flow-durable-artifact-manifest-receipt-artifact-id receipt))
   (cons 'artifact-kind
         (poo-flow-durable-artifact-manifest-receipt-artifact-kind receipt))
   (cons 'storage-class
         (poo-flow-durable-artifact-manifest-receipt-storage-class receipt))
   (cons 'lifecycle-state
         (poo-flow-durable-artifact-manifest-receipt-lifecycle-state receipt))
   (cons 'producer-ref
         (poo-flow-durable-artifact-manifest-receipt-producer-ref receipt))
   (cons 'owner-ref
         (poo-flow-durable-artifact-manifest-receipt-owner-ref receipt))
   (cons 'sandbox-scope
         (poo-flow-durable-artifact-manifest-receipt-sandbox-scope receipt))
   (cons 'policy-receipt
         (poo-flow-durable-artifact-manifest-receipt-policy-receipt receipt))
   (cons 'artifact-row
         (poo-flow-durable-artifact-manifest-receipt-artifact-row receipt))
   (cons 'profile-row
         (poo-flow-durable-artifact-manifest-receipt-profile-row receipt))
   (cons 'database-row
         (poo-flow-durable-artifact-manifest-receipt-database-row receipt))
   (cons 'valid?
         (poo-flow-durable-artifact-manifest-receipt-valid? receipt))
   (cons 'diagnostics
         (poo-flow-durable-artifact-manifest-receipt-diagnostics receipt))
   (cons 'diagnostic-count
         (length
          (poo-flow-durable-artifact-manifest-receipt-diagnostics receipt)))
   (cons 'metadata
         (poo-flow-durable-artifact-manifest-receipt-metadata receipt))
   (cons 'runtime-owner
         (poo-flow-durable-artifact-manifest-receipt-runtime-owner receipt))
   (cons 'handoff-required
         (poo-flow-durable-artifact-manifest-receipt-handoff-required receipt))
   (cons 'runtime-executed
         (poo-flow-durable-artifact-manifest-receipt-runtime-executed receipt))))

(def (poo-flow-durable-artifact-manifest->marlin-handoff receipt
                                                           . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (manifest-row
          (poo-flow-durable-artifact-manifest-receipt->alist receipt))
         (operation
          (poo-flow-artifact-option-ref options
                                        'manifest-operation
                                        'durable-artifact-manifest))
         (command-executable
          (poo-flow-artifact-option-ref options
                                        'executable
                                        "marlin-artifact-store"))
         (command-arguments
          (poo-flow-artifact-option-ref options
                                        'arguments
                                        '("durable-artifact" "manifest")))
         (command-protocol
          (poo-flow-artifact-option-ref options
                                        'protocol
                                        'stdout-s-expression))
         (command-metadata
          (list
           (cons 'source 'poo-flow.durable.artifact.manifest)
           (cons 'artifact-id
                 (poo-flow-durable-artifact-manifest-receipt-artifact-id
                  receipt))
           (cons 'runtime-executed #f)))
         (envelope
          (list
           (cons 'schema +runtime-request-schema+)
           (cons 'runtime 'marlin)
           (cons 'operation operation)
           (cons 'request-id
                 (list 'poo-flow.durable.artifact.manifest
                       (poo-flow-durable-artifact-manifest-receipt-artifact-id
                        receipt)))
           (cons 'artifact-handle
                 (poo-flow-durable-artifact-manifest-receipt-artifact-id
                  receipt))
           (cons 'request
                 (list (cons 'artifact-manifest manifest-row)))
           (cons 'policy
                 (list
                  (cons 'runtime-owner
                        (poo-flow-durable-artifact-manifest-receipt-runtime-owner
                         receipt))
                  (cons 'handoff-required #t)
                  (cons 'runtime-executed #f)))
           (cons 'plan-id #f)
           (cons 'node-id
                 (poo-flow-durable-artifact-manifest-receipt-manifest-id
                  receipt))
           (cons 'frontier '())))
         (manifest
          (runtime-command-fields->manifest
           operation
           command-executable
           command-arguments
           command-protocol
           command-metadata
           envelope)))
    (list
     (cons 'kind 'poo-flow.durable.artifact.marlin-handoff)
     (cons 'schema +poo-flow-durable-artifact-manifest-handoff-schema+)
     (cons 'request-schema +runtime-request-schema+)
     (cons 'operation operation)
     (cons 'request-id (poo-flow-artifact-alist-ref manifest 'request-id #f))
     (cons 'artifact-id
           (poo-flow-durable-artifact-manifest-receipt-artifact-id receipt))
     (cons 'manifest-id
           (poo-flow-durable-artifact-manifest-receipt-manifest-id receipt))
     (cons 'runtime-owner
           (poo-flow-durable-artifact-manifest-receipt-runtime-owner receipt))
     (cons 'handoff-ready?
           (poo-flow-durable-artifact-manifest-receipt-valid? receipt))
     (cons 'artifact-manifest manifest-row)
     (cons 'runtime-command-manifest manifest)
     (cons 'runtime-executed #f)
     (cons 'runtime-parses-scheme-source #f)
     (cons 'scheme-manufactures-runtime-handlers #f))))

(defsyntax (artifact-profile stx)
  (syntax-case stx (:with)
    ((_ name section ... :with (hook ...))
     #'(poo-flow-artifact-profile-apply-hooks
        (poo-flow-artifact-profile 'name '(section ...))
        (list hook ...)))
    ((_ name section ... :with hook)
     #'(hook (poo-flow-artifact-profile 'name '(section ...))))
    ((_ name section ...)
     #'(poo-flow-artifact-profile 'name '(section ...)))))

(defsyntax (database-profile stx)
  (syntax-case stx ()
    ((_ name section ...)
     #'(poo-flow-artifact-database-profile 'name '(section ...)))))

(defsyntax (durable-artifact stx)
  (syntax-case stx ()
    ((_ artifact-id section ...)
     #'(poo-flow-durable-artifact 'artifact-id '(section ...)))))

(defsyntax (artifact-module stx)
  (syntax-case stx ()
    ((_ (_ name section ...) ...)
     #'(.o (name (artifact-profile name section ...)) ...))))

(defsyntax (database-module stx)
  (syntax-case stx ()
    ((_ (_ name section ...) ...)
     #'(.o (name (database-profile name section ...)) ...))))
