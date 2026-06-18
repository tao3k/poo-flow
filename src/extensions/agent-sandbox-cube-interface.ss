;;; -*- Gerbil -*-
;;; Owner: CubeSandbox interface projection lives in this backend leaf.
;;; Boundary: this module emits API lifecycle manifests only.
;;; Runtime contract: Marlin owns Cube API calls, remote sessions, and snapshots.
;;; Policy evidence: Cube interface tests assert descriptor override and gates.

(import (only-in :clan/poo/object .ref .mix object?)
        :core/api
        :extensions/agent-sandbox-util
        :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-bridge)

(export +cube-interface-schema+
        +cube-interface-api-compatibilities+
        +cube-interface-network-modes+
        +cube-interface-mount-modes+
        +cube-interface-lifecycle-operations+
        cube-interface-descriptor-prototype
        make-cube-interface-descriptor
        cube-interface-descriptor?
        cube-interface-descriptor-name
        cube-interface-descriptor-backend-kind
        cube-interface-descriptor-api-compatibility
        cube-interface-descriptor-runtime-owner
        cube-interface-descriptor-lifecycle-operations
        cube-interface-descriptor-network-modes
        cube-interface-descriptor-mount-modes
        cube-interface-descriptor->contract
        cube-interface-descriptor-validation-errors
        cube-interface-validate-descriptor
        cube-interface-runtime-manifest-validation-errors
        cube-interface-validate-runtime-manifest
        cube-interface-runtime-manifest->manifest
        agent-sandbox-request->cube-interface-manifest
        agent-sandbox-execution-request->cube-interface-manifest)

;;; Cube interface schema is separate from the neutral runtime manifest because
;;; Marlin needs backend lifecycle semantics, not only process/filesystem fields.
;; Symbol <- Unit
(def +cube-interface-schema+ 'poo-flow.agent-sandbox-cube-interface.v1)

;;; API compatibility names the runtime surface Marlin should bind to. Today it
;;; is E2B-compatible; future Cube-native APIs can override this descriptor slot.
;; [Symbol] <- Unit
(def +cube-interface-api-compatibilities+
  '(e2b-compatible cube-native))

;;; Cube network policy is API-level policy. These symbols remain declarative;
;;; Marlin maps them to the provider-specific network controls.
;; [Symbol] <- Unit
(def +cube-interface-network-modes+
  '(egress-filtered blocked allow-all proxy-only))

;;; Mount modes are the filesystem grants this Scheme layer can validate before
;;; Marlin turns them into remote workspace upload or mount calls.
;; [Symbol] <- Unit
(def +cube-interface-mount-modes+
  '(read write read-write))

;;; Lifecycle operations are stable operation names, not function symbols.
;;; The ordered plan lets Marlin replay request setup without reading Gerbil
;;; request internals or guessing where snapshot/resume belongs.
;; [Alist] <- Unit
(def +cube-interface-lifecycle-operations+
  '(((stage . resolve-template)
     (operation . cube.template.resolve))
    ((stage . create-sandbox)
     (operation . cube.sandbox.create))
    ((stage . start-sandbox)
     (operation . cube.sandbox.start))
    ((stage . mount-filesystem)
     (operation . cube.filesystem.mount))
    ((stage . exec-process)
     (operation . cube.process.exec))
    ((stage . fetch-output)
     (operation . cube.output.fetch))
    ((stage . snapshot)
     (operation . cube.snapshot.create))
    ((stage . resume)
     (operation . cube.sandbox.resume))
    ((stage . destroy)
     (operation . cube.sandbox.destroy))))

;;; Cube interface descriptors are POO policy objects so API compatibility and
;;; lifecycle operation names can be overridden without changing request shape.
;; CubeInterfaceDescriptorPrototype <- Unit
(def cube-interface-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'schema +cube-interface-schema+)
                      (cons 'name 'cube-interface)
                      (cons 'backend-kind 'cube)
                      (cons 'api-compatibility 'e2b-compatible)
                      (cons 'runtime-owner 'marlin)
                      (cons 'lifecycle-operations
                            +cube-interface-lifecycle-operations+)
                      (cons 'network-modes +cube-interface-network-modes+)
                      (cons 'mount-modes +cube-interface-mount-modes+)
                      (cons 'validator
                            (lambda (descriptor)
                              (cube-interface-validate-descriptor
                               descriptor)))))
        execution-policy-role))

;;; Descriptor construction is the extension override point for local Cube API
;;; variants; default construction remains enough for the Tencent Cube profile.
;; CubeInterfaceDescriptor <- [Alist]
(def (make-cube-interface-descriptor . maybe-overrides)
  (.mix slots: (role-constant-slots
                (if (null? maybe-overrides) '() (car maybe-overrides)))
        cube-interface-descriptor-prototype))

;; Boolean <- CubeInterfaceDescriptorCandidate
(def (cube-interface-descriptor? descriptor)
  (object? descriptor))

;;; Descriptor slots are read dynamically because backend interface descriptors
;;; are POO objects with override precedence, not fixed records.
;; Value <- CubeInterfaceDescriptor Symbol Value
(def (cube-interface-descriptor-slot descriptor slot default)
  (if (cube-interface-descriptor? descriptor)
    (.ref descriptor slot)
    default))

;; Symbol <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-name descriptor)
  (cube-interface-descriptor-slot descriptor 'name #f))

;; Symbol <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-backend-kind descriptor)
  (cube-interface-descriptor-slot descriptor 'backend-kind #f))

;; Symbol <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-api-compatibility descriptor)
  (cube-interface-descriptor-slot descriptor 'api-compatibility #f))

;; Symbol <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-runtime-owner descriptor)
  (cube-interface-descriptor-slot descriptor 'runtime-owner #f))

;; [Alist] <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-lifecycle-operations descriptor)
  (cube-interface-descriptor-slot descriptor 'lifecycle-operations '()))

;; [Symbol] <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-network-modes descriptor)
  (cube-interface-descriptor-slot descriptor 'network-modes '()))

