;;; -*- Gerbil -*-
;;; Boundary: public POO-native nono sandbox profile super object.
;;; Invariant: native nono execution remains outside profile authoring.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/modules/sandbox-core/profile-interface)

(export nono-sandbox-profile)

;;; Boundary: nono sandbox profile is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
(def +nono-sandbox-profile-backend-kind+ 'nono)
(def +nono-sandbox-profile-capabilities+
  '(process-run filesystem-read tmpdir))
(def +nono-sandbox-profile-metadata+
  '((backend . nono-sandbox)))

;;; Boundary: nono sandbox profile is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : PooSandboxProfilePrototype
(def nono-sandbox-profile
  (.o (:: @ sandbox-profile)
  backend-kind: +nono-sandbox-profile-backend-kind+
  backend-ref: #f
  capabilities: +nono-sandbox-profile-capabilities+
  metadata: => (lambda (super-metadata)
                 (append super-metadata
                         +nono-sandbox-profile-metadata+))))
