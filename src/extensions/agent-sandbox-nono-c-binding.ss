;;; -*- Gerbil -*-
;;; Owner: nono C binding contract projection lives in this backend leaf.
;;; Boundary: this module emits ABI data and capability plans only.
;;; Runtime contract: Marlin or another C runtime owns dlopen/FFI execution.
;;; Source contract: symbols mirror .data/nono/bindings/c/include/nono.h.
;;; Policy evidence: binding tests assert descriptor override and manifest gates.

(import (only-in :clan/poo/object .ref .mix object?)
        :core/api
        :extensions/agent-sandbox-util
        :extensions/agent-sandbox-profile
        :extensions/agent-sandbox-bridge)

(export +nono-c-binding-schema+
        +nono-c-binding-access-modes+
        +nono-c-binding-network-modes+
        +nono-c-binding-types+
        +nono-c-binding-functions+
        nono-c-binding-descriptor-prototype
        make-nono-c-binding-descriptor
        nono-c-binding-descriptor?
        nono-c-binding-descriptor-name
        nono-c-binding-descriptor-abi
        nono-c-binding-descriptor-package
        nono-c-binding-descriptor-library
        nono-c-binding-descriptor-adapter-header
        nono-c-binding-descriptor-adapter-include-ref
        nono-c-binding-descriptor-header
        nono-c-binding-descriptor-include-ref
        nono-c-binding-descriptor-crate-ref
        nono-c-binding-descriptor-probe-ref
        nono-c-binding-descriptor-types
        nono-c-binding-descriptor-functions
        nono-c-binding-descriptor-access-modes
        nono-c-binding-descriptor-network-modes
        nono-c-binding-descriptor->contract
        nono-c-binding-descriptor-validation-errors
        nono-c-binding-validate-descriptor
        nono-c-binding-access-mode-info
        nono-c-binding-network-mode-info
        nono-c-binding-runtime-manifest-validation-errors
        nono-c-binding-validate-runtime-manifest
        nono-c-binding-runtime-manifest->manifest
        agent-sandbox-request->nono-c-binding-manifest
        agent-sandbox-execution-request->nono-c-binding-manifest)

;;; Binding manifest schema versioning is separate from the neutral runtime
;;; manifest so nono ABI changes can evolve without changing bridge envelopes.
;; Symbol <- Unit
(def +nono-c-binding-schema+ 'poo-flow.agent-sandbox-nono-c-binding.v1)

;;; Access modes pin Scheme mount policy to the integer constants used by the
;;; C capability API, so validation and projection cannot drift separately.
;; [AccessModeContract] <- Unit
(def +nono-c-binding-access-modes+
  '(((scheme . read)
     (constant . NONO_ACCESS_MODE_READ)
     (value . 0))
    ((scheme . write)
     (constant . NONO_ACCESS_MODE_WRITE)
     (value . 1))
    ((scheme . read-write)
     (constant . NONO_ACCESS_MODE_READ_WRITE)
     (value . 2))))

;;; Network modes follow the generated C header exactly. Adding a mode here
;;; requires matching validation and capability-plan projection.
;; [NetworkModeContract] <- Unit
(def +nono-c-binding-network-modes+
  '(((scheme . blocked)
     (constant . NONO_NETWORK_MODE_BLOCKED)
     (value . 0))
    ((scheme . allow-all)
     (constant . NONO_NETWORK_MODE_ALLOW_ALL)
     (value . 1))
    ((scheme . proxy-only)
     (constant . NONO_NETWORK_MODE_PROXY_ONLY)
     (value . 2))))

;;; Type names are contract data for a Rust/C bridge; Scheme records the native
;;; ABI inventory but never allocates or owns those C objects.
;; [Symbol] <- Unit
(def +nono-c-binding-types+
  '(NonoErrorCode
    NonoCapabilitySourceTag
    NonoQueryStatus
    NonoQueryReason
    NonoQueryResult
    NonoSupportInfo
    NonoCapabilitySet
    NonoQueryContext
    NonoSandboxState))

