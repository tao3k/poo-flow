;;; Boundary: exposes hygienic syntax for declaring POO-native features and profiles.
;;; Invariant: macros expand to ordinary model constructors without owning runtime behavior.
(import :poo-flow/src/feature-system/model)

(export defpoo-feature
        defpoo-feature-profile)

;; feature-clause->fragment
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Lower one declarative feature clause to its POO-native fragment.
;;
;;       # Examples
;;
;;       ```scheme
;;       (feature-clause->fragment (requires storage))
;;       ;; => (feature-required-features storage)
;;       ```
;;     %
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

;; defpoo-feature
;;   : (-> Identifier Clauses FeatureBinding)
;;   | doc m%
;;       Bind a feature descriptor from declarative, module-owned clauses.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-feature cache (feature-id cache) (owner-module-id runtime))
;;       ;; => binds cache to a feature descriptor
;;       ```
;;     %
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

;; feature-selection-form
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Lower one feature selection, preserving optional selection values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (feature-selection-form (select cache))
;;       ;; => (feature-selection cache)
;;       ```
;;     %
(defrules feature-selection-form (select options)
  ((_ (select descriptor))
   (feature-selection descriptor))
  ((_ (select descriptor (options option-values)))
   (feature-selection descriptor option-values)))

;; defpoo-feature-profile
;;   : (-> Identifier Clauses FeatureProfileBinding)
;;   | doc m%
;;       Bind a feature profile from selections and optional contracts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-feature-profile default (profile-id default) (selections))
;;       ;; => binds default to a feature profile
;;       ```
;;     %
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
