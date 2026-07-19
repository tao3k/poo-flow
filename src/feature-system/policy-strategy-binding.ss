(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/domain-case-assembly
        :poo-flow/src/utilities/functional)

(export +feature-policy-contribution-kind+
        +feature-strategy-contribution-kind+
        feature-policy-contribution
        feature-policy-contribution?
        feature-strategy-contribution
        feature-strategy-contribution?
        defpoo-feature-policy-contribution
        defpoo-feature-strategy-contribution
        feature-policy-strategy-binding
        require-feature-policy-strategy-binding
        defpoo-feature-policy-strategy-binding)

(def +feature-policy-contribution-kind+
  'poo-flow.feature-policy-contribution.v1)

(def +feature-strategy-contribution-kind+
  'poo-flow.feature-strategy-contribution.v1)

(def (constant-feature-binding-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-algebra-contribution kind contribution-id algebra-id prototype)
  (constant-feature-binding-object
   `((kind . ,kind)
     (schema-version . 1)
     (contribution-id . ,contribution-id)
     (algebra-id . ,algebra-id)
     (prototype . ,prototype))))

(def (feature-algebra-contribution? value expected-kind)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (and (eq? (.ref value 'kind) expected-kind)
          (.ref value 'contribution-id)
          (.ref value 'algebra-id)
          (object? (.ref value 'prototype))
          #t))))

(defrules define-feature-algebra-contribution-family ()
  ((_ kind-constant constructor predicate)
   (begin
     (def (constructor contribution-id algebra-id prototype)
       (feature-algebra-contribution
        kind-constant contribution-id algebra-id prototype))
     (def (predicate value)
       (feature-algebra-contribution? value kind-constant)))))

(define-feature-algebra-contribution-family
  +feature-policy-contribution-kind+
  feature-policy-contribution
  feature-policy-contribution?)

(define-feature-algebra-contribution-family
  +feature-strategy-contribution-kind+
  feature-strategy-contribution
  feature-strategy-contribution?)

(def (feature-binding-diagnostic code channel observed)
  (constant-feature-binding-object
   `((kind . poo-flow.feature-policy-strategy-binding-diagnostic.v1)
     (code . ,code)
     (channel . ,channel)
     (observed . ,observed))))

(def (feature-binding-code channel suffix)
  (case channel
    ((policy)
     (case suffix
       ((invalid) 'invalid-policy-contribution)
       ((duplicate) 'duplicate-policy-contribution-id)
       ((missing-algebra) 'missing-policy-algebra)
       ((mismatch) 'policy-algebra-mismatch)
       ((composition) 'policy-role-composition-failed)))
    ((strategy)
     (case suffix
       ((invalid) 'invalid-strategy-contribution)
       ((duplicate) 'duplicate-strategy-contribution-id)
       ((missing-algebra) 'missing-strategy-algebra)
       ((mismatch) 'strategy-algebra-mismatch)
       ((composition) 'strategy-role-composition-failed)))))

(def (feature-valid-contributions contribution? contributions)
  (poo-flow-filter-map
   (lambda (contribution)
     (and (contribution? contribution) contribution))
   contributions))

(def (feature-invalid-contribution-diagnostics
      channel contribution? contributions)
  (poo-flow-filter-map
   (lambda (contribution)
     (and (not (contribution? contribution))
          (feature-binding-diagnostic
           (feature-binding-code channel 'invalid)
           channel
           contribution)))
   contributions))

(def (feature-duplicate-contribution-diagnostics channel contributions)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (poo-flow-fold-left
      (lambda (contribution diagnostics)
        (let (contribution-id (.ref contribution 'contribution-id))
          (cond
           ((hash-get duplicates contribution-id) diagnostics)
           ((hash-get seen contribution-id)
            (hash-put! duplicates contribution-id #t)
            (cons
             (feature-binding-diagnostic
              (feature-binding-code channel 'duplicate)
              channel
              contribution-id)
             diagnostics))
           (else
            (hash-put! seen contribution-id #t)
            diagnostics))))
      '()
      contributions))))

(def (feature-algebra-mismatch-diagnostics
      channel algebra-id contributions)
  (if algebra-id
    (poo-flow-filter-map
     (lambda (contribution)
       (let (observed-algebra-id (.ref contribution 'algebra-id))
         (and (not (equal? algebra-id observed-algebra-id))
              (feature-binding-diagnostic
               (feature-binding-code channel 'mismatch)
               channel
               `((expected . ,algebra-id)
                 (observed . ,observed-algebra-id)
                 (contribution-id
                  . ,(.ref contribution 'contribution-id)))))))
     contributions)
    '()))

(def (feature-compose-contribution-prototypes channel contributions)
  (if (null? contributions)
    (list #t #f '())
    (with-catch
     (lambda (failure)
       (list
        #f
        #f
        (list
         (feature-binding-diagnostic
          (feature-binding-code channel 'composition)
          channel
          failure))))
     (lambda ()
       (list
        #t
        (apply role-compose
               (reverse
                (poo-flow-map
                 (lambda (contribution) (.ref contribution 'prototype))
                 contributions)))
        '())))))

(def (feature-one-algebra-binding
      channel kind contribution? algebra-id contributions)
  (let* ((valid-contributions
          (feature-valid-contributions contribution? contributions))
         (diagnostics
          (append
           (feature-invalid-contribution-diagnostics
            channel contribution? contributions)
           (feature-duplicate-contribution-diagnostics
            channel valid-contributions)
           (if (and (pair? valid-contributions) (not algebra-id))
             (list
              (feature-binding-diagnostic
               (feature-binding-code channel 'missing-algebra)
               channel
               (poo-flow-map
                (lambda (contribution)
                  (.ref contribution 'contribution-id))
                valid-contributions)))
             '())
           (feature-algebra-mismatch-diagnostics
            channel algebra-id valid-contributions)))
         (composition
          (if (pair? diagnostics)
            (list #f #f '())
            (feature-compose-contribution-prototypes
             channel valid-contributions)))
         (composition-diagnostics (caddr composition))
         (all-diagnostics (append diagnostics composition-diagnostics))
         (accepted? (and (car composition) (null? all-diagnostics))))
    (constant-feature-binding-object
     `((kind . ,kind)
       (schema-version . 1)
       (channel . ,channel)
       (algebra-id . ,algebra-id)
       (contributions . ,contributions)
       (contribution-count . ,(length contributions))
       (prototype . ,(cadr composition))
       (accepted? . ,accepted?)
       (status . ,(if accepted? 'ready 'rejected))
       (diagnostics . ,all-diagnostics)))))

(def (feature-domain-case-assembly-state assembly)
  (with-catch
   (lambda (_failure) (list #f #f 'invalid-domain-case-assembly))
   (lambda ()
     (if (eq? (.ref assembly 'kind) 'feature-domain-case-assembly)
       (if (.ref assembly 'accepted?)
         (list #t (.ref assembly 'domain-case) #f)
         (list #f #f 'domain-case-assembly-rejected))
       (list #f #f 'invalid-domain-case-assembly)))))

(def (feature-policy-strategy-binding assembly)
  (let* ((assembly-state (feature-domain-case-assembly-state assembly))
         (assembly-accepted? (car assembly-state))
         (domain-case (cadr assembly-state)))
    (if (not assembly-accepted?)
      (constant-feature-binding-object
       `((kind . feature-policy-strategy-binding)
         (schema-version . 1)
         (assembly . ,assembly)
         (domain-case . #f)
         (policy-binding . #f)
         (strategy-binding . #f)
         (accepted? . #f)
         (status . rejected)
         (diagnostics
          . ,(list
              (feature-binding-diagnostic
               (caddr assembly-state) 'assembly assembly)))))
      (let* ((policy-binding
              (feature-one-algebra-binding
               'policy
               'poo-flow.feature-policy-algebra-binding.v1
               feature-policy-contribution?
               (.ref domain-case 'policy-algebra)
               (.ref assembly 'policy-contributions)))
             (strategy-binding
              (feature-one-algebra-binding
               'strategy
               'poo-flow.feature-strategy-algebra-binding.v1
               feature-strategy-contribution?
               (.ref domain-case 'strategy-algebra)
               (.ref assembly 'strategy-contributions)))
             (diagnostics
              (append (.ref policy-binding 'diagnostics)
                      (.ref strategy-binding 'diagnostics)))
             (accepted? (null? diagnostics)))
        (constant-feature-binding-object
         `((kind . feature-policy-strategy-binding)
           (schema-version . 1)
           (assembly . ,assembly)
           (domain-case . ,domain-case)
           (policy-binding . ,policy-binding)
           (strategy-binding . ,strategy-binding)
           (accepted? . ,accepted?)
           (status . ,(if accepted? 'ready 'rejected))
           (diagnostics . ,diagnostics)))))))

(def (require-feature-policy-strategy-binding binding)
  (if (.ref binding 'accepted?)
    binding
    (error "feature policy/strategy binding rejected"
           (.ref binding 'diagnostics))))

(defrules defpoo-feature-algebra-contribution ()
  ((_ constructor binding
      (contribution-id semantic-id)
      (algebra-id algebra-identity)
      (prototype role-prototype))
   (def binding
     (constructor semantic-id algebra-identity role-prototype))))

(defrules defpoo-feature-policy-contribution
  (contribution-id algebra-id prototype)
  ((_ binding
      (contribution-id semantic-id)
      (algebra-id algebra-identity)
      (prototype role-prototype))
   (defpoo-feature-algebra-contribution
     feature-policy-contribution
     binding
     (contribution-id semantic-id)
     (algebra-id algebra-identity)
     (prototype role-prototype))))

(defrules defpoo-feature-strategy-contribution
  (contribution-id algebra-id prototype)
  ((_ binding
      (contribution-id semantic-id)
      (algebra-id algebra-identity)
      (prototype role-prototype))
   (defpoo-feature-algebra-contribution
     feature-strategy-contribution
     binding
     (contribution-id semantic-id)
     (algebra-id algebra-identity)
     (prototype role-prototype))))

(defrules defpoo-feature-policy-strategy-binding
  (from-assembly)
  ((_ binding (from-assembly assembly))
   (def binding (feature-policy-strategy-binding assembly))))
