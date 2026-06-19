;;; -*- Gerbil -*-
;;; Owner: agent-sandbox profile descriptors and validation live here.
;;; Boundary: core task/flow modules consume validated profiles, not backend defaults.
;;; Import contract: backend modules opt in to POO descriptors through this module.
;;; Runtime contract: profile data is inert until a runtime bridge interprets it.
;;; Policy evidence: backend defaults should depend on this owner, not the facade.

(import (only-in :clan/poo/object .@ .mix object?)
        :core/api
        :modules/agent-sandbox/alist)

(export +agent-sandbox-profile-schema+
        agent-sandbox-profile-descriptor-prototype
        make-agent-sandbox-backend-profile-descriptor
        make-agent-sandbox-profile-descriptor
        agent-sandbox-profile-descriptor?
        agent-sandbox-profile-descriptor-name
        agent-sandbox-profile-descriptor-backend-kind
        agent-sandbox-profile-descriptor-backend-ref
        agent-sandbox-profile-descriptor-network-policy
        agent-sandbox-profile-descriptor-capabilities
        agent-sandbox-profile-descriptor-resource-policy
        agent-sandbox-profile-descriptor-metadata
        agent-sandbox-profile-descriptor-validator
        agent-sandbox-profile-descriptor->profile
        make-agent-sandbox-backend-profile
        agent-sandbox-required-field-errors
        agent-sandbox-profile-validation-errors
        agent-sandbox-validate-profile
        agent-sandbox-profile-ref
        agent-sandbox-profile-backend-kind
        agent-sandbox-profile-backend-ref
        agent-sandbox-profile-network-policy
        agent-sandbox-profile-capabilities
        agent-sandbox-profile-resource-policy
        agent-sandbox-profile-metadata)

