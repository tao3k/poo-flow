;;; -*- Gerbil -*-
;;; Boundary: Docker sandbox kernel module selection.
;;; Invariant: Docker task-flow extension remains in :poo-flow/src/modules/docker.

(import :poo-flow/src/modules/docker-sandbox/objects
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/modules-system-base)

(export poo-flow-docker-sandbox-module-bundles
        poo-flow-docker-sandbox-profile-config
        poo-flow-docker-sandbox-profile
        poo-flow-docker-sandbox-profiles)

;;; Docker is exposed as a sandbox module row; concrete container operations
;;; remain in runtime-facing Docker task modules.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-docker-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox docker-sandbox +docker +doctor))))

;;; Backend wrappers pass their inherited profile object into sandbox-core; this
;;; keeps Docker-specific defaults out of the user-facing macro body.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-docker-sandbox-profile-config name-value forms)
  (poo-flow-sandbox-profile-object-config
   poo-flow-docker-sandbox-profile-object
   'docker
   name-value
   forms))

;;; Profile row macros are syntax-only quotation; object validation and POO
;;; merge/remove semantics are owned by sandbox-core.
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-docker-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-docker-sandbox-profile-config 'name '(form ...))))

;;; Docker profile collections preserve declaration order for config receipts
;;; and runtime handoff planning.
;; : (-> DockerSandboxProfileRow... [PooSandboxProfile])
(defrules poo-flow-docker-sandbox-profiles ()
  ((_)
   '())
  ((_ (name form ...) profile-clause ...)
   (cons (poo-flow-docker-sandbox-profile name form ...)
         (poo-flow-docker-sandbox-profiles profile-clause ...))))
