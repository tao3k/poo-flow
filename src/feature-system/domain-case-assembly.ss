(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/capability-model
        :poo-flow/src/feature-system/composition
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/utilities/functional)

(export feature-domain-case-assembly
        require-feature-domain-case-assembly
        defpoo-feature-domain-case-assembly)

(def (constant-domain-case-assembly-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-domain-case-projection-request-diagnostic request)
  (constant-domain-case-assembly-object
   `((kind . poo-flow.feature-domain-case-assembly-diagnostic.v1)
     (code . invalid-feature-projection-request)
     (channel . projections)
     (observed . ,request))))

(def (feature-domain-case-projection-request-diagnostics requests)
  (poo-flow-filter-map
   (lambda (request)
     (and (not (feature-projection-request? request))
          (feature-domain-case-projection-request-diagnostic request)))
   requests))

(def (feature-domain-case-assembly-receipt
      domain-case-id domain-case-version composition-plan components
      projection-requests selected-projection-ids closure-receipt
      accepted? key domain-case diagnostics)
  (constant-domain-case-assembly-object
   `((kind . feature-domain-case-assembly)
     (schema-version . 1)
     (domain-case-id . ,domain-case-id)
     (domain-case-version . ,domain-case-version)
     (composition-plan . ,composition-plan)
     (components . ,components)
     (closure-receipt . ,closure-receipt)
     (accepted? . ,accepted?)
     (status . ,(if accepted? 'ready 'rejected))
     (key . ,key)
     (domain-case . ,domain-case)
     (diagnostics . ,diagnostics)
     (policy-contributions
      . ,(.ref composition-plan 'policy-contributions))
     (strategy-contributions
      . ,(.ref composition-plan 'strategy-contributions))
     (adapter-requirements
      . ,(.ref composition-plan 'adapter-requirements))
     (projection-requests . ,projection-requests)
     (selected-projection-ids . ,selected-projection-ids)
     (projections . ,projection-requests))))

(def (feature-domain-case-assembly cache
                                   domain-case-id
                                   domain-case-version
                                   composition-plan)
  (let* ((components (.ref composition-plan 'components))
         (projection-requests (.ref composition-plan 'projections))
         (request-diagnostics
          (feature-domain-case-projection-request-diagnostics
           projection-requests)))
    (if (pair? request-diagnostics)
      (feature-domain-case-assembly-receipt
       domain-case-id domain-case-version composition-plan components
       projection-requests '() #f #f #f #f request-diagnostics)
      (let* ((selected-projection-ids
              (poo-flow-map
               (lambda (request) (.ref request 'projection-id))
               projection-requests))
             (closure-receipt
              (poo-flow-domain-case-close
               cache
               domain-case-id
               domain-case-version
               components
               '()
               selected-projection-ids))
             (accepted? (.ref closure-receipt 'accepted?)))
        (feature-domain-case-assembly-receipt
         domain-case-id domain-case-version composition-plan components
         projection-requests selected-projection-ids closure-receipt
         accepted?
         (.ref closure-receipt 'key)
         (.ref closure-receipt 'domain-case)
         (.ref closure-receipt 'diagnostics))))))

(def (require-feature-domain-case-assembly assembly)
  (if (.ref assembly 'accepted?)
    assembly
    (error "feature domain Case assembly rejected"
           (.ref assembly 'domain-case-id)
           (.ref assembly 'diagnostics))))

(defrules defpoo-feature-domain-case-assembly
  (using-cache domain-case-id domain-case-version from-plan)
  ((_ binding
      (using-cache cache-value)
      (domain-case-id semantic-id)
      (domain-case-version version)
      (from-plan composition-plan))
   (def binding
     (feature-domain-case-assembly
      cache-value semantic-id version composition-plan))))
