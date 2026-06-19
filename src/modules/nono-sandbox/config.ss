;;; -*- Gerbil -*-
;;; Boundary: nono sandbox kernel module selection.
;;; Invariant: object inheritance and row extension live in objects.ss owners.

(import :modules/nono-sandbox/objects
        :modules/sandbox-core/objects
        :modules/user-config-base)

(export poo-flow-nono-sandbox-module-bundles
        poo-flow-nono-sandbox-profile-config
        poo-flow-nono-sandbox-profile
        poo-flow-nono-sandbox-profiles)

;;; Nono is a sandbox module row; Marlin remains the runtime owner, not the row.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-nono-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox nono-sandbox +nono +doctor))))

;;; Backend wrappers pass their inherited profile object into sandbox-core; nono
;;; C binding state never enters this user-facing macro path.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-config name-value forms)
  (poo-flow-sandbox-profile-object-config
   poo-flow-nono-sandbox-profile-object
   'nono
   name-value
   forms))

;;; Profile row macros quote user syntax and leave validation to the inherited
;;; nono profile object.
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-nono-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-nono-sandbox-profile-config 'name '(form ...))))

;;; Nono profile rows inherit backend kind from the selected module. Users name
;;; profile refs and policy rows; the module config owns backend projection.
;; : (-> NonoSandboxProfileRow... [PooSandboxProfile])
(defrules poo-flow-nono-sandbox-profiles ()
  ((_)
   '())
  ((_ (name form ...) profile-clause ...)
   (cons (poo-flow-nono-sandbox-profile name form ...)
         (poo-flow-nono-sandbox-profiles profile-clause ...))))