;; [Symbol] <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-mount-modes descriptor)
  (cube-interface-descriptor-slot descriptor 'mount-modes '()))

;;; Descriptor contracts are the serializable API surface that Marlin should
;;; read before interpreting Cube lifecycle plans.
;; Alist <- CubeInterfaceDescriptor
(def (cube-interface-descriptor->contract descriptor)
  (let (valid-descriptor (cube-interface-validate-descriptor descriptor))
    (list (cons 'schema +cube-interface-schema+)
          (cons 'name (cube-interface-descriptor-name valid-descriptor))
          (cons 'backend-kind
                (cube-interface-descriptor-backend-kind valid-descriptor))
          (cons 'api-compatibility
                (cube-interface-descriptor-api-compatibility valid-descriptor))
          (cons 'runtime-owner
                (cube-interface-descriptor-runtime-owner valid-descriptor))
          (cons 'lifecycle-operations
                (cube-interface-descriptor-lifecycle-operations
                 valid-descriptor))
          (cons 'network-modes
                (cube-interface-descriptor-network-modes valid-descriptor))
          (cons 'mount-modes
                (cube-interface-descriptor-mount-modes valid-descriptor)))))

;;; Descriptor validation prevents drift between Cube profile defaults and the
;;; backend interface contract consumed by Marlin.
;; [ValidationError] <- CubeInterfaceDescriptor
(def (cube-interface-descriptor-validation-errors descriptor)
  (if (cube-interface-descriptor? descriptor)
    (agent-sandbox-required-field-errors
     (list (cons 'schema
                 (cube-interface-descriptor-slot descriptor 'schema #f))
           (cons 'name (cube-interface-descriptor-name descriptor))
           (cons 'backend-kind
                 (cube-interface-descriptor-backend-kind descriptor))
           (cons 'api-compatibility
                 (cube-interface-descriptor-api-compatibility descriptor))
           (cons 'runtime-owner
                 (cube-interface-descriptor-runtime-owner descriptor))
           (cons 'lifecycle-operations
                 (cube-interface-descriptor-lifecycle-operations
                  descriptor)))
     (list (cons 'schema
                 (lambda (value) (eq? value +cube-interface-schema+)))
           (cons 'name (lambda (value) (and value #t)))
           (cons 'backend-kind (lambda (value) (eq? value 'cube)))
           (cons 'api-compatibility
                 (lambda (value)
                   (memq value +cube-interface-api-compatibilities+)))
           (cons 'runtime-owner (lambda (value) (eq? value 'marlin)))
           (cons 'lifecycle-operations
                 (lambda (value)
                   (and (list? value)
                        (pair? value))))))
    (list '((field . descriptor) (code . not-poo-object)))))

;;; Descriptor failures use typed control-plane errors so callers can recover by
;;; code and keep Cube API details out of Scheme exception strings.
;; CubeInterfaceDescriptor <- CubeInterfaceDescriptor
(def (cube-interface-validate-descriptor descriptor)
  (let (errors (cube-interface-descriptor-validation-errors descriptor))
    (if (null? errors)
      descriptor
      (raise-control-plane-failure
       'agent-sandbox-cube
       'invalid-cube-interface-descriptor
       "invalid CubeSandbox interface descriptor"
       (list (cons 'errors errors))))))

;; Boolean <- Value [Symbol]
(def (cube-interface-member? value allowed)
  (and (memq value allowed) #t))

;;; Mount validation records indices so Marlin-facing failures identify exactly
;;; which remote workspace grant cannot be projected.
;; [ValidationError] <- Mount Integer CubeInterfaceDescriptor
(def (cube-interface-mount-validation-errors mount index descriptor)
  (if (list? mount)
    (let* ((path (agent-sandbox-alist-ref mount 'path #f))
           (mode (agent-sandbox-alist-ref mount 'mode #f)))
      (append
       (if (string? path)
         '()
         (list (list (cons 'field 'mount-path)
                     (cons 'index index)
                     (cons 'code 'missing-or-invalid-path))))
       (if (cube-interface-member?
            mode
            (cube-interface-descriptor-mount-modes descriptor))
         '()
         (list (list (cons 'field 'mount-mode)
                     (cons 'index index)
                     (cons 'value mode)
                     (cons 'code 'unsupported-mount-mode)))))) 
    (list (list (cons 'field 'mount)
                (cons 'index index)
                (cons 'code 'not-alist)))))

;;; Recursive mount validation keeps the original grant order because the
;;; lifecycle plan will preserve one remote mount operation per request mount.
;; [ValidationError] <- [Mount] Integer CubeInterfaceDescriptor
(def (cube-interface-mounts-validation-errors mounts index descriptor)
  (if (null? mounts)
    '()
    (append (cube-interface-mount-validation-errors (car mounts)
                                                    index
                                                    descriptor)
            (cube-interface-mounts-validation-errors (cdr mounts)
                                                     (+ index 1)
                                                     descriptor))))

;;; Network validation is Cube-specific: the neutral bridge does not know which
;;; provider modes Marlin can map into remote sandbox networking.
;; [ValidationError] <- NetworkPolicy CubeInterfaceDescriptor
(def (cube-interface-network-validation-errors network-policy descriptor)
  (let (mode (agent-sandbox-alist-ref network-policy 'mode 'egress-filtered))
    (if (cube-interface-member?
         mode
         (cube-interface-descriptor-network-modes descriptor))
      '()
      (list (list (cons 'field 'network-mode)
                  (cons 'value mode)
                  (cons 'code 'unsupported-network-mode))))))

;;; Runtime manifest validation is the backend gate before Marlin receives a
;;; Cube lifecycle manifest. It rejects non-Cube backends and unsupported policy.
;; [ValidationError] <- RuntimeManifest CubeInterfaceDescriptor
(def (cube-interface-runtime-manifest-validation-errors runtime-manifest
                                                       descriptor)
  (if (list? runtime-manifest)
    (let* ((backend (agent-sandbox-alist-ref runtime-manifest 'backend '()))
           (process (agent-sandbox-alist-ref runtime-manifest 'process '()))
           (filesystem (agent-sandbox-alist-ref runtime-manifest 'filesystem '()))
           (mounts (agent-sandbox-alist-ref filesystem 'mounts '()))
           (network-policy
            (agent-sandbox-alist-ref runtime-manifest 'network-policy '())))
      (append
       (agent-sandbox-required-field-errors
        runtime-manifest
        (list (cons 'schema
                    (lambda (value)
                      (eq? value +agent-sandbox-runtime-manifest-schema+)))))
       (agent-sandbox-required-field-errors
        backend
        (list (cons 'kind (lambda (value) (eq? value 'cube)))
              (cons 'ref (lambda (value) (and value #t)))))
       (agent-sandbox-required-field-errors
        process
        (list (cons 'command (lambda (value) (and value #t)))
              (cons 'argv list?)))
       (if (list? mounts)
         (cube-interface-mounts-validation-errors mounts 0 descriptor)
         (list '((field . mounts) (code . not-list))))
       (cube-interface-network-validation-errors network-policy descriptor)))
    (list '((field . runtime-manifest) (code . not-alist)))))

;;; Validation preserves the original manifest in failure details so bridge
;;; tests and Marlin adapters can inspect the rejected policy.
;; AgentSandboxRuntimeManifest <- RuntimeManifest [CubeInterfaceDescriptor]
(def (cube-interface-validate-runtime-manifest runtime-manifest
                                              . maybe-descriptor)
  (let* ((descriptor
          (cube-interface-validate-descriptor
           (if (null? maybe-descriptor)
             (make-cube-interface-descriptor)
             (car maybe-descriptor))))
         (errors
          (cube-interface-runtime-manifest-validation-errors runtime-manifest
                                                            descriptor)))
    (if (null? errors)
      runtime-manifest
      (raise-control-plane-failure
       'agent-sandbox-cube
       'invalid-cube-interface-manifest
       "invalid CubeSandbox interface manifest"
       (list (cons 'errors errors)
             (cons 'runtime-manifest runtime-manifest))))))

;; Alist <- RuntimeManifest CubeInterfaceDescriptor
(def (cube-interface-template runtime-manifest descriptor)
  (let (backend (agent-sandbox-alist-ref runtime-manifest 'backend '()))
    (list (cons 'ref (agent-sandbox-alist-ref backend 'ref #f))
          (cons 'api-compatibility
                (cube-interface-descriptor-api-compatibility descriptor)))))

;; Alist <- RuntimeManifest
(def (cube-interface-snapshot-policy runtime-manifest)
  (let (resource-policy
        (agent-sandbox-alist-ref runtime-manifest 'resource-policy '()))
    (list (cons 'snapshot
                (agent-sandbox-alist-ref resource-policy 'snapshot #f))
          (cons 'resume
                (agent-sandbox-alist-ref resource-policy 'resume #f)))))

;; Alist <- LifecycleOperation RuntimeManifest CubeInterfaceDescriptor
(def (cube-interface-lifecycle-step operation runtime-manifest descriptor)
  (let ((stage (agent-sandbox-alist-ref operation 'stage #f))
        (resource-policy
         (agent-sandbox-alist-ref runtime-manifest 'resource-policy '())))
    (append operation
            (cond
             ((eq? stage 'resolve-template)
              (list (cons 'template
                          (cube-interface-template runtime-manifest descriptor))))
             ((eq? stage 'exec-process)
              (list (cons 'process
                          (agent-sandbox-alist-ref runtime-manifest
                                                   'process
                                                   '()))))
             ((eq? stage 'mount-filesystem)
              (list (cons 'filesystem
                          (agent-sandbox-alist-ref runtime-manifest
                                                   'filesystem
                                                   '()))))
             ((eq? stage 'snapshot)
              (list (cons 'policy
                          (agent-sandbox-alist-ref resource-policy
                                                   'snapshot
                                                   #f))))
             ((eq? stage 'resume)
              (list (cons 'policy
                          (agent-sandbox-alist-ref resource-policy
                                                   'resume
                                                   #f))))
             (else '())))))

;;; Lifecycle plans are pure data transforms over validated manifests. Each
;;; operation is annotated with the request subset Marlin needs for that phase.
;; [Alist] <- RuntimeManifest CubeInterfaceDescriptor
(def (cube-interface-lifecycle-plan runtime-manifest descriptor)
  (map (lambda (operation)
         (cube-interface-lifecycle-step operation runtime-manifest descriptor))
       (cube-interface-descriptor-lifecycle-operations descriptor)))

;;; Final projection packages Cube API compatibility, lifecycle operations, and
;;; neutral request policy into one Marlin-facing manifest.
;; CubeInterfaceManifest <- AgentSandboxRuntimeManifest [CubeInterfaceDescriptor]
(def (cube-interface-runtime-manifest->manifest runtime-manifest
                                                . maybe-descriptor)
  (let* ((descriptor
          (cube-interface-validate-descriptor
           (if (null? maybe-descriptor)
             (make-cube-interface-descriptor)
             (car maybe-descriptor))))
         (valid-manifest
          (cube-interface-validate-runtime-manifest runtime-manifest
                                                    descriptor))
         (backend (agent-sandbox-alist-ref valid-manifest 'backend '()))
         (process (agent-sandbox-alist-ref valid-manifest 'process '()))
         (filesystem (agent-sandbox-alist-ref valid-manifest 'filesystem '()))
         (network-policy
          (agent-sandbox-alist-ref valid-manifest 'network-policy '())))
    (list (cons 'schema +cube-interface-schema+)
          (cons 'interface
                (cube-interface-descriptor->contract descriptor))
          (cons 'runtime-schema
                (agent-sandbox-alist-ref valid-manifest 'schema #f))
          (cons 'backend backend)
          (cons 'template
                (cube-interface-template valid-manifest descriptor))
          (cons 'process process)
          (cons 'filesystem filesystem)
          (cons 'network-policy network-policy)
          (cons 'capabilities
                (agent-sandbox-alist-ref valid-manifest 'capabilities '()))
          (cons 'resource-policy
                (agent-sandbox-alist-ref valid-manifest 'resource-policy '()))
          (cons 'snapshot-policy
                (cube-interface-snapshot-policy valid-manifest))
          (cons 'lifecycle-plan
                (cube-interface-lifecycle-plan valid-manifest descriptor))
          (cons 'output-policy
                (agent-sandbox-alist-ref valid-manifest 'output-policy #f))
          (cons 'metadata
                (agent-sandbox-alist-ref valid-manifest 'metadata '())))))

;;; Request projection lets Scheme callers ask for a Cube interface manifest
;;; without constructing a runtime envelope first.
;; CubeInterfaceManifest <- AgentSandboxRequest [CubeInterfaceDescriptor]
(def (agent-sandbox-request->cube-interface-manifest request
                                                     . maybe-descriptor)
  (apply cube-interface-runtime-manifest->manifest
         (agent-sandbox-request->runtime-manifest request)
         maybe-descriptor))

;;; Execution-request projection reuses the bridge envelope so Cube interface
;;; manifests and Marlin request envelopes stay aligned.
;; CubeInterfaceManifest <- ExecutionRequest [CubeInterfaceDescriptor]
(def (agent-sandbox-execution-request->cube-interface-manifest request
                                                               . maybe-descriptor)
  (let (runtime-manifest
        (agent-sandbox-alist-ref
         (make-agent-sandbox-bridge-envelope request)
         'runtime-manifest
         #f))
    (apply cube-interface-runtime-manifest->manifest
           runtime-manifest
           maybe-descriptor)))
