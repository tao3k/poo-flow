;;; Boundary: durable artifact profile objects and database profile objects.
;;; Invariant: this module returns POO-native objects and performs no runtime
;;; storage, database, artifact lifecycle, or Marlin handoff work.

(import (only-in :clan/poo/object .ref .slot? object? object<-alist))

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
        poo-flow-artifact-alist-ref)

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

(def +poo-flow-artifact-section-slot-aliases+
  '((:extends . extends)
    (extends . extends)
    (:kind . kind)
    (kind . kind)
    (:scope . scope)
    (scope . scope)
    (:storage . storage)
    (storage . storage)
    (:analysis . analysis)
    (analysis . analysis)
    (:publish . publish)
    (publish . publish)
    (:retention . retention)
    (retention . retention)
    (:lifecycle . lifecycle)
    (lifecycle . lifecycle)
    (:database . database)
    (database . database)
    (:with . hooks)
    (with . hooks)
    (:classes . classes)
    (classes . classes)
    (:capabilities . capabilities)
    (capabilities . capabilities)))

;; poo-flow-artifact-section-slot
;; : (-> ArtifactSectionKey Symbol)
;; | doc m%
;;   Normalize artifact profile section keywords into stable object slots.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-section-slot ':publish)
;;   ;; => publish
;;   ```
(def (poo-flow-artifact-section-slot key)
  (let (entry (assq key +poo-flow-artifact-section-slot-aliases+))
    (if entry (cdr entry) key)))

;; : (-> [ArtifactSectionDatum] Alist)
(def (poo-flow-artifact-sections->alist sections)
  (match sections
    ([] '())
    ([key]
     (error "artifact profile section requires a value" key))
    ([key value . rest]
     (cons (cons (poo-flow-artifact-section-slot key) value)
           (poo-flow-artifact-sections->alist rest)))))

;; poo-flow-artifact-alist-ref
;; : (-> ArtifactFieldAlist Symbol Datum Datum)
;; | doc m%
;;   Read an artifact field from normalized section rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-alist-ref fields 'scope '())
;;   ;; => field value or default
;;   ```
(def (poo-flow-artifact-alist-ref alist key default-value)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default-value)))

