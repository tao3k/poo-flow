;;; -*- Gerbil -*-
;;; Boundary: thin user configuration surface for hot-plug module selection.
;;; Invariant: user config is declarative data.
;;; Descriptor realization stays in src/modules.
;;; Intent: keep the downstream surface focused on POO Flow module activation.

(import (only-in :clan/poo/object .o .ref object?))

(export poo-user-config-kind
        poo-user-module-selection-kind
        pooUserConfig
        poo-user-config?
        poo-user-config-modules
        poo-user-config-settings
        poo-user-config-module-keys
        poo-user-module-selection
        poo-user-module-selection?
        poo-user-module-selection-key
        poo-user-module-selection-flags
        poo-user-module-selection-has-flag?
        poo-settings)

;;; Boundary: public ids are receipt vocabulary, not runtime owners.
;; PooUserConfigKind <- Unit
(def poo-user-config-kind
  "poo-flow.modules.user-config.v1")

;;; Module selections are user-facing hot-plug facts, so their kind id stays
;;; separate from realized descriptor and module contract ids.
;; PooUserModuleSelectionKind <- Unit
(def poo-user-module-selection-kind
  "poo-flow.modules.user-selection.v1")

;;; Boundary: kind checks keep root user files independent of constructor identity.
;; Boolean <- POOObject String
(def (poo-user-object-kind? value expected-kind)
  (and (object? value)
       (equal? (.ref value 'kind) expected-kind)))

;;; Boundary: user modules are hot-plug selections, not descriptors.
;; POOObject <- Symbol Symbol [Symbol]
(def (poo-user-module-selection group module flags)
  (.o kind: poo-user-module-selection-kind
      user-group: group
      user-module: module
      selection-flags: flags
      enabled?: #t))

;; Boolean <- PooUserModuleSelectionCandidate
(def (poo-user-module-selection? value)
  (poo-user-object-kind? value poo-user-module-selection-kind))

;; Pair <- POOObject
(def (poo-user-module-selection-key selection)
  (cons (.ref selection 'user-group)
        (.ref selection 'user-module)))

;; [Symbol] <- POOObject
(def (poo-user-module-selection-flags selection)
  (.ref selection 'selection-flags))

;; Boolean <- POOObject Symbol
(def (poo-user-module-selection-has-flag? selection flag)
  (not (not (member flag (poo-user-module-selection-flags selection)))))

;;; Boundary: settings are a plain slot object so option semantics stay upstream.
;; POOObject <- UserSettingSyntax
(defrules poo-settings ()
  ((_ setting ...)
   (.o setting ...)))

;;; Boundary: top-level user config groups module choices and strategy settings.
;; POOObject <- [PooUserModuleSelection] POOObject
(def (pooUserConfig modules settings)
  (.o kind: poo-user-config-kind
      user-modules: modules
      user-settings: settings))

;; Boolean <- PooUserConfigCandidate
(def (poo-user-config? value)
  (poo-user-object-kind? value poo-user-config-kind))

;; [PooUserModuleSelection] <- PooUserConfig
(def (poo-user-config-modules config)
  (.ref config 'user-modules))

;; POOObject <- PooUserConfig
(def (poo-user-config-settings config)
  (.ref config 'user-settings))

;;; Module key projection is a user-facing summary for selected groups and
;;; names. It intentionally drops flags because flag checks stay per selection.
;; [Pair] <- PooUserConfig
(def (poo-user-config-module-keys config)
  (map poo-user-module-selection-key
       (poo-user-config-modules config)))
