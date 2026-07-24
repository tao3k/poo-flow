(import :clan/poo/object
        :poo-flow/src/policy/protocol-person-promotion
        :poo-flow/src/contract/runtime-v0-abi-schema)

(export +poo-flow-runtime-language-promotion-request-schema+
        +poo-flow-runtime-language-promotion-receipt-schema+
        +poo-flow-runtime-language-promotion-required-capabilities+
        +poo-flow-runtime-language-promotion-outcomes+
        poo-flow-runtime-language-promotion-idempotency-key
        poo-flow-runtime-language-promotion-idempotency-key->alist
        poo-flow-runtime-language-promotion-request
        poo-flow-runtime-language-promotion-request->alist
        poo-flow-runtime-language-promotion-request->vector
        poo-flow-runtime-language-promotion-abi->c-header
        poo-flow-runtime-language-promotion-capabilities-cover?
        poo-flow-runtime-language-promotion-epochs-current?
        poo-flow-runtime-language-promotion-receipt
        poo-flow-runtime-language-promotion-receipt-failures
        poo-flow-runtime-language-promotion-receipt-valid?
        poo-flow-runtime-language-promotion-receipt-active?
        poo-flow-runtime-language-promotion-receipt->alist
        poo-flow-runtime-language-promotion-receipts-exactly-once?
        +poo-flow-runtime-language-source-query-receipt-schema+
        +poo-flow-runtime-language-admission-receipt-schema+
        +poo-flow-contract-artifact-projection-receipt-schema+
        +poo-flow-runtime-language-source-representations+
        +poo-flow-contract-artifact-kinds+
        +poo-flow-runtime-language-admission-outcomes+
        poo-flow-runtime-language-source-query-receipt
        poo-flow-runtime-language-source-query-receipt-failures
        poo-flow-runtime-language-source-query-receipt-valid?
        poo-flow-runtime-language-source-query-receipt->alist
        poo-flow-runtime-language-admission-receipt
        poo-flow-runtime-language-admission-receipt-failures
        poo-flow-runtime-language-admission-receipt-valid?
        poo-flow-runtime-language-admission-receipt-admitted?
        poo-flow-runtime-language-admission-receipt->alist
        poo-flow-contract-artifact-projection-receipt
        poo-flow-contract-artifact-projection-receipt-failures
        poo-flow-contract-artifact-projection-receipt-valid?
        poo-flow-contract-artifact-projection-receipt->alist)

