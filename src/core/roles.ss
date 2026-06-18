;;; -*- Gerbil -*-
;;; Boundary: POO roles describe conceptual control-plane ownership.
;;; Invariant: runtime data stays in typed structs and adapter receipts.

(import (only-in :clan/poo/object .o .@ .ref .mix .slot? object? $constant-slot-spec))

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
        role-slot/default
        role-compose
        role-object?
        role-constant-slots)

;;; Boundary: compose is the only higher-order role operation in this module.
;;; Invariant: derived roles share one mixing path with leftmost POO precedence.
;; Role <- Unit
(def control-plane-role
  (.o (name 'control-plane)
      (kind 'system)
      (responsibility 'conceptual-model)
      (runtime-owner 'gerbil)
      (control-plane-capability 'conceptual-model)
      (compose (lambda roles (apply .mix (append roles (list control-plane-role)))))))

;; Role <- Unit
(def flow-role
  (.o (:: @ control-plane-role)
      (name 'flow)
      (kind 'declaration)
      (responsibility 'workflow-composition)
      (flow-capability 'workflow-composition)))

;; Role <- Unit
(def branch-role
  (.o (:: @ control-plane-role)
      (name 'branch)
      (kind 'composition)
      (responsibility 'dag-fanout-join)
      (branch-capability 'dag-fanout-join)))

;; Role <- Unit
(def task-role
  (.o (:: @ control-plane-role)
      (name 'task)
      (kind 'declaration)
      (responsibility 'work-intent)
      (task-capability 'work-intent)))

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
      (responsibility 'runtime-policy-handoff)
      (policy-capability 'runtime-policy-handoff)))

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
      (runtime-capability 'heavy-runtime-delegation)
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

;;; Slot probing is the safe boundary for C3-composed role objects: descriptor
;;; callers can inspect inherited capabilities without assuming every role
;;; contributes the same slot set.
;; Value <- Role Symbol Value
(def (role-slot/default role slot default)
  (if (and (role-object? role)
           (.slot? role slot))
    (.ref role slot)
    default))

;; Role <- [Role]
(def (role-compose . roles)
  (apply (.@ control-plane-role compose) roles))

;; Boolean <- Role
(def (role-object? role)
  (object? role))

;;; Boundary: descriptor modules hand this helper plain slot/value pairs.
;;; Data flow: each pair becomes the constant slot spec required by =.mix=.
;;; Invariant: callers use slot precedence so descriptors can override inherited
;;; role slots without falling back to lower-precedence defaults.
;; [SlotSpec] <- Alist
(def (role-constant-slots alist)
  (map (lambda (entry) (cons (car entry) ($constant-slot-spec (cdr entry))))
       alist))
