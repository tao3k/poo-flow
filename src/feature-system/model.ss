(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/utilities/functional)

(export feature-descriptor-base
        feature-spec-compose
        feature-schema-version
        feature-category
        feature-required-dependencies
        feature-optional-dependencies
        feature-conflicts-with
        feature-option-schemas
        feature-components
        feature-policy-contributions
        feature-strategy-contributions
        feature-adapter-requirements
        feature-projections
        feature-descriptor
        feature-selection
        feature-profile
        feature-diagnostic
        feature-activation-plan)

;; The alist is an internal encoding for clan/poo constant slot specs.  Public
;; Feature authoring is made of named POO fragments and functional composition.
(def (constant-feature-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (one-feature-slot slot value)
  (constant-feature-object (list (cons slot value))))

(def (feature-descriptor-base feature-id owner-module-id)
  (constant-feature-object
   (list
    (cons 'feature-id feature-id)
    (cons 'owner-module-id owner-module-id))))

(def (feature-spec-compose base . fragments)
  (apply role-instance-overlay (cons base fragments)))

(def (feature-category category)
  (one-feature-slot 'category category))

(def (feature-schema-version schema-version)
  (one-feature-slot 'schema-version schema-version))

(def (feature-required-dependencies . feature-ids)
  (one-feature-slot 'requires feature-ids))

(def (feature-optional-dependencies . feature-ids)
  (one-feature-slot 'optional-requires feature-ids))

(def (feature-conflicts-with . feature-ids)
  (one-feature-slot 'conflicts feature-ids))

(def (feature-option-schemas . option-schemas)
  (one-feature-slot 'option-schemas option-schemas))

(def (feature-components . components)
  (one-feature-slot 'components components))

(def (feature-policy-contributions . contributions)
  (one-feature-slot 'policy-contributions contributions))

(def (feature-strategy-contributions . contributions)
  (one-feature-slot 'strategy-contributions contributions))

(def (feature-adapter-requirements . requirements)
  (one-feature-slot 'adapter-requirements requirements))

(def (feature-projections . projections)
  (one-feature-slot 'projections projections))

(def (feature-slot/default object slot default-value)
  (if (.slot? object slot)
    (.ref object slot)
    default-value))

(def (copy-feature-values values)
  (poo-flow-map (lambda (value) value) values))

(def (feature-descriptor spec)
  (unless (.slot? spec 'feature-id)
    (error "missing required POO Feature slot" 'feature-id))
  (unless (.slot? spec 'owner-module-id)
    (error "missing required POO Feature slot" 'owner-module-id))
  (constant-feature-object
   (list
    (cons 'kind 'feature-descriptor)
    (cons 'feature-id (.ref spec 'feature-id))
    (cons 'schema-version (feature-slot/default spec 'schema-version 1))
    (cons 'owner-module-id (.ref spec 'owner-module-id))
    (cons 'category (feature-slot/default spec 'category 'uncategorized))
    (cons 'requires
          (copy-feature-values
           (feature-slot/default spec 'requires '())))
    (cons 'optional-requires
          (copy-feature-values
           (feature-slot/default spec 'optional-requires '())))
    (cons 'conflicts
          (copy-feature-values
           (feature-slot/default spec 'conflicts '())))
    (cons 'option-schemas
          (copy-feature-values
           (feature-slot/default spec 'option-schemas '())))
    (cons 'components
          (copy-feature-values
           (feature-slot/default spec 'components '())))
    (cons 'policy-contributions
          (copy-feature-values
           (feature-slot/default spec 'policy-contributions '())))
    (cons 'strategy-contributions
          (copy-feature-values
           (feature-slot/default spec 'strategy-contributions '())))
    (cons 'adapter-requirements
          (copy-feature-values
           (feature-slot/default spec 'adapter-requirements '())))
    (cons 'projections
          (copy-feature-values
           (feature-slot/default spec 'projections '()))))))

(def (empty-feature-options)
  (constant-feature-object (list (cons 'kind 'feature-options))))

(def (feature-selection descriptor (option-values (empty-feature-options)))
  (constant-feature-object
   (list
    (cons 'kind 'feature-selection)
    (cons 'feature-id (.ref descriptor 'feature-id))
    (cons 'descriptor descriptor)
    (cons 'option-values option-values))))

(def (feature-profile profile-id selections (contracts '()))
  (constant-feature-object
   (list
    (cons 'kind 'feature-profile)
    (cons 'profile-id profile-id)
    (cons 'selections (copy-feature-values selections))
    (cons 'contracts (copy-feature-values contracts)))))

(def (feature-diagnostic code feature-id related-id detail)
  (constant-feature-object
   (list
    (cons 'kind 'feature-diagnostic)
    (cons 'code code)
    (cons 'feature-id feature-id)
    (cons 'related-id related-id)
    (cons 'detail detail))))

(def (feature-activation-plan profile status ordered-selections
                              feature-ids diagnostics)
  (constant-feature-object
   (list
    (cons 'kind 'feature-activation-plan)
    (cons 'profile profile)
    (cons 'profile-id (.ref profile 'profile-id))
    (cons 'status status)
    (cons 'ordered-selections
          (copy-feature-values ordered-selections))
    (cons 'feature-ids (copy-feature-values feature-ids))
    (cons 'diagnostics (copy-feature-values diagnostics)))))
