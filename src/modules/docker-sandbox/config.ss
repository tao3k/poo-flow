;;; -*- Gerbil -*-
;;; Boundary: Docker sandbox kernel module selection.
;;; Invariant: Docker task-flow extension remains in :poo-flow/src/modules/docker.

(import :poo-flow/src/modules/docker-sandbox/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/projection-syntax)

(export poo-flow-docker-sandbox-module-bundles
        poo-flow-docker-sandbox-config-flags
        poo-flow-docker-sandbox-profile-config
        poo-flow-docker-sandbox-profile-derive-config
        poo-flow-docker-sandbox-profile
        poo-flow-docker-sandbox-profile-derive
        poo-flow-docker-sandbox-profiles)

;;; Docker is exposed as a sandbox module row; concrete container operations
;;; remain in runtime-facing Docker task modules.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-docker-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox docker-sandbox +docker +doctor))))

;;; Module config flags keep the internal POO profile payload separate from the
;;; user-authored config body shown by the user-interface presentation.
;; : (-> [PooSandboxProfile] [UserModuleFlagEntry])
(def (poo-flow-docker-sandbox-config-flags profiles . maybe-user-config)
  (if (null? maybe-user-config)
    (poo-flow-module-field-rows
     (:config profiles))
    (poo-flow-module-field-rows
     (:config profiles)
     (:user-config (car maybe-user-config)))))

;;; Backend wrappers pass their inherited profile object into sandbox-core; this
;;; keeps Docker-specific defaults out of the user-facing macro body.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-docker-sandbox-profile-config name-value forms)
  (poo-flow-sandbox-profile-object-config
   poo-flow-docker-sandbox-profile-object
   'docker
   name-value
   forms))

;;; Derived Docker profiles reuse the sandbox-core POO derivation path; this
;;; module only supplies the backend profile object.
;; poo-flow-docker-sandbox-profile-derive
;;   : (-> PooSandboxProfile Symbol [SandboxProfileForm] Alist PooSandboxProfile)
;;   | doc m%
;;       `poo-flow-docker-sandbox-profile-derive` documents the sandbox
;;       boundary that the Gerbil policy harness treats as agent-facing
;;       behavior. The example keeps the call shape visible without duplicating
;;       implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-docker-sandbox-profile-derive ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(def (poo-flow-docker-sandbox-profile-derive-config parent-profile
                                                    name-value
                                                    forms
                                                    options)
  (poo-flow-sandbox-profile-object-derive
   poo-flow-docker-sandbox-profile-object
   parent-profile
   name-value
   forms
   options))

;;; Profile row macros are syntax-only quotation; object validation and POO
;;; merge/remove semantics are owned by sandbox-core.
;; poo-flow-docker-sandbox-profile
;;   : (-> Symbol SandboxProfileForm... PooSandboxProfile)
;;   | doc m%
;;       `poo-flow-docker-sandbox-profile` documents the sandbox boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-docker-sandbox-profile ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules poo-flow-docker-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-docker-sandbox-profile-config 'name '(form ...))))

;;; Backend-specific shorthand over the shared sandbox-core POO derive helper.
;; poo-flow-docker-sandbox-profile-derive
;;   : (-> PooSandboxProfile Symbol DerivationOption... SandboxProfileForm... PooSandboxProfile)
;;   | doc m%
;;       `poo-flow-docker-sandbox-profile-derive` documents the sandbox
;;       boundary that the Gerbil policy harness treats as agent-facing
;;       behavior. The example keeps the call shape visible without duplicating
;;       implementation details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-docker-sandbox-profile-derive ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules poo-flow-docker-sandbox-profile-derive ()
  ((_ parent name (option ...) form ...)
   (poo-flow-docker-sandbox-profile-derive-config
    parent
    'name
    '(form ...)
    '(option ...)))
  ((_ parent name form ...)
   (poo-flow-docker-sandbox-profile-derive-config
    parent
    'name
    '(form ...)
    '())))

;;; Docker profile collections preserve declaration order for config receipts
;;; and runtime handoff planning.
;; poo-flow-docker-sandbox-profiles
;;   : (-> DockerSandboxProfileRow... [PooSandboxProfile])
;;   | doc m%
;;       `poo-flow-docker-sandbox-profiles` documents the sandbox boundary that
;;       the Gerbil policy harness treats as agent-facing behavior. The example
;;       keeps the call shape visible without duplicating implementation
;;       details.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-docker-sandbox-profiles ...)
;;       ;; => policy-visible result
;;       ```
;;     %
(defrules poo-flow-docker-sandbox-profiles ()
  ((_)
   '())
  ((_ profile-clause ...)
   (poo-flow-sandbox-profile-object-profiles
    poo-flow-docker-sandbox-profile-config
    poo-flow-docker-sandbox-profile-derive-config
    profile-clause ...)))
