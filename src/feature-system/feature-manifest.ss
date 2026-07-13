(import :std/misc/hash
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/model
        :poo-flow/src/feature-system/resolver
        :poo-flow/src/utilities/functional)

(export feature-manifest
        feature-manifest-bundle
        feature-manifest-bundle-ref
        require-feature-manifest-bundle-ref
        require-valid-feature-manifest-bundle
        defpoo-feature-manifest-bundle)

;; The hash is bundle-owned construction state.  The uninterned slot key keeps
;; it outside the stable POO extension contract while preserving O(1) lookup.
(def feature-manifest-index-storage-slot
  (gensym 'feature-manifest-index-storage))

;; Manifest and bundle values deliberately use the same constant-slot POO
;; representation as the feature model. The local mutation is restricted to
;; constructing a fresh object whose public slots are immutable afterwards.
(def (constant-manifest-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-manifest-index-object storage size)
  (constant-manifest-object
   `((kind . feature-manifest-index)
     (size . ,size)
     (,feature-manifest-index-storage-slot . ,storage))))

(def (feature-manifest-index-ref index feature-id)
  (hash-ref (.ref index feature-manifest-index-storage-slot)
            feature-id
            #f))

(def (feature-manifest descriptor)
  (constant-manifest-object
   `((kind . feature-manifest)
     (schema-version . ,(.ref descriptor 'schema-version))
     (feature-id . ,(.ref descriptor 'feature-id))
     (owner-module-id . ,(.ref descriptor 'owner-module-id))
     (category . ,(.ref descriptor 'category))
     (requires . ,(.ref descriptor 'requires))
     (optional-requires . ,(.ref descriptor 'optional-requires))
     (conflicts . ,(.ref descriptor 'conflicts))
     (option-schemas . ,(.ref descriptor 'option-schemas))
     (components . ,(.ref descriptor 'components))
     (policy-contributions . ,(.ref descriptor 'policy-contributions))
     (strategy-contributions . ,(.ref descriptor 'strategy-contributions))
     (adapter-requirements . ,(.ref descriptor 'adapter-requirements))
     (projections . ,(.ref descriptor 'projections)))))

(def (feature-manifest-option-diagnostics manifest diagnostics)
  (let ((feature-id (.ref manifest 'feature-id))
        (seen (make-hash-table-eq)))
    (let loop ((schemas (.ref manifest 'option-schemas))
               (diagnostics diagnostics))
      (match schemas
        ([schema . rest]
         (let ((option-id (.ref schema 'option-id)))
           (if (hash-key? seen option-id)
             (loop rest
                   (cons (feature-diagnostic
                          'duplicate-option-schema
                          feature-id
                          option-id
                          'option-ids-must-be-unique-within-a-feature)
                         diagnostics))
             (begin
               (hash-put! seen option-id #t)
               (loop rest diagnostics)))))
        ([] diagnostics)))))

(def (feature-manifests+diagnostics descriptors)
  (let ((storage (make-hash-table-eq)))
    (let loop ((descriptors descriptors)
               (manifests [])
               (diagnostics [])
               (index-size 0))
      (match descriptors
        ([descriptor . rest]
         (let* ((manifest (feature-manifest descriptor))
                (feature-id (.ref manifest 'feature-id))
                (new-identity? (not (hash-key? storage feature-id))))
           (when new-identity?
             (hash-put! storage feature-id manifest))
           (loop rest
                 (cons manifest manifests)
                 (feature-manifest-option-diagnostics
                  manifest diagnostics)
                 (if new-identity?
                   (+ index-size 1)
                   index-size))))
        ([] (values (reverse manifests)
                    (reverse diagnostics)
                    (feature-manifest-index-object
                     storage index-size)))))))

(def (feature-manifest-bundle bundle-id descriptors)
  (let-values (((manifests structural-diagnostics manifest-index)
                (feature-manifests+diagnostics descriptors)))
    (let* ((selections (poo-flow-map feature-selection descriptors))
           (profile (feature-profile bundle-id selections))
           (activation-plan (resolve-feature-profile profile))
           (diagnostics
            (append (.ref activation-plan 'diagnostics)
                    structural-diagnostics))
           (status (if (null? diagnostics) 'ready 'rejected)))
      (constant-manifest-object
       `((kind . feature-manifest-bundle)
         (schema-version . 1)
         (bundle-id . ,bundle-id)
         (descriptors . ,descriptors)
         (manifests . ,manifests)
         (manifest-index . ,(if (eq? status 'ready)
                              manifest-index
                              #f))
         (activation-plan . ,activation-plan)
         (feature-ids . ,(.ref activation-plan 'feature-ids))
         (status . ,status)
         (accepted? . ,(eq? status 'ready))
         (diagnostics . ,diagnostics))))))

(def (feature-manifest-bundle-ref bundle feature-id)
  (let ((index (.ref bundle 'manifest-index)))
    (if index
      (feature-manifest-index-ref index feature-id)
      (error "cannot query rejected feature manifest bundle"
             (.ref bundle 'bundle-id)
             (.ref bundle 'diagnostics)))))

(def (require-feature-manifest-bundle-ref bundle feature-id)
  (or (feature-manifest-bundle-ref bundle feature-id)
      (error "feature manifest not found in bundle"
             (.ref bundle 'bundle-id)
             feature-id)))

(def (require-valid-feature-manifest-bundle bundle)
  (if (.ref bundle 'accepted?)
    bundle
    (error "feature manifest bundle rejected"
           (.ref bundle 'bundle-id)
           (.ref bundle 'diagnostics))))

(defrules defpoo-feature-manifest-bundle (bundle-id features)
  ((_ binding
      (bundle-id semantic-id)
      (features descriptor ...))
   (def binding
     (feature-manifest-bundle semantic-id
                              (list descriptor ...)))))
