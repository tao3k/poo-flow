(export #t)

(import :clan/poo/object
        :std/crypto/digest
        :std/sort
        :std/text/hex
        :poo-flow/src/core/object-syntax
        :poo-flow/src/module-system/object-family-syntax
        :poo-flow/src/qualification/capability-prototypes)

(def +poo-flow-release-assurance-manifest-schema+
  'poo-flow.release-assurance-manifest.v1)

(def +poo-flow-assurance-claim-kind+ 'poo-flow.assurance-claim.v1)
(def +poo-flow-assurance-tcb-kind+ 'poo-flow.assurance-tcb.v1)
(def +poo-flow-assurance-evidence-reference-kind+
  'poo-flow.assurance-evidence-reference.v1)
(def +poo-flow-assurance-gate-result-kind+ 'poo-flow.assurance-gate-result.v1)
(def +poo-flow-assurance-abi-decision-kind+ 'poo-flow.assurance-abi-decision.v1)

(defpoo-object-family +poo-flow-assurance-claim-kind+
  poo-flow-assurance-claim?
  (accessors
   (poo-flow-assurance-claim-id claim-id)
   (poo-flow-assurance-claim-level level)
   (poo-flow-assurance-claim-owner owner)
   (poo-flow-assurance-claim-tcb tcb)
   (poo-flow-assurance-claim-evidence evidence)
   (poo-flow-assurance-claim-exclusions exclusions)
   (poo-flow-assurance-claim-failure-state failure-state))
  (projections))

(defpoo-object-family +poo-flow-assurance-tcb-kind+
  poo-flow-assurance-tcb?
  (accessors
   (poo-flow-assurance-tcb-id tcb-id)
   (poo-flow-assurance-tcb-family family)
   (poo-flow-assurance-tcb-components components))
  (projections))

(defpoo-object-family +poo-flow-assurance-evidence-reference-kind+
  poo-flow-assurance-evidence-reference?
  (accessors
   (poo-flow-assurance-evidence-reference-id evidence-id)
   (poo-flow-assurance-evidence-reference-owner owner)
   (poo-flow-assurance-evidence-reference-artifact artifact)
   (poo-flow-assurance-evidence-reference-digest digest))
  (projections))

(defpoo-object-family +poo-flow-assurance-gate-result-kind+
  poo-flow-assurance-gate-result?
  (accessors
   (poo-flow-assurance-gate-result-id gate-id)
   (poo-flow-assurance-gate-result-owner owner)
   (poo-flow-assurance-gate-result-status status)
   (poo-flow-assurance-gate-result-evidence evidence))
  (projections))

(defpoo-object-family +poo-flow-assurance-abi-decision-kind+
  poo-flow-assurance-abi-decision?
  (accessors
   (poo-flow-assurance-abi-decision-version version)
   (poo-flow-assurance-abi-decision-frozen? frozen?)
   (poo-flow-assurance-abi-decision-review review))
  (projections))

(defpoo-object-family +poo-flow-release-assurance-manifest-schema+
  poo-flow-release-assurance-manifest?
  (accessors
   (release-assurance-manifest-release release)
   (release-assurance-manifest-environment environment)
   (release-assurance-manifest-assurance assurance)
   (poo-flow-release-assurance-manifest-abi-decision abi-decision))
  (projections))

(def (poo-flow-release-assurance-manifest-release-id manifest)
  (.ref (release-assurance-manifest-release manifest) 'release-id))
(def (poo-flow-release-assurance-manifest-source-revision manifest)
  (.ref (release-assurance-manifest-release manifest) 'source-revision))
(def (poo-flow-release-assurance-manifest-host manifest)
  (.ref (release-assurance-manifest-environment manifest) 'host))
(def (poo-flow-release-assurance-manifest-toolchains manifest)
  (.ref (release-assurance-manifest-environment manifest) 'toolchains))
(def (poo-flow-release-assurance-manifest-identities manifest)
  (.ref (release-assurance-manifest-assurance manifest) 'identities))
(def (poo-flow-release-assurance-manifest-tcbs manifest)
  (.ref (release-assurance-manifest-assurance manifest) 'tcbs))
(def (poo-flow-release-assurance-manifest-claims manifest)
  (.ref (release-assurance-manifest-assurance manifest) 'claims))
(def (poo-flow-release-assurance-manifest-gates manifest)
  (.ref (release-assurance-manifest-assurance manifest) 'gates))

(def (poo-flow-assurance-tcb tcb-id-value family-value components-value)
  (object<-alist
   (list (cons 'kind +poo-flow-assurance-tcb-kind+)
         (cons 'tcb-id tcb-id-value)
         (cons 'family family-value)
         (cons 'components components-value))))

(def (poo-flow-assurance-evidence-reference evidence-id-value owner-value
                                             artifact-value digest-value)
  (object<-alist
   (list (cons 'kind +poo-flow-assurance-evidence-reference-kind+)
         (cons 'evidence-id evidence-id-value)
         (cons 'owner owner-value)
         (cons 'artifact artifact-value)
         (cons 'digest digest-value))))

(def (poo-flow-assurance-claim claim-id-value level-value owner-value tcb-value
                               evidence-value exclusions-value
                               failure-state-value)
  (object<-alist
   (list (cons 'kind +poo-flow-assurance-claim-kind+)
         (cons 'claim-id claim-id-value)
         (cons 'level level-value)
         (cons 'owner owner-value)
         (cons 'tcb tcb-value)
         (cons 'evidence evidence-value)
         (cons 'exclusions exclusions-value)
         (cons 'failure-state failure-state-value))))

(def (poo-flow-assurance-gate-result gate-id-value owner-value status-value
                                     evidence-value)
  (object<-alist
   (list (cons 'kind +poo-flow-assurance-gate-result-kind+)
         (cons 'gate-id gate-id-value)
         (cons 'owner owner-value)
         (cons 'status status-value)
         (cons 'evidence evidence-value))))

(def (poo-flow-assurance-abi-decision version-value frozen-value? review-value)
  (object<-alist
   (list (cons 'kind +poo-flow-assurance-abi-decision-kind+)
         (cons 'version version-value)
         (cons 'frozen? frozen-value?)
         (cons 'review review-value))))

(def (poo-flow-release-assurance-manifest release-id-value revision-value
                                           host-value toolchains-value
                                           identities-value tcbs-value
                                           claims-value gates-value
                                           abi-decision-value)
  (poo-flow-qualification-capability-composition-assert!
   (list (cons 'versioned +poo-flow-versioned-capability-slots+)
         (cons 'revision-bound +poo-flow-revision-bound-capability-slots+)))
  (let ((release-value
         (object<-alist
          (list (cons 'kind 'poo-flow.release-assurance-release.v1)
                (cons 'release-id release-id-value)
                (cons 'source-revision revision-value))))
        (environment-value
         (object<-alist
          (list (cons 'kind 'poo-flow.release-assurance-environment.v1)
                (cons 'host host-value)
                (cons 'toolchains toolchains-value))))
        (assurance-value
         (object<-alist
          (list (cons 'kind 'poo-flow.release-assurance-evidence.v1)
                (cons 'identities identities-value)
                (cons 'tcbs tcbs-value)
                (cons 'claims claims-value)
                (cons 'gates gates-value)))))
    (poo-core-role-object
     (slots ((kind +poo-flow-release-assurance-manifest-schema+)
             (schema +poo-flow-release-assurance-manifest-schema+)
             (release release-value)
             (environment environment-value)
             (assurance assurance-value)
             (abi-decision abi-decision-value)))
     (supers
      (poo-flow-versioned-capability
       +poo-flow-release-assurance-manifest-schema+ 1)
      (poo-flow-revision-bound-capability revision-value)))))

(def (assurance-id->string value)
  (cond
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   (else (call-with-output-string (lambda (port) (write value port))))))

(def (assurance-sort values id-of)
  (sort (append values '())
        (lambda (left right)
          (string<? (assurance-id->string (id-of left))
                    (assurance-id->string (id-of right))))))

(def (assurance-sort-values values)
  (sort (append values '())
        (lambda (left right)
          (string<? (assurance-id->string left)
                    (assurance-id->string right)))))

(def (assurance-pair-sort values)
  (sort (append values '())
        (lambda (left right)
          (string<? (assurance-id->string (car left))
                    (assurance-id->string (car right))))))

(def (tcb->canonical value)
  (list 'tcb
        (poo-flow-assurance-tcb-id value)
        (poo-flow-assurance-tcb-family value)
        (cons 'components
              (assurance-sort-values
               (poo-flow-assurance-tcb-components value)))))

(def (evidence->canonical value)
  (list 'evidence
        (poo-flow-assurance-evidence-reference-id value)
        (list 'owner (poo-flow-assurance-evidence-reference-owner value))
        (list 'artifact (poo-flow-assurance-evidence-reference-artifact value))
        (list 'digest (poo-flow-assurance-evidence-reference-digest value))))

(def (claim->canonical value)
  (list 'claim
        (poo-flow-assurance-claim-id value)
        (list 'level (poo-flow-assurance-claim-level value))
        (list 'owner (poo-flow-assurance-claim-owner value))
        (list 'tcb (poo-flow-assurance-tcb-id
                    (poo-flow-assurance-claim-tcb value)))
        (cons 'evidence
              (map evidence->canonical
                   (assurance-sort
                    (poo-flow-assurance-claim-evidence value)
                    poo-flow-assurance-evidence-reference-id)))
        (cons 'exclusions
              (assurance-sort-values
               (poo-flow-assurance-claim-exclusions value)))
        (list 'failure-state
              (poo-flow-assurance-claim-failure-state value))))

(def (gate->canonical value)
  (list 'gate
        (poo-flow-assurance-gate-result-id value)
        (list 'owner (poo-flow-assurance-gate-result-owner value))
        (list 'status (poo-flow-assurance-gate-result-status value))
        (list 'evidence
              (evidence->canonical
               (poo-flow-assurance-gate-result-evidence value)))))

(def (abi-decision->canonical value)
  (list 'abi-decision
        (list 'version (poo-flow-assurance-abi-decision-version value))
        (list 'frozen? (poo-flow-assurance-abi-decision-frozen? value))
        (list 'review (poo-flow-assurance-abi-decision-review value))))

(def (poo-flow-release-assurance-manifest-normalize manifest)
  (list +poo-flow-release-assurance-manifest-schema+
        (list 'release-id
              (poo-flow-release-assurance-manifest-release-id manifest))
        (list 'source-revision
              (poo-flow-release-assurance-manifest-source-revision manifest))
        (list 'host (poo-flow-release-assurance-manifest-host manifest))
        (cons 'toolchains
              (assurance-pair-sort
               (poo-flow-release-assurance-manifest-toolchains manifest)))
        (cons 'identities
              (assurance-pair-sort
               (poo-flow-release-assurance-manifest-identities manifest)))
        (cons 'tcbs
              (map tcb->canonical
                   (assurance-sort
                    (poo-flow-release-assurance-manifest-tcbs manifest)
                    poo-flow-assurance-tcb-id)))
        (cons 'claims
              (map claim->canonical
                   (assurance-sort
                    (poo-flow-release-assurance-manifest-claims manifest)
                    poo-flow-assurance-claim-id)))
        (cons 'gates
              (map gate->canonical
                   (assurance-sort
                    (poo-flow-release-assurance-manifest-gates manifest)
                    poo-flow-assurance-gate-result-id)))
        (abi-decision->canonical
         (poo-flow-release-assurance-manifest-abi-decision manifest))))

(def (duplicate-ids values id-of)
  (let loop ((rest (assurance-sort values id-of))
             (previous #f)
             (duplicates '()))
    (if (null? rest)
      (reverse duplicates)
      (let (id (id-of (car rest)))
        (loop (cdr rest) id
              (if (and previous (equal? previous id))
                (cons id duplicates)
                duplicates))))))

(def (nonempty-id? value)
  (or (symbol? value)
      (and (string? value) (> (string-length value) 0))))

(def (diagnostic code path observed)
  (list (cons 'code code) (cons 'path path) (cons 'observed observed)))

(def (poo-flow-release-assurance-manifest-validate manifest)
  (let (diagnostics '())
    (def (reject! code path observed)
      (set! diagnostics (cons (diagnostic code path observed) diagnostics)))
    (unless (poo-flow-release-assurance-manifest? manifest)
      (reject! 'invalid-manifest '(kind) manifest))
    (when (poo-flow-release-assurance-manifest? manifest)
      (let (capabilities-valid?
            (poo-flow-qualification-capabilities-valid?
             manifest
             (list poo-flow-versioned-capability-valid?
                   poo-flow-revision-bound-capability-valid?)))
        (unless capabilities-valid?
          (reject! 'invalid-capability-composition '(capabilities) #f))
        (when capabilities-valid?
          (unless (and (equal? (.ref manifest 'schema-id)
                               +poo-flow-release-assurance-manifest-schema+)
                       (= (.ref manifest 'schema-version) 1))
            (reject! 'capability-schema-mismatch
                     '(capabilities versioned)
                     (list (.ref manifest 'schema-id)
                           (.ref manifest 'schema-version))))
          (unless (equal?
                   (.ref manifest 'source-revision)
                   (poo-flow-release-assurance-manifest-source-revision
                    manifest))
            (reject! 'capability-revision-mismatch
                     '(capabilities revision-bound source-revision)
                     (.ref manifest 'source-revision)))))
      (unless (nonempty-id?
               (poo-flow-release-assurance-manifest-release-id manifest))
        (reject! 'missing-release-id '(release-id) #f))
      (unless (nonempty-id?
               (poo-flow-release-assurance-manifest-source-revision manifest))
        (reject! 'missing-source-revision '(source-revision) #f))
      (unless (pair? (poo-flow-release-assurance-manifest-identities manifest))
        (reject! 'missing-identities '(identities) '()))
      (let ((tcbs (poo-flow-release-assurance-manifest-tcbs manifest))
            (claims (poo-flow-release-assurance-manifest-claims manifest))
            (gates (poo-flow-release-assurance-manifest-gates manifest))
            (abi (poo-flow-release-assurance-manifest-abi-decision manifest)))
        (unless (and (pair? tcbs) (andmap poo-flow-assurance-tcb? tcbs))
          (reject! 'invalid-tcbs '(tcbs) tcbs))
        (unless (and (pair? claims) (andmap poo-flow-assurance-claim? claims))
          (reject! 'invalid-claims '(claims) claims))
        (unless (and (pair? gates) (andmap poo-flow-assurance-gate-result? gates))
          (reject! 'invalid-gates '(gates) gates))
        (when (andmap poo-flow-assurance-tcb? tcbs)
          (let (duplicates (duplicate-ids tcbs poo-flow-assurance-tcb-id))
            (when (pair? duplicates)
              (reject! 'duplicate-tcb-id '(tcbs) duplicates))))
        (when (andmap poo-flow-assurance-claim? claims)
          (let (duplicates (duplicate-ids claims poo-flow-assurance-claim-id))
            (when (pair? duplicates)
              (reject! 'duplicate-claim-id '(claims) duplicates)))
          (for-each
           (lambda (claim)
             (unless (and (nonempty-id? (poo-flow-assurance-claim-owner claim))
                          (poo-flow-assurance-tcb?
                           (poo-flow-assurance-claim-tcb claim))
                          (pair? (poo-flow-assurance-claim-evidence claim))
                          (andmap poo-flow-assurance-evidence-reference?
                                  (poo-flow-assurance-claim-evidence claim))
                          (nonempty-id?
                           (poo-flow-assurance-claim-failure-state claim)))
               (reject! 'incomplete-claim
                        (list 'claims (poo-flow-assurance-claim-id claim))
                        claim)))
           claims))
        (when (andmap poo-flow-assurance-gate-result? gates)
          (let (duplicates
                (duplicate-ids gates poo-flow-assurance-gate-result-id))
            (when (pair? duplicates)
              (reject! 'duplicate-gate-id '(gates) duplicates)))
          (for-each
           (lambda (gate)
             (unless (and (memq (poo-flow-assurance-gate-result-status gate)
                                '(passed failed unsupported))
                          (poo-flow-assurance-evidence-reference?
                           (poo-flow-assurance-gate-result-evidence gate)))
               (reject! 'invalid-gate-result
                        (list 'gates
                              (poo-flow-assurance-gate-result-id gate))
                        gate)))
           gates))
        (unless (and (poo-flow-assurance-abi-decision? abi)
                     (boolean?
                      (poo-flow-assurance-abi-decision-frozen? abi))
                     (nonempty-id?
                      (poo-flow-assurance-abi-decision-review abi)))
          (reject! 'invalid-abi-decision '(abi-decision) abi))))
    (object<-alist
     (list
      (cons 'kind 'poo-flow.release-assurance-validation-receipt.v1)
      (cons 'accepted? (null? diagnostics))
      (cons 'code (if (null? diagnostics) 'accepted 'rejected))
      (cons 'diagnostics (reverse diagnostics))))))

(def (poo-flow-release-assurance-manifest-identity manifest)
  (let (validation (poo-flow-release-assurance-manifest-validate manifest))
    (unless (.ref validation 'accepted?)
      (error "cannot identify invalid release assurance manifest"
             (.ref validation 'diagnostics)))
    (let* ((canonical (poo-flow-release-assurance-manifest-normalize manifest))
           (digest-value
            (hex-encode
             (sha256
              (call-with-output-string
               (lambda (port) (write canonical port)))))))
      (object<-alist
       (list
        (cons 'kind 'poo-flow.release-assurance-manifest.identity.v1)
        (cons 'algorithm 'sha256)
        (cons 'digest digest-value)
        (cons 'release-id
              (poo-flow-release-assurance-manifest-release-id manifest))
        (cons 'source-revision
              (poo-flow-release-assurance-manifest-source-revision manifest)))))))
