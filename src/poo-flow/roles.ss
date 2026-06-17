(import (only-in :clan/poo/object .o .@ .mix object?))

(export control-plane-role
        flow-role
        task-role
        strategy-role
        runner-role
        runtime-adapter-role
        receipt-role
        role-name
        role-kind
        role-responsibility
        role-runtime-owner
        role-compose
        role-object?)

;; These prototypes are the high-level POO control-plane role descriptors.
;; Runtime records remain thin adapters until the Rust boundary is stable.
(def control-plane-role
  (.o (name 'control-plane)
      (kind 'system)
      (responsibility 'conceptual-model)
      (runtime-owner 'gerbil)
      (compose (lambda roles (apply .mix (append roles (list control-plane-role)))))))

(def flow-role
  (.o (:: @ control-plane-role)
      (name 'flow)
      (kind 'declaration)
      (responsibility 'workflow-composition)))

(def task-role
  (.o (:: @ control-plane-role)
      (name 'task)
      (kind 'declaration)
      (responsibility 'work-intent)))

(def strategy-role
  (.o (:: @ control-plane-role)
      (name 'strategy)
      (kind 'policy)
      (responsibility 'execution-selection)))

(def runner-role
  (.o (:: @ control-plane-role)
      (name 'runner)
      (kind 'interpreter)
      (responsibility 'plan-interpretation)))

(def runtime-adapter-role
  (.o (:: @ control-plane-role)
      (name 'runtime-adapter)
      (kind 'boundary)
      (responsibility 'heavy-runtime-delegation)
      (runtime-owner 'rust-or-external-runtime)))

(def receipt-role
  (.o (:: @ control-plane-role)
      (name 'receipt)
      (kind 'evidence)
      (responsibility 'execution-explanation)))

(def (role-name role)
  (.@ role name))

(def (role-kind role)
  (.@ role kind))

(def (role-responsibility role)
  (.@ role responsibility))

(def (role-runtime-owner role)
  (.@ role runtime-owner))

(def (role-compose . roles)
  (apply (.@ control-plane-role compose) roles))

(def (role-object? role)
  (object? role))
