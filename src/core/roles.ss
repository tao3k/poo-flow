;;; -*- Gerbil -*-
;;; Boundary: POO roles describe conceptual control-plane ownership.
;;; Invariant: runtime data stays in typed structs and adapter receipts.

(import (only-in :clan/poo/object .o .@ .mix object?))

(export control-plane-role
        flow-role
        branch-role
        task-role
        strategy-role
        execution-policy-role
        run-config-role
        runner-role
        runtime-adapter-role
        receipt-role
        replay-role
        role-name
        role-kind
        role-responsibility
        role-runtime-owner
        role-compose
        role-object?)

;;; Boundary: compose is the only higher-order role operation in this module.
;;; Invariant: derived roles share one mixing path with leftmost POO precedence.
;; Role <- Unit
(def control-plane-role
  (.o (name 'control-plane)
      (kind 'system)
      (responsibility 'conceptual-model)
      (runtime-owner 'gerbil)
      (compose (lambda roles (apply .mix (append roles (list control-plane-role)))))))

;; Role <- Unit
(def flow-role
  (.o (:: @ control-plane-role)
      (name 'flow)
      (kind 'declaration)
      (responsibility 'workflow-composition)))

;; Role <- Unit
(def branch-role
  (.o (:: @ control-plane-role)
      (name 'branch)
      (kind 'composition)
      (responsibility 'dag-fanout-join)))

;; Role <- Unit
(def task-role
  (.o (:: @ control-plane-role)
      (name 'task)
      (kind 'declaration)
      (responsibility 'work-intent)))

;; Role <- Unit
(def strategy-role
  (.o (:: @ control-plane-role)
      (name 'strategy)
      (kind 'policy)
      (responsibility 'execution-selection)))

;; Role <- Unit
(def execution-policy-role
  (.o (:: @ control-plane-role)
      (name 'execution-policy)
      (kind 'policy-envelope)
      (responsibility 'runtime-policy-handoff)))

;; Role <- Unit
(def run-config-role
  (.o (:: @ control-plane-role)
      (name 'run-config)
      (kind 'configuration)
      (responsibility 'configured-runner-assembly)))

;; Role <- Unit
(def runner-role
  (.o (:: @ control-plane-role)
      (name 'runner)
      (kind 'interpreter)
      (responsibility 'plan-interpretation)))

;; Role <- Unit
(def runtime-adapter-role
  (.o (:: @ control-plane-role)
      (name 'runtime-adapter)
      (kind 'boundary)
      (responsibility 'heavy-runtime-delegation)
      (runtime-owner 'rust-or-external-runtime)))

;; Role <- Unit
(def receipt-role
  (.o (:: @ control-plane-role)
      (name 'receipt)
      (kind 'evidence)
      (responsibility 'execution-explanation)))

;; Role <- Unit
(def replay-role
  (.o (:: @ control-plane-role)
      (name 'replay)
      (kind 'policy)
      (responsibility 'audit-validation)))

;; Symbol <- Role
(def (role-name role)
  (.@ role name))

;; Symbol <- Role
(def (role-kind role)
  (.@ role kind))

;; Symbol <- Role
(def (role-responsibility role)
  (.@ role responsibility))

;; Symbol <- Role
(def (role-runtime-owner role)
  (.@ role runtime-owner))

;; Role <- [Role]
(def (role-compose . roles)
  (apply (.@ control-plane-role compose) roles))

;; Boolean <- Role
(def (role-object? role)
  (object? role))
