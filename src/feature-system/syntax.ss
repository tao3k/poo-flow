(import :poo-flow/src/feature-system/model)

(export defpoo-feature
        defpoo-feature-profile)

(defrules feature-clause->fragment
  (schema-version
   category
   requires
   optional-requires
   conflicts
   option-schemas
   components
   policy-contributions
   strategy-contributions
   adapter-requirements
   projections)
  ((_ (schema-version value))
   (feature-schema-version value))
  ((_ (category value))
   (feature-category value))
  ((_ (requires descriptor ...))
   (feature-required-features descriptor ...))
  ((_ (optional-requires descriptor ...))
   (feature-optional-features descriptor ...))
  ((_ (conflicts descriptor ...))
   (feature-conflicting-features descriptor ...))
  ((_ (option-schemas option-schema ...))
   (feature-option-schemas option-schema ...))
  ((_ (components component ...))
   (feature-components component ...))
  ((_ (policy-contributions contribution ...))
   (feature-policy-contributions contribution ...))
  ((_ (strategy-contributions contribution ...))
   (feature-strategy-contributions contribution ...))
  ((_ (adapter-requirements requirement ...))
   (feature-adapter-requirements requirement ...))
  ((_ (projections projection ...))
   (feature-projections projection ...)))

(defrules defpoo-feature (feature-id owner-module-id)
  ((_ binding
      (feature-id semantic-id)
      (owner-module-id owner-id)
      clause ...)
   (def binding
     (feature-descriptor
      (feature-spec-compose
       (feature-descriptor-base semantic-id owner-id)
       (feature-clause->fragment clause) ...)))))

(defrules feature-selection-form (select options)
  ((_ (select descriptor))
   (feature-selection descriptor))
  ((_ (select descriptor (options option-values)))
   (feature-selection descriptor option-values)))

(defrules defpoo-feature-profile
  (profile-id selections contracts select options)
  ((_ binding
      (profile-id semantic-id)
      (selections selection ...))
   (def binding
     (feature-profile
      semantic-id
      (list (feature-selection-form selection) ...))))
  ((_ binding
      (profile-id semantic-id)
      (selections selection ...)
      (contracts contract ...))
   (def binding
     (feature-profile
      semantic-id
      (list (feature-selection-form selection) ...)
      (list contract ...)))))
