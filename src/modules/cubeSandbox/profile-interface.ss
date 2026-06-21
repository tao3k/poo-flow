;;; -*- Gerbil -*-
;;; Boundary: public POO-native CubeSandbox profile super object.
;;; Invariant: CubeSandbox execution remains a runtime handoff concern.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/modules/sandbox-core/profile-interface)

(export cubeSandbox-profile)

(def +cubeSandbox-profile-backend-kind+ 'cube)
(def +cubeSandbox-profile-capabilities+
  '(process-run filesystem-read tmpdir))
(def +cubeSandbox-profile-metadata+
  '((backend . cubeSandbox)))

;; : PooSandboxProfilePrototype
(def cubeSandbox-profile
  (.o (:: @ sandbox-profile)
  backend-kind: +cubeSandbox-profile-backend-kind+
  backend-ref: #f
  capabilities: +cubeSandbox-profile-capabilities+
  metadata: => (lambda (super-metadata)
                 (append super-metadata
                         +cubeSandbox-profile-metadata+))))
