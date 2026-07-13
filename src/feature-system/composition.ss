(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/feature-manifest
        :poo-flow/src/utilities/functional)

(export feature-composition-plan
        defpoo-feature-composition-plan)

(def (constant-composition-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

;; Accumulators are kept in reverse order so every contribution is visited once
;; without append-driven quadratic growth.  The final reverse restores the
;; resolver-defined feature order and each feature's declaration order.
(def (feature-composition-accumulate values accumulator)
  (let loop ((values values)
             (accumulator accumulator))
    (match values
      ([value . rest]
       (loop rest (cons value accumulator)))
      ([] accumulator))))

(def (feature-composition-contributions manifests)
  (let loop ((manifests manifests)
             (components [])
             (policy-contributions [])
             (strategy-contributions [])
             (adapter-requirements [])
             (projections []))
    (match manifests
      ([manifest . rest]
       (loop rest
             (feature-composition-accumulate
              (.ref manifest 'components) components)
             (feature-composition-accumulate
              (.ref manifest 'policy-contributions)
              policy-contributions)
             (feature-composition-accumulate
              (.ref manifest 'strategy-contributions)
              strategy-contributions)
             (feature-composition-accumulate
              (.ref manifest 'adapter-requirements)
              adapter-requirements)
             (feature-composition-accumulate
              (.ref manifest 'projections) projections)))
      ([] (values (reverse components)
                  (reverse policy-contributions)
                  (reverse strategy-contributions)
                  (reverse adapter-requirements)
                  (reverse projections))))))

(def (feature-composition-plan bundle)
  (let* ((bundle (require-valid-feature-manifest-bundle bundle))
         (feature-ids (.ref bundle 'feature-ids))
         (manifests
          (poo-flow-map
           (lambda (feature-id)
             (require-feature-manifest-bundle-ref bundle feature-id))
           feature-ids)))
    (let-values (((components
                   policy-contributions
                   strategy-contributions
                   adapter-requirements
                   projections)
                  (feature-composition-contributions manifests)))
      (constant-composition-object
       `((kind . feature-composition-plan)
         (schema-version . 1)
         (bundle-id . ,(.ref bundle 'bundle-id))
         (bundle . ,bundle)
         (status . ready)
         (accepted? . #t)
         (feature-ids . ,feature-ids)
         (manifests . ,manifests)
         (components . ,components)
         (policy-contributions . ,policy-contributions)
         (strategy-contributions . ,strategy-contributions)
         (adapter-requirements . ,adapter-requirements)
         (projections . ,projections))))))

(defrules defpoo-feature-composition-plan (from-bundle)
  ((_ binding (from-bundle bundle-value))
   (def binding
     (feature-composition-plan bundle-value))))
