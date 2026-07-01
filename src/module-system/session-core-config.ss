;;; -*- Gerbil -*-
;;; Boundary: session-core presentation rows for the module system.
;;; Invariant: this module projects selected session-core features only; session
;;; values and graph receipts stay in src/modules/session.

(import :poo-flow/src/module-system/base)

(export poo-flow-user-module-selection-session-core?
        poo-flow-user-module-selection-session-core-intent
        poo-flow-user-config-session-core-intents)

;; : (-> PooUserModuleSelection Boolean)
(def (poo-flow-user-module-selection-session-core? selection)
  (equal? (poo-flow-user-module-selection-key selection)
          '(session . session-core)))

;; : (-> PooUserModuleSelection Alist)
(def (poo-flow-user-module-selection-session-core-intent selection)
  (let (flags (poo-flow-user-module-selection-flags selection))
    (list (cons 'kind 'poo-flow.session-core.intent)
          (cons 'key (poo-flow-user-module-selection-key selection))
          (cons 'flags flags)
          (cons 'lineage-enabled?
                (poo-flow-user-module-selection-has-flag? selection '+lineage))
          (cons 'placement-enabled?
                (poo-flow-user-module-selection-has-flag? selection '+placement))
          (cons 'handoff-enabled?
                (poo-flow-user-module-selection-has-flag? selection '+handoff))
          (cons 'graph-enabled?
                (poo-flow-user-module-selection-has-flag? selection '+graph))
          (cons 'transform-enabled?
                (poo-flow-user-module-selection-has-flag? selection
                                                            '+transform))
          (cons 'doctor-enabled?
                (poo-flow-user-module-selection-has-flag? selection '+doctor))
          (cons 'runtime-owner "marlin-agent-core")
          (cons 'descriptor-realized? #f)
          (cons 'runtime-executed #f))))

;;; Boundary: user config session core intents add is the policy-visible edge
;;; for module-system, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooUserModuleSelection] [Alist] [Alist])
(def (poo-flow-user-config-session-core-intents/add-rev selections
                                                           intents-rev)
  (if (null? selections)
    intents-rev
    (let (intent
          (poo-flow-user-config-session-core-intent (car selections)))
      (poo-flow-user-config-session-core-intents/add-rev
       (cdr selections)
       (if intent
         (cons intent intents-rev)
         intents-rev)))))

;; : (-> [PooUserModuleSelection] [Alist])
(def (poo-flow-user-config-session-core-intents/add selections)
  (reverse
   (poo-flow-user-config-session-core-intents/add-rev selections '())))

;; : (-> PooUserModuleSelection MaybeAlist)
(def (poo-flow-user-config-session-core-intent selection)
  (and (poo-flow-user-module-selection-session-core? selection)
       (poo-flow-user-module-selection-session-core-intent selection)))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-session-core-intents config)
  (poo-flow-user-config-session-core-intents/add
   (poo-flow-user-config-modules config)))
