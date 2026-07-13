;;; -*- Gerbil -*-
;;; Boundary: internal CaseComponent/DomainCase closure; no public DSL.

(export #t)

(import :clan/poo/object
        :std/crypto/digest
        :std/sort
        :std/text/hex
        :poo-flow/src/core/object-syntax
        :poo-flow/src/core/roles)

(def +poo-flow-case-slot-contract-kind+ 'poo-flow.case-slot-contract.v1)
(def +poo-flow-case-type-contract-kind+ 'poo-flow.case-type-contract.v1)
(def +poo-flow-case-method-contract-kind+ 'poo-flow.case-method-contract.v1)
(def +poo-flow-case-projection-kind+ 'poo-flow.case-projection.v1)
(def +poo-flow-case-component-kind+ 'poo-flow.case-component.v1)
(def +poo-flow-domain-case-kind+ 'poo-flow.domain-case.v1)
(def +poo-flow-domain-case-cache-kind+ 'poo-flow.domain-case-cache.v1)
(def +poo-flow-domain-case-closure-receipt-kind+
  'poo-flow.domain-case-closure-receipt.v1)
(def +poo-flow-domain-case-instance-receipt-kind+
  'poo-flow.domain-case-instance-receipt.v1)
(def +poo-flow-domain-case-method-receipt-kind+
  'poo-flow.domain-case-method-receipt.v1)
(def +poo-flow-domain-case-projection-receipt-kind+
  'poo-flow.domain-case-projection-receipt.v1)
(def +poo-flow-domain-case-key-domain+ 'poo-flow.domain-case-key.v1)

(def (domain-case-id? value)
  (or (symbol? value)
      (and (string? value) (> (string-length value) 0))))

(def (domain-case-object-kind? value expected)
  (with-catch (lambda (_failure) #f)
              (lambda () (eq? (.ref value 'kind) expected))))

(def (domain-case-safe-call predicate value)
  (with-catch (lambda (_failure) #f)
              (lambda () (and (predicate value) #t))))

(def (domain-case-safe-binary-call predicate left right)
  (with-catch (lambda (_failure) #f)
              (lambda () (and (predicate left right) #t))))

(def (domain-case-id->string value)
  (cond
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   (else (call-with-output-string (lambda (port) (write value port))))))

(def (domain-case-sort values id-of)
  (sort (append values '())
        (lambda (left right)
          (string<? (domain-case-id->string (id-of left))
                    (domain-case-id->string (id-of right))))))

(def (domain-case-sort-ids values)
  (sort (append values '())
        (lambda (left right)
          (string<? (domain-case-id->string left)
                    (domain-case-id->string right)))))

(def (domain-case-unique values)
  (let loop ((rest values) (seen '()) (result '()))
    (if (null? rest)
        (reverse result)
        (if (member (car rest) seen)
            (loop (cdr rest) seen result)
            (loop (cdr rest)
                  (cons (car rest) seen)
                  (cons (car rest) result))))))

(def (domain-case-duplicates values)
  (let loop ((rest values) (seen '()) (duplicates '()))
    (if (null? rest)
        (reverse (domain-case-unique duplicates))
        (if (member (car rest) seen)
            (loop (cdr rest) seen (cons (car rest) duplicates))
            (loop (cdr rest) (cons (car rest) seen) duplicates)))))

(def (domain-case-every-eq? left right)
  (and (= (length left) (length right))
       (let loop ((left-rest left) (right-rest right))
         (or (null? left-rest)
             (and (eq? (car left-rest) (car right-rest))
                  (loop (cdr left-rest) (cdr right-rest)))))))

(def (poo-flow-case-slot-contract slot-id-value owner-id-value type-id-value
                                  default-id-value merge-algebra-value
                                  (override-owner-ids-value '())
                                  (compatibility-witness-id-value #f)
                                  (validator-value #f))
  (poo-core-role-object
   (slots ((kind +poo-flow-case-slot-contract-kind+)
           (slot-id slot-id-value)
           (owner-id owner-id-value)
           (type-id type-id-value)
           (default-id default-id-value)
           (merge-algebra merge-algebra-value)
           (override-owner-ids override-owner-ids-value)
           (compatibility-witness-id compatibility-witness-id-value)
           (validator validator-value)))
   (supers)))

(def (poo-flow-case-slot-contract? value)
  (domain-case-object-kind? value +poo-flow-case-slot-contract-kind+))

(def (poo-flow-case-type-contract type-id-value parent-type-ids-value
                                  predicate-value)
  (poo-core-role-object
   (slots ((kind +poo-flow-case-type-contract-kind+)
           (type-id type-id-value)
           (parent-type-ids parent-type-ids-value)
           (predicate predicate-value)))
   (supers)))

(def (poo-flow-case-type-contract? value)
  (domain-case-object-kind? value +poo-flow-case-type-contract-kind+))

(def (poo-flow-case-method-contract contract-id-value owner-id-value
                                    subject-id-value contract-kind-value
                                    domain-id-value precondition-id-value
                                    postcondition-id-value validator-value
                                    (refines-contract-ids-value '())
                                    (compatibility-witness-id-value #f)
                                    (compatibility-witness-value #f))
  (poo-core-role-object
   (slots ((kind +poo-flow-case-method-contract-kind+)
           (contract-id contract-id-value)
           (owner-id owner-id-value)
           (subject-id subject-id-value)
           (contract-kind contract-kind-value)
           (domain-id domain-id-value)
           (precondition-id precondition-id-value)
           (postcondition-id postcondition-id-value)
           (validator validator-value)
           (refines-contract-ids refines-contract-ids-value)
           (compatibility-witness-id compatibility-witness-id-value)
           (compatibility-witness compatibility-witness-value)))
   (supers)))

(def (poo-flow-case-method-contract? value)
  (domain-case-object-kind? value +poo-flow-case-method-contract-kind+))

(def (poo-flow-case-projection projection-id-value owner-id-value
                               schema-id-value projector-value)
  (poo-core-role-object
   (slots ((kind +poo-flow-case-projection-kind+)
           (projection-id projection-id-value)
           (owner-id owner-id-value)
           (schema-id schema-id-value)
           (projector projector-value)))
   (supers)))

(def (poo-flow-case-projection? value)
  (domain-case-object-kind? value +poo-flow-case-projection-kind+))

(def (poo-flow-case-component component-id-value component-version-value
                              role-prototype-value type-contract-value
                              slot-contracts-value method-contracts-value
                              projections-value
                              (parent-component-ids-value '())
                              (policy-algebra-value #f)
                              (strategy-algebra-value #f))
  (poo-core-role-object
   (slots ((kind +poo-flow-case-component-kind+)
           (component-id component-id-value)
           (component-version component-version-value)
           (role-prototype role-prototype-value)
           (type-contract type-contract-value)
           (slot-contracts slot-contracts-value)
           (method-contracts method-contracts-value)
           (projections projections-value)
           (parent-component-ids parent-component-ids-value)
           (policy-algebra policy-algebra-value)
           (strategy-algebra strategy-algebra-value)))
   (supers)))

(def (poo-flow-case-component? value)
  (domain-case-object-kind? value +poo-flow-case-component-kind+))

(def (case-slot-contract-valid? value)
  (and (poo-flow-case-slot-contract? value)
       (domain-case-id? (.ref value 'slot-id))
       (domain-case-id? (.ref value 'owner-id))
       (domain-case-id? (.ref value 'type-id))
       (domain-case-id? (.ref value 'default-id))
       (domain-case-id? (.ref value 'merge-algebra))
       (list? (.ref value 'override-owner-ids))
       (andmap domain-case-id? (.ref value 'override-owner-ids))
       (or (not (.ref value 'compatibility-witness-id))
           (domain-case-id? (.ref value 'compatibility-witness-id)))
       (procedure? (.ref value 'validator))))

(def (case-type-contract-valid? value)
  (and (poo-flow-case-type-contract? value)
       (domain-case-id? (.ref value 'type-id))
       (list? (.ref value 'parent-type-ids))
       (andmap domain-case-id? (.ref value 'parent-type-ids))
       (procedure? (.ref value 'predicate))))

(def (case-method-contract-valid? value)
  (and (poo-flow-case-method-contract? value)
       (domain-case-id? (.ref value 'contract-id))
       (domain-case-id? (.ref value 'owner-id))
       (domain-case-id? (.ref value 'subject-id))
       (memq (.ref value 'contract-kind) '(state method))
       (domain-case-id? (.ref value 'domain-id))
       (domain-case-id? (.ref value 'precondition-id))
       (domain-case-id? (.ref value 'postcondition-id))
       (procedure? (.ref value 'validator))
       (list? (.ref value 'refines-contract-ids))
       (andmap domain-case-id? (.ref value 'refines-contract-ids))
       (or (and (null? (.ref value 'refines-contract-ids))
                (not (.ref value 'compatibility-witness-id))
                (not (.ref value 'compatibility-witness)))
           (and (pair? (.ref value 'refines-contract-ids))
                (domain-case-id?
                 (.ref value 'compatibility-witness-id))
                (procedure? (.ref value 'compatibility-witness))))))

(def (case-projection-valid? value)
  (and (poo-flow-case-projection? value)
       (domain-case-id? (.ref value 'projection-id))
       (domain-case-id? (.ref value 'owner-id))
       (domain-case-id? (.ref value 'schema-id))
       (procedure? (.ref value 'projector))))

(def (poo-flow-case-component-valid? value)
  (and (poo-flow-case-component? value)
       (domain-case-id? (.ref value 'component-id))
       (exact-integer? (.ref value 'component-version))
       (> (.ref value 'component-version) 0)
       (.ref value 'role-prototype)
       (case-type-contract-valid? (.ref value 'type-contract))
       (list? (.ref value 'slot-contracts))
       (andmap case-slot-contract-valid? (.ref value 'slot-contracts))
       (list? (.ref value 'method-contracts))
       (andmap case-method-contract-valid? (.ref value 'method-contracts))
       (list? (.ref value 'projections))
       (andmap case-projection-valid? (.ref value 'projections))
       (list? (.ref value 'parent-component-ids))
       (andmap domain-case-id? (.ref value 'parent-component-ids))
       (or (not (.ref value 'policy-algebra))
           (domain-case-id? (.ref value 'policy-algebra)))
       (or (not (.ref value 'strategy-algebra))
           (domain-case-id? (.ref value 'strategy-algebra)))))

(def (case-slot-contract-normalize value)
  (list 'slot
        (.ref value 'slot-id)
        (.ref value 'owner-id)
        (.ref value 'type-id)
        (.ref value 'default-id)
        (.ref value 'merge-algebra)
        (cons 'overrides
              (sort (append (.ref value 'override-owner-ids) '())
                    (lambda (left right)
                      (string<? (domain-case-id->string left)
                                (domain-case-id->string right)))))
        (list 'witness (.ref value 'compatibility-witness-id))))

(def (case-type-contract-normalize value)
  (list 'type
        (.ref value 'type-id)
        (cons 'parents (.ref value 'parent-type-ids))))

(def (case-method-contract-normalize value)
  (list 'contract
        (.ref value 'contract-id)
        (.ref value 'owner-id)
        (.ref value 'subject-id)
        (.ref value 'contract-kind)
        (.ref value 'domain-id)
        (.ref value 'precondition-id)
        (.ref value 'postcondition-id)
        (cons 'refines
              (sort (append (.ref value 'refines-contract-ids) '())
                    (lambda (left right)
                      (string<? (domain-case-id->string left)
                                (domain-case-id->string right)))))
        (list 'witness (.ref value 'compatibility-witness-id))))

(def (case-projection-normalize value)
  (list 'projection
        (.ref value 'projection-id)
        (.ref value 'owner-id)
        (.ref value 'schema-id)))

(def (case-component-normalize value)
  (list 'component
        (.ref value 'component-id)
        (.ref value 'component-version)
        (cons 'parents (.ref value 'parent-component-ids))
        (case-type-contract-normalize (.ref value 'type-contract))
        (cons 'slots
              (map case-slot-contract-normalize
                   (domain-case-sort (.ref value 'slot-contracts)
                                     (lambda (slot) (.ref slot 'slot-id)))))
        (cons 'contracts
              (map case-method-contract-normalize
                   (domain-case-sort
                    (.ref value 'method-contracts)
                    (lambda (contract) (.ref contract 'contract-id)))))
        (cons 'projections
              (map case-projection-normalize
                   (domain-case-sort
                    (.ref value 'projections)
                    (lambda (projection) (.ref projection 'projection-id)))))
        (list 'policy-algebra (.ref value 'policy-algebra))
        (list 'strategy-algebra (.ref value 'strategy-algebra))))

(def (poo-flow-domain-case-canonical-descriptor schema-id-value
                                                schema-version-value
                                                components
                                                local-overrides
                                                selected-projection-ids)
  (list +poo-flow-domain-case-key-domain+
        (list 'schema-id schema-id-value)
        (list 'schema-version schema-version-value)
        (cons 'components (map case-component-normalize components))
        (cons 'local-overrides
              (map case-slot-contract-normalize
                   (domain-case-sort local-overrides
                                     (lambda (slot) (.ref slot 'slot-id)))))
        (cons 'selected-projections
              (domain-case-sort-ids selected-projection-ids))))

(def (poo-flow-domain-case-canonical-key descriptor)
  (hex-encode
   (sha256
    (call-with-output-string (lambda (port) (write descriptor port))))))

(def (domain-case-diagnostic code path observed)
  (poo-core-role-object
   (slots ((kind 'poo-flow.domain-case-diagnostic.v1)
           (code code)
           (path path)
           (observed observed)))
   (supers)))

(def (domain-case-slot-equivalent? left right)
  (equal? (case-slot-contract-normalize left)
          (case-slot-contract-normalize right)))

(def (domain-case-explicit-override? candidate inherited)
  (and (member (.ref inherited 'owner-id)
               (.ref candidate 'override-owner-ids))
       (.ref candidate 'compatibility-witness-id)))

(def (domain-case-resolve-slots slots)
  (let loop ((rest slots) (effective '()) (diagnostics '()))
    (if (null? rest)
        (values (reverse effective) (reverse diagnostics))
        (let* ((candidate (car rest))
               (existing
                (find (lambda (slot)
                        (equal? (.ref slot 'slot-id)
                                (.ref candidate 'slot-id)))
                      effective)))
          (cond
           ((not existing)
            (loop (cdr rest) (cons candidate effective) diagnostics))
           ((domain-case-slot-equivalent? existing candidate)
            (loop (cdr rest) effective diagnostics))
           ((and (domain-case-explicit-override? candidate existing)
                 (domain-case-explicit-override? existing candidate))
            (loop (cdr rest) effective
                  (cons (domain-case-diagnostic
                         'ambiguous-slot-override
                         (list 'slots (.ref candidate 'slot-id))
                         (list (.ref existing 'owner-id)
                               (.ref candidate 'owner-id)))
                        diagnostics)))
           ((domain-case-explicit-override? candidate existing)
            (loop (cdr rest)
                  (cons candidate (remq existing effective)) diagnostics))
           ((domain-case-explicit-override? existing candidate)
            (loop (cdr rest) effective diagnostics))
           (else
            (loop (cdr rest) effective
                  (cons (domain-case-diagnostic
                         'slot-contract-conflict
                         (list 'slots (.ref candidate 'slot-id))
                         (list (case-slot-contract-normalize existing)
                               (case-slot-contract-normalize candidate)))
                        diagnostics))))))))

(def (domain-case-contract-equivalent? left right)
  (equal? (case-method-contract-normalize left)
          (case-method-contract-normalize right)))

(def (domain-case-contract-refines? candidate inherited)
  (and (member (.ref inherited 'contract-id)
               (.ref candidate 'refines-contract-ids))
       (equal? (.ref candidate 'domain-id) (.ref inherited 'domain-id))
       (domain-case-safe-binary-call
        (.ref candidate 'compatibility-witness) candidate inherited)))

(def (domain-case-resolve-method-contracts contracts)
  (let loop ((rest contracts) (effective '()) (diagnostics '()))
    (if (null? rest)
        (values (reverse effective) (reverse diagnostics))
        (let* ((candidate (car rest))
               (kind (.ref candidate 'contract-kind))
               (existing
                (and (eq? kind 'method)
                     (find (lambda (contract)
                             (and (eq? (.ref contract 'contract-kind) 'method)
                                  (equal? (.ref contract 'subject-id)
                                          (.ref candidate 'subject-id))))
                           effective))))
          (cond
           ((or (eq? kind 'state) (not existing))
            (loop (cdr rest) (cons candidate effective) diagnostics))
           ((domain-case-contract-equivalent? existing candidate)
            (loop (cdr rest) effective diagnostics))
           ((and (domain-case-contract-refines? candidate existing)
                 (domain-case-contract-refines? existing candidate))
            (loop (cdr rest) effective
                  (cons (domain-case-diagnostic
                         'ambiguous-contract-refinement
                         (list 'contracts (.ref candidate 'subject-id))
                         (list (.ref existing 'contract-id)
                               (.ref candidate 'contract-id)))
                        diagnostics)))
           ((domain-case-contract-refines? candidate existing)
            (loop (cdr rest)
                  (cons candidate (remq existing effective)) diagnostics))
           ((domain-case-contract-refines? existing candidate)
            (loop (cdr rest) effective diagnostics))
           (else
            (loop (cdr rest) effective
                  (cons (domain-case-diagnostic
                         'contract-refinement-conflict
                         (list 'contracts (.ref candidate 'subject-id))
                         (list (.ref existing 'contract-id)
                               (.ref candidate 'contract-id)))
                        diagnostics))))))))

(def (domain-case-projection-conflicts projections)
  (let loop ((rest projections) (seen '()) (diagnostics '()))
    (if (null? rest)
        (reverse diagnostics)
        (let* ((candidate (car rest))
               (id (.ref candidate 'projection-id))
               (existing (find (lambda (projection)
                                 (equal? id (.ref projection 'projection-id)))
                               seen)))
          (loop (cdr rest)
                (if existing seen (cons candidate seen))
                (if existing
                    (cons (domain-case-diagnostic
                           'projection-name-conflict
                           (list 'projections id)
                           (list (.ref existing 'owner-id)
                                 (.ref candidate 'owner-id)))
                          diagnostics)
                    diagnostics))))))

(def (domain-case-single-algebra components slot code)
  (let (algebras
        (domain-case-unique
         (filter (lambda (value) value)
                 (map (lambda (component) (.ref component slot)) components))))
    (if (> (length algebras) 1)
        (values #f (list (domain-case-diagnostic code (list slot) algebras)))
        (values (and (pair? algebras) (car algebras)) '()))))

(def (domain-case-parent-diagnostics components)
  (let loop ((rest components) (seen '()) (diagnostics '()))
    (if (null? rest)
        (reverse diagnostics)
        (let* ((component (car rest))
               (id (.ref component 'component-id))
               (missing
                (filter (lambda (parent-id) (not (member parent-id seen)))
                        (.ref component 'parent-component-ids))))
          (loop (cdr rest) (cons id seen)
                (append
                 (map (lambda (parent-id)
                        (domain-case-diagnostic
                         'missing-or-forward-parent-component
                         (list 'components id 'parents)
                         parent-id))
                      missing)
                 diagnostics))))))

(def (domain-case-type-diagnostics components)
  (let loop ((rest components) (seen '()) (diagnostics '()))
    (if (null? rest)
        (reverse diagnostics)
        (let* ((component (car rest))
               (type-contract (.ref component 'type-contract))
               (type-id (.ref type-contract 'type-id))
               (existing (assoc type-id seen))
               (missing
                (filter (lambda (parent-id) (not (assoc parent-id seen)))
                        (.ref type-contract 'parent-type-ids))))
          (loop
           (cdr rest)
           (if existing seen (cons (cons type-id type-contract) seen))
           (append
            (if (and existing (not (eq? (cdr existing) type-contract)))
                (list
                 (domain-case-diagnostic
                  'type-identity-conflict
                  (list 'types type-id)
                  (list (.ref (cdr existing) 'parent-type-ids)
                        (.ref type-contract 'parent-type-ids))))
                '())
            (map (lambda (parent-id)
                   (domain-case-diagnostic
                    'missing-or-forward-parent-type
                    (list 'types type-id 'parents)
                    parent-id))
                 missing)
            diagnostics))))))

(def (domain-case-select-projections projections selected-ids)
  (let loop ((rest selected-ids) (catalog '()) (diagnostics '()))
    (if (null? rest)
        (values (reverse catalog) (reverse diagnostics))
        (let* ((id (car rest))
               (matches
                (filter (lambda (projection)
                          (equal? id (.ref projection 'projection-id)))
                        projections)))
          (cond
           ((null? matches)
            (loop (cdr rest) catalog
                  (cons (domain-case-diagnostic
                         'unknown-projection
                         (list 'selected-projections id) #f)
                        diagnostics)))
           ((> (length matches) 1)
            (loop (cdr rest) catalog diagnostics))
           (else
            (loop (cdr rest) (cons (car matches) catalog) diagnostics)))))))

(def (poo-flow-domain-case-cache)
  (poo-core-role-object
   (slots ((kind +poo-flow-domain-case-cache-kind+)
           (entries (make-hash-table))
           (metrics (vector 0 0))))
   (supers)))

(def (poo-flow-domain-case-cache? value)
  (domain-case-object-kind? value +poo-flow-domain-case-cache-kind+))

(def (poo-flow-domain-case-cache-closure-count cache)
  (vector-ref (.ref cache 'metrics) 0))

(def (poo-flow-domain-case-cache-hit-count cache)
  (vector-ref (.ref cache 'metrics) 1))

(def (domain-case-cache-increment! cache index)
  (let (metrics (.ref cache 'metrics))
    (vector-set! metrics index (+ 1 (vector-ref metrics index)))))

(def (poo-flow-domain-case? value)
  (domain-case-object-kind? value +poo-flow-domain-case-kind+))

(def (poo-flow-domain-case-instance-mix-count domain-case)
  (vector-ref (.ref domain-case 'metrics) 0))

(def (domain-case-instance-mix-increment! domain-case)
  (let (metrics (.ref domain-case 'metrics))
    (vector-set! metrics 0 (+ 1 (vector-ref metrics 0)))))

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

(def (poo-flow-domain-case-close cache schema-id-value schema-version-value
                                 components
                                 (local-overrides '())
                                 (selected-projection-ids '()))
  (let (diagnostics '())
    (def (reject! diagnostic)
      (set! diagnostics (cons diagnostic diagnostics)))
    (unless (poo-flow-domain-case-cache? cache)
      (reject! (domain-case-diagnostic 'invalid-domain-case-cache '(cache)
                                       cache)))
    (unless (domain-case-id? schema-id-value)
      (reject! (domain-case-diagnostic 'invalid-domain-case-schema
                                       '(schema-id) schema-id-value)))
    (unless (and (exact-integer? schema-version-value)
                 (> schema-version-value 0))
      (reject! (domain-case-diagnostic 'invalid-domain-case-version
                                       '(schema-version)
                                       schema-version-value)))
    (unless (and (list? components) (pair? components))
      (reject! (domain-case-diagnostic 'missing-case-components
                                       '(components) components)))
    (unless (and (list? local-overrides)
                 (andmap case-slot-contract-valid? local-overrides))
      (reject! (domain-case-diagnostic 'invalid-local-overrides
                                       '(local-overrides) local-overrides)))
    (unless (and (list? selected-projection-ids)
                 (andmap domain-case-id? selected-projection-ids))
      (reject! (domain-case-diagnostic 'invalid-projection-selection
                                       '(selected-projections)
                                       selected-projection-ids)))
    (when (list? selected-projection-ids)
      (for-each
       (lambda (projection-id)
         (reject! (domain-case-diagnostic
                   'duplicate-projection-selection
                   '(selected-projections) projection-id)))
       (domain-case-duplicates selected-projection-ids)))
    (when (list? components)
      (for-each
       (lambda (component)
         (unless (poo-flow-case-component-valid? component)
           (reject! (domain-case-diagnostic 'invalid-case-component
                                            '(components) component))))
       components))
    (if (pair? diagnostics)
        (domain-case-make-closure-receipt
         #f #f #f (reverse diagnostics) #f)
        (let* ((normalized-local-overrides
                (domain-case-sort
                 local-overrides (lambda (slot) (.ref slot 'slot-id))))
               (normalized-selected-projection-ids
                (domain-case-sort-ids selected-projection-ids))
               (component-ids
                (map (lambda (component) (.ref component 'component-id))
                     components))
               (duplicate-component-ids
                (domain-case-duplicates component-ids))
               (all-slots
                (append
                 normalized-local-overrides
                 (apply append
                        (map (lambda (component)
                               (.ref component 'slot-contracts))
                             components))))
               (all-contracts
                (apply append
                       (map (lambda (component)
                              (.ref component 'method-contracts))
                            components)))
               (all-projections
                (apply append
                       (map (lambda (component)
                              (.ref component 'projections))
                            components))))
          (for-each
           (lambda (id)
             (reject! (domain-case-diagnostic 'duplicate-component-id
                                              '(components) id)))
          duplicate-component-ids)
          (for-each reject! (domain-case-parent-diagnostics components))
          (for-each reject! (domain-case-type-diagnostics components))
          (for-each reject! (domain-case-projection-conflicts all-projections))
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
            (for-each reject! slot-diagnostics)
            (for-each reject! contract-diagnostics)
            (for-each reject! projection-diagnostics)
            (for-each reject! policy-diagnostics)
            (for-each reject! strategy-diagnostics)
            (let* ((descriptor
                    (poo-flow-domain-case-canonical-descriptor
                     schema-id-value schema-version-value components
                     normalized-local-overrides
                     normalized-selected-projection-ids))
                   (key (poo-flow-domain-case-canonical-key descriptor)))
              (if (pair? diagnostics)
                  (domain-case-make-closure-receipt
                   #f key #f (reverse diagnostics) #f)
                  (let (cached (hash-get (.ref cache 'entries) key))
                    (cond
                     ((and cached
                           (domain-case-every-eq?
                            components (.ref cached 'components))
                           (domain-case-every-eq?
                            normalized-local-overrides
                            (.ref cached 'local-overrides)))
                      (domain-case-cache-increment! cache 1)
                      (domain-case-make-closure-receipt
                       #t key cached '() #t))
                     (cached
                      (domain-case-make-closure-receipt
                       #f key #f
                        (list
                        (domain-case-diagnostic
                         'module-owner-identity-alias '(key) key))
                       #f))
                     (else
                      (let (composition
                            (with-catch
                             (lambda (failure)
                               (domain-case-diagnostic
                                'role-composition-failed '(components)
                                failure))
                             (lambda ()
                               (apply role-compose
                                      (reverse
                                       (map (lambda (component)
                                              (.ref component
                                                    'role-prototype))
                                            components))))))
                        (if (domain-case-object-kind?
                             composition 'poo-flow.domain-case-diagnostic.v1)
                            (domain-case-make-closure-receipt
                             #f key #f (list composition) #f)
                            (let* ((type-contracts
                                    (map (lambda (component)
                                           (.ref component 'type-contract))
                                         components))
                                   (case-value
                                    (poo-core-role-object
                                     (slots
                                      ((kind +poo-flow-domain-case-kind+)
                                       (schema-id schema-id-value)
                                       (schema-version schema-version-value)
                                       (key key)
                                       (components components)
                                       (local-overrides
                                        normalized-local-overrides)
                                       (shared-prototype composition)
                                       (type-contracts type-contracts)
                                       (effective-slots effective-slots)
                                       (effective-contracts
                                        effective-contracts)
                                       (projection-catalog projection-catalog)
                                       (selected-projection-ids
                                        normalized-selected-projection-ids)
                                       (policy-algebra policy-algebra)
                                       (strategy-algebra strategy-algebra)
                                       (canonical-descriptor descriptor)
                                       (metrics (vector 0))
                                       (closed? #t)))
                                     (supers))))
                              (hash-put! (.ref cache 'entries) key case-value)
                              (domain-case-cache-increment! cache 0)
                              (domain-case-make-closure-receipt
                               #t key case-value '() #f))))))))))))))

(def (domain-case-instance-diagnostic code owner observed)
  (domain-case-diagnostic code (list 'instance owner) observed))

(def (poo-flow-domain-case-instantiate domain-case local-role)
  (if (not (and (poo-flow-domain-case? domain-case)
                (.ref domain-case 'closed?)
                (role-object? local-role)))
      (poo-core-role-object
       (slots ((kind +poo-flow-domain-case-instance-receipt-kind+)
               (accepted? #f)
               (instance #f)
               (diagnostics
                (list (domain-case-diagnostic
                       'invalid-domain-case-instance-input '(instance)
                       local-role)))))
       (supers))
      (let* ((shared-prototype (.ref domain-case 'shared-prototype))
             (case-marker-role
              (poo-core-role-object
               (slots ((domain-case/ref domain-case)
                       (domain-case/key (.ref domain-case 'key))))
               (supers)))
             (instance
              (with-catch
               (lambda (failure)
                 (domain-case-diagnostic
                  'instance-role-composition-failed '(instance) failure))
               (lambda ()
                 (role-compose case-marker-role local-role
                               shared-prototype)))))
        (if (domain-case-object-kind?
             instance 'poo-flow.domain-case-diagnostic.v1)
            (poo-core-role-object
             (slots ((kind +poo-flow-domain-case-instance-receipt-kind+)
                     (accepted? #f)
                     (instance #f)
                     (diagnostics (list instance))))
             (supers))
            (let (diagnostics '())
              (domain-case-instance-mix-increment! domain-case)
              (for-each
               (lambda (slot-contract)
                 (let* ((missing-marker (list 'missing-slot))
                        (slot-id (.ref slot-contract 'slot-id))
                        (value
                         (with-catch
                          (lambda (_failure) missing-marker)
                          (lambda () (.ref instance slot-id)))))
                   (cond
                    ((and (eq? value missing-marker)
                          (eq? (.ref slot-contract 'default-id) 'required))
                     (set! diagnostics
                           (cons (domain-case-instance-diagnostic
                                  'required-slot-missing slot-id #f)
                                 diagnostics)))
                    ((and (not (eq? value missing-marker))
                          (not (domain-case-safe-call
                                (.ref slot-contract 'validator) value)))
                     (set! diagnostics
                           (cons (domain-case-instance-diagnostic
                                  'slot-contract-rejected slot-id value)
                                 diagnostics))))))
               (.ref domain-case 'effective-slots))
              (for-each
               (lambda (type-contract)
                 (unless (domain-case-safe-call
                          (.ref type-contract 'predicate) instance)
                   (set! diagnostics
                         (cons (domain-case-instance-diagnostic
                                'type-contract-rejected
                                (.ref type-contract 'type-id) instance)
                               diagnostics))))
               (.ref domain-case 'type-contracts))
              (for-each
               (lambda (contract)
                 (when (eq? (.ref contract 'contract-kind) 'state)
                   (unless (domain-case-safe-call
                            (.ref contract 'validator) instance)
                     (set! diagnostics
                           (cons (domain-case-instance-diagnostic
                                  'state-contract-rejected
                                  (.ref contract 'contract-id) instance)
                                 diagnostics)))))
               (.ref domain-case 'effective-contracts))
              (poo-core-role-object
               (slots ((kind +poo-flow-domain-case-instance-receipt-kind+)
                       (accepted? (null? diagnostics))
                       (instance instance)
                       (diagnostics (reverse diagnostics))))
               (supers)))))))

(def (poo-flow-domain-case-check-method domain-case subject-id-value context)
  (let (contract
        (and (poo-flow-domain-case? domain-case)
             (find (lambda (candidate)
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

(def (poo-flow-domain-case-project domain-case projection-id-value instance)
  (let (projection
        (and (poo-flow-domain-case? domain-case)
             (find (lambda (candidate)
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
