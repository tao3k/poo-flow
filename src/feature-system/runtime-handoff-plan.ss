(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/adapter-projection-binding
        :poo-flow/src/utilities/functional)

(export +feature-runtime-c-bundle-version+
        +feature-runtime-bundle-handoff-kind+
        +feature-cedar-input-handoff-kind+
        +feature-evidence-obligation-kind+
        +feature-runtime-handoff-manifest-kind+
        feature-runtime-bundle-handoff
        feature-runtime-bundle-handoff?
        feature-cedar-input-handoff
        feature-cedar-input-handoff?
        feature-evidence-obligation
        feature-evidence-obligation?
        defpoo-feature-runtime-bundle-handoff
        defpoo-feature-cedar-input-handoff
        defpoo-feature-evidence-obligation
        feature-runtime-handoff-manifest
        feature-runtime-handoff-manifest?
        feature-runtime-handoff-manifest-ref
        require-valid-feature-runtime-handoff-manifest
        require-feature-runtime-handoff-manifest-ref
        defpoo-feature-runtime-handoff-manifest
        feature-runtime-handoff-plan
        require-feature-runtime-handoff-plan
        defpoo-feature-runtime-handoff-plan)

(def +feature-runtime-c-bundle-version+ 1)

(def +feature-runtime-bundle-handoff-kind+
  'poo-flow.feature-runtime-bundle-handoff.v1)

(def +feature-cedar-input-handoff-kind+
  'poo-flow.feature-cedar-input-handoff.v1)

(def +feature-evidence-obligation-kind+
  'poo-flow.feature-evidence-obligation.v1)

(def +feature-runtime-handoff-manifest-kind+
  'poo-flow.feature-runtime-handoff-manifest.v1)

(def (constant-feature-runtime-handoff-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-runtime-handoff-value
      kind handoff-id adapter-requirement-id projection-request-id
      contract-id contract-version schema-id)
  (constant-feature-runtime-handoff-object
   `((kind . ,kind)
     (schema-version . 1)
     (handoff-id . ,handoff-id)
     (adapter-requirement-id . ,adapter-requirement-id)
     (projection-request-id . ,projection-request-id)
     (contract-id . ,contract-id)
     (contract-version . ,contract-version)
     (projection-schema-id . ,schema-id))))

(def (feature-runtime-handoff-kind? value expected-kind)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (and (object? value)
          (eq? (.ref value 'kind) expected-kind)
          (.ref value 'handoff-id)
          (.ref value 'adapter-requirement-id)
          (.ref value 'projection-request-id)
          (.ref value 'contract-id)
          (.ref value 'contract-version)
          (.ref value 'projection-schema-id)
          #t))))

(defrules define-feature-runtime-handoff-family ()
  ((_ kind-constant constructor predicate)
   (begin
     (def (constructor handoff-id adapter-requirement-id
                       projection-request-id contract-id
                       contract-version schema-id)
       (feature-runtime-handoff-value
        kind-constant
        handoff-id
        adapter-requirement-id
        projection-request-id
        contract-id
        contract-version
        schema-id))
     (def (predicate value)
       (feature-runtime-handoff-kind? value kind-constant)))))

(define-feature-runtime-handoff-family
  +feature-runtime-bundle-handoff-kind+
  feature-runtime-bundle-handoff
  feature-runtime-bundle-handoff?)

(define-feature-runtime-handoff-family
  +feature-cedar-input-handoff-kind+
  feature-cedar-input-handoff
  feature-cedar-input-handoff?)

(define-feature-runtime-handoff-family
  +feature-evidence-obligation-kind+
  feature-evidence-obligation
  feature-evidence-obligation?)

(def (feature-runtime-handoff? value)
  (or (feature-runtime-bundle-handoff? value)
      (feature-cedar-input-handoff? value)
      (feature-evidence-obligation? value)))

(def (feature-runtime-handoff-diagnostic
      code channel subject expected observed)
  (constant-feature-runtime-handoff-object
   `((kind . poo-flow.feature-runtime-handoff-diagnostic.v1)
     (code . ,code)
     (channel . ,channel)
     (subject . ,subject)
     (expected . ,expected)
     (observed . ,observed))))

(def (feature-runtime-handoff-invalid-diagnostics handoffs)
  (poo-flow-filter-map
   (lambda (handoff)
     (and (not (feature-runtime-handoff? handoff))
          (feature-runtime-handoff-diagnostic
           'invalid-runtime-handoff
           'manifest
           handoff
           'poo-feature-runtime-handoff
           handoff)))
   handoffs))

(def (feature-runtime-handoff-valid-values handoffs)
  (poo-flow-filter-map
   (lambda (handoff) (and (feature-runtime-handoff? handoff) handoff))
   handoffs))

(def (feature-runtime-handoff-duplicate-diagnostics handoffs)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (poo-flow-fold-left
      (lambda (handoff diagnostics)
        (let (handoff-id (.ref handoff 'handoff-id))
          (cond
           ((hash-get duplicates handoff-id) diagnostics)
           ((hash-get seen handoff-id)
            (hash-put! duplicates handoff-id #t)
            (cons
             (feature-runtime-handoff-diagnostic
              'duplicate-runtime-handoff-id
              'manifest
              handoff-id
              'unique
              handoff-id)
             diagnostics))
           (else
            (hash-put! seen handoff-id #t)
            diagnostics))))
      '()
      handoffs))))

(def (feature-runtime-handoff-index values id-slot)
  (let (index (make-hash-table))
    (for-each
     (lambda (value) (hash-put! index (.ref value id-slot) value))
     values)
    index))

(def (feature-runtime-handoff-manifest manifest-id handoffs)
  (let* ((valid-handoffs
          (feature-runtime-handoff-valid-values handoffs))
         (diagnostics
          (append
           (feature-runtime-handoff-invalid-diagnostics handoffs)
           (feature-runtime-handoff-duplicate-diagnostics valid-handoffs)))
         (accepted? (null? diagnostics))
         (index
          (and accepted?
               (feature-runtime-handoff-index valid-handoffs 'handoff-id))))
    (constant-feature-runtime-handoff-object
     `((kind . ,+feature-runtime-handoff-manifest-kind+)
       (schema-version . 1)
       (manifest-id . ,manifest-id)
       (handoffs . ,handoffs)
       (handoff-index . ,index)
       (size . ,(length handoffs))
       (accepted? . ,accepted?)
       (status . ,(if accepted? 'ready 'rejected))
       (diagnostics . ,diagnostics)))))

(def (feature-runtime-handoff-manifest? value)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (and (object? value)
          (eq? (.ref value 'kind)
               +feature-runtime-handoff-manifest-kind+)))))

(def (feature-runtime-handoff-manifest-ref manifest handoff-id)
  (and (feature-runtime-handoff-manifest? manifest)
       (.ref manifest 'accepted?)
       (hash-get (.ref manifest 'handoff-index) handoff-id)))

(def (require-valid-feature-runtime-handoff-manifest manifest)
  (if (and (feature-runtime-handoff-manifest? manifest)
           (.ref manifest 'accepted?))
    manifest
    (error "feature runtime handoff manifest rejected" manifest)))

(def (require-feature-runtime-handoff-manifest-ref manifest handoff-id)
  (or (feature-runtime-handoff-manifest-ref manifest handoff-id)
      (error "feature runtime handoff is not declared"
             handoff-id manifest)))

(def (feature-runtime-handoff-binding-state binding)
  (with-catch
   (lambda (_failure)
     (list #f 'invalid-feature-adapter-projection-binding))
   (lambda ()
     (if (eq? (.ref binding 'kind) 'feature-adapter-projection-binding)
       (if (.ref binding 'accepted?)
         (list #t #f)
         (list #f 'feature-adapter-projection-binding-rejected))
       (list #f 'invalid-feature-adapter-projection-binding)))))

(def (feature-runtime-handoff-manifest-state manifest)
  (cond
   ((not (feature-runtime-handoff-manifest? manifest))
    (list #f 'invalid-feature-runtime-handoff-manifest))
   ((not (.ref manifest 'accepted?))
    (list #f 'feature-runtime-handoff-manifest-rejected))
   (else (list #t #f))))

(def (feature-runtime-handoff-contract-matches? handoff adapter-binding)
  (and (equal? (.ref handoff 'contract-id)
               (.ref adapter-binding 'contract-id))
       (equal? (.ref handoff 'contract-version)
               (.ref adapter-binding 'contract-version))))

(def (feature-runtime-handoff-schema-matches? handoff projection-binding)
  (equal? (.ref handoff 'projection-schema-id)
          (.ref projection-binding 'schema-id)))

(def (feature-one-runtime-handoff-diagnostics
      handoff adapter-binding projection-binding)
  (append
   (if adapter-binding
     '()
     (list
      (feature-runtime-handoff-diagnostic
       'missing-handoff-adapter-requirement
       (.ref handoff 'kind)
       (.ref handoff 'handoff-id)
       (.ref handoff 'adapter-requirement-id)
       #f)))
   (if projection-binding
     '()
     (list
      (feature-runtime-handoff-diagnostic
       'missing-handoff-projection-request
       (.ref handoff 'kind)
       (.ref handoff 'handoff-id)
       (.ref handoff 'projection-request-id)
       #f)))
   (if (and adapter-binding
            (not (feature-runtime-handoff-contract-matches?
                  handoff adapter-binding)))
     (list
      (feature-runtime-handoff-diagnostic
       'runtime-handoff-contract-mismatch
       (.ref handoff 'kind)
       (.ref handoff 'handoff-id)
       handoff
       adapter-binding))
     '())
   (if (and projection-binding
            (not (feature-runtime-handoff-schema-matches?
                  handoff projection-binding)))
     (list
      (feature-runtime-handoff-diagnostic
       'runtime-handoff-schema-mismatch
       (.ref handoff 'kind)
       (.ref handoff 'handoff-id)
       (.ref handoff 'projection-schema-id)
       (.ref projection-binding 'schema-id)))
     '())))

(def (feature-resolved-runtime-handoff
      handoff adapter-binding projection-binding)
  (constant-feature-runtime-handoff-object
   `((kind . poo-flow.feature-resolved-runtime-handoff.v1)
     (handoff-kind . ,(.ref handoff 'kind))
     (handoff-id . ,(.ref handoff 'handoff-id))
     (handoff . ,handoff)
     (adapter-binding . ,adapter-binding)
     (projection-binding . ,projection-binding)
     (provider-module-id . ,(.ref adapter-binding 'provider-module-id))
     (contract-id . ,(.ref adapter-binding 'contract-id))
     (contract-version . ,(.ref adapter-binding 'contract-version))
     (projection-schema-id . ,(.ref projection-binding 'schema-id)))))

(def (feature-resolve-runtime-handoffs binding manifest)
  (let ((adapter-index
         (feature-runtime-handoff-index
          (.ref binding 'adapter-bindings) 'requirement-id))
        (projection-index
         (feature-runtime-handoff-index
          (.ref binding 'projection-bindings) 'request-id)))
    (let (state
          (poo-flow-fold-left
           (lambda (handoff state)
             (let* ((resolved (car state))
                    (diagnostics (cadr state))
                    (adapter-binding
                     (hash-get
                      adapter-index
                      (.ref handoff 'adapter-requirement-id)))
                    (projection-binding
                     (hash-get
                      projection-index
                      (.ref handoff 'projection-request-id)))
                    (handoff-diagnostics
                     (feature-one-runtime-handoff-diagnostics
                      handoff adapter-binding projection-binding)))
               (if (pair? handoff-diagnostics)
                 (list
                  resolved
                  (append (reverse handoff-diagnostics) diagnostics))
                 (list
                  (cons
                   (feature-resolved-runtime-handoff
                    handoff adapter-binding projection-binding)
                   resolved)
                  diagnostics))))
           (list '() '())
           (.ref manifest 'handoffs)))
      (list (reverse (car state)) (reverse (cadr state))))))

(def (feature-runtime-handoff-plan binding manifest)
  (let ((binding-state (feature-runtime-handoff-binding-state binding))
        (manifest-state (feature-runtime-handoff-manifest-state manifest)))
    (if (or (not (car binding-state)) (not (car manifest-state)))
      (constant-feature-runtime-handoff-object
       `((kind . feature-runtime-handoff-plan)
         (schema-version . 1)
         (adapter-projection-binding . ,binding)
         (manifest . ,manifest)
         (resolved-handoffs . ())
         (accepted? . #f)
         (status . rejected)
         (diagnostics
          . ,(append
              (if (car binding-state)
                '()
                (list
                 (feature-runtime-handoff-diagnostic
                  (cadr binding-state)
                  'binding
                  binding
                  'accepted-feature-adapter-projection-binding
                  binding)))
              (if (car manifest-state)
                '()
                (list
                 (feature-runtime-handoff-diagnostic
                  (cadr manifest-state)
                  'manifest
                  manifest
                  +feature-runtime-handoff-manifest-kind+
                  manifest)))))))
      (let* ((resolution
              (feature-resolve-runtime-handoffs binding manifest))
             (diagnostics (cadr resolution))
             (accepted? (null? diagnostics)))
        (constant-feature-runtime-handoff-object
         `((kind . feature-runtime-handoff-plan)
           (schema-version . 1)
           (adapter-projection-binding . ,binding)
           (manifest . ,manifest)
           (resolved-handoffs . ,(car resolution))
           (accepted? . ,accepted?)
           (status . ,(if accepted? 'ready 'rejected))
           (diagnostics . ,diagnostics)))))))

(def (require-feature-runtime-handoff-plan plan)
  (if (.ref plan 'accepted?)
    plan
    (error "feature runtime handoff plan rejected"
           (.ref plan 'diagnostics))))

(defrules defpoo-feature-runtime-bundle-handoff
  (handoff-id adapter-requirement-id projection-request-id
              bundle-contract-id bundle-version schema-id)
  ((_ binding
      (handoff-id semantic-id)
      (adapter-requirement-id requirement-id)
      (projection-request-id request-id)
      (bundle-contract-id contract-id)
      (bundle-version contract-version)
      (schema-id projection-schema-id))
   (def binding
     (feature-runtime-bundle-handoff
      semantic-id
      requirement-id
      request-id
      contract-id
      contract-version
      projection-schema-id))))

(defrules defpoo-feature-cedar-input-handoff
  (handoff-id adapter-requirement-id projection-request-id
              input-contract-id input-contract-version schema-id)
  ((_ binding
      (handoff-id semantic-id)
      (adapter-requirement-id requirement-id)
      (projection-request-id request-id)
      (input-contract-id contract-id)
      (input-contract-version contract-version)
      (schema-id projection-schema-id))
   (def binding
     (feature-cedar-input-handoff
      semantic-id
      requirement-id
      request-id
      contract-id
      contract-version
      projection-schema-id))))

(defrules defpoo-feature-evidence-obligation
  (handoff-id adapter-requirement-id projection-request-id
              evidence-contract-id evidence-contract-version schema-id)
  ((_ binding
      (handoff-id semantic-id)
      (adapter-requirement-id requirement-id)
      (projection-request-id request-id)
      (evidence-contract-id contract-id)
      (evidence-contract-version contract-version)
      (schema-id projection-schema-id))
   (def binding
     (feature-evidence-obligation
      semantic-id
      requirement-id
      request-id
      contract-id
      contract-version
      projection-schema-id))))

(defrules defpoo-feature-runtime-handoff-manifest
  (manifest-id handoffs)
  ((_ binding
      (manifest-id semantic-id)
      (handoffs handoff ...))
   (def binding
     (feature-runtime-handoff-manifest
      semantic-id (list handoff ...)))))

(defrules defpoo-feature-runtime-handoff-plan
  (from-binding using-manifest)
  ((_ binding
      (from-binding adapter-projection-binding)
      (using-manifest manifest))
   (def binding
     (feature-runtime-handoff-plan
      adapter-projection-binding manifest))))
