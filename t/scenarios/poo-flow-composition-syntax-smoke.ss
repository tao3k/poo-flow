;;; -*- Gerbil -*-
;;; Boundary: direct syntax smoke for POO-native composition macros.

(import (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/profile-composition)

(def session-module
  (.o (hardened (.o (name 'session-hardened)))))

(def sandbox-module
  (.o (restricted (.o (name 'sandbox-restricted)))))

(def syntax-smoke-composition
  (poo-flow-composition syntax-smoke
    (modules
     (use-module session-module #:as session)
     (use-module sandbox-module #:as sandbox))
    (stage production
      (compose
       (profile session hardened)
       (profile sandbox restricted))
      (graph guarded-flow)
      (loop #:fuel 2 #:exit done))))

(unless (poo-flow-composition? syntax-smoke-composition)
  (error "syntax smoke did not build a composition object"))

(let* ((stage (car (poo-flow-composition-stages syntax-smoke-composition)))
       (profiles (poo-flow-composition-stage-compose-profiles stage)))
  (unless (equal? (map (lambda (profile) (.ref profile 'name)) profiles)
                  '(session-hardened sandbox-restricted))
    (error "syntax smoke selected the wrong profile slots")))