(def +poo-flow-runtime-language-promotion-request-schema+
  (string->symbol
   (.ref +poo-flow-runtime-v0-abi-schema+ 'promotion-request-schema)))

(def +poo-flow-runtime-language-promotion-receipt-schema+
  (string->symbol
   (.ref +poo-flow-runtime-v0-abi-schema+ 'promotion-receipt-schema)))

(def +poo-flow-runtime-language-promotion-required-capabilities+
  '(PROMOTION_MATERIALIZE
    INJECTION_RECEIPT
    ROLLBACK
    EXACTLY_ONCE
    LANGUAGE_QUALIFICATION))

(def +poo-flow-runtime-language-promotion-outcomes+
  '(accepted
    materialized
    injected
    replayed-active
    rejected-stale-epoch
    rejected-capability
    rolled-back
    failed))

(def (poo-flow-runtime-language-promotion-idempotency-key intent)
  (.o (kind 'poo-flow.runtime-language.promotion-idempotency-key.1)
      (promotion-id (.ref intent 'promotion-id))
      (materialization-id (.ref intent 'materialization-id))
      (candidate-digest (.ref intent 'candidate-digest))
      (injection-target (.ref intent 'injection-target))))

(def (poo-flow-runtime-language-promotion-idempotency-key->alist key)
  (list (cons 'kind (.ref key 'kind))
        (cons 'promotion-id (.ref key 'promotion-id))
        (cons 'materialization-id (.ref key 'materialization-id))
        (cons 'candidate-digest (.ref key 'candidate-digest))
        (cons 'injection-target (.ref key 'injection-target))))

(def (poo-flow-runtime-language-promotion-request intent validation-receipt)
  (unless (and (object? intent)
               (eq? (.ref intent 'kind) 'poo-flow-promotion-intent))
    (error "runtime language ABI requires a POO promotion intent" intent))
  (unless (and (poo-flow-promotion-validation-receipt?
                validation-receipt)
               (poo-flow-promotion-validation-receipt-approved?
                validation-receipt))
    (error "runtime language ABI rejects an unapproved promotion"
           validation-receipt))
  (unless (and (equal? (.ref intent 'promotion-id)
                       (poo-flow-promotion-validation-receipt-promotion-id
                        validation-receipt))
               (equal? (.ref intent 'candidate-digest)
                       (poo-flow-promotion-validation-receipt-candidate-digest
                        validation-receipt)))
    (error "promotion intent and validation receipt identities differ"
           intent validation-receipt))
  (.o (kind +poo-flow-runtime-language-promotion-request-schema+)
      (abi-major 0)
      (abi-minor 3)
      (required-capabilities
       +poo-flow-runtime-language-promotion-required-capabilities+)
      (idempotency-key
       (poo-flow-runtime-language-promotion-idempotency-key intent))
      (promotion-id (.ref intent 'promotion-id))
      (candidate-digest (.ref intent 'candidate-digest))
      (subject-id (.ref intent 'subject-id))
      (commitment-id (.ref intent 'commitment-id))
      (source-role (.ref intent 'source-role))
      (target-role (.ref intent 'target-role))
      (scope (.ref intent 'scope))
      (bundle-epoch (.ref intent 'expected-bundle-epoch))
      (authority-epoch (.ref intent 'expected-authority-epoch))
      (proof-epoch (.ref intent 'expected-proof-epoch))
      (evaluator-epoch (.ref intent 'expected-evaluator-epoch))
      (evidence-root (.ref intent 'evidence-root))
      (materialization-id (.ref intent 'materialization-id))
      (injection-target (.ref intent 'injection-target))
      (rollback-target (.ref intent 'rollback-target))
      (validation-receipt-schema
       (poo-flow-promotion-validation-receipt-schema validation-receipt))
      (approval-code
       (poo-flow-promotion-validation-receipt-approval-code
        validation-receipt))
      (checked-gates
       (poo-flow-promotion-validation-receipt-checked-gates
        validation-receipt))
      (runtime-executed #f)))

(def (poo-flow-runtime-language-promotion-request->alist request)
  (let (key (.ref request 'idempotency-key))
    (list
     (cons 'kind (.ref request 'kind))
     (cons 'abi-major (.ref request 'abi-major))
     (cons 'abi-minor (.ref request 'abi-minor))
     (cons 'required-capabilities (.ref request 'required-capabilities))
     (cons 'idempotency-key
           (poo-flow-runtime-language-promotion-idempotency-key->alist key))
     (cons 'promotion-id (.ref request 'promotion-id))
     (cons 'candidate-digest (.ref request 'candidate-digest))
     (cons 'subject-id (.ref request 'subject-id))
     (cons 'commitment-id (.ref request 'commitment-id))
     (cons 'source-role (.ref request 'source-role))
     (cons 'target-role (.ref request 'target-role))
     (cons 'scope (.ref request 'scope))
     (cons 'bundle-epoch (.ref request 'bundle-epoch))
     (cons 'authority-epoch (.ref request 'authority-epoch))
     (cons 'proof-epoch (.ref request 'proof-epoch))
     (cons 'evaluator-epoch (.ref request 'evaluator-epoch))
     (cons 'evidence-root (.ref request 'evidence-root))
     (cons 'materialization-id (.ref request 'materialization-id))
     (cons 'injection-target (.ref request 'injection-target))
     (cons 'rollback-target (.ref request 'rollback-target))
     (cons 'validation-receipt-schema
           (.ref request 'validation-receipt-schema))
     (cons 'approval-code (.ref request 'approval-code))
     (cons 'checked-gates (.ref request 'checked-gates))
     (cons 'runtime-executed (.ref request 'runtime-executed)))))

(def (runtime-language-abi-emit-field port name value)
  (display name port)
  (display "=" port)
  (display value port)
  (newline port))

(def (poo-flow-runtime-language-promotion-request->vector request)
  (let ((port (open-output-string))
        (key (.ref request 'idempotency-key)))
    (runtime-language-abi-emit-field port "schema" (.ref request 'kind))
    (runtime-language-abi-emit-field port "abi-major" (.ref request 'abi-major))
    (runtime-language-abi-emit-field port "abi-minor" (.ref request 'abi-minor))
    (runtime-language-abi-emit-field
     port "required-capabilities" (.ref request 'required-capabilities))
    (runtime-language-abi-emit-field
     port "idempotency-key-schema" (.ref key 'kind))
    (runtime-language-abi-emit-field
     port "promotion-id" (.ref request 'promotion-id))
    (runtime-language-abi-emit-field
     port "materialization-id" (.ref request 'materialization-id))
    (runtime-language-abi-emit-field
     port "candidate-digest" (.ref request 'candidate-digest))
    (runtime-language-abi-emit-field
     port "subject-id" (.ref request 'subject-id))
    (runtime-language-abi-emit-field
     port "commitment-id" (.ref request 'commitment-id))
    (runtime-language-abi-emit-field
     port "source-role" (.ref request 'source-role))
    (runtime-language-abi-emit-field
     port "target-role" (.ref request 'target-role))
    (runtime-language-abi-emit-field port "scope" (.ref request 'scope))
    (runtime-language-abi-emit-field
     port "bundle-epoch" (.ref request 'bundle-epoch))
    (runtime-language-abi-emit-field
     port "authority-epoch" (.ref request 'authority-epoch))
    (runtime-language-abi-emit-field
     port "proof-epoch" (.ref request 'proof-epoch))
    (runtime-language-abi-emit-field
     port "evaluator-epoch" (.ref request 'evaluator-epoch))
    (runtime-language-abi-emit-field
     port "evidence-root" (.ref request 'evidence-root))
    (runtime-language-abi-emit-field
     port "injection-target" (.ref request 'injection-target))
    (runtime-language-abi-emit-field
     port "rollback-target" (.ref request 'rollback-target))
    (runtime-language-abi-emit-field
     port "validation-receipt-schema"
     (.ref request 'validation-receipt-schema))
    (runtime-language-abi-emit-field
     port "approval-code" (.ref request 'approval-code))
    (runtime-language-abi-emit-field
     port "checked-gates" (.ref request 'checked-gates))
    (get-output-string port)))

(def (poo-flow-runtime-language-promotion-abi->c-header)
  (poo-flow-runtime-v0-abi-schema->c-header
   +poo-flow-runtime-v0-abi-schema+))

(def (poo-flow-runtime-language-promotion-capabilities-cover? supported)
  (let loop ((required
              +poo-flow-runtime-language-promotion-required-capabilities+))
    (or (null? required)
        (and (memq (car required) supported)
             (loop (cdr required))))))

(def (poo-flow-runtime-language-promotion-epochs-current? request world)
  (and (= (.ref request 'bundle-epoch) (.ref world 'bundle-epoch))
       (= (.ref request 'authority-epoch) (.ref world 'authority-epoch))
       (= (.ref request 'proof-epoch) (.ref world 'proof-epoch))
       (= (.ref request 'evaluator-epoch) (.ref world 'evaluator-epoch))))

(def (poo-flow-runtime-language-promotion-receipt
      request world implementation-id-value implementation-version-value
      language-value supported-capabilities-value attempt-value outcome-value
      materialization-digest-value injection-receipt-digest-value
      rollback-receipt-digest-value causal-receipt-digest-value)
  (unless (and (object? request)
               (eq? (.ref request 'kind)
                    +poo-flow-runtime-language-promotion-request-schema+))
    (error "runtime receipt requires a canonical promotion request" request))
  (.o (kind +poo-flow-runtime-language-promotion-receipt-schema+)
      (abi-major (.ref request 'abi-major))
      (abi-minor (.ref request 'abi-minor))
      (idempotency-key (.ref request 'idempotency-key))
      (promotion-id (.ref request 'promotion-id))
      (materialization-id (.ref request 'materialization-id))
      (candidate-digest (.ref request 'candidate-digest))
      (implementation-id implementation-id-value)
      (implementation-version implementation-version-value)
      (language language-value)
      (supported-capabilities supported-capabilities-value)
      (capability-qualified
       (poo-flow-runtime-language-promotion-capabilities-cover?
        supported-capabilities-value))
      (attempt attempt-value)
      (outcome outcome-value)
      (observed-bundle-epoch (.ref world 'bundle-epoch))
      (observed-authority-epoch (.ref world 'authority-epoch))
      (observed-proof-epoch (.ref world 'proof-epoch))
      (observed-evaluator-epoch (.ref world 'evaluator-epoch))
      (epoch-current
       (poo-flow-runtime-language-promotion-epochs-current? request world))
      (materialization-digest materialization-digest-value)
      (injection-receipt-digest injection-receipt-digest-value)
      (rollback-receipt-digest rollback-receipt-digest-value)
      (causal-receipt-digest causal-receipt-digest-value)
      (runtime-executed #t)))

(def (runtime-language-abi-present? value)
  (and value
       (not (equal? value ""))
       (not (equal? value 'none))))

(def (runtime-language-abi-rejected-outcome? outcome)
  (memq outcome '(rejected-stale-epoch rejected-capability failed)))

(def (poo-flow-runtime-language-promotion-receipt-failures receipt)
  (let ((outcome (.ref receipt 'outcome))
        (qualified? (.ref receipt 'capability-qualified))
        (current? (.ref receipt 'epoch-current))
        (materialization (.ref receipt 'materialization-digest))
        (injection (.ref receipt 'injection-receipt-digest))
        (rollback (.ref receipt 'rollback-receipt-digest))
        (causal (.ref receipt 'causal-receipt-digest)))
    (let loop
        ((checks
          (list
           (cons (and (integer? (.ref receipt 'attempt))
                      (> (.ref receipt 'attempt) 0))
                 'invalid-attempt)
           (cons (memq outcome +poo-flow-runtime-language-promotion-outcomes+)
                 'invalid-outcome)
           (cons (or qualified? (eq? outcome 'rejected-capability))
                 'unsupported-capability-effect)
           (cons (or (not qualified?)
                     (not (eq? outcome 'rejected-capability)))
                 'false-capability-rejection)
           (cons (or current? (eq? outcome 'rejected-stale-epoch))
                 'stale-epoch-effect)
           (cons (or (not current?)
                     (not (eq? outcome 'rejected-stale-epoch)))
                 'false-stale-rejection)
           (cons (or (not (eq? outcome 'materialized))
                     (runtime-language-abi-present? materialization))
                 'materialization-digest-missing)
           (cons (or (not (memq outcome '(injected replayed-active)))
                     (and (runtime-language-abi-present? materialization)
                          (runtime-language-abi-present? injection)))
                 'injection-receipt-incomplete)
           (cons (or (not (eq? outcome 'replayed-active))
                     (runtime-language-abi-present? causal))
                 'replay-causal-receipt-missing)
           (cons (or (not (eq? outcome 'rolled-back))
                     (runtime-language-abi-present? rollback))
                 'rollback-receipt-missing)
           (cons (or (not (runtime-language-abi-rejected-outcome? outcome))
                     (and (not (runtime-language-abi-present? materialization))
                          (not (runtime-language-abi-present? injection))
                          (not (runtime-language-abi-present? rollback))))
                 'rejected-outcome-carried-effects)
           (cons (.ref receipt 'runtime-executed)
                 'runtime-execution-receipt-missing)))
         (failures '()))
      (if (null? checks)
          (reverse failures)
          (let (check (car checks))
            (loop (cdr checks)
                  (if (car check)
                      failures
                      (cons (cdr check) failures))))))))

(def (poo-flow-runtime-language-promotion-receipt-valid? receipt)
  (null? (poo-flow-runtime-language-promotion-receipt-failures receipt)))

(def (poo-flow-runtime-language-promotion-receipt-active? receipt)
  (and (poo-flow-runtime-language-promotion-receipt-valid? receipt)
       (memq (.ref receipt 'outcome) '(injected replayed-active))
       #t))

(def (poo-flow-runtime-language-promotion-receipt->alist receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'abi-major (.ref receipt 'abi-major))
   (cons 'abi-minor (.ref receipt 'abi-minor))
   (cons 'idempotency-key
         (poo-flow-runtime-language-promotion-idempotency-key->alist
          (.ref receipt 'idempotency-key)))
   (cons 'promotion-id (.ref receipt 'promotion-id))
   (cons 'materialization-id (.ref receipt 'materialization-id))
   (cons 'candidate-digest (.ref receipt 'candidate-digest))
   (cons 'implementation-id (.ref receipt 'implementation-id))
   (cons 'implementation-version (.ref receipt 'implementation-version))
   (cons 'language (.ref receipt 'language))
   (cons 'supported-capabilities (.ref receipt 'supported-capabilities))
   (cons 'capability-qualified (.ref receipt 'capability-qualified))
   (cons 'attempt (.ref receipt 'attempt))
   (cons 'outcome (.ref receipt 'outcome))
   (cons 'observed-bundle-epoch (.ref receipt 'observed-bundle-epoch))
   (cons 'observed-authority-epoch (.ref receipt 'observed-authority-epoch))
   (cons 'observed-proof-epoch (.ref receipt 'observed-proof-epoch))
   (cons 'observed-evaluator-epoch (.ref receipt 'observed-evaluator-epoch))
   (cons 'epoch-current (.ref receipt 'epoch-current))
   (cons 'materialization-digest (.ref receipt 'materialization-digest))
   (cons 'injection-receipt-digest
         (.ref receipt 'injection-receipt-digest))
   (cons 'rollback-receipt-digest
         (.ref receipt 'rollback-receipt-digest))
   (cons 'causal-receipt-digest (.ref receipt 'causal-receipt-digest))
   (cons 'runtime-executed (.ref receipt 'runtime-executed))
   (cons 'valid
         (poo-flow-runtime-language-promotion-receipt-valid? receipt))
   (cons 'failures
         (poo-flow-runtime-language-promotion-receipt-failures receipt))))

(def (poo-flow-runtime-language-promotion-receipts-exactly-once? receipts)
  (let loop ((rest receipts) (committed 0))
    (cond
     ((> committed 1) #f)
     ((null? rest) (= committed 1))
     (else
      (let (receipt (car rest))
        (if (and (poo-flow-runtime-language-promotion-receipt-valid? receipt)
                 (eq? (.ref receipt 'outcome) 'injected))
            (loop (cdr rest) (+ committed 1))
            (loop (cdr rest) committed)))))))
(def +poo-flow-runtime-language-source-query-receipt-schema+
  (string->symbol
   (.ref +poo-flow-runtime-v0-abi-schema+ 'source-query-receipt-schema)))

(def +poo-flow-runtime-language-admission-receipt-schema+
  (string->symbol
   (.ref +poo-flow-runtime-v0-abi-schema+ 'runtime-admission-receipt-schema)))

(def +poo-flow-contract-artifact-projection-receipt-schema+
  (string->symbol
   (.ref +poo-flow-runtime-v0-abi-schema+
         'contract-artifact-projection-receipt-schema)))

(def +poo-flow-runtime-language-source-representations+
  '(json ast-data))

(def +poo-flow-contract-artifact-kinds+
  '(abi-vector c-header json-schema python-type rust-type gerbil-poo
    lean-proposition))

(def +poo-flow-runtime-language-admission-outcomes+
  '(admitted rejected))

(def (runtime-language-identity-present? value)
  (and value
       (not (equal? value ""))
       (not (equal? value '()))))

(def (runtime-language-version-present? value)
  (and (string? value)
       (runtime-language-identity-present? value)))

(def (poo-flow-runtime-language-source-query-receipt
      source-language-value
      source-content-id-value
      source-version-value
      parser-id-value
      parser-version-value
      query-id-value
      query-version-value
      selected-node-identities-value
      representation-value
      provenance-root-value
      result-digest-value)
  (.o (kind +poo-flow-runtime-language-source-query-receipt-schema+)
      (source-language source-language-value)
      (source-content-id source-content-id-value)
      (source-version source-version-value)
      (parser-id parser-id-value)
      (parser-version parser-version-value)
      (query-id query-id-value)
      (query-version query-version-value)
      (selected-node-identities selected-node-identities-value)
      (representation representation-value)
      (provenance-root provenance-root-value)
      (result-digest result-digest-value)))

(def (poo-flow-runtime-language-source-query-receipt-failures receipt)
  (let ((failures '()))
    (def (fail! code)
      (set! failures (cons code failures)))
    (unless (and (object? receipt)
                 (eq? (.ref receipt 'kind)
                      +poo-flow-runtime-language-source-query-receipt-schema+))
      (fail! 'invalid-source-query-receipt-schema))
    (when (object? receipt)
      (unless (runtime-language-identity-present?
               (.ref receipt 'source-language))
        (fail! 'missing-source-language))
      (unless (runtime-language-identity-present?
               (.ref receipt 'source-content-id))
        (fail! 'missing-source-content-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'source-version))
        (fail! 'missing-source-version))
      (unless (runtime-language-identity-present? (.ref receipt 'parser-id))
        (fail! 'missing-parser-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'parser-version))
        (fail! 'missing-parser-version))
      (unless (runtime-language-identity-present? (.ref receipt 'query-id))
        (fail! 'missing-query-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'query-version))
        (fail! 'missing-query-version))
      (unless (pair? (.ref receipt 'selected-node-identities))
        (fail! 'missing-selected-node-identities))
      (unless (member (.ref receipt 'representation)
                      +poo-flow-runtime-language-source-representations+)
        (fail! 'unsupported-source-representation))
      (unless (runtime-language-identity-present?
               (.ref receipt 'provenance-root))
        (fail! 'missing-provenance-root))
      (unless (runtime-language-identity-present?
               (.ref receipt 'result-digest))
        (fail! 'missing-query-result-digest)))
    (reverse failures)))

(def (poo-flow-runtime-language-source-query-receipt-valid? receipt)
  (null? (poo-flow-runtime-language-source-query-receipt-failures receipt)))

(def (poo-flow-runtime-language-source-query-receipt->alist receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'source-language (.ref receipt 'source-language))
   (cons 'source-content-id (.ref receipt 'source-content-id))
   (cons 'source-version (.ref receipt 'source-version))
   (cons 'parser-id (.ref receipt 'parser-id))
   (cons 'parser-version (.ref receipt 'parser-version))
   (cons 'query-id (.ref receipt 'query-id))
   (cons 'query-version (.ref receipt 'query-version))
   (cons 'selected-node-identities
         (.ref receipt 'selected-node-identities))
   (cons 'representation (.ref receipt 'representation))
   (cons 'provenance-root (.ref receipt 'provenance-root))
   (cons 'result-digest (.ref receipt 'result-digest))
   (cons 'valid
         (poo-flow-runtime-language-source-query-receipt-valid? receipt))
   (cons 'failures
         (poo-flow-runtime-language-source-query-receipt-failures receipt))))

(def (poo-flow-runtime-language-admission-receipt
      source-query-receipt-value
      contract-id-value
      contract-version-value
      adapter-id-value
      adapter-version-value
      target-language-value
      normalized-semantic-digest-value
      admission-outcome-value
      failure-codes-value)
  (.o (kind +poo-flow-runtime-language-admission-receipt-schema+)
      (source-query-receipt source-query-receipt-value)
      (source-query-result-digest
       (and (object? source-query-receipt-value)
            (.ref source-query-receipt-value 'result-digest)))
      (contract-id contract-id-value)
      (contract-version contract-version-value)
      (adapter-id adapter-id-value)
      (adapter-version adapter-version-value)
      (target-language target-language-value)
      (normalized-semantic-digest normalized-semantic-digest-value)
      (admission-outcome admission-outcome-value)
      (failure-codes failure-codes-value)))

(def (poo-flow-runtime-language-admission-receipt-failures receipt)
  (let ((failures '()))
    (def (fail! code)
      (set! failures (cons code failures)))
    (unless (and (object? receipt)
                 (eq? (.ref receipt 'kind)
                      +poo-flow-runtime-language-admission-receipt-schema+))
      (fail! 'invalid-admission-receipt-schema))
    (when (object? receipt)
      (unless (poo-flow-runtime-language-source-query-receipt-valid?
               (.ref receipt 'source-query-receipt))
        (fail! 'invalid-source-query-receipt))
      (unless (runtime-language-identity-present? (.ref receipt 'contract-id))
        (fail! 'missing-contract-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'contract-version))
        (fail! 'missing-contract-version))
      (unless (runtime-language-identity-present? (.ref receipt 'adapter-id))
        (fail! 'missing-adapter-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'adapter-version))
        (fail! 'missing-adapter-version))
      (unless (runtime-language-identity-present?
               (.ref receipt 'target-language))
        (fail! 'missing-target-language))
      (unless (member (.ref receipt 'admission-outcome)
                      +poo-flow-runtime-language-admission-outcomes+)
        (fail! 'unsupported-admission-outcome))
      (when (eq? (.ref receipt 'admission-outcome) 'admitted)
        (unless (runtime-language-identity-present?
                 (.ref receipt 'normalized-semantic-digest))
          (fail! 'missing-normalized-semantic-digest))
        (unless (null? (.ref receipt 'failure-codes))
          (fail! 'admitted-projection-has-failures)))
      (when (eq? (.ref receipt 'admission-outcome) 'rejected)
        (unless (pair? (.ref receipt 'failure-codes))
          (fail! 'rejected-projection-missing-failures))))
    (reverse failures)))

(def (poo-flow-runtime-language-admission-receipt-valid? receipt)
  (null? (poo-flow-runtime-language-admission-receipt-failures receipt)))

(def (poo-flow-runtime-language-admission-receipt-admitted? receipt)
  (and (poo-flow-runtime-language-admission-receipt-valid? receipt)
       (eq? (.ref receipt 'admission-outcome) 'admitted)))

(def (poo-flow-runtime-language-admission-receipt->alist receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'source-query-result-digest
         (.ref receipt 'source-query-result-digest))
   (cons 'contract-id (.ref receipt 'contract-id))
   (cons 'contract-version (.ref receipt 'contract-version))
   (cons 'adapter-id (.ref receipt 'adapter-id))
   (cons 'adapter-version (.ref receipt 'adapter-version))
   (cons 'target-language (.ref receipt 'target-language))
   (cons 'normalized-semantic-digest
         (.ref receipt 'normalized-semantic-digest))
   (cons 'admission-outcome (.ref receipt 'admission-outcome))
   (cons 'failure-codes (.ref receipt 'failure-codes))
   (cons 'valid
         (poo-flow-runtime-language-admission-receipt-valid? receipt))
   (cons 'admitted
         (poo-flow-runtime-language-admission-receipt-admitted? receipt))
   (cons 'failures
         (poo-flow-runtime-language-admission-receipt-failures receipt))))
(def (poo-flow-contract-artifact-projection-receipt
      projection-id-value
      contract-id-value
      contract-version-value
      source-contract-digest-value
      projector-id-value
      projector-version-value
      artifact-kind-value
      artifact-id-value
      output-digest-value)
  (.o (kind +poo-flow-contract-artifact-projection-receipt-schema+)
      (projection-id projection-id-value)
      (contract-id contract-id-value)
      (contract-version contract-version-value)
      (source-contract-digest source-contract-digest-value)
      (projector-id projector-id-value)
      (projector-version projector-version-value)
      (artifact-kind artifact-kind-value)
      (artifact-id artifact-id-value)
      (output-digest output-digest-value)))

(def (poo-flow-contract-artifact-projection-receipt-failures receipt)
  (let ((failures '()))
    (def (fail! code)
      (set! failures (cons code failures)))
    (unless (and (object? receipt)
                 (eq? (.ref receipt 'kind)
                      +poo-flow-contract-artifact-projection-receipt-schema+))
      (fail! 'invalid-artifact-projection-receipt-schema))
    (when (object? receipt)
      (unless (runtime-language-identity-present?
               (.ref receipt 'projection-id))
        (fail! 'missing-projection-id))
      (unless (runtime-language-identity-present? (.ref receipt 'contract-id))
        (fail! 'missing-contract-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'contract-version))
        (fail! 'missing-contract-version))
      (unless (runtime-language-identity-present?
               (.ref receipt 'source-contract-digest))
        (fail! 'missing-source-contract-digest))
      (unless (runtime-language-identity-present? (.ref receipt 'projector-id))
        (fail! 'missing-projector-id))
      (unless (runtime-language-version-present?
               (.ref receipt 'projector-version))
        (fail! 'missing-projector-version))
      (unless (member (.ref receipt 'artifact-kind)
                      +poo-flow-contract-artifact-kinds+)
        (fail! 'unsupported-artifact-kind))
      (unless (runtime-language-identity-present? (.ref receipt 'artifact-id))
        (fail! 'missing-artifact-id))
      (unless (runtime-language-identity-present? (.ref receipt 'output-digest))
        (fail! 'missing-output-digest)))
    (reverse failures)))

(def (poo-flow-contract-artifact-projection-receipt-valid? receipt)
  (null? (poo-flow-contract-artifact-projection-receipt-failures receipt)))

(def (poo-flow-contract-artifact-projection-receipt->alist receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'projection-id (.ref receipt 'projection-id))
   (cons 'contract-id (.ref receipt 'contract-id))
   (cons 'contract-version (.ref receipt 'contract-version))
   (cons 'source-contract-digest (.ref receipt 'source-contract-digest))
   (cons 'projector-id (.ref receipt 'projector-id))
   (cons 'projector-version (.ref receipt 'projector-version))
   (cons 'artifact-kind (.ref receipt 'artifact-kind))
   (cons 'artifact-id (.ref receipt 'artifact-id))
   (cons 'output-digest (.ref receipt 'output-digest))
   (cons 'valid
         (poo-flow-contract-artifact-projection-receipt-valid? receipt))
   (cons 'failures
         (poo-flow-contract-artifact-projection-receipt-failures receipt))))
