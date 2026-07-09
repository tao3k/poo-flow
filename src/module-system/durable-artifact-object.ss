;;; Boundary: durable artifact object construction, visibility, and lifecycle.
;;; Invariant: this module owns artifact policy data only; validation receipts
;;; and runtime handoff manifests stay in durable-artifact-policy.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist)
        :poo-flow/src/module-system/durable-artifact-profile)

(export poo-flow-durable-artifact
        poo-flow-durable-artifact?
        poo-flow-durable-artifact->alist
        poo-flow-durable-artifact-visible?
        poo-flow-durable-artifact-lifecycle-transition-allowed?
        poo-flow-durable-artifact-transition
        poo-flow-artifact-list-has?
        poo-flow-artifact-scope-subset?)

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

;; : (-> Symbol Symbol)
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

;; : (-> [Datum] Alist)
(def (poo-flow-durable-artifact-sections->alist sections)
  (match sections
    ([] '())
    ([key]
     (error "durable artifact section requires a value" key))
    ([key value . rest]
     (cons (cons (poo-flow-durable-artifact-section-slot key) value)
           (poo-flow-durable-artifact-sections->alist rest)))))

;; : (-> Symbol Symbol [Symbol] Symbol Symbol Datum Datum [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] PooDurableArtifact)
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
  (object<-alist
   (list
    (cons 'durable-artifact-kind +poo-flow-durable-artifact-kind+)
    (cons 'durable-artifact-schema +poo-flow-durable-artifact-schema+)
    (cons 'artifact-id artifact-id-value)
    (cons 'artifact-kind artifact-kind-value)
    (cons 'artifact-scope artifact-scope-value)
    (cons 'storage-class storage-class-value)
    (cons 'lifecycle-state lifecycle-state-value)
    (cons 'producer-ref producer-ref-value)
    (cons 'owner-ref owner-ref-value)
    (cons 'sandbox-scope sandbox-scope-value)
    (cons 'checksum-policy checksum-policy-value)
    (cons 'analysis-policy analysis-policy-value)
    (cons 'index-policy index-policy-value)
    (cons 'call-policy call-policy-value)
    (cons 'publish-policy publish-policy-value)
    (cons 'retention-policy retention-policy-value)
    (cons 'explicit-grants explicit-grants-value)
    (cons 'runtime-executed #f)
    (cons 'source 'poo-flow.durable.artifact.policy))))

;; : (-> Symbol [Datum] PooDurableArtifact)
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

;; : (-> Datum Boolean)
(def (poo-flow-durable-artifact? artifact)
  (and (object? artifact)
       (.slot? artifact 'durable-artifact-kind)
       (eq? (.ref artifact 'durable-artifact-kind)
            +poo-flow-durable-artifact-kind+)))

;; : (-> PooDurableArtifact Alist)
(def (poo-flow-durable-artifact->alist artifact)
  (map (lambda (field) (cons field (.ref artifact field)))
       +poo-flow-durable-artifact-fields+))

;; poo-flow-artifact-list-has?
;; : (-> [Datum] Datum Boolean)
;; | doc m%
;;   Return true when ITEMS contains VALUE using durable policy equality.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-list-has? '(session publish) 'session)
;;   ;; => #t
;;   ```
(def (poo-flow-artifact-list-has? items value)
  (and (member value items) #t))

;; poo-flow-artifact-scope-subset?
;; : (-> [Symbol] [Symbol] Boolean)
;; | doc m%
;;   Return true when every actor scope entry is allowed by artifact scope.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-scope-subset? '(session) '(session project))
;;   ;; => #t
;;   ```
(def (poo-flow-artifact-scope-subset? actor-scope artifact-scope)
  (andmap (lambda (scope-id)
            (poo-flow-artifact-list-has? artifact-scope scope-id))
          actor-scope))

;; : (-> PooDurableArtifact Datum Boolean)
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

;; : (-> PooDurableArtifact Datum Boolean)
(def (poo-flow-durable-artifact-visible? artifact actor)
  (let ((actor-scope (if (and (object? actor) (.slot? actor 'scope))
                       (.ref actor 'scope)
                       '()))
        (artifact-scope (.ref artifact 'artifact-scope)))
    (or (poo-flow-artifact-scope-subset? actor-scope artifact-scope)
        (poo-flow-durable-artifact-explicit-grant? artifact actor))))

;; : (-> Symbol Symbol Boolean)
(def (poo-flow-durable-artifact-lifecycle-transition-allowed? from-state
                                                              to-state)
  (poo-flow-artifact-list-has?
   +poo-flow-durable-artifact-lifecycle-edges+
   (cons from-state to-state)))

;; : (-> PooDurableArtifact Symbol PooDurableArtifact)
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
