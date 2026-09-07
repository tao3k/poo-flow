;;; Boundary: declarative feature capability values and kind predicates;
;;; catalog indexing and adapter resolution remain separate owners.
(import (only-in :clan/poo/object
                 .ref
                 make-object
                 object-slots-set!
                 object?)
        :poo-flow/src/core/roles)

(export +feature-adapter-capability-kind+
        +feature-adapter-requirement-kind+
        +feature-projection-request-kind+
        feature-adapter-capability
        feature-adapter-capability?
        feature-adapter-requirement
        feature-adapter-requirement?
        feature-projection-request
        feature-projection-request?
        defpoo-feature-adapter-capability
        defpoo-feature-adapter-requirement
        defpoo-feature-projection-request)

(def +feature-adapter-capability-kind+
  'poo-flow.feature-adapter-capability.v1)

(def +feature-adapter-requirement-kind+
  'poo-flow.feature-adapter-requirement.v1)

(def +feature-projection-request-kind+
  'poo-flow.feature-projection-request.v1)

;; : (-> Alist POOObject)
(def (constant-feature-capability-object slot-values)
  (let ((object (make-object)))
    (object-slots-set! object (role-constant-slots slot-values))
    object))

;; : (-> Object Symbol [Symbol] Boolean)
(def (feature-capability-object-kind? value expected-kind required-slots)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (and (object? value)
          (eq? (.ref value 'kind) expected-kind)
          (let loop ((slots required-slots))
            (cond
             ((null? slots) #t)
             ((.ref value (car slots)) (loop (cdr slots)))
             (else #f)))))))

;; : (-> Symbol Symbol Symbol Integer PooFeatureAdapterCapability)
(def (feature-adapter-capability capability-id provider-module-id
                                 contract-id contract-version)
  (constant-feature-capability-object
   `((kind . ,+feature-adapter-capability-kind+)
     (schema-version . 1)
     (capability-id . ,capability-id)
     (provider-module-id . ,provider-module-id)
     (contract-id . ,contract-id)
     (contract-version . ,contract-version))))

;; : (-> Object Boolean)
(def (feature-adapter-capability? value)
  (feature-capability-object-kind?
   value
   +feature-adapter-capability-kind+
   '(capability-id provider-module-id contract-id contract-version)))

;; : (-> Symbol Symbol Symbol Integer PooFeatureAdapterRequirement)
(def (feature-adapter-requirement requirement-id capability-id
                                  contract-id contract-version)
  (constant-feature-capability-object
   `((kind . ,+feature-adapter-requirement-kind+)
     (schema-version . 1)
     (requirement-id . ,requirement-id)
     (capability-id . ,capability-id)
     (contract-id . ,contract-id)
     (contract-version . ,contract-version))))

;; : (-> Object Boolean)
(def (feature-adapter-requirement? value)
  (feature-capability-object-kind?
   value
   +feature-adapter-requirement-kind+
   '(requirement-id capability-id contract-id contract-version)))

;; : (-> Symbol Symbol Symbol PooFeatureProjectionRequest)
(def (feature-projection-request request-id projection-id schema-id)
  (constant-feature-capability-object
   `((kind . ,+feature-projection-request-kind+)
     (schema-version . 1)
     (request-id . ,request-id)
     (projection-id . ,projection-id)
     (schema-id . ,schema-id))))

;; : (-> Object Boolean)
(def (feature-projection-request? value)
  (feature-capability-object-kind?
   value
   +feature-projection-request-kind+
   '(request-id projection-id schema-id)))

;; defpoo-feature-adapter-capability
;;   : (-> Identifier Clauses FeatureAdapterCapabilityBinding)
;;   | doc m%
;;       Bind a module-owned adapter capability as a POO object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-feature-adapter-capability adapter
;;         (capability-id adapter) (provider-module-id runtime)
;;         (contract-id adapter.v1) (contract-version 1))
;;       ;; => binds adapter
;;       ```
;;     %
(defrules defpoo-feature-adapter-capability
  (capability-id provider-module-id contract-id contract-version)
  ((_ binding
      (capability-id semantic-id)
      (provider-module-id module-id)
      (contract-id adapter-contract-id)
      (contract-version adapter-contract-version))
   (def binding
     (feature-adapter-capability
      semantic-id module-id adapter-contract-id adapter-contract-version))))

;; defpoo-feature-adapter-requirement
;;   : (-> Identifier Clauses FeatureAdapterRequirementBinding)
;;   | doc m%
;;       Bind an adapter requirement as a POO object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-feature-adapter-requirement required
;;         (requirement-id required) (capability-id adapter)
;;         (contract-id adapter.v1) (contract-version 1))
;;       ;; => binds required
;;       ```
;;     %
(defrules defpoo-feature-adapter-requirement
  (requirement-id capability-id contract-id contract-version)
  ((_ binding
      (requirement-id semantic-id)
      (capability-id required-capability-id)
      (contract-id adapter-contract-id)
      (contract-version adapter-contract-version))
   (def binding
     (feature-adapter-requirement
      semantic-id
      required-capability-id
      adapter-contract-id
      adapter-contract-version))))

;; defpoo-feature-projection-request
;;   : (-> Identifier Clauses FeatureProjectionRequestBinding)
;;   | doc m%
;;       Bind a named projection request for a feature profile.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-feature-projection-request request
;;         (request-id request) (projection-id runtime) (schema-id runtime.v1))
;;       ;; => binds request
;;       ```
;;     %
(defrules defpoo-feature-projection-request
  (request-id projection-id schema-id)
  ((_ binding
      (request-id semantic-id)
      (projection-id case-projection-id)
      (schema-id projection-schema-id))
   (def binding
     (feature-projection-request
      semantic-id case-projection-id projection-schema-id))))
