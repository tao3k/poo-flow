;;; -*- Gerbil -*-
;;; Boundary: nono sandbox kernel module selection.
;;; Invariant: object inheritance and row extension live in objects.ss owners.

(import :poo-flow/src/modules/nono-sandbox/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/module-system/base)

(export poo-flow-nono-sandbox-module-bundles
        +poo-flow-nono-sandbox-default-binding+
        poo-flow-nono-sandbox-binding-config
        poo-flow-nono-sandbox-config-flags
        poo-flow-nono-sandbox-profile-config
        poo-flow-nono-sandbox-profile-derive-config
        poo-flow-nono-sandbox-profile
        poo-flow-nono-sandbox-profile-derive
        poo-flow-nono-sandbox-profiles)

;;; Nono is a sandbox module row; Marlin remains the runtime owner, not the row.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-nono-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox nono-sandbox +nono +native-ffi +doctor))))

;; : Symbol
(def +poo-flow-nono-sandbox-default-binding+ 'native-ffi)

;;; Module-level binding flags are user-visible configuration facts. The
;;; native FFI implementation remains in native.ss; this layer only records the
;;; selected binding strategy for use-module/module presentation.
;; : (-> Symbol Symbol)
(def (poo-flow-nono-sandbox-binding-config binding-value)
  binding-value)

;; : (-> Symbol [PooSandboxProfile] [UserModuleFlagEntry])
(def (poo-flow-nono-sandbox-config-flags binding-value profiles . maybe-user-config)
  (append
   (list (cons ':binding
               (poo-flow-nono-sandbox-binding-config binding-value))
         (cons ':config profiles))
   (if (null? maybe-user-config)
     '()
     (list (cons ':user-config (car maybe-user-config))))))

;;; Backend wrappers pass their inherited profile object into sandbox-core; nono
;;; runtime state stays in native.ss while module flags record binding choice.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-config name-value forms)
  (poo-flow-sandbox-profile-object-config
   poo-flow-nono-sandbox-profile-object
   'nono
   name-value
   forms))

;;; Derived nono profiles keep project/session/branch/task splits on the same
;;; POO object merge path as ordinary profile rows.
;; : (-> PooSandboxProfile Symbol [SandboxProfileForm] Alist PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-derive-config parent-profile
                                                  name-value
                                                  forms
                                                  options)
  (poo-flow-sandbox-profile-object-derive
   poo-flow-nono-sandbox-profile-object
   parent-profile
   name-value
   forms
   options))

;;; Profile row macros quote user syntax and leave validation to the inherited
;;; nono profile object.
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-nono-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-nono-sandbox-profile-config 'name '(form ...))))

;;; Derived profile rows are a user-facing shorthand over the sandbox-core POO
;;; derivation API. Options are derivation metadata such as scope/scope-ref.
;; : (-> PooSandboxProfile Symbol DerivationOption... SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-nono-sandbox-profile-derive ()
  ((_ parent name (option ...) form ...)
   (poo-flow-nono-sandbox-profile-derive-config
    parent
    'name
    '(form ...)
    '(option ...)))
  ((_ parent name form ...)
   (poo-flow-nono-sandbox-profile-derive-config
    parent
    'name
    '(form ...)
    '())))

;;; Nono profile rows inherit backend kind from the selected module. Users name
;;; profile refs and policy rows; the module config owns backend projection.
;; : (-> NonoSandboxProfileRow... [PooSandboxProfile])
(defrules poo-flow-nono-sandbox-profiles ()
  ((_)
   '())
  ((_ profile-clause ...)
   (poo-flow-sandbox-profile-object-profiles
    poo-flow-nono-sandbox-profile-config
    poo-flow-nono-sandbox-profile-derive-config
    profile-clause ...)))
