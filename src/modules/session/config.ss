;;; -*- Gerbil -*-
;;; Boundary: user-facing session object module facade.
;;; Invariant: session declarations are report-only until a runtime bridge
;;; consumes their handoff receipts.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/config-prototype-syntax
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/agent
        :poo-flow/src/modules/session/agent-param
        :poo-flow/src/modules/session/communication
        :poo-flow/src/modules/session/materialization
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-validation
        :poo-flow/src/modules/session/registry
        :poo-flow/src/modules/session/selector
        :poo-flow/src/modules/session/transform
        :poo-flow/src/modules/session/config-session-syntax
        :poo-flow/src/modules/session/config-policy-syntax)

(export (import: :poo-flow/src/module-system/durable-policy)
        (import: :poo-flow/src/modules/session/agent)
        (import: :poo-flow/src/modules/session/agent-param)
        (import: :poo-flow/src/modules/session/communication)
        (import: :poo-flow/src/modules/session/materialization)
        (import: :poo-flow/src/modules/session/objects)
        (import: :poo-flow/src/modules/session/policy)
        (import: :poo-flow/src/modules/session/policy-validation)
        (import: :poo-flow/src/modules/session/registry)
        (import: :poo-flow/src/modules/session/selector)
        (import: :poo-flow/src/modules/session/transform)
        (import: :poo-flow/src/modules/session/config-session-syntax)
        (import: :poo-flow/src/modules/session/config-policy-syntax)
        poo-flow-session-memory-intent
        poo-flow-session-memory-intent?
        poo-flow-session-memory-intent-name
        poo-flow-session-memory-intent-store-ref
        poo-flow-session-memory-intent-scope
        poo-flow-session-memory-intent-recall
        poo-flow-session-memory-intent-commit-policy
        poo-flow-session-memory-intent-runtime-owner
        poo-flow-session-memory-intent-metadata
        +poo-flow-session-core-config-kind+
        session-config
        poo-flow-session-core-poo-config?
        poo-flow-session-core-poo-config->rows
        poo-flow-session-core-poo-configs->rows
        poo-flow-session-core-poo-config-flags)

;; : (-> List List List)
(def (poo-flow-session-core-config-rows/tail rows tail)
  (append rows tail))

;; : Symbol
(def +poo-flow-session-core-config-kind+ 'poo-flow.session-core.config)

;; : PooSessionCoreConfigPrototype
(defpoo-module-config-prototype
  session-config
  (slots ((kind +poo-flow-session-core-config-kind+)
          (rows '())
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-session-core-poo-config?
  +poo-flow-session-core-config-kind+)

;; : (-> PooSessionCoreConfigPrototype [Alist])
(def (poo-flow-session-core-poo-config->rows config)
  (let (rows (.ref config 'rows))
    (if (list? rows)
      rows
      (error "session-core config rows must be a list" rows))))

;; : (-> [PooSessionCoreConfigPrototype] [Alist])
(def (poo-flow-session-core-poo-configs->rows configs)
  (cond
   ((null? configs) '())
   ((pair? configs)
    (poo-flow-session-core-config-rows/tail
     (poo-flow-session-core-poo-config->rows (car configs))
     (poo-flow-session-core-poo-configs->rows (cdr configs))))
   (else
    (error "session-core POO configs must be a list" configs))))

;; : (-> [POOObject] [UserModuleFlagEntry])
(def (poo-flow-session-core-poo-config-flags prototypes user-config)
  (let* ((configs (filter poo-flow-session-core-poo-config? prototypes))
         (rows (poo-flow-session-core-poo-configs->rows configs)))
    (list '+policy
          '+typed-receipts
          (cons ':config rows)
          (cons ':session-rows rows)
          (cons ':session-config-prototypes configs)
          (cons ':user-config user-config))))