;;; Function inventory ownership:
;;; - This list is the allowlist of native entry points a backend may bind.
;;; - Descriptor validation depends on lifecycle and apply symbols being present.
;;; - Runtime bridges can compare this list to `nono.h` during ABI refresh work.
;; [Symbol] <- Unit
(def +nono-c-binding-functions+
  '(nono_last_error
    nono_clear_error
    nono_string_free
    nono_version
    nono_capability_set_new
    nono_capability_set_free
    nono_capability_set_allow_path
    nono_capability_set_allow_file
    nono_capability_set_set_network_blocked
    nono_capability_set_set_network_mode
    nono_capability_set_network_mode
    nono_capability_set_set_proxy_port
    nono_capability_set_proxy_port
    nono_capability_set_allow_command
    nono_capability_set_block_command
    nono_capability_set_add_platform_rule
    nono_capability_set_deduplicate
    nono_capability_set_path_covered
    nono_capability_set_is_network_blocked
    nono_capability_set_summary
    nono_capability_set_fs_count
    nono_capability_set_fs_original
    nono_capability_set_fs_resolved
    nono_capability_set_fs_access
    nono_capability_set_fs_is_file
    nono_capability_set_fs_source_tag
    nono_capability_set_fs_source_group_name
    nono_query_context_new
    nono_query_context_free
    nono_query_context_query_path
    nono_query_context_query_network
    nono_sandbox_apply
    nono_sandbox_is_supported
    nono_sandbox_support_info
    nono_sandbox_state_from_caps
    nono_sandbox_state_free
    nono_sandbox_state_to_json
    nono_sandbox_state_from_json
    nono_sandbox_state_to_caps))