;; poo-flow-artifact-profile/direct
;; : (-> Symbol ArtifactExtends Symbol [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [Symbol] [(-> PooArtifactProfile PooArtifactProfile)] PooArtifactProfile)
;; | doc m%
;;   Build the POO-native artifact profile object from normalized slots.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-profile/direct 'report #f 'report '() '() '() '() '() '() '() '())
;;   ;; => artifact profile object
;;   ```
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
  (object<-alist
   (list
    (cons 'artifact-profile-kind +poo-flow-durable-artifact-profile-kind+)
    (cons 'artifact-profile-schema +poo-flow-durable-artifact-profile-schema+)
    (cons 'name profile-name)
    (cons 'extends extends-value)
    (cons 'kind kind-value)
    (cons 'scope scope-value)
    (cons 'storage storage-value)
    (cons 'analysis analysis-value)
    (cons 'publish publish-value)
    (cons 'retention retention-value)
    (cons 'lifecycle lifecycle-value)
    (cons 'database database-value)
    (cons 'hooks hooks-value)
    (cons 'runtime-executed #f)
    (cons 'source 'poo-flow.durable.artifact.policy))))

;; poo-flow-artifact-database-profile/direct
;; : (-> Symbol ArtifactExtends [Symbol] [Symbol] [Symbol] PooArtifactDatabaseProfile)
;; | doc m%
;;   Build the POO-native artifact database profile object from normalized slots.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-database-profile/direct 'turso #f '(sqlite) '(kv) '(file))
;;   ;; => artifact database profile object
;;   ```
(def (poo-flow-artifact-database-profile/direct profile-name
                                                extends-value
                                                classes-value
                                                capabilities-value
                                                storage-value)
  (object<-alist
   (list
    (cons 'artifact-database-profile-kind
          +poo-flow-durable-artifact-database-profile-kind+)
    (cons 'artifact-database-profile-schema
          +poo-flow-durable-artifact-database-profile-schema+)
    (cons 'name profile-name)
    (cons 'extends extends-value)
    (cons 'classes classes-value)
    (cons 'capabilities capabilities-value)
    (cons 'storage storage-value)
    (cons 'source 'poo-flow.durable.artifact.database))))

;; poo-flow-artifact-profile-from-alist
;; : (-> Symbol ArtifactFieldAlist PooArtifactProfile)
;; | doc m%
;;   Fill artifact profile defaults from normalized section rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-profile-from-alist 'report fields)
;;   ;; => artifact profile object
;;   ```
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

;; poo-flow-artifact-database-profile-from-alist
;; : (-> Symbol ArtifactFieldAlist PooArtifactDatabaseProfile)
;; | doc m%
;;   Fill database profile defaults from normalized section rows.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-database-profile-from-alist 'turso fields)
;;   ;; => artifact database profile object
;;   ```
(def (poo-flow-artifact-database-profile-from-alist profile-name fields)
  (poo-flow-artifact-database-profile/direct
   profile-name
   (poo-flow-artifact-alist-ref fields 'extends #f)
   (poo-flow-artifact-alist-ref fields 'classes '())
   (poo-flow-artifact-alist-ref fields 'capabilities '())
   (poo-flow-artifact-alist-ref fields 'storage '())))

;; poo-flow-artifact-profile
;; : (-> Symbol [ArtifactSectionDatum] PooArtifactProfile)
;; | doc m%
;;   Parse section syntax data and return a reusable POO artifact profile.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-profile 'report '(:scope (session)))
;;   ;; => artifact profile object
;;   ```
(def (poo-flow-artifact-profile name sections)
  (poo-flow-artifact-profile-from-alist
   name
   (poo-flow-artifact-sections->alist sections)))

;; poo-flow-artifact-database-profile
;; : (-> Symbol [ArtifactSectionDatum] PooArtifactDatabaseProfile)
;; | doc m%
;;   Parse section syntax data and return a reusable POO database profile.
;;   # Examples
;;   ```scheme
;;   (poo-flow-artifact-database-profile 'turso '(:storage (file)))
;;   ;; => artifact database profile object
;;   ```
(def (poo-flow-artifact-database-profile name sections)
  (poo-flow-artifact-database-profile-from-alist
   name
   (poo-flow-artifact-sections->alist sections)))

;; : (-> PooArtifactProfile Alist)
(def (poo-flow-artifact-profile->alist profile)
  (map (lambda (field) (cons field (.ref profile field)))
       +poo-flow-artifact-profile-fields+))

;; : (-> PooArtifactDatabaseProfile Alist)
(def (poo-flow-artifact-database-profile->alist profile)
  (map (lambda (field) (cons field (.ref profile field)))
       +poo-flow-artifact-database-profile-fields+))

;; : (-> PooArtifactProfile Symbol Datum Datum)
(def (poo-flow-artifact-object-ref/default object field default)
  (if (.slot? object field)
    (.ref object field)
    default))

;; : (-> Symbol PooArtifactProfile PooArtifactProfile PooArtifactProfile)
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

;; : (-> Symbol PooArtifactProfile PooArtifactProfile PooArtifactProfile)
(def (poo-flow-artifact-profile-extend name base override)
  (poo-flow-artifact-profile-override name base override))

;; : (-> PooArtifactProfile [(-> PooArtifactProfile PooArtifactProfile)] PooArtifactProfile)
(def (poo-flow-artifact-profile-apply-hooks profile hooks)
  (foldl (lambda (hook current) (hook current))
         profile
         hooks))

;; : (-> Datum Boolean)
(def (poo-flow-artifact-profile? profile)
  (and (object? profile)
       (.slot? profile 'artifact-profile-kind)
       (eq? (.ref profile 'artifact-profile-kind)
            +poo-flow-durable-artifact-profile-kind+)))

;; : (-> Datum Boolean)
(def (poo-flow-artifact-database-profile? profile)
  (and (object? profile)
       (.slot? profile 'artifact-database-profile-kind)
       (eq? (.ref profile 'artifact-database-profile-kind)
            +poo-flow-durable-artifact-database-profile-kind+)))

;; : (-> PooArtifactProfile [Symbol] Boolean)
(def (poo-flow-artifact-scope-contained? profile required-scope)
  (let (scope (.ref profile 'scope))
    (andmap (lambda (scope-id) (memq scope-id scope)) required-scope)))

;; : (-> PooArtifactProfile Boolean)
(def (poo-flow-artifact-publish-gated? profile)
  (let (publish (.ref profile 'publish))
    (or (null? publish)
        (and (memq 'human-approved publish)
             (memq 'proof-gated publish)
             #t))))
