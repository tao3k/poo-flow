(export #t)

(import :clan/poo/object
        :poo-flow/src/semantic/organization-bundle)

(def (poo-flow-organization-bundle->contract bundle)
  (let ((canonical-value (poo-flow-organization-bundle-normalize bundle))
        (identity-value (poo-flow-organization-bundle-identity bundle)))
    (.o (kind 'poo-flow.organization-bundle.contract.v1)
        (schema +poo-flow-organization-bundle-schema+)
        (canonical canonical-value)
        (identity identity-value))))

(def (poo-flow-organization-bundle-contract? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (eq? (.ref value 'kind)
               'poo-flow.organization-bundle.contract.v1)))))

(def (poo-flow-organization-bundle-contract-ref contract slot)
  (unless (poo-flow-organization-bundle-contract? contract)
    (error "expected organization Bundle contract" contract))
  (case slot
    ((schema canonical identity) (.ref contract slot))
    (else (error "unknown organization Bundle contract slot" slot))))
