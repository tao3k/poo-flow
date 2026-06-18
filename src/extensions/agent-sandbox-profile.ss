;;; -*- Gerbil -*-
;;; Owner: agent-sandbox profile descriptors and validation live here.
;;; Boundary: core task/flow modules consume validated profiles, not backend defaults.
;;; Import contract: backend modules opt in to POO descriptors through this module.
;;; Runtime contract: profile data is inert until a runtime bridge interprets it.
;;; Policy evidence: backend defaults should depend on this owner, not the facade.

(import (only-in :clan/poo/object .@ .mix object?)
        :core/api
        :extensions/agent-sandbox-util)

(export +agent-sandbox-profile-schema+
        agent-sandbox-profile-descriptor-prototype
        defagent-sandbox-backend-profile
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

;; Symbol <- Unit
(def +agent-sandbox-profile-schema+ 'poo-flow.agent-sandbox-profile.v1)

;;; Backend profile declaration is the macro layer for Scheme extensions:
;;; backend modules provide defaults, while this owner wires POO projection,
;;; option override, and validation through one generated constructor pair.
;;; Macro boundary:
;;; - The macro expands only descriptor/profile helpers, never runtime code.
;;; - Generated constructors must pass through =make-agent-sandbox-profile-descriptor=.
;;; Higher-order boundary:
;;; - MetadataProcedure is a BackendRef -> Metadata callback.
;;; - Backend modules own metadata shape without capturing core variables.
;;; Macro governance witness:
;;; - gerbil.pkg witness: =search runtime-source macro sugar module-sugar=.
;;; - Runtime source: Gerbil v0.18.2-4-gadd92248 =std/sugar.ss#defsyntax-call=.
;;; - Executable logic lives in generated constructors, so this macro is naming sugar only.
;; Syntax <- DescriptorConstructor ProfileConstructor Symbol Symbol NetworkPolicy Capabilities ResourcePolicy MetadataProcedure
(defrules defagent-sandbox-backend-profile ()
  ((_ descriptor-constructor
      profile-constructor
      descriptor-name
      backend-kind
      default-network-policy
      default-capabilities
      default-resource-policy
      metadata-procedure)
   (begin
     (def (descriptor-constructor backend-ref . maybe-options)
       (make-agent-sandbox-backend-profile-descriptor
        descriptor-name
        backend-kind
        backend-ref
        default-network-policy
        default-capabilities
        default-resource-policy
        metadata-procedure
        (if (null? maybe-options) '() (car maybe-options))))
     (def (profile-constructor backend-ref . maybe-options)
       (agent-sandbox-profile-descriptor->profile
        (descriptor-constructor
         backend-ref
         (if (null? maybe-options) '() (car maybe-options))))))))

;;; Profile descriptors are POO policy objects: backend modules override slots,
;;; while core keeps one validation and projection path into request profiles.
;;; Higher-order boundary:
;;; - The validator slot is a Profile -> Profile procedure.
;;; - Backend overrides may replace policy data, but validation remains explicit.
;; AgentSandboxProfileDescriptorPrototype <- Unit
(def agent-sandbox-profile-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'name 'agent-sandbox-profile)
                      (cons 'backend-kind #f)
                      (cons 'backend-ref #f)
                      (cons 'network-policy '())
                      (cons 'capabilities '())
                      (cons 'resource-policy '())
                      (cons 'metadata '())
                      (cons 'validator
                            (lambda (profile)
                              (agent-sandbox-validate-profile profile)))))
        execution-policy-role))

;;; Descriptor construction is the override point for backend modules. The
;;; resulting object still projects through the same core profile contract.
;; AgentSandboxProfileDescriptor <- Symbol Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy Metadata [Alist]
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
;; AgentSandboxProfileDescriptor <- Symbol Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy MetadataProcedure Alist
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

;; Boolean <- AgentSandboxProfileDescriptorCandidate
(def (agent-sandbox-profile-descriptor? descriptor)
  (object? descriptor))

;; Symbol <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-name descriptor)
  (.@ descriptor name))

;; Symbol | #f <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-backend-kind descriptor)
  (.@ descriptor backend-kind))

;; BackendRef | #f <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-backend-ref descriptor)
  (.@ descriptor backend-ref))

;; NetworkPolicy <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-network-policy descriptor)
  (.@ descriptor network-policy))

;; Capabilities <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-capabilities descriptor)
  (.@ descriptor capabilities))

;; ResourcePolicy <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-resource-policy descriptor)
  (.@ descriptor resource-policy))

;; Metadata <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-metadata descriptor)
  (.@ descriptor metadata))

;; Validator <- AgentSandboxProfileDescriptor
(def (agent-sandbox-profile-descriptor-validator descriptor)
  (.@ descriptor validator))

;;; Descriptor projection validates the final profile, so backend slot override
;;; remains extensible without bypassing the stable profile schema.
;; AgentSandboxProfile <- AgentSandboxProfileDescriptor
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
;; AgentSandboxProfile <- Symbol BackendRef NetworkPolicy Capabilities ResourcePolicy Metadata
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
;; [ValidationError] <- Alist [(Symbol Value -> Boolean)]
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
;; [ValidationError] <- AgentSandboxProfile
(def (agent-sandbox-profile-validation-errors profile)
  (append
   (if (eq? (agent-sandbox-profile-ref profile 'schema #f)
            +agent-sandbox-profile-schema+)
     '()
     (list '((field . schema) (code . schema-mismatch))))
   (agent-sandbox-required-field-errors
    profile
    (list (cons 'backend-kind (lambda (value) (and value #t)))
          (cons 'backend-ref (lambda (value) (and value #t)))))))

;;; Validation raises typed control-plane failures at the Scheme boundary before
;;; malformed profile data reaches adapter or Marlin bridge code.
;; AgentSandboxProfile <- AgentSandboxProfile
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
;; Value <- AgentSandboxProfile Symbol Value
(def (agent-sandbox-profile-ref profile key default)
  (agent-sandbox-alist-ref profile key default))

;; Symbol | #f <- AgentSandboxProfile
(def (agent-sandbox-profile-backend-kind profile)
  (agent-sandbox-profile-ref profile 'backend-kind #f))

;; BackendRef | #f <- AgentSandboxProfile
(def (agent-sandbox-profile-backend-ref profile)
  (agent-sandbox-profile-ref profile 'backend-ref #f))

;; NetworkPolicy <- AgentSandboxProfile
(def (agent-sandbox-profile-network-policy profile)
  (agent-sandbox-profile-ref profile 'network-policy '()))

;; Capabilities <- AgentSandboxProfile
(def (agent-sandbox-profile-capabilities profile)
  (agent-sandbox-profile-ref profile 'capabilities '()))

;; ResourcePolicy <- AgentSandboxProfile
(def (agent-sandbox-profile-resource-policy profile)
  (agent-sandbox-profile-ref profile 'resource-policy '()))

;; Metadata <- AgentSandboxProfile
(def (agent-sandbox-profile-metadata profile)
  (agent-sandbox-profile-ref profile 'metadata '()))
