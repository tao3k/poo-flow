(import :std/misc/hash
        :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/model
        :poo-flow/src/feature-system/resolver
        :poo-flow/src/utilities/functional)

(export feature-manifest
        feature-manifest-bundle
        require-valid-feature-manifest-bundle
        defpoo-feature-manifest-bundle)

;; Manifest and bundle values deliberately use the same constant-slot POO
;; representation as the feature model. The local mutation is restricted to
;; constructing a fresh object whose public slots are immutable afterwards.
(def (constant-manifest-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

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

(def (feature-manifest-option-diagnostics manifest)
  (let ((feature-id (.ref manifest 'feature-id))
        (seen (make-hash-table-eq)))
    (let loop ((schemas (.ref manifest 'option-schemas))
               (diagnostics []))
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
        ([] (reverse diagnostics))))))

(def (feature-manifest-structural-diagnostics manifests)
  (apply append
         (poo-flow-map feature-manifest-option-diagnostics manifests)))

(def (feature-manifest-bundle bundle-id descriptors)
  (let* ((manifests (poo-flow-map feature-manifest descriptors))
         (selections (poo-flow-map feature-selection descriptors))
         (profile (feature-profile bundle-id selections))
         (activation-plan (resolve-feature-profile profile))
         (diagnostics
          (append (.ref activation-plan 'diagnostics)
                  (feature-manifest-structural-diagnostics manifests)))
         (status (if (null? diagnostics) 'ready 'rejected)))
    (constant-manifest-object
     `((kind . feature-manifest-bundle)
       (schema-version . 1)
       (bundle-id . ,bundle-id)
       (descriptors . ,descriptors)
       (manifests . ,manifests)
       (activation-plan . ,activation-plan)
       (feature-ids . ,(.ref activation-plan 'feature-ids))
       (status . ,status)
       (accepted? . ,(eq? status 'ready))
       (diagnostics . ,diagnostics)))))

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
