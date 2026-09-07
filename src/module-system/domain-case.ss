;;; -*- Gerbil -*-
;;; Boundary: DomainCase runtime closure, cache, instance, method, and projection operations.
;;; Invariant: public bindings from domain-case-contracts remain re-exported by this owner.

(export #t (import: :poo-flow/src/module-system/domain-case-contracts))

(import :poo-flow/src/module-system/domain-case-contracts
        (only-in :clan/poo/object .ref object?)
        (only-in :std/crypto/digest sha256)
        (only-in :std/sort sort)
        (only-in :std/text/hex hex-encode)
        (only-in :std/srfi/1 every)
        :poo-flow/src/core/object-syntax
        :poo-flow/src/core/roles
        (only-in :poo-flow/src/utilities/functional
                 poo-flow-fold-left
                 poo-flow-fold-right
                 poo-flow-map
                 poo-flow-find
                 poo-flow-filter-map
                 poo-flow-remove
                 poo-flow-append-map
                 poo-flow-all?
                 poo-flow-member?
                 poo-flow-list-of?))

;; : (-> PooDomainCaseCache)
(def (poo-flow-domain-case-cache)
  (poo-core-role-object
   (slots ((kind +poo-flow-domain-case-cache-kind+)
           (entries (make-hash-table))
           (metrics (vector 0 0))))
   (supers)))

;; : (-> Object Boolean)
(def (poo-flow-domain-case-cache? value)
  (domain-case-object-kind? value +poo-flow-domain-case-cache-kind+))

;; : (-> PooDomainCaseCache Integer)
(def (poo-flow-domain-case-cache-closure-count cache)
  (vector-ref (.ref cache 'metrics) 0))

;; : (-> PooDomainCaseCache Integer)
(def (poo-flow-domain-case-cache-hit-count cache)
  (vector-ref (.ref cache 'metrics) 1))

;; : (-> PooDomainCaseCache Integer Unit)
(def (domain-case-cache-increment! cache index)
  (let (metrics (.ref cache 'metrics))
    (vector-set! metrics index (+ 1 (vector-ref metrics index)))))

;; : (-> Object Boolean)
(def (poo-flow-domain-case? value)
  (domain-case-object-kind? value +poo-flow-domain-case-kind+))

;; : (-> PooDomainCase Integer)
(def (poo-flow-domain-case-instance-mix-count domain-case)
  (vector-ref (.ref domain-case 'metrics) 0))

;; : (-> PooDomainCase Unit)
(def (domain-case-instance-mix-increment! domain-case)
  (let (metrics (.ref domain-case 'metrics))
    (vector-set! metrics 0 (+ 1 (vector-ref metrics 0)))))

;; : (-> PooDomainCase Integer)
(def (poo-flow-domain-case-instance-overlay-count domain-case)
  (vector-ref (.ref domain-case 'metrics) 1))

;; : (-> PooDomainCase Unit)
(def (domain-case-instance-overlay-increment! domain-case)
  (let (metrics (.ref domain-case 'metrics))
    (vector-set! metrics 1 (+ 1 (vector-ref metrics 1)))))

;; : (-> Boolean Object MaybeDomainCase [Alist] Boolean PooDomainCaseClosureReceipt)
(def (domain-case-make-closure-receipt accepted? key case-value diagnostics
                                       cache-hit?)
  (poo-core-role-object
   (slots ((kind +poo-flow-domain-case-closure-receipt-kind+)
           (accepted? accepted?)
           (key key)
           (domain-case case-value)
           (diagnostics diagnostics)
           (cache-hit? cache-hit?)))
   (supers)))

;; : (-> Object Object Object Object Object Object [Alist])
(def (domain-case-closure-input-diagnostics cache schema-id-value
                                            schema-version-value components
                                            local-overrides
                                            selected-projection-ids)
  (append
   (poo-flow-filter-map
    (lambda (diagnostic) diagnostic)
    (list
     (and (not (poo-flow-domain-case-cache? cache))
          (domain-case-diagnostic 'invalid-domain-case-cache '(cache) cache))
     (and (not (domain-case-id? schema-id-value))
          (domain-case-diagnostic
           'invalid-domain-case-schema '(schema-id) schema-id-value))
     (and (not (and (exact-integer? schema-version-value)
                    (> schema-version-value 0)))
          (domain-case-diagnostic
           'invalid-domain-case-version '(schema-version)
           schema-version-value))
     (and (not (and (list? components) (pair? components)))
          (domain-case-diagnostic
           'missing-case-components '(components) components))
     (and (not (poo-flow-list-of? case-slot-contract-valid?
                                  local-overrides))
          (domain-case-diagnostic
           'invalid-local-overrides '(local-overrides) local-overrides))
     (and (not (poo-flow-list-of? domain-case-id?
                                  selected-projection-ids))
          (domain-case-diagnostic
           'invalid-projection-selection '(selected-projections)
           selected-projection-ids))))
   (if (list? selected-projection-ids)
       (poo-flow-map
        (lambda (projection-id)
          (domain-case-diagnostic
           'duplicate-projection-selection '(selected-projections)
           projection-id))
        (domain-case-duplicates selected-projection-ids))
       '())
   (if (list? components)
       (poo-flow-filter-map
        (lambda (component)
          (and (not (poo-flow-case-component-valid? component))
               (domain-case-diagnostic
                'invalid-case-component '(components) component)))
        components)
       '())))

;; : (-> [PooCaseComponent] [PooCaseProjection] [Alist])
(def (domain-case-closure-structural-diagnostics components projections)
  (append
   (poo-flow-map
    (lambda (component-id)
      (domain-case-diagnostic
       'duplicate-component-id '(components) component-id))
    (domain-case-duplicates
     (poo-flow-map
      (lambda (component) (.ref component 'component-id))
      components)))
   (domain-case-parent-diagnostics components)
   (domain-case-type-diagnostics components)
   (domain-case-projection-conflicts projections)))

;; : (-> [PooCaseComponent] Object)
(def (domain-case-compose-components components)
  (with-catch
   (lambda (failure)
     (domain-case-diagnostic
      'role-composition-failed '(components) failure))
   (lambda ()
     (apply role-compose
            (reverse
             (poo-flow-map
              (lambda (component) (.ref component 'role-prototype))
              components))))))

;; : (-> Symbol Integer Object List List [Symbol] PooRole List List List Object Object PooDomainCase)
(def (domain-case-make-closed-value schema-id-value schema-version-value
                                    key descriptor components local-overrides
                                    selected-projection-ids composition
                                    effective-slots effective-contracts
                                    projection-catalog policy-algebra
                                    strategy-algebra)
  (poo-core-role-object
   (slots
    ((kind +poo-flow-domain-case-kind+)
     (schema-id schema-id-value)
     (schema-version schema-version-value)
     (key key)
     (components components)
     (local-overrides local-overrides)
     (shared-prototype composition)
     (instance-overlay-compatible?
      (role-instance-overlay-compatible? composition))
     (type-contracts
      (poo-flow-map
       (lambda (component) (.ref component 'type-contract))
       components))
     (effective-slots effective-slots)
     (effective-contracts effective-contracts)
     (projection-catalog projection-catalog)
     (selected-projection-ids selected-projection-ids)
     (policy-algebra policy-algebra)
     (strategy-algebra strategy-algebra)
     (canonical-descriptor descriptor)
     (metrics (vector 0 0))
     (closed? #t)))
   (supers)))

;; : (-> PooDomainCaseCache Symbol Integer Object Object List List [Symbol] List List List Object Object PooDomainCaseClosureReceipt)
(def (domain-case-cache-resolve cache schema-id-value schema-version-value
                                key descriptor components local-overrides
                                selected-projection-ids effective-slots
                                effective-contracts projection-catalog
                                policy-algebra strategy-algebra)
  (let (cached (hash-get (.ref cache 'entries) key))
    (cond
     ((and cached
           (domain-case-every-eq? components (.ref cached 'components))
           (domain-case-every-eq?
            local-overrides (.ref cached 'local-overrides)))
      (domain-case-cache-increment! cache 1)
      (domain-case-make-closure-receipt #t key cached '() #t))
     (cached
      (domain-case-make-closure-receipt
       #f key #f
       (list
        (domain-case-diagnostic
         'module-owner-identity-alias '(key) key))
       #f))
     (else
      (let (composition (domain-case-compose-components components))
        (if (domain-case-object-kind?
             composition 'poo-flow.domain-case-diagnostic.v1)
            (domain-case-make-closure-receipt
             #f key #f (list composition) #f)
            (let (case-value
                  (domain-case-make-closed-value
                   schema-id-value schema-version-value key descriptor
                   components local-overrides selected-projection-ids
                   composition effective-slots effective-contracts
                   projection-catalog policy-algebra strategy-algebra))
              (hash-put! (.ref cache 'entries) key case-value)
              (domain-case-cache-increment! cache 0)
              (domain-case-make-closure-receipt
               #t key case-value '() #f))))))))

;; : (-> PooCaseSlotContract Symbol)
(def (domain-case-slot-contract-id slot)
  (.ref slot 'slot-id))

;; : (-> PooCaseComponent [PooCaseSlotContract])
(def (domain-case-component-slot-contracts component)
  (.ref component 'slot-contracts))

;; : (-> PooCaseComponent [PooCaseMethodContract])
(def (domain-case-component-method-contracts component)
  (.ref component 'method-contracts))

;; : (-> PooCaseComponent [PooCaseProjection])
(def (domain-case-component-projections component)
  (.ref component 'projections))

;;; Closure boundary: normalize inputs once, resolve every contract family, then admit the cache entry atomically.
;; : (-> PooDomainCaseCache Symbol Integer [PooCaseComponent] [PooCaseSlotContract] [Symbol] PooDomainCaseClosureReceipt)
(def (poo-flow-domain-case-close cache schema-id-value schema-version-value
                                 components
                                 (local-overrides '())
                                 (selected-projection-ids '()))
  (let (input-diagnostics
        (domain-case-closure-input-diagnostics
         cache schema-id-value schema-version-value components
         local-overrides selected-projection-ids))
    (if (pair? input-diagnostics)
        (domain-case-make-closure-receipt
         #f #f #f input-diagnostics #f)
        (let* ((normalized-local-overrides
                (domain-case-sort
                 local-overrides domain-case-slot-contract-id))
               (normalized-selected-projection-ids
                (domain-case-sort-ids selected-projection-ids))
               (all-slots
                (append
                 normalized-local-overrides
                 (poo-flow-append-map
                  domain-case-component-slot-contracts
                  components)))
               (all-contracts
                (poo-flow-append-map
                 domain-case-component-method-contracts
                 components))
               (all-projections
                (poo-flow-append-map
                 domain-case-component-projections
                 components))
               (structural-diagnostics
                (domain-case-closure-structural-diagnostics
                 components all-projections)))
          (let-values (((effective-slots slot-diagnostics)
                        (domain-case-resolve-slots all-slots))
                       ((effective-contracts contract-diagnostics)
                        (domain-case-resolve-method-contracts all-contracts))
                       ((projection-catalog projection-diagnostics)
                        (domain-case-select-projections
                         all-projections normalized-selected-projection-ids))
                       ((policy-algebra policy-diagnostics)
                        (domain-case-single-algebra
                         components 'policy-algebra
                         'policy-algebra-conflict))
                       ((strategy-algebra strategy-diagnostics)
                        (domain-case-single-algebra
                         components 'strategy-algebra
                         'strategy-algebra-conflict)))
            (let* ((diagnostics
                    (append structural-diagnostics
                            slot-diagnostics
                            contract-diagnostics
                            projection-diagnostics
                            policy-diagnostics
                            strategy-diagnostics))
                   (descriptor
                    (poo-flow-domain-case-canonical-descriptor
                     schema-id-value schema-version-value components
                     normalized-local-overrides
                     normalized-selected-projection-ids))
                   (key (poo-flow-domain-case-canonical-key descriptor)))
              (if (pair? diagnostics)
                  (domain-case-make-closure-receipt
                   #f key #f diagnostics #f)
                  (domain-case-cache-resolve
                   cache schema-id-value schema-version-value key descriptor
                   components normalized-local-overrides
                   normalized-selected-projection-ids effective-slots
                   effective-contracts projection-catalog policy-algebra
                   strategy-algebra))))))))

;; : (-> Symbol Object Object Alist)
(def (domain-case-instance-diagnostic code owner observed)
  (domain-case-diagnostic code (list 'instance owner) observed))

;; : (-> PooRole PooCaseSlotContract MaybeAlist)
(def (domain-case-slot-instance-diagnostic instance slot-contract)
  (let* ((missing-marker (list 'missing-slot))
         (slot-id (.ref slot-contract 'slot-id))
         (value
          (with-catch
           (lambda (_failure) missing-marker)
           (lambda () (.ref instance slot-id)))))
    (cond
     ((and (eq? value missing-marker)
           (eq? (.ref slot-contract 'default-id) 'required))
      (domain-case-instance-diagnostic
       'required-slot-missing slot-id #f))
     ((and (not (eq? value missing-marker))
           (not (domain-case-safe-call
                 (.ref slot-contract 'validator) value)))
      (domain-case-instance-diagnostic
       'slot-contract-rejected slot-id value))
     (else #f))))

;; : (-> PooRole PooCaseTypeContract MaybeAlist)
(def (domain-case-type-instance-diagnostic instance type-contract)
  (and (not (domain-case-safe-call
             (.ref type-contract 'predicate) instance))
       (domain-case-instance-diagnostic
        'type-contract-rejected
        (.ref type-contract 'type-id)
        instance)))

;; : (-> PooRole PooCaseMethodContract MaybeAlist)
(def (domain-case-state-instance-diagnostic instance contract)
  (and (eq? (.ref contract 'contract-kind) 'state)
       (not (domain-case-safe-call (.ref contract 'validator) instance))
       (domain-case-instance-diagnostic
        'state-contract-rejected
        (.ref contract 'contract-id)
        instance)))

;; : (-> PooDomainCase PooRole [Alist])
(def (domain-case-instance-diagnostics domain-case instance)
  (append
   (poo-flow-filter-map
    (lambda (slot-contract)
      (domain-case-slot-instance-diagnostic instance slot-contract))
    (.ref domain-case 'effective-slots))
   (poo-flow-filter-map
    (lambda (type-contract)
      (domain-case-type-instance-diagnostic instance type-contract))
    (.ref domain-case 'type-contracts))
   (poo-flow-filter-map
    (lambda (contract)
      (domain-case-state-instance-diagnostic instance contract))
    (.ref domain-case 'effective-contracts))))

;; : (-> Boolean MaybePOOObject [Diagnostic] PooDomainCaseInstanceReceipt)
(def (domain-case-instance-receipt accepted? instance diagnostics)
  (poo-core-role-object
   (slots ((kind +poo-flow-domain-case-instance-receipt-kind+)
           (accepted? accepted?)
           (instance instance)
           (diagnostics diagnostics)))
   (supers)))

;; : (-> Object PooDomainCaseInstanceReceipt)
(def (domain-case-invalid-instance-receipt observed)
  (domain-case-instance-receipt
   #f #f
   (list (domain-case-diagnostic
          'invalid-domain-case-instance-input '(instance) observed))))

;; : (-> PooDomainCase Boolean PooRole PooRole PooRole (Values MaybeSymbol Object))
(def (domain-case-compose-instance domain-case overlay-compatible?
                                   case-marker-role local-role shared-prototype)
  (with-catch
   (lambda (failure)
     (values
      #f
      (domain-case-diagnostic
       'instance-role-composition-failed '(instance) failure)))
   (lambda ()
     (if overlay-compatible?
       (values 'overlay
               (role-instance-overlay
                case-marker-role local-role shared-prototype))
       (values 'mix
               (role-compose case-marker-role local-role shared-prototype))))))

;; : (-> PooDomainCase Symbol Void)
(def (domain-case-record-instance-composition! domain-case mode)
  (if (eq? mode 'overlay)
    (domain-case-instance-overlay-increment! domain-case)
    (domain-case-instance-mix-increment! domain-case)))

;; : (-> PooDomainCase PooRole PooDomainCaseInstanceReceipt)
(def (domain-case-accepted-instance-receipt domain-case instance)
  (let (diagnostics (domain-case-instance-diagnostics domain-case instance))
    (domain-case-instance-receipt
     (null? diagnostics) instance diagnostics)))

;; : (-> PooDomainCase MaybeSymbol Object PooDomainCaseInstanceReceipt)
(def (domain-case-finish-instance domain-case mode result)
  (if mode
    (begin
      (domain-case-record-instance-composition! domain-case mode)
      (domain-case-accepted-instance-receipt domain-case result))
    (domain-case-instance-receipt #f #f (list result))))

;; : (-> PooDomainCase PooRole PooDomainCaseInstanceReceipt)
(def (domain-case-instantiate-valid domain-case local-role)
  (let* ((shared-prototype (.ref domain-case 'shared-prototype))
         (overlay-compatible?
          (and (.ref domain-case 'instance-overlay-compatible?)
               (role-instance-overlay-compatible? local-role)))
         (case-marker-role
          (poo-core-role-object
           (slots ((domain-case/ref domain-case)
                   (domain-case/key (.ref domain-case 'key))
                   (domain-case/instance-overlay-kind
                    (and overlay-compatible?
                         'poo-flow.role-instance-overlay.v1))
                   (domain-case/instance-composition-kind
                    (if overlay-compatible?
                      'poo-flow.role-instance-overlay.v1
                      'poo-flow.role-compose-mix.v1))
                   (domain-case/instance-overlay-resolver-depth
                   (and overlay-compatible? 1))))
           (supers))))
    (let-values (((mode result)
                  (domain-case-compose-instance
                   domain-case overlay-compatible? case-marker-role
                   local-role shared-prototype)))
      (domain-case-finish-instance domain-case mode result))))

;; : (-> PooDomainCase PooRole PooDomainCaseInstanceReceipt)
(def (poo-flow-domain-case-instantiate domain-case local-role)
  (if (not (and (poo-flow-domain-case? domain-case)
                (.ref domain-case 'closed?)
                (role-object? local-role)))
    (domain-case-invalid-instance-receipt local-role)
    (domain-case-instantiate-valid domain-case local-role)))

;; : (-> PooDomainCase Symbol Object PooDomainCaseMethodReceipt)
(def (poo-flow-domain-case-check-method domain-case subject-id-value context)
  (let (contract
        (and (poo-flow-domain-case? domain-case)
             (poo-flow-find
              (lambda (candidate)
                (and (eq? (.ref candidate 'contract-kind) 'method)
                     (equal? (.ref candidate 'subject-id)
                             subject-id-value)))
              (.ref domain-case 'effective-contracts))))
    (let (accepted?
          (and contract
               (domain-case-safe-call (.ref contract 'validator) context)))
      (poo-core-role-object
       (slots ((kind +poo-flow-domain-case-method-receipt-kind+)
               (accepted? accepted?)
               (subject-id subject-id-value)
               (contract-id (and contract (.ref contract 'contract-id)))
               (diagnostics
                (if accepted? '()
                    (list
                     (domain-case-diagnostic
                      (if contract
                          'method-contract-rejected
                          'unknown-method-contract)
                      (list 'methods subject-id-value) context))))))
       (supers)))))

;; : (-> PooDomainCase Symbol PooRole PooDomainCaseProjectionReceipt)
(def (poo-flow-domain-case-project domain-case projection-id-value instance)
  (let (projection
        (and (poo-flow-domain-case? domain-case)
             (poo-flow-find
              (lambda (candidate)
                (equal? projection-id-value
                        (.ref candidate 'projection-id)))
              (.ref domain-case 'projection-catalog))))
    (if (not projection)
        (poo-core-role-object
         (slots ((kind +poo-flow-domain-case-projection-receipt-kind+)
                 (accepted? #f)
                 (projection-id projection-id-value)
                 (schema-id #f)
                 (payload #f)
                 (diagnostics
                  (list (domain-case-diagnostic
                         'projection-not-selected
                         (list 'projections projection-id-value) #f)))))
         (supers))
        (let* ((failure-marker (list 'projection-failed))
               (payload
                (with-catch (lambda (_failure) failure-marker)
                            (lambda ()
                              ((.ref projection 'projector) instance))))
               (accepted? (not (eq? payload failure-marker))))
          (poo-core-role-object
           (slots ((kind +poo-flow-domain-case-projection-receipt-kind+)
                   (accepted? accepted?)
                   (projection-id projection-id-value)
                   (schema-id (.ref projection 'schema-id))
                   (payload (if accepted? payload #f))
                   (diagnostics
                    (if accepted? '()
                        (list (domain-case-diagnostic
                               'projection-failed
                               (list 'projections projection-id-value)
                               #f))))))
           (supers))))))