;;; Binding descriptors are POO objects so backend users can override the ABI
;;; artifact names or header path without changing runtime manifest projection.
;; NonoCBindingDescriptorPrototype <- Unit
(def nono-c-binding-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'schema +nono-c-binding-schema+)
                      (cons 'name 'nono-c-binding)
                      (cons 'abi 'c)
                      (cons 'package "nono-ffi")
                      (cons 'library "nono_ffi")
                      (cons 'adapter-header "poo_flow_nono_binding.h")
                      (cons 'adapter-include-ref
                            "bindings/nono-c/poo_flow_nono_binding.h")
                      (cons 'header "nono.h")
                      (cons 'include-ref ".data/nono/bindings/c/include/nono.h")
                      (cons 'crate-ref ".data/nono/bindings/c")
                      (cons 'probe-ref
                            "bindings/nono-c/poo_flow_nono_binding_probe.c")
                      (cons 'types +nono-c-binding-types+)
                      (cons 'functions +nono-c-binding-functions+)
                      (cons 'access-modes +nono-c-binding-access-modes+)
                      (cons 'network-modes +nono-c-binding-network-modes+)
                      (cons 'validator
                            (lambda (descriptor)
                              (nono-c-binding-validate-descriptor
                               descriptor)))))
        execution-policy-role))

;;; Descriptor construction is the POO override point for local builds that
;;; rename the native library while keeping the same nono ABI contract.
;; NonoCBindingDescriptor <- [Alist]
(def (make-nono-c-binding-descriptor . maybe-overrides)
  (.mix slots: (role-constant-slots
                (if (null? maybe-overrides) '() (car maybe-overrides)))
        nono-c-binding-descriptor-prototype))

;; Boolean <- NonoCBindingDescriptorCandidate
(def (nono-c-binding-descriptor? descriptor)
  (object? descriptor))

;;; Descriptor access deliberately stays dynamic because the POO object carries
;;; policy defaults and per-call overrides through the same `.ref` path.
;; Value <- NonoCBindingDescriptor Symbol Value
(def (nono-c-binding-descriptor-slot descriptor slot default)
  (if (nono-c-binding-descriptor? descriptor)
    (.ref descriptor slot)
    default))

;; Symbol <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-name descriptor)
  (nono-c-binding-descriptor-slot descriptor 'name #f))

;; Symbol <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-abi descriptor)
  (nono-c-binding-descriptor-slot descriptor 'abi #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-package descriptor)
  (nono-c-binding-descriptor-slot descriptor 'package #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-library descriptor)
  (nono-c-binding-descriptor-slot descriptor 'library #f))

;;; Adapter header accessors name the POO Flow-owned C language surface, not the
;;; upstream nono header generated by cbindgen.
;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-adapter-header descriptor)
  (nono-c-binding-descriptor-slot descriptor 'adapter-header #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-adapter-include-ref descriptor)
  (nono-c-binding-descriptor-slot descriptor 'adapter-include-ref #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-header descriptor)
  (nono-c-binding-descriptor-slot descriptor 'header #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-include-ref descriptor)
  (nono-c-binding-descriptor-slot descriptor 'include-ref #f))

;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-crate-ref descriptor)
  (nono-c-binding-descriptor-slot descriptor 'crate-ref #f))

;;; Probe references make compile success auditable from the Scheme contract
;;; without forcing Scheme to execute or link the native nono library.
;; String <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-probe-ref descriptor)
  (nono-c-binding-descriptor-slot descriptor 'probe-ref #f))

;; [Symbol] <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-types descriptor)
  (nono-c-binding-descriptor-slot descriptor 'types '()))

;; [Symbol] <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-functions descriptor)
  (nono-c-binding-descriptor-slot descriptor 'functions '()))

;; [AccessModeContract] <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-access-modes descriptor)
  (nono-c-binding-descriptor-slot descriptor 'access-modes '()))

;; [NetworkModeContract] <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-network-modes descriptor)
  (nono-c-binding-descriptor-slot descriptor 'network-modes '()))

;;; Descriptor contracts are the stable serializable ABI surface. Runtime
;;; bridges should consume this alist instead of depending on Gerbil POO object
;;; internals or slot precedence rules.
;; Alist <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor->contract descriptor)
  (let (valid-descriptor (nono-c-binding-validate-descriptor descriptor))
    (list (cons 'schema +nono-c-binding-schema+)
          (cons 'name (nono-c-binding-descriptor-name valid-descriptor))
          (cons 'abi (nono-c-binding-descriptor-abi valid-descriptor))
          (cons 'package (nono-c-binding-descriptor-package valid-descriptor))
          (cons 'library (nono-c-binding-descriptor-library valid-descriptor))
          (cons 'adapter-header
                (nono-c-binding-descriptor-adapter-header valid-descriptor))
          (cons 'adapter-include-ref
                (nono-c-binding-descriptor-adapter-include-ref
                 valid-descriptor))
          (cons 'header (nono-c-binding-descriptor-header valid-descriptor))
          (cons 'include-ref
                (nono-c-binding-descriptor-include-ref valid-descriptor))
          (cons 'crate-ref
                (nono-c-binding-descriptor-crate-ref valid-descriptor))
          (cons 'probe-ref
                (nono-c-binding-descriptor-probe-ref valid-descriptor))
          (cons 'types (nono-c-binding-descriptor-types valid-descriptor))
          (cons 'functions
                (nono-c-binding-descriptor-functions valid-descriptor))
          (cons 'access-modes
                (nono-c-binding-descriptor-access-modes valid-descriptor))
          (cons 'network-modes
                (nono-c-binding-descriptor-network-modes valid-descriptor)))))

;;; Descriptor validation protects the generated ABI surface from accidental
;;; Scheme-side drift: users may override artifact names, but the descriptor
;;; must still identify a C binding with the core nono lifecycle/apply symbols.
;; [ValidationError] <- NonoCBindingDescriptor
(def (nono-c-binding-descriptor-validation-errors descriptor)
  (if (nono-c-binding-descriptor? descriptor)
    (agent-sandbox-required-field-errors
     (list (cons 'schema
                 (nono-c-binding-descriptor-slot descriptor 'schema #f))
           (cons 'name (nono-c-binding-descriptor-name descriptor))
           (cons 'abi (nono-c-binding-descriptor-abi descriptor))
           (cons 'package (nono-c-binding-descriptor-package descriptor))
           (cons 'library (nono-c-binding-descriptor-library descriptor))
           (cons 'adapter-header
                 (nono-c-binding-descriptor-adapter-header descriptor))
           (cons 'adapter-include-ref
                 (nono-c-binding-descriptor-adapter-include-ref descriptor))
           (cons 'header (nono-c-binding-descriptor-header descriptor))
           (cons 'probe-ref (nono-c-binding-descriptor-probe-ref descriptor))
           (cons 'functions (nono-c-binding-descriptor-functions descriptor)))
     (list (cons 'schema
                 (lambda (value) (eq? value +nono-c-binding-schema+)))
           (cons 'name (lambda (value) (and value #t)))
           (cons 'abi (lambda (value) (eq? value 'c)))
           (cons 'package string?)
           (cons 'library string?)
           (cons 'adapter-header string?)
           (cons 'adapter-include-ref string?)
           (cons 'header string?)
           (cons 'probe-ref string?)
           (cons 'functions
                 (lambda (value)
                   (and (list? value)
                        (memq 'nono_capability_set_new value)
                        (memq 'nono_sandbox_apply value))))))
    (list '((field . descriptor) (code . not-poo-object)))))

;;; Validation raises the same typed failure shape as other extension gates so
;;; callers can recover by code without parsing native binding error strings.
;; NonoCBindingDescriptor <- NonoCBindingDescriptor
(def (nono-c-binding-validate-descriptor descriptor)
  (let (errors (nono-c-binding-descriptor-validation-errors descriptor))
    (if (null? errors)
      descriptor
      (raise-control-plane-failure
       'agent-sandbox-nono
       'invalid-nono-c-binding-descriptor
       "invalid nono C binding descriptor"
       (list (cons 'errors errors))))))

;;; Mode lookup is descriptor-scoped so tests and runtime bridges can override
;;; constants for a regenerated header while sharing projection code.
;; MaybeAlist <- [ModeContract] Symbol
(def (nono-c-binding-mode-info modes scheme-name)
  (if (null? modes)
    #f
    (let (mode (car modes))
      (if (eq? (agent-sandbox-alist-ref mode 'scheme #f) scheme-name)
        mode
        (nono-c-binding-mode-info (cdr modes) scheme-name)))))

;;; Public access-mode lookup defaults through the descriptor constructor and
;;; returns the exact C constant/value pair projected for filesystem policy.
;; MaybeAlist <- Symbol [NonoCBindingDescriptor]
(def (nono-c-binding-access-mode-info scheme-name . maybe-descriptor)
  (let (descriptor (if (null? maybe-descriptor)
                    (make-nono-c-binding-descriptor)
                    (car maybe-descriptor)))
    (nono-c-binding-mode-info
     (nono-c-binding-descriptor-access-modes descriptor)
     scheme-name)))

;;; Public network-mode lookup mirrors access lookup and keeps validation tied
;;; to the same descriptor that will be serialized for the runtime.
;; MaybeAlist <- Symbol [NonoCBindingDescriptor]
(def (nono-c-binding-network-mode-info scheme-name . maybe-descriptor)
  (let (descriptor (if (null? maybe-descriptor)
                    (make-nono-c-binding-descriptor)
                    (car maybe-descriptor)))
    (nono-c-binding-mode-info
     (nono-c-binding-descriptor-network-modes descriptor)
     scheme-name)))

;;; Mount validation is deliberately stricter than the neutral request schema:
;;; the C ABI needs a UTF-8 path and one of the generated access constants.
;; [ValidationError] <- Mount Integer
(def (nono-c-binding-mount-validation-errors mount index)
  (if (list? mount)
    (let* ((path (agent-sandbox-alist-ref mount 'path #f))
           (mode (agent-sandbox-alist-ref mount 'mode #f)))
      (append
       (if (string? path)
         '()
         (list (list (cons 'field 'mount-path)
                     (cons 'index index)
                     (cons 'code 'missing-or-invalid-path))))
       (if (nono-c-binding-access-mode-info mode)
         '()
         (list (list (cons 'field 'mount-mode)
                     (cons 'index index)
                     (cons 'value mode)
                     (cons 'code 'unsupported-access-mode)))))) 
    (list (list (cons 'field 'mount)
                (cons 'index index)
                (cons 'code 'not-alist)))))

;;; Mount validation preserves indices so runtime-manifest errors point back to
;;; the exact filesystem grant that cannot be represented by nono's C ABI.
;; [ValidationError] <- [Mount] Integer
(def (nono-c-binding-mounts-validation-errors mounts index)
  (if (null? mounts)
    '()
    (append (nono-c-binding-mount-validation-errors (car mounts) index)
            (nono-c-binding-mounts-validation-errors (cdr mounts)
                                                     (+ index 1)))))

;;; Network validation maps Scheme policy modes to nono's concrete constants
;;; before any runtime tries to set an unsupported mode through C.
;; [ValidationError] <- NetworkPolicy
(def (nono-c-binding-network-validation-errors network-policy)
  (let (mode (agent-sandbox-alist-ref network-policy 'mode 'blocked))
    (if (nono-c-binding-network-mode-info mode)
      '()
      (list (list (cons 'field 'network-mode)
                  (cons 'value mode)
                  (cons 'code 'unsupported-network-mode))))))

;;; Runtime manifest validation is the backend-specific gate missing from the
;;; neutral bridge layer: only nono manifests with C-representable processes,
;;; mounts, and network modes may become FFI call plans.
;; [ValidationError] <- RuntimeManifest
(def (nono-c-binding-runtime-manifest-validation-errors runtime-manifest)
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
        (list (cons 'kind (lambda (value) (eq? value 'nono)))))
       (agent-sandbox-required-field-errors
        process
        (list (cons 'command (lambda (value) (and value #t)))
              (cons 'argv list?)))
       (if (list? mounts)
         (nono-c-binding-mounts-validation-errors mounts 0)
         (list '((field . mounts) (code . not-list))))
       (nono-c-binding-network-validation-errors network-policy)))
    (list '((field . runtime-manifest) (code . not-alist)))))

;;; This validator is the last Scheme-side boundary before a native runtime
;;; receives the manifest, so it preserves the original manifest in failures
;;; for bridge diagnostics and policy tests.
;; AgentSandboxRuntimeManifest <- RuntimeManifest
(def (nono-c-binding-validate-runtime-manifest runtime-manifest)
  (let (errors
        (nono-c-binding-runtime-manifest-validation-errors runtime-manifest))
    (if (null? errors)
      runtime-manifest
      (raise-control-plane-failure
       'agent-sandbox-nono
       'invalid-nono-c-binding-manifest
       "invalid nono C binding runtime manifest"
       (list (cons 'errors errors)
             (cons 'runtime-manifest runtime-manifest))))))

;;; Mount manifests accept both `kind` and legacy `type` so older sandbox
;;; descriptors can be normalized without changing the C capability call shape.
;; Symbol <- Mount
(def (nono-c-binding-mount-kind mount)
  (agent-sandbox-alist-ref
   mount
   'kind
   (agent-sandbox-alist-ref mount 'type 'directory)))

;; Symbol <- Mount
(def (nono-c-binding-mount-function mount)
  (if (eq? (nono-c-binding-mount-kind mount) 'file)
    'nono_capability_set_allow_file
    'nono_capability_set_allow_path))

;;; Mount calls choose the exact nono function at projection time. File grants
;;; become `allow_file`, while directory/path grants use `allow_path`.
;; Alist <- Mount
(def (nono-c-binding-mount-call mount)
  (let* ((mode (agent-sandbox-alist-ref mount 'mode #f))
         (mode-info (nono-c-binding-access-mode-info mode)))
    (list (cons 'stage 'filesystem)
          (cons 'function (nono-c-binding-mount-function mount))
          (cons 'path (agent-sandbox-alist-ref mount 'path #f))
          (cons 'kind (nono-c-binding-mount-kind mount))
          (cons 'access-mode mode)
          (cons 'access-constant
                (agent-sandbox-alist-ref mode-info 'constant #f))
          (cons 'access-value
                (agent-sandbox-alist-ref mode-info 'value #f)))))

;;; Mount call mapping is a pure sequence transform: every validated mount has
;;; enough path/kind/mode data for `nono-c-binding-mount-call`, so `map` keeps
;;; one output ABI call per input grant without hidden filtering or reordering.
;; [Alist] <- [Mount]
(def (nono-c-binding-mount-calls mounts)
  (map nono-c-binding-mount-call mounts))

;;; Network calls are split so proxy-only manifests can set both the mode and
;;; optional port while blocked/allow-all remain single-call plans.
;; [Alist] <- NetworkPolicy
(def (nono-c-binding-network-calls network-policy)
  (let* ((mode (agent-sandbox-alist-ref network-policy 'mode 'blocked))
         (mode-info (nono-c-binding-network-mode-info mode))
         (proxy-port (agent-sandbox-alist-ref network-policy 'proxy-port #f))
         (mode-call
          (list (cons 'stage 'network)
                (cons 'function 'nono_capability_set_set_network_mode)
                (cons 'mode mode)
                (cons 'network-constant
                      (agent-sandbox-alist-ref mode-info 'constant #f))
                (cons 'network-value
                      (agent-sandbox-alist-ref mode-info 'value #f)))))
    (if proxy-port
      (list mode-call
            (list (cons 'stage 'network-proxy)
                  (cons 'function 'nono_capability_set_set_proxy_port)
                  (cons 'port proxy-port)))
      (list mode-call))))

;;; Capability inputs accept scalar or list values; normalizing here keeps all
;;; plan builders list-shaped before they emit ABI function calls.
;; [Value] <- MaybeValue
(def (nono-c-binding-list-value value)
  (cond ((not value) '())
        ((list? value) value)
        (else (list value))))

;;; Command and platform-rule capability helpers keep optional nono-specific
;;; policy extensions out of the neutral request schema.
;; [Alist] <- Capabilities Symbol Symbol Symbol
(def (nono-c-binding-string-calls capabilities key stage function-name)
  (map (lambda (value)
         (list (cons 'stage stage)
               (cons 'function function-name)
               (cons 'value value)))
       (nono-c-binding-list-value
        (agent-sandbox-alist-ref capabilities key '()))))

;;; Capability plans are declarative C call sequences. They preserve ordering
;;; for a Rust/C runtime bridge while Scheme keeps ownership of validation and
;;; avoids applying the irreversible nono sandbox itself.
;; [Alist] <- RuntimeManifest
(def (nono-c-binding-capability-plan runtime-manifest)
  (let* ((filesystem (agent-sandbox-alist-ref runtime-manifest 'filesystem '()))
         (mounts (agent-sandbox-alist-ref filesystem 'mounts '()))
         (network-policy
          (agent-sandbox-alist-ref runtime-manifest 'network-policy '()))
         (capabilities
          (agent-sandbox-alist-ref runtime-manifest 'capabilities '())))
    (append
     (list '((stage . create-capability-set)
             (function . nono_capability_set_new)))
     (nono-c-binding-mount-calls mounts)
     (nono-c-binding-network-calls network-policy)
     (nono-c-binding-string-calls capabilities
                                  'allow-commands
                                  'allow-command
                                  'nono_capability_set_allow_command)
     (nono-c-binding-string-calls capabilities
                                  'block-commands
                                  'block-command
                                  'nono_capability_set_block_command)
     (nono-c-binding-string-calls capabilities
                                  'platform-rules
                                  'platform-rule
                                  'nono_capability_set_add_platform_rule)
     (list '((stage . deduplicate)
             (function . nono_capability_set_deduplicate))))))

;;; Final projection packages the verified ABI contract, request policy, and
;;; query/apply/state entry points into one backend-owned manifest. Consumers
;;; can bind this data to C directly without reading Gerbil request internals
;;; or invoking native code from the Scheme layer.
;; NonoCBindingManifest <- AgentSandboxRuntimeManifest [NonoCBindingDescriptor]
(def (nono-c-binding-runtime-manifest->manifest runtime-manifest
                                                . maybe-descriptor)
  (let* ((descriptor
          (nono-c-binding-validate-descriptor
           (if (null? maybe-descriptor)
             (make-nono-c-binding-descriptor)
             (car maybe-descriptor))))
         (valid-manifest
          (nono-c-binding-validate-runtime-manifest runtime-manifest))
         (backend (agent-sandbox-alist-ref valid-manifest 'backend '()))
         (process (agent-sandbox-alist-ref valid-manifest 'process '()))
         (filesystem (agent-sandbox-alist-ref valid-manifest 'filesystem '()))
         (network-policy
          (agent-sandbox-alist-ref valid-manifest 'network-policy '())))
    (list (cons 'schema +nono-c-binding-schema+)
          (cons 'binding
                (nono-c-binding-descriptor->contract descriptor))
          (cons 'runtime-schema
                (agent-sandbox-alist-ref valid-manifest 'schema #f))
          (cons 'backend backend)
          (cons 'process process)
          (cons 'filesystem filesystem)
          (cons 'network-policy network-policy)
          (cons 'capability-plan
                (nono-c-binding-capability-plan valid-manifest))
          (cons 'query-plan
                '((context-new . nono_query_context_new)
                  (context-free . nono_query_context_free)
                  (query-path . nono_query_context_query_path)
                  (query-network . nono_query_context_query_network)
                  (result-string-free . nono_string_free)))
          (cons 'apply-plan
                '((apply . nono_sandbox_apply)
                  (support . nono_sandbox_is_supported)
                  (support-info . nono_sandbox_support_info)))
          (cons 'state-plan
                '((from-caps . nono_sandbox_state_from_caps)
                  (state-free . nono_sandbox_state_free)
                  (to-json . nono_sandbox_state_to_json)
                  (from-json . nono_sandbox_state_from_json)
                  (to-caps . nono_sandbox_state_to_caps)))
          (cons 'resource-policy
                (agent-sandbox-alist-ref valid-manifest 'resource-policy '()))
          (cons 'output-policy
                (agent-sandbox-alist-ref valid-manifest 'output-policy #f))
          (cons 'metadata
                (agent-sandbox-alist-ref valid-manifest 'metadata '())))))

;;; Request projection lets Scheme callers ask for a nono C binding manifest
;;; directly while still passing through the neutral runtime manifest contract.
;; NonoCBindingManifest <- AgentSandboxRequest [NonoCBindingDescriptor]
(def (agent-sandbox-request->nono-c-binding-manifest request
                                                     . maybe-descriptor)
  (apply nono-c-binding-runtime-manifest->manifest
         (agent-sandbox-request->runtime-manifest request)
         maybe-descriptor))

;;; Execution-request projection is the adapter-facing entry point: it reuses
;;; the bridge envelope so C binding manifests and Marlin envelopes cannot drift.
;; NonoCBindingManifest <- ExecutionRequest [NonoCBindingDescriptor]
(def (agent-sandbox-execution-request->nono-c-binding-manifest request
                                                               . maybe-descriptor)
  (let (runtime-manifest
        (agent-sandbox-alist-ref
         (make-agent-sandbox-bridge-envelope request)
         'runtime-manifest
         #f))
    (apply nono-c-binding-runtime-manifest->manifest
           runtime-manifest
           maybe-descriptor)))