;; : (-> Unit Symbol)
(def +agent-sandbox-profile-schema+ 'poo-flow.agent-sandbox-profile.v1)

;;; Profile descriptors are POO policy objects: backend modules override slots,
;;; while core keeps one validation and projection path into request profiles.
;;; Higher-order boundary:
;;; - The validator slot is a Profile -> Profile procedure.
;;; - Backend overrides may replace policy data, but validation remains explicit.
;; : (-> AgentSandboxProfile AgentSandboxProfile)
(def (agent-sandbox-profile-validator profile)
  (agent-sandbox-validate-profile profile))

;; : (-> Unit AgentSandboxProfileDescriptorPrototype)
(def agent-sandbox-profile-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'name 'agent-sandbox-profile)
                      (cons 'backend-kind #f)
                      (cons 'backend-ref #f)
                      (cons 'network-policy '())
                      (cons 'capabilities '())
                      (cons 'resource-policy '())
                      (cons 'metadata '())
                      (cons 'validator agent-sandbox-profile-validator)))
        execution-policy-role))

;;; Descriptor construction is the override point for backend modules. The
;;; resulting object still projects through the same core profile contract.
;; : (-> Symbol Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy Metadata [Alist] AgentSandboxProfileDescriptor)
(def (make-agent-sandbox-profile-descriptor name
                                            backend-kind
                                            backend-ref
                                            network-policy
                                            capabilities
                                            resource-policy
                                            metadata
                                            . maybe-overrides)
  (.mix slots: (role-constant-slots
        (append
                 (list (cons 'name name)
                       (cons 'backend-kind backend-kind)
                       (cons 'backend-ref backend-ref)
                       (cons 'network-policy network-policy)
                       (cons 'capabilities capabilities)
                       (cons 'resource-policy resource-policy)
                       (cons 'metadata metadata))
                 (if (null? maybe-overrides) '() (car maybe-overrides))))
        agent-sandbox-profile-descriptor-prototype))

;;; Runtime source for the backend declaration macro. Keeping this as a normal
;;; function makes option merging and metadata callbacks inspectable by policy.
;;; Macro-expansion witness:
;;; - =defagent-sandbox-backend-profile= only supplies constructor names.
;;; - Every generated descriptor constructor delegates here before validation.
;; : (-> Symbol Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy MetadataProcedure Alist AgentSandboxProfileDescriptor)
(def (make-agent-sandbox-backend-profile-descriptor descriptor-name
                                                   backend-kind
                                                   backend-ref
                                                   default-network-policy
                                                   default-capabilities
                                                   default-resource-policy
                                                   metadata-procedure
                                                   options)
  (let (metadata-maker metadata-procedure)
    (make-agent-sandbox-profile-descriptor
     descriptor-name
     backend-kind
     backend-ref
     (agent-sandbox-option options 'network-policy default-network-policy)
     (agent-sandbox-option options 'capabilities default-capabilities)
     (agent-sandbox-option options 'resource-policy default-resource-policy)
     (agent-sandbox-option options
                           'metadata
                           (metadata-maker backend-ref)))))

;; : (-> AgentSandboxProfileDescriptorCandidate Boolean)
(def (agent-sandbox-profile-descriptor? descriptor)
  (object? descriptor))

;; : (-> AgentSandboxProfileDescriptor Symbol)
(def (agent-sandbox-profile-descriptor-name descriptor)
  (.@ descriptor name))

;; : (-> AgentSandboxProfileDescriptor (U Symbol #f))
(def (agent-sandbox-profile-descriptor-backend-kind descriptor)
  (.@ descriptor backend-kind))

;; : (-> AgentSandboxProfileDescriptor (U BackendRef #f))
(def (agent-sandbox-profile-descriptor-backend-ref descriptor)
  (.@ descriptor backend-ref))

;; : (-> AgentSandboxProfileDescriptor NetworkPolicy)
(def (agent-sandbox-profile-descriptor-network-policy descriptor)
  (.@ descriptor network-policy))

;; : (-> AgentSandboxProfileDescriptor Capabilities)
(def (agent-sandbox-profile-descriptor-capabilities descriptor)
  (.@ descriptor capabilities))

;; : (-> AgentSandboxProfileDescriptor ResourcePolicy)
(def (agent-sandbox-profile-descriptor-resource-policy descriptor)
  (.@ descriptor resource-policy))

;; : (-> AgentSandboxProfileDescriptor Metadata)
(def (agent-sandbox-profile-descriptor-metadata descriptor)
  (.@ descriptor metadata))

;; : (-> AgentSandboxProfileDescriptor Validator)
(def (agent-sandbox-profile-descriptor-validator descriptor)
  (.@ descriptor validator))

;;; Descriptor projection validates the final profile, so backend slot override
;;; remains extensible without bypassing the stable profile schema.
;; : (-> AgentSandboxProfileDescriptor AgentSandboxProfile)
(def (agent-sandbox-profile-descriptor->profile descriptor)
  ((agent-sandbox-profile-descriptor-validator descriptor)
   (make-agent-sandbox-backend-profile
    (agent-sandbox-profile-descriptor-backend-kind descriptor)
    (agent-sandbox-profile-descriptor-backend-ref descriptor)
    (agent-sandbox-profile-descriptor-network-policy descriptor)
    (agent-sandbox-profile-descriptor-capabilities descriptor)
    (agent-sandbox-profile-descriptor-resource-policy descriptor)
    (agent-sandbox-profile-descriptor-metadata descriptor))))

;;; Backend profiles package reusable runtime defaults without choosing the
;;; actual adapter implementation. They are bridge hints, not runtime handles.
;; : (-> Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy Metadata AgentSandboxProfile)
(def (make-agent-sandbox-backend-profile backend-kind
                                         backend-ref
                                         network-policy
                                         capabilities
                                         resource-policy
                                         metadata)
  (list (cons 'schema +agent-sandbox-profile-schema+)
        (cons 'backend-kind backend-kind)
        (cons 'backend-ref backend-ref)
        (cons 'network-policy network-policy)
        (cons 'capabilities capabilities)
        (cons 'resource-policy resource-policy)
        (cons 'metadata metadata)))

;;; Validation errors are data, not strings, so tests and Marlin bridge code can
;;; distinguish missing fields from schema mismatch without parsing messages.
;; : (-> Alist [(Symbol Value -> Boolean)] [ValidationError])
(def (agent-sandbox-required-field-errors alist specs)
  (if (null? specs)
    '()
    (let* ((spec (car specs))
           (key (car spec))
           (valid? (cdr spec))
           (entry (and alist (assoc key alist))))
      (append
       (if (and entry (valid? (cdr entry)))
         '()
         (list (list (cons 'field key)
                     (cons 'code 'missing-or-invalid))))
       (agent-sandbox-required-field-errors alist (cdr specs))))))

;;; Profile validation checks the contract-owned fields only. Backend-specific
;;; policy contents remain descriptor/runtime concerns.
;; | AgentSandboxRequiredFieldValue = (U Symbol String Pair #f)
;; : (-> AgentSandboxRequiredFieldValue Boolean)
(def (agent-sandbox-profile-required-value? value)
  (and value #t))

;; : (-> AgentSandboxProfile [ValidationError])
(def (agent-sandbox-profile-validation-errors profile)
  (append
   (if (eq? (agent-sandbox-profile-ref profile 'schema #f)
            +agent-sandbox-profile-schema+)
     '()
     (list '((field . schema) (code . schema-mismatch))))
   (agent-sandbox-required-field-errors
    profile
    (list (cons 'backend-kind agent-sandbox-profile-required-value?)
          (cons 'backend-ref agent-sandbox-profile-required-value?)))))

;;; Validation raises typed control-plane failures at the Scheme boundary before
;;; malformed profile data reaches adapter or Marlin bridge code.
;; : (-> AgentSandboxProfile AgentSandboxProfile)
(def (agent-sandbox-validate-profile profile)
  (let (errors (agent-sandbox-profile-validation-errors profile))
    (if (null? errors)
      profile
      (raise-control-plane-failure
       'agent-sandbox
       'invalid-agent-sandbox-profile
       "invalid agent sandbox profile"
       (list (cons 'errors errors)
             (cons 'profile profile))))))

;;; Profile accessors keep future bridges away from raw list positions.
;; : (-> AgentSandboxProfile Symbol Value Value)
(def (agent-sandbox-profile-ref profile key default)
  (agent-sandbox-alist-ref profile key default))

;; : (-> AgentSandboxProfile (U Symbol #f))
(def (agent-sandbox-profile-backend-kind profile)
  (agent-sandbox-profile-ref profile 'backend-kind #f))

;; : (-> AgentSandboxProfile (U BackendRef #f))
(def (agent-sandbox-profile-backend-ref profile)
  (agent-sandbox-profile-ref profile 'backend-ref #f))

;; : (-> AgentSandboxProfile NetworkPolicy)
(def (agent-sandbox-profile-network-policy profile)
  (agent-sandbox-profile-ref profile 'network-policy '()))

;; : (-> AgentSandboxProfile Capabilities)
(def (agent-sandbox-profile-capabilities profile)
  (agent-sandbox-profile-ref profile 'capabilities '()))

;; : (-> AgentSandboxProfile ResourcePolicy)
(def (agent-sandbox-profile-resource-policy profile)
  (agent-sandbox-profile-ref profile 'resource-policy '()))

;; : (-> AgentSandboxProfile Metadata)
(def (agent-sandbox-profile-metadata profile)
  (agent-sandbox-profile-ref profile 'metadata '()))
