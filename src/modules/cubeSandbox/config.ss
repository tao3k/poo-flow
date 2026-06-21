;;; -*- Gerbil -*-
;;; Boundary: CubeSandbox kernel module selection.
;;; Invariant: object inheritance and row extension live in objects.ss owners.

(import :poo-flow/src/modules/cubeSandbox/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/module-system/base)

(export poo-flow-cubeSandbox-module-bundles
        poo-flow-cubeSandbox-config-flags
        poo-flow-cubeSandbox-profile-config
        poo-flow-cubeSandbox-profile
        poo-flow-cubeSandbox-profiles)

;;; CubeSandbox is a sandbox module row; runtime handoff stays outside selection.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-cubeSandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox cubeSandbox +cube +doctor))))

;;; Module config flags carry both the validated internal profile list and the
;;; raw user-authored config body used by user-interface presentation.
;; : (-> [PooSandboxProfile] [UserModuleFlagEntry])
(def (poo-flow-cubeSandbox-config-flags profiles . maybe-user-config)
  (append
   (list (cons ':config profiles))
   (if (null? maybe-user-config)
     '()
     (list (cons ':user-config (car maybe-user-config))))))

;;; Backend wrappers pass their inherited profile object into sandbox-core; this
;;; keeps user syntax thin while object merge semantics stay centralized.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-cubeSandbox-profile-config name-value forms)
  (poo-flow-sandbox-profile-object-config
   poo-flow-cubeSandbox-profile-object
   'cube
   name-value
   forms))

;;; Profile row macros quote the profile name and forms only; validation is
;;; delegated to the backend profile object above.
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-cubeSandbox-profile ()
  ((_ name form ...)
   (poo-flow-cubeSandbox-profile-config 'name '(form ...))))

;;; Multiple CubeSandbox profile rows remain ordered user declarations for the
;;; module-system facade and presentation tests.
;; : (-> CubeSandboxProfileRow... [PooSandboxProfile])
(defrules poo-flow-cubeSandbox-profiles ()
  ((_)
   '())
  ((_ (name form ...) profile-clause ...)
   (cons (poo-flow-cubeSandbox-profile name form ...)
         (poo-flow-cubeSandbox-profiles profile-clause ...))))
