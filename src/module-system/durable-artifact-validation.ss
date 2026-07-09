;;; Boundary: durable artifact validation and policy receipt projection.
;;; Invariant: validation compares already-built POO objects and emits bounded
;;; policy receipts; it does not create runtime manifests or perform handoff.

(import (only-in :clan/poo/object .ref .slot? object?)
        :poo-flow/src/module-system/durable-artifact-profile
        :poo-flow/src/module-system/durable-artifact-object)

(export poo-flow-durable-artifact-validate
        poo-flow-durable-artifact-policy-receipt?
        poo-flow-durable-artifact-policy-receipt-valid?
        poo-flow-durable-artifact-policy-receipt->alist)

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

(defstruct poo-flow-durable-artifact-policy-receipt-record
  (artifact-policy-receipt-kind
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
   source)
  transparent: #t)

;; : (-> PooDurableArtifactPolicyReceipt Symbol Datum)
(def (poo-flow-durable-artifact-policy-receipt-ref receipt field)
  (if (poo-flow-durable-artifact-policy-receipt-record? receipt)
    (case field
      ((artifact-policy-receipt-kind)
       (poo-flow-durable-artifact-policy-receipt-record-artifact-policy-receipt-kind receipt))
      ((artifact-policy-receipt-schema)
       (poo-flow-durable-artifact-policy-receipt-record-artifact-policy-receipt-schema receipt))
      ((artifact-id)
       (poo-flow-durable-artifact-policy-receipt-record-artifact-id receipt))
      ((profile-name)
       (poo-flow-durable-artifact-policy-receipt-record-profile-name receipt))
      ((database-name)
       (poo-flow-durable-artifact-policy-receipt-record-database-name receipt))
      ((valid?)
       (poo-flow-durable-artifact-policy-receipt-record-valid? receipt))
      ((scope-contained?)
       (poo-flow-durable-artifact-policy-receipt-record-scope-contained? receipt))
      ((storage-supported?)
       (poo-flow-durable-artifact-policy-receipt-record-storage-supported? receipt))
      ((analysis-supported?)
       (poo-flow-durable-artifact-policy-receipt-record-analysis-supported? receipt))
      ((publish-gated?)
       (poo-flow-durable-artifact-policy-receipt-record-publish-gated? receipt))
      ((retention-supported?)
       (poo-flow-durable-artifact-policy-receipt-record-retention-supported? receipt))
      ((lifecycle-state-valid?)
       (poo-flow-durable-artifact-policy-receipt-record-lifecycle-state-valid? receipt))
      ((database-storage-supported?)
       (poo-flow-durable-artifact-policy-receipt-record-database-storage-supported? receipt))
      ((database-capability-satisfied?)
       (poo-flow-durable-artifact-policy-receipt-record-database-capability-satisfied? receipt))
      ((diagnostics)
       (poo-flow-durable-artifact-policy-receipt-record-diagnostics receipt))
      ((runtime-executed)
       (poo-flow-durable-artifact-policy-receipt-record-runtime-executed receipt))
      ((source)
       (poo-flow-durable-artifact-policy-receipt-record-source receipt))
      (else #f))
    (.ref receipt field)))

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

;; : (-> Datum [Datum])
(def (poo-flow-artifact-value->list value)
  (cond
   ((null? value) '())
   ((pair? value) value)
   (else (list value))))

;; : (-> Datum Datum Boolean)
(def (poo-flow-artifact-values-contained? required allowed)
  (poo-flow-artifact-scope-subset?
   (poo-flow-artifact-value->list required)
   (poo-flow-artifact-value->list allowed)))

;; : (-> [Symbol] Boolean Symbol [Symbol])
(def (poo-flow-artifact-diagnostic diagnostics ok? code)
  (if ok?
    diagnostics
    (cons code diagnostics)))

;; : (-> Symbol Boolean)
(def (poo-flow-durable-artifact-lifecycle-state-valid? state)
  (poo-flow-artifact-list-has?
   +poo-flow-durable-artifact-lifecycle-states+
   state))

;; : (-> Symbol Symbol Symbol Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean [Symbol] PooDurableArtifactPolicyReceipt)
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
  (make-poo-flow-durable-artifact-policy-receipt-record
   +poo-flow-durable-artifact-policy-receipt-kind+
   +poo-flow-durable-artifact-policy-receipt-schema+
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
   diagnostics-value
   #f
   'poo-flow.durable.artifact.policy))

;;; Boundary: artifact validation is the durable policy gate between POO
;;; profile objects and downstream artifact/database runtime handoff.
;; : (-> PooDurableArtifact PooArtifactProfile PooArtifactDatabaseProfile PooDurableArtifactPolicyReceipt)
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

;; : (-> Datum Boolean)
(def (poo-flow-durable-artifact-policy-receipt? receipt)
  (or (poo-flow-durable-artifact-policy-receipt-record? receipt)
      (and (object? receipt)
           (.slot? receipt 'artifact-policy-receipt-kind)
           (eq? (.ref receipt 'artifact-policy-receipt-kind)
                +poo-flow-durable-artifact-policy-receipt-kind+))))

;; : (-> PooDurableArtifactPolicyReceipt Boolean)
(def (poo-flow-durable-artifact-policy-receipt-valid? receipt)
  (poo-flow-durable-artifact-policy-receipt-ref receipt 'valid?))

;; : (-> PooDurableArtifactPolicyReceipt Alist)
(def (poo-flow-durable-artifact-policy-receipt->alist receipt)
  (map (lambda (field)
         (cons field
               (poo-flow-durable-artifact-policy-receipt-ref receipt field)))
       +poo-flow-durable-artifact-policy-receipt-fields+))
