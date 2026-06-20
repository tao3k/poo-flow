;;; -*- Gerbil -*-
;;; Owner: agent-sandbox profile descriptors and validation live here.
;;; Boundary: core task/flow modules consume validated profiles, not backend defaults.
;;; Import contract: backend modules opt in to POO descriptors through this module.
;;; Runtime contract: profile data is inert until a runtime bridge interprets it.
;;; Policy evidence: backend defaults should depend on this owner, not the facade.

(import (only-in :clan/poo/object .@ .mix object?)
        :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/alist)

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
        agent-sandbox-profile-resource-policy-filesystem-entry?
        agent-sandbox-profile-resource-policy-structured-filesystem-entry?
        agent-sandbox-profile-resource-policy-has-structured-filesystem?
        agent-sandbox-profile-resource-policy-filesystem-diagnostics
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
          (cons 'backend-ref agent-sandbox-profile-required-value?)))
   (agent-sandbox-profile-filesystem-sandbox-errors profile)))

;;; Resource policies only make sense when the profile also declares a
;;; filesystem sandbox capability and a concrete filesystem resource boundary.
;;; A bare symbol or `(filesystem . scoped)` is an unsafe marker: it says a
;;; filesystem sandbox exists without naming the scope and materialization hook.
;; | AgentSandboxCapability = (U Symbol Pair)
;; : (-> AgentSandboxCapability Boolean)
(def (agent-sandbox-profile-filesystem-capability? capability)
  (cond
   ((symbol? capability)
    (or (eq? capability 'filesystem)
        (eq? capability 'filesystem-read)
        (eq? capability 'filesystem-write)))
   ((pair? capability)
    (agent-sandbox-profile-filesystem-capability? (car capability)))
   (else #f)))

;; : (-> Capabilities Boolean)
(def (agent-sandbox-profile-capabilities-have-filesystem? capabilities)
  (cond
   ((null? capabilities) #f)
   ((not (pair? capabilities)) #f)
   ((agent-sandbox-profile-filesystem-capability? (car capabilities)) #t)
   (else
    (agent-sandbox-profile-capabilities-have-filesystem? (cdr capabilities)))))

;; | AgentSandboxResourcePolicyEntry = (U Symbol Pair)
;; : (-> AgentSandboxResourcePolicyEntry Boolean)
(def (agent-sandbox-profile-resource-policy-filesystem-entry? resource)
  (cond
   ((symbol? resource)
    (eq? resource 'filesystem))
   ((pair? resource)
    (eq? (car resource) 'filesystem))
   (else #f)))

;; : (-> ResourcePolicy Boolean)
(def (agent-sandbox-profile-resource-policy-has-filesystem? resource-policy)
  (cond
   ((null? resource-policy) #f)
   ((not (pair? resource-policy)) #f)
   ((agent-sandbox-profile-resource-policy-filesystem-entry?
     (car resource-policy)) #t)
   (else
    (agent-sandbox-profile-resource-policy-has-filesystem?
     (cdr resource-policy)))))

;; : (-> AgentSandboxFilesystemResourceSpec Symbol Boolean)
(def (agent-sandbox-profile-resource-policy-spec-has-key? spec key)
  (cond
   ((null? spec) #f)
   ((not (pair? spec)) #f)
   ((and (pair? (car spec))
         (eq? (caar spec) key))
    #t)
   (else
    (agent-sandbox-profile-resource-policy-spec-has-key? (cdr spec) key))))

;; : (-> AgentSandboxFilesystemResourceSpec Boolean)
(def (agent-sandbox-profile-resource-policy-spec-has-anchor? spec)
  (or (agent-sandbox-profile-resource-policy-spec-has-key? spec 'mounts)
      (agent-sandbox-profile-resource-policy-spec-has-key? spec 'workspace)
      (agent-sandbox-profile-resource-policy-spec-has-key? spec 'paths)
      (agent-sandbox-profile-resource-policy-spec-has-key? spec 'root)
      (agent-sandbox-profile-resource-policy-spec-has-key? spec 'volume)
      (agent-sandbox-profile-resource-policy-spec-has-key? spec 'snapshot)))

;; : (-> String String Boolean)
(def (agent-sandbox-profile-string-prefix? prefix value)
  (let ((prefix-length (string-length prefix))
        (value-length (string-length value)))
    (and (<= prefix-length value-length)
         (string=? (substring value 0 prefix-length) prefix))))

;; : (-> String String Boolean)
(def (agent-sandbox-profile-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (<= suffix-length value-length)
         (string=?
          (substring value (- value-length suffix-length) value-length)
          suffix))))

;; : (-> String String Integer Boolean)
(def (agent-sandbox-profile-string-at? needle value index)
  (let (needle-length (string-length needle))
    (and (<= (+ index needle-length) (string-length value))
         (string=? (substring value index (+ index needle-length))
                   needle))))

;; agent-sandbox-profile-string-contains?
;;   : (-> String String Boolean)
;;   | contract: checks whether value contains needle without regex semantics.
;;   | doc m%
;;     # Examples
;;     ```scheme
;;     (agent-sandbox-profile-string-contains? "sandbox" "agent-sandbox-profile")
;;     ;; result: #t
;;     (agent-sandbox-profile-string-contains? "nono" "agent-sandbox-profile")
;;     ;; result: #f
;;     ```
;; : (-> String String Boolean)
(def (agent-sandbox-profile-string-contains? needle value)
  (if (string-contains value needle) #t #f))

;; : (-> String Boolean)
(def (agent-sandbox-profile-absolute-path? value)
  (and (> (string-length value) 0)
       (char=? (string-ref value 0) #\/)))

;; : (-> String Boolean)
(def (agent-sandbox-profile-parent-path? value)
  (or (string=? value "..")
      (agent-sandbox-profile-string-prefix? "../" value)
      (agent-sandbox-profile-string-suffix? "/.." value)
      (agent-sandbox-profile-string-contains? "/../" value)))

;; : (-> String Boolean)
(def (agent-sandbox-profile-relative-path-shape? value)
  (and (string? value)
       (> (string-length value) 0)
       (not (agent-sandbox-profile-absolute-path? value))
       (not (agent-sandbox-profile-parent-path? value))))

;; : (-> String Boolean)
(def (agent-sandbox-profile-static-source-path? value)
  (and (agent-sandbox-profile-relative-path-shape? value)
       (file-exists? value)))

;; : (-> String Boolean)
(def (agent-sandbox-profile-sandbox-target-path? value)
  (and (string? value)
       (> (string-length value) 0)
       (agent-sandbox-profile-absolute-path? value)
       (not (agent-sandbox-profile-parent-path? value))))

;; : (-> String Boolean)
(def (agent-sandbox-profile-env-source? value)
  (and (string? value)
       (agent-sandbox-profile-string-prefix? "$" value)
       (> (string-length value) 1)))

;; : (-> String String String)
(def (agent-sandbox-profile-path-join base path)
  (if (string=? base ".")
    path
    (string-append base "/" path)))

;; : (-> Symbol Alist Value)
(def (agent-sandbox-profile-path-entry-ref key entry default)
  (agent-sandbox-alist-ref entry key default))

;; : (-> Symbol Alist ValidationError)
(def (agent-sandbox-profile-filesystem-diagnostic code payload)
  (append (list (cons 'field 'resource-policy)
                (cons 'code code))
          payload))

;;; Static source diagnostics distinguish runtime/env/static paths before path
;;; existence checks, preserving the original resource entry in every error.
;; : (-> Alist [ValidationError])
(def (agent-sandbox-profile-static-source-diagnostics entry)
  (let* ((source (agent-sandbox-profile-path-entry-ref 'source entry #f))
         (source-kind
          (agent-sandbox-profile-path-entry-ref 'source-kind entry 'static))
         (role (agent-sandbox-profile-path-entry-ref 'role entry #f))
         (marker (agent-sandbox-profile-path-entry-ref 'project-marker
                                                       entry
                                                       #f)))
    (cond
     ((eq? source-kind 'runtime) '())
     ((eq? source-kind 'env)
      (append
       (if (agent-sandbox-profile-env-source? source)
         '()
         (list (agent-sandbox-profile-filesystem-diagnostic
                'invalid-env-source
                (list (cons 'source source)
                      (cons 'entry entry)))))
       (if (eq? role 'project-workspace)
         (list (agent-sandbox-profile-filesystem-diagnostic
                'dynamic-project-workspace-source
                (list (cons 'source source)
                      (cons 'entry entry))))
         '())))
     ((not (agent-sandbox-profile-static-source-path? source))
      (list (agent-sandbox-profile-filesystem-diagnostic
             'invalid-static-source-path
             (list (cons 'source source)
                   (cons 'entry entry)))))
     ((and (eq? role 'project-workspace)
           (not (and (agent-sandbox-profile-relative-path-shape? marker)
                     (file-exists?
                      (agent-sandbox-profile-path-join source marker)))))
      (list (agent-sandbox-profile-filesystem-diagnostic
             'missing-project-workspace-marker
             (list (cons 'source source)
                   (cons 'project-marker marker)
                   (cons 'entry entry)))))
     (else '()))))

;; : (-> Alist [ValidationError])
(def (agent-sandbox-profile-target-path-diagnostics entry)
  (let (target (agent-sandbox-profile-path-entry-ref 'target entry #f))
    (if (or (not target)
            (agent-sandbox-profile-sandbox-target-path? target))
      '()
      (list (agent-sandbox-profile-filesystem-diagnostic
             'invalid-sandbox-target-path
             (list (cons 'target target)
                   (cons 'entry entry)))))))

;; : (-> Alist [ValidationError])
(def (agent-sandbox-profile-filesystem-path-entry-diagnostics entry)
  (if (list? entry)
    (append (agent-sandbox-profile-static-source-diagnostics entry)
            (agent-sandbox-profile-target-path-diagnostics entry))
    (list (agent-sandbox-profile-filesystem-diagnostic
           'invalid-filesystem-path-entry
           (list (cons 'entry entry))))))

;; : (-> Alist Boolean)
(def (agent-sandbox-profile-project-workspace-path-entry? entry)
  (and (list? entry)
       (eq? (agent-sandbox-profile-path-entry-ref 'role entry #f)
            'project-workspace)))

;; : (-> [Alist] Boolean)
(def (agent-sandbox-profile-paths-have-project-workspace? entries)
  (cond
   ((null? entries) #f)
   ((not (pair? entries)) #f)
   ((agent-sandbox-profile-project-workspace-path-entry? (car entries)) #t)
   (else
    (agent-sandbox-profile-paths-have-project-workspace? (cdr entries)))))

;;; Path diagnostics fan out over every declared path entry so sandbox profiles
;;; can report all bad mounts instead of failing on the first row.
;; : (-> [Alist] [ValidationError])
(def (agent-sandbox-profile-filesystem-paths-diagnostics entries)
  (cond
   ((not (pair? entries))
    (list (agent-sandbox-profile-filesystem-diagnostic
           'missing-filesystem-paths
           (list (cons 'paths entries)))))
   (else
    (apply append
           (map agent-sandbox-profile-filesystem-path-entry-diagnostics
                entries)))))

;; : (-> Alist [ValidationError])
(def (agent-sandbox-profile-filesystem-mount-entry-diagnostics entry)
  (if (list? entry)
    (append (agent-sandbox-profile-static-source-diagnostics entry)
            (agent-sandbox-profile-target-path-diagnostics entry))
    (list (agent-sandbox-profile-filesystem-diagnostic
           'invalid-filesystem-mount-entry
           (list (cons 'entry entry))))))

;;; Mount diagnostics mirror path diagnostics because project-copy and runtime
;;; mounts share validation shape but keep separate error codes.
;; : (-> [Alist] [ValidationError])
(def (agent-sandbox-profile-filesystem-mounts-diagnostics entries)
  (cond
   ((not (pair? entries))
    (list (agent-sandbox-profile-filesystem-diagnostic
           'missing-filesystem-mounts
           (list (cons 'mounts entries)))))
   (else
    (apply append
           (map agent-sandbox-profile-filesystem-mount-entry-diagnostics
                entries)))))

;; : (-> ResourcePolicy Symbol Value)
(def (agent-sandbox-profile-resource-policy-entry-value resource-policy
                                                        key
                                                        default)
  (agent-sandbox-alist-ref resource-policy key default))

;; : (-> ResourcePolicy MaybeAgentSandboxResourcePolicyEntry)
(def (agent-sandbox-profile-resource-policy-filesystem-entry resource-policy)
  (cond
   ((null? resource-policy) #f)
   ((not (pair? resource-policy)) #f)
   ((agent-sandbox-profile-resource-policy-filesystem-entry?
     (car resource-policy))
    (car resource-policy))
   (else
    (agent-sandbox-profile-resource-policy-filesystem-entry
     (cdr resource-policy)))))

;;; Materialization diagnostics are the structured sandbox gate: a filesystem
;;; scope is only valid when at least one concrete anchor can produce it.
;; : (-> AgentSandboxFilesystemResourceSpec ResourcePolicy [ValidationError])
(def (agent-sandbox-profile-resource-policy-materialization-diagnostics
      spec
      resource-policy)
  (let* ((scope (agent-sandbox-alist-ref spec 'scope #f))
         (paths (agent-sandbox-alist-ref spec 'paths #f))
         (mounts (agent-sandbox-alist-ref spec 'mounts #f))
         (top-level-mounts
          (agent-sandbox-profile-resource-policy-entry-value
           resource-policy
           'mounts
           #f))
         (materialized-by
          (agent-sandbox-alist-ref spec 'materialized-by #f))
         (path-errors
          (if paths
            (agent-sandbox-profile-filesystem-paths-diagnostics paths)
            '()))
         (mount-errors
         (cond
           ((list? mounts)
            (agent-sandbox-profile-filesystem-mounts-diagnostics mounts))
           ((eq? mounts 'declared)
            (agent-sandbox-profile-filesystem-mounts-diagnostics
             top-level-mounts))
           (else '())))
         (has-path-anchor? (and paths #t))
         (has-mount-anchor?
          (or (list? mounts) (eq? mounts 'declared)))
         (has-dynamic-runtime-anchor?
          (and (eq? mounts 'runtime)
               (eq? materialized-by 'runtime)))
         (has-provider-anchor?
          (or (agent-sandbox-alist-ref spec 'snapshot #f)
              (agent-sandbox-alist-ref spec 'volume #f))))
    (append
     (if scope
       '()
       (list (agent-sandbox-profile-filesystem-diagnostic
              'missing-filesystem-scope
              (list (cons 'filesystem spec)))))
     (if (and (eq? scope 'project-workspace)
              (not (agent-sandbox-profile-paths-have-project-workspace?
                    paths)))
       (list (agent-sandbox-profile-filesystem-diagnostic
              'missing-project-workspace-path
              (list (cons 'paths paths))))
       '())
     path-errors
     mount-errors
     (if (or has-path-anchor?
             has-mount-anchor?
             has-dynamic-runtime-anchor?
             has-provider-anchor?)
       '()
       (list (agent-sandbox-profile-filesystem-diagnostic
              'missing-filesystem-materialization
              (list (cons 'filesystem spec))))))))

;; : (-> ResourcePolicy [ValidationError])
(def (agent-sandbox-profile-resource-policy-filesystem-diagnostics
      resource-policy)
  (let (filesystem-entry
        (agent-sandbox-profile-resource-policy-filesystem-entry
         resource-policy))
    (cond
     ((not filesystem-entry) '())
     ((not (agent-sandbox-profile-resource-policy-structured-filesystem-entry?
            filesystem-entry))
      (list (agent-sandbox-profile-filesystem-diagnostic
             'unsafe-filesystem-sandbox-resource
             (list (cons 'requires
                         '(filesystem scope materialization-anchor))
                   (cons 'resource-policy resource-policy)))))
     (else
      (agent-sandbox-profile-resource-policy-materialization-diagnostics
       (cdr filesystem-entry)
       resource-policy)))))

;; : (-> AgentSandboxResourcePolicyEntry Boolean)
(def (agent-sandbox-profile-resource-policy-structured-filesystem-entry?
      resource)
  (and (pair? resource)
       (eq? (car resource) 'filesystem)
       (list? (cdr resource))
       (agent-sandbox-profile-resource-policy-spec-has-key? (cdr resource)
                                                            'scope)
       (agent-sandbox-profile-resource-policy-spec-has-anchor?
        (cdr resource))))

;; : (-> ResourcePolicy Boolean)
(def (agent-sandbox-profile-resource-policy-has-structured-filesystem?
      resource-policy)
  (cond
   ((null? resource-policy) #f)
   ((not (pair? resource-policy)) #f)
   ((agent-sandbox-profile-resource-policy-structured-filesystem-entry?
     (car resource-policy))
    #t)
   (else
    (agent-sandbox-profile-resource-policy-has-structured-filesystem?
     (cdr resource-policy)))))

;;; Filesystem sandbox errors cross-check capability and resource policy so a
;;; profile cannot claim isolation without a materialized filesystem boundary.
;; : (-> AgentSandboxProfile [ValidationError])
(def (agent-sandbox-profile-filesystem-sandbox-errors profile)
  (let* ((resource-policy (agent-sandbox-profile-resource-policy profile))
         (capabilities (agent-sandbox-profile-capabilities profile))
         (has-filesystem-capability?
          (agent-sandbox-profile-capabilities-have-filesystem? capabilities))
         (has-filesystem-resource?
          (agent-sandbox-profile-resource-policy-has-filesystem?
           resource-policy)))
    (append
     (if (and (not (null? resource-policy))
              (not has-filesystem-capability?))
       (list (list (cons 'field 'capabilities)
                   (cons 'code 'missing-filesystem-sandbox-capability)
                   (cons 'requires 'resource-policy)
                   (cons 'resource-policy resource-policy)))
       '())
     (if (and has-filesystem-capability?
              (not has-filesystem-resource?))
       (list (list (cons 'field 'resource-policy)
                   (cons 'code 'missing-filesystem-sandbox-resource)
                   (cons 'requires 'filesystem)
                   (cons 'resource-policy resource-policy)))
       '())
     (if has-filesystem-resource?
       (agent-sandbox-profile-resource-policy-filesystem-diagnostics
        resource-policy)
       '()))))

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
