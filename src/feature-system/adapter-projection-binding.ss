(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/capability-model
        :poo-flow/src/feature-system/policy-strategy-binding
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export +feature-adapter-capability-catalog-kind+
        feature-adapter-capability-catalog
        feature-adapter-capability-catalog?
        feature-adapter-capability-catalog-ref
        require-valid-feature-adapter-capability-catalog
        require-feature-adapter-capability-catalog-ref
        defpoo-feature-adapter-capability-catalog
        feature-adapter-projection-binding
        require-feature-adapter-projection-binding
        defpoo-feature-adapter-projection-binding)

(def +feature-adapter-capability-catalog-kind+
  'poo-flow.feature-adapter-capability-catalog.v1)

(def (constant-feature-capability-binding-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-capability-binding-diagnostic
      code channel subject expected observed)
  (constant-feature-capability-binding-object
   `((kind . poo-flow.feature-adapter-projection-binding-diagnostic.v1)
     (code . ,code)
     (channel . ,channel)
     (subject . ,subject)
     (expected . ,expected)
     (observed . ,observed))))

(def (feature-adapter-capability-catalog? value)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (and (object? value)
          (eq? (.ref value 'kind)
               +feature-adapter-capability-catalog-kind+)))))

(def (feature-invalid-value-diagnostics
      values predicate code channel expected-kind)
  (poo-flow-filter-map
   (lambda (value)
     (and (not (predicate value))
          (feature-capability-binding-diagnostic
           code channel value expected-kind value)))
   values))

(def (feature-valid-values values predicate)
  (poo-flow-filter-map
   (lambda (value) (and (predicate value) value))
   values))

(def (feature-duplicate-id-diagnostics
      values id-slot code channel)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (poo-flow-fold-left
      (lambda (value diagnostics)
        (let (semantic-id (.ref value id-slot))
          (cond
           ((hash-get duplicates semantic-id) diagnostics)
           ((hash-get seen semantic-id)
            (hash-put! duplicates semantic-id #t)
            (cons
             (feature-capability-binding-diagnostic
              code channel semantic-id 'unique semantic-id)
             diagnostics))
           (else
            (hash-put! seen semantic-id #t)
            diagnostics))))
      '()
      values))))

(def (feature-index-values values id-slot)
  (let (index (make-hash-table))
    (for-each
     (lambda (value) (hash-put! index (.ref value id-slot) value))
     values)
    index))

(def (feature-adapter-capability-catalog catalog-id capabilities)
  (let* ((valid-capabilities
          (feature-valid-values
           capabilities feature-adapter-capability?))
         (diagnostics
          (append
           (feature-invalid-value-diagnostics
            capabilities
            feature-adapter-capability?
            'invalid-adapter-capability
            'adapter-catalog
            +feature-adapter-capability-kind+)
           (feature-duplicate-id-diagnostics
            valid-capabilities
            'capability-id
            'duplicate-adapter-capability-id
            'adapter-catalog)))
         (accepted? (null? diagnostics))
         (index
          (and accepted?
               (feature-index-values valid-capabilities 'capability-id))))
    (constant-feature-capability-binding-object
     `((kind . ,+feature-adapter-capability-catalog-kind+)
       (schema-version . 1)
       (catalog-id . ,catalog-id)
       (capabilities . ,capabilities)
       (capability-index . ,index)
       (size . ,(length capabilities))
       (accepted? . ,accepted?)
       (status . ,(if accepted? 'ready 'rejected))
       (diagnostics . ,diagnostics)))))

