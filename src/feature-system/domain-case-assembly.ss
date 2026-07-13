(import :clan/poo/object
        :poo-flow/src/core/roles
        :poo-flow/src/feature-system/composition
        :poo-flow/src/module-system/domain-case)

(export feature-domain-case-assembly
        require-feature-domain-case-assembly
        defpoo-feature-domain-case-assembly)

(def (constant-domain-case-assembly-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

(def (feature-domain-case-assembly cache
                                   domain-case-id
                                   domain-case-version
                                   composition-plan)
  (let* ((components (.ref composition-plan 'components))
         (closure-receipt
          (poo-flow-domain-case-close
           cache domain-case-id domain-case-version components))
         (accepted? (.ref closure-receipt 'accepted?)))
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
       (key . ,(.ref closure-receipt 'key))
       (domain-case . ,(.ref closure-receipt 'domain-case))
       (diagnostics . ,(.ref closure-receipt 'diagnostics))
       (policy-contributions
        . ,(.ref composition-plan 'policy-contributions))
       (strategy-contributions
        . ,(.ref composition-plan 'strategy-contributions))
       (adapter-requirements
        . ,(.ref composition-plan 'adapter-requirements))
       (projections . ,(.ref composition-plan 'projections))))))

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
