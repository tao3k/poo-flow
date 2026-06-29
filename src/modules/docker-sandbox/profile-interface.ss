;;; -*- Gerbil -*-
;;; Boundary: public POO-native Docker sandbox profile super object.
;;; Invariant: container execution remains a runtime handoff concern.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/modules/sandbox-core/profile-interface)

(export docker-sandbox-profile)

;;; Boundary: docker sandbox profile is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
(def +docker-sandbox-profile-backend-kind+ 'docker)
(def +docker-sandbox-profile-capabilities+
  '(process-run filesystem-read filesystem-write tmpdir))
(def +docker-sandbox-profile-metadata+
  '((backend . docker-sandbox)))

;;; Boundary: docker sandbox profile is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : PooSandboxProfilePrototype
(def docker-sandbox-profile
  (.o (:: @ sandbox-profile)
  backend-kind: +docker-sandbox-profile-backend-kind+
  backend-ref: #f
  capabilities: +docker-sandbox-profile-capabilities+
  metadata: => (lambda (super-metadata)
                 (append super-metadata
                         +docker-sandbox-profile-metadata+))))