(def (feature-adapter-capability-catalog-ref catalog capability-id)
  (and (feature-adapter-capability-catalog? catalog)
       (.ref catalog 'accepted?)
       (hash-get (.ref catalog 'capability-index) capability-id)))

(def (require-valid-feature-adapter-capability-catalog catalog)
  (if (and (feature-adapter-capability-catalog? catalog)
           (.ref catalog 'accepted?))
    catalog
    (error "feature adapter capability catalog rejected" catalog)))

(def (require-feature-adapter-capability-catalog-ref catalog capability-id)
  (or (feature-adapter-capability-catalog-ref catalog capability-id)
      (error "feature adapter capability is not declared"
             capability-id catalog)))

(def (feature-policy-strategy-binding-state binding)
  (with-catch
   (lambda (_failure)
     (list #f 'invalid-feature-policy-strategy-binding #f #f))
   (lambda ()
     (if (eq? (.ref binding 'kind) 'feature-policy-strategy-binding)
       (if (.ref binding 'accepted?)
         (list
          #t
          #f
          (.ref binding 'assembly)
          (.ref binding 'domain-case))
         (list #f 'feature-policy-strategy-binding-rejected #f #f))
       (list #f 'invalid-feature-policy-strategy-binding #f #f)))))

(def (feature-catalog-state catalog)
  (cond
   ((not (feature-adapter-capability-catalog? catalog))
    (list #f 'invalid-adapter-capability-catalog))
   ((not (.ref catalog 'accepted?))
    (list #f 'adapter-capability-catalog-rejected))
   (else (list #t #f))))

(def (feature-adapter-contract-matches? requirement capability)
  (and (equal? (.ref requirement 'contract-id)
               (.ref capability 'contract-id))
       (equal? (.ref requirement 'contract-version)
               (.ref capability 'contract-version))))

(def (feature-adapter-capability-binding requirement capability)
  (constant-feature-capability-binding-object
   `((kind . poo-flow.feature-adapter-capability-binding.v1)
     (requirement . ,requirement)
     (capability . ,capability)
     (requirement-id . ,(.ref requirement 'requirement-id))
     (capability-id . ,(.ref capability 'capability-id))
     (provider-module-id . ,(.ref capability 'provider-module-id))
     (contract-id . ,(.ref capability 'contract-id))
     (contract-version . ,(.ref capability 'contract-version)))))

(def (feature-bind-adapter-requirements catalog requirements)
  (let* ((valid-requirements
          (feature-valid-values requirements feature-adapter-requirement?))
         (input-diagnostics
          (append
           (feature-invalid-value-diagnostics
            requirements
            feature-adapter-requirement?
            'invalid-adapter-requirement
            'adapters
            +feature-adapter-requirement-kind+)
           (feature-duplicate-id-diagnostics
            valid-requirements
            'requirement-id
            'duplicate-adapter-requirement-id
            'adapters))))
    (if (pair? input-diagnostics)
      (list '() input-diagnostics)
      (let (state
            (poo-flow-fold-left
             (lambda (requirement state)
               (let ((bindings (car state))
                     (diagnostics (cadr state))
                     (capability
                      (feature-adapter-capability-catalog-ref
                       catalog (.ref requirement 'capability-id))))
                 (cond
                  ((not capability)
                   (list
                    bindings
                    (cons
                     (feature-capability-binding-diagnostic
                      'missing-adapter-capability
                      'adapters
                      (.ref requirement 'requirement-id)
                      (.ref requirement 'capability-id)
                      #f)
                     diagnostics)))
                  ((not (feature-adapter-contract-matches?
                         requirement capability))
                   (list
                    bindings
                    (cons
                     (feature-capability-binding-diagnostic
                      'adapter-contract-mismatch
                      'adapters
                      (.ref requirement 'requirement-id)
                      requirement
                      capability)
                     diagnostics)))
                  (else
                   (list
                    (cons
                     (feature-adapter-capability-binding
                      requirement capability)
                     bindings)
                    diagnostics)))))
             (list '() '())
             valid-requirements))
        (list (reverse (car state)) (reverse (cadr state)))))))

(def (feature-projection-binding request projection)
  (constant-feature-capability-binding-object
   `((kind . poo-flow.feature-projection-binding.v1)
     (request . ,request)
     (projection . ,projection)
     (request-id . ,(.ref request 'request-id))
     (projection-id . ,(.ref projection 'projection-id))
     (schema-id . ,(.ref projection 'schema-id)))))

(def (feature-bind-projection-requests domain-case requests)
  (let* ((valid-requests
          (feature-valid-values requests feature-projection-request?))
         (input-diagnostics
          (append
           (feature-invalid-value-diagnostics
            requests
            feature-projection-request?
            'invalid-feature-projection-request
            'projections
            +feature-projection-request-kind+)
           (feature-duplicate-id-diagnostics
            valid-requests
            'request-id
            'duplicate-projection-request-id
            'projections))))
    (if (pair? input-diagnostics)
      (list '() input-diagnostics)
      (let* ((projection-index
              (feature-index-values
               (.ref domain-case 'projection-catalog)
               'projection-id))
             (state
              (poo-flow-fold-left
               (lambda (request state)
                 (let ((bindings (car state))
                       (diagnostics (cadr state))
                       (projection
                        (hash-get
                         projection-index (.ref request 'projection-id))))
                   (cond
                    ((not projection)
                     (list
                      bindings
                      (cons
                       (feature-capability-binding-diagnostic
                        'missing-domain-case-projection
                        'projections
                        (.ref request 'request-id)
                        (.ref request 'projection-id)
                        #f)
                       diagnostics)))
                    ((not (equal? (.ref request 'schema-id)
                                  (.ref projection 'schema-id)))
                     (list
                      bindings
                      (cons
                       (feature-capability-binding-diagnostic
                        'projection-schema-mismatch
                        'projections
                        (.ref request 'request-id)
                        (.ref request 'schema-id)
                        (.ref projection 'schema-id))
                       diagnostics)))
                    (else
                     (list
                      (cons
                       (feature-projection-binding request projection)
                       bindings)
                      diagnostics)))))
               (list '() '())
               valid-requests)))
        (list (reverse (car state)) (reverse (cadr state)))))))

(def (feature-adapter-projection-binding catalog policy-strategy-binding)
  (let* ((binding-state
          (feature-policy-strategy-binding-state policy-strategy-binding))
         (catalog-state (feature-catalog-state catalog)))
    (if (or (not (car binding-state)) (not (car catalog-state)))
      (constant-feature-capability-binding-object
       `((kind . feature-adapter-projection-binding)
         (schema-version . 1)
         (policy-strategy-binding . ,policy-strategy-binding)
         (assembly . #f)
         (domain-case . #f)
         (capability-catalog . ,catalog)
         (adapter-bindings . ())
         (projection-bindings . ())
         (accepted? . #f)
         (status . rejected)
         (diagnostics
          . ,(append
              (if (car binding-state)
                '()
                (list
                 (feature-capability-binding-diagnostic
                  (cadr binding-state)
                  'binding
                  policy-strategy-binding
                  'accepted-feature-policy-strategy-binding
                  policy-strategy-binding)))
              (if (car catalog-state)
                '()
                (list
                 (feature-capability-binding-diagnostic
                  (cadr catalog-state)
                  'adapter-catalog
                  catalog
                  +feature-adapter-capability-catalog-kind+
                  catalog)))))))
      (let* ((assembly (caddr binding-state))
             (domain-case (cadddr binding-state))
             (adapter-result
              (feature-bind-adapter-requirements
               catalog (.ref assembly 'adapter-requirements)))
             (projection-result
              (feature-bind-projection-requests
               domain-case (.ref assembly 'projection-requests)))
             (diagnostics
              (append (cadr adapter-result) (cadr projection-result)))
             (accepted? (null? diagnostics)))
        (constant-feature-capability-binding-object
         `((kind . feature-adapter-projection-binding)
           (schema-version . 1)
           (policy-strategy-binding . ,policy-strategy-binding)
           (assembly . ,assembly)
           (domain-case . ,domain-case)
           (capability-catalog . ,catalog)
           (adapter-bindings . ,(car adapter-result))
           (projection-bindings . ,(car projection-result))
           (accepted? . ,accepted?)
           (status . ,(if accepted? 'ready 'rejected))
           (diagnostics . ,diagnostics)))))))

(def (require-feature-adapter-projection-binding binding)
  (if (.ref binding 'accepted?)
    binding
    (error "feature adapter/projection binding rejected"
           (.ref binding 'diagnostics))))

(defrules defpoo-feature-adapter-capability-catalog
  (catalog-id capabilities)
  ((_ binding
      (catalog-id semantic-id)
      (capabilities capability ...))
   (def binding
     (feature-adapter-capability-catalog
      semantic-id (list capability ...)))))

(defrules defpoo-feature-adapter-projection-binding
  (using-catalog from-binding)
  ((_ binding
      (using-catalog catalog)
      (from-binding policy-strategy-binding))
   (def binding
     (feature-adapter-projection-binding
      catalog policy-strategy-binding))))
