;;; -*- Gerbil -*-
;;; Boundary: public POO-native CubeSandbox profile super object.
;;; Invariant: CubeSandbox execution remains a runtime handoff concern.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/modules/sandbox-core/profile-interface)

(export cubeSandbox-profile)

;;; Boundary: cubeSandbox profile is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
(def +cubeSandbox-profile-backend-kind+ 'cube)
(def +cubeSandbox-profile-capabilities+
  '(process-run filesystem-read tmpdir))
(def +cubeSandbox-profile-metadata+
  '((backend . cubeSandbox)))

;;; Boundary: cubeSandbox profile is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : PooSandboxProfilePrototype
(def cubeSandbox-profile
  (.o (:: @ sandbox-profile)
  backend-kind: +cubeSandbox-profile-backend-kind+
  backend-ref: #f
  capabilities: +cubeSandbox-profile-capabilities+
  metadata: => (lambda (super-metadata)
                 (append super-metadata
                         +cubeSandbox-profile-metadata+))))
