;;; -*- Gerbil -*-
;;; Boundary: structured agent-sandbox profile validation.
;;; Invariant: invalid filesystem/resource markers are reported before runtime handoff.

(import :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/alist
        :poo-flow/src/modules/agent-sandbox/profile-data)

(export agent-sandbox-required-field-errors
        agent-sandbox-profile-validation-errors
        agent-sandbox-profile-resource-policy-filesystem-entry?
        agent-sandbox-profile-resource-policy-filesystem-entry
        agent-sandbox-profile-resource-policy-structured-filesystem-entry?
        agent-sandbox-profile-resource-policy-has-structured-filesystem?
        agent-sandbox-profile-resource-policy-filesystem-diagnostics
        agent-sandbox-validate-profile)

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

;;; Boundary: agent sandbox profile validation errors is the policy-visible
;;; edge for sandbox behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile capabilities have filesystem predicate is
;;; the policy-visible edge for sandbox behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> Capabilities Boolean)
(def (agent-sandbox-profile-capabilities-have-filesystem? capabilities)
  (cond
   ((null? capabilities) #f)
   ((not (pair? capabilities)) #f)
   ((agent-sandbox-profile-filesystem-capability? (car capabilities)) #t)
   (else
    (agent-sandbox-profile-capabilities-have-filesystem? (cdr capabilities)))))

;; | AgentSandboxResourcePolicyEntry = (U Symbol Pair)
;;; Boundary: agent sandbox profile resource policy filesystem entry is the
;;; policy-visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> AgentSandboxResourcePolicyEntry Boolean)
(def (agent-sandbox-profile-resource-policy-filesystem-entry? resource)
  (cond
   ((symbol? resource)
    (eq? resource 'filesystem))
   ((pair? resource)
    (eq? (car resource) 'filesystem))
   (else #f)))

;;; Boundary: agent sandbox profile resource policy has filesystem predicate is
;;; the policy-visible edge for sandbox behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile resource policy spec has key predicate is
;;; the policy-visible edge for sandbox behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile path join is the policy-visible edge for
;;; sandbox behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile target path diagnostics is the policy-
;;; visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile filesystem path entry diagnostics is the
;;; policy-visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile paths have project workspace predicate is
;;; the policy-visible edge for sandbox behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile filesystem mount entry diagnostics is the
;;; policy-visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile resource policy filesystem entry is the
;;; policy-visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile resource path diagnostics is the policy-
;;; visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> MaybeAgentSandboxPaths [ValidationError])
(def (agent-sandbox-profile-resource-path-diagnostics paths)
  (if paths
    (agent-sandbox-profile-filesystem-paths-diagnostics paths)
    '()))

;;; Boundary: agent sandbox profile resource mount diagnostics is the policy-
;;; visible edge for sandbox behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> MaybeAgentSandboxMounts MaybeAgentSandboxMounts [ValidationError])
(def (agent-sandbox-profile-resource-mount-diagnostics mounts top-level-mounts)
  (cond
   ((list? mounts)
    (agent-sandbox-profile-filesystem-mounts-diagnostics mounts))
   ((eq? mounts 'declared)
    (agent-sandbox-profile-filesystem-mounts-diagnostics top-level-mounts))
   (else '())))

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
          (agent-sandbox-profile-resource-path-diagnostics paths))
         (mount-errors
          (agent-sandbox-profile-resource-mount-diagnostics
           mounts
           top-level-mounts))
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

;;; Boundary: agent sandbox profile resource policy filesystem diagnostics is
;;; the policy-visible edge for sandbox behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
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

;;; Boundary: agent sandbox profile resource policy has structured filesystem
;;; predicate is the policy-visible edge for sandbox behavior, keeping
;;; validation, lookup, or projection responsibilities centralized for callers.
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
