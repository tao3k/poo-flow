;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow authoring policy and semantic Module admission.
(import (only-in :clan/poo/object .o object?)
        (only-in :clan/poo/mop define-type)
        (only-in :core/types
                 PooFlowContract. PooFlowNativeObjectContract.
                 poo-flow-classification-evidence)
        (only-in :core/module-schema/relations
                 SemanticSymbol ModuleIdentityContract ModuleImportsContract
                 ModuleProfilesContract ModuleCapabilitiesContract))
(export ModuleSourceRoleContract ModuleAuthoringProfileContract
        SemanticModuleContract)

;; : (-> Unit POOObject)
(def (semantic-empty-prototype) (.o))

;; : (-> Object Object PooFlowClassificationEvidence)
(def (semantic-symbol-list-classify candidate context)
  (let (accepted?
        (and (list? candidate) (andmap symbol? candidate)))
    (poo-flow-classification-evidence
     'semantic-symbol-list candidate accepted?
     (if accepted? '() '(expected-symbol-list)) context)))

;; : (-> Object Object PooFlowClassificationEvidence)
(def (semantic-object-classify candidate context)
  (poo-flow-classification-evidence
   'semantic-object candidate (object? candidate)
   (if (object? candidate) '() '(expected-poo-object)) context))

(def (semantic-boolean-classify candidate context)
  (poo-flow-classification-evidence
   'semantic-boolean candidate (boolean? candidate)
   (if (boolean? candidate) '() '(expected-boolean)) context))

;;; Boundary: authoring policy collections remain symbolic, inspectable values.
(define-type (SemanticSymbolList @ PooFlowContract.)
  identity: 'semantic-symbol-list
  .classify: semantic-symbol-list-classify)

;;; Boundary: executor strategy is any native POO value. Concrete method
;;; bundles still specialize its prototype identity through CLOS.
(define-type (SemanticObject @ PooFlowContract.)
  identity: 'semantic-object
  .classify: semantic-object-classify)

(define-type (SemanticBoolean @ PooFlowContract.)
  identity: 'semantic-boolean
  .classify: semantic-boolean-classify)

;;; A source role is an extensible policy value, not a hard-coded linter mode.
;;; The lists describe recommended syntax and repair vocabulary; they are not
;;; a closed grammar.  Execution remains owned by the authoring Contract
;;; executor, and refined roles may add contextual prohibitions.
(define-type (ModuleSourceRoleContract @ PooFlowNativeObjectContract.)
  identity: 'module-source-role
  proto: (semantic-empty-prototype)
  responsibilities:
  (.o identity: SemanticSymbol
      recommended-forms: SemanticSymbolList
      forbidden-slot-verbs: SemanticSymbolList
      forbidden-root-forms: SemanticSymbolList
      recursive-root-forms?: SemanticBoolean
      forbidden-imports: SemanticSymbolList
      forbidden-forms: SemanticSymbolList
      forbid-raw-behavior-hooks?: SemanticBoolean
      forbid-raw-query-initializers?: SemanticBoolean
      repair-operators: SemanticSymbolList
      freedom: SemanticSymbol))

;;; Every semantic Module carries one role-indexed authoring Profile.  A
;;; vertical module may refine individual role objects without replacing the
;;; admission protocol or disabling unrelated rules.
(define-type (ModuleAuthoringProfileContract @ PooFlowNativeObjectContract.)
  identity: 'module-authoring-profile
  proto: (semantic-empty-prototype)
  responsibilities:
  (.o executor: SemanticObject
      types: ModuleSourceRoleContract
      objects: ModuleSourceRoleContract
      funs: ModuleSourceRoleContract
      config: ModuleSourceRoleContract
      interface: ModuleSourceRoleContract))

;;; Invariant: a semantic module is admitted only through every native
;;; responsibility, including its role-indexed authoring Profile.
(define-type (SemanticModuleContract @ PooFlowNativeObjectContract.)
  identity: 'semantic-module
  proto: (semantic-empty-prototype)
  responsibilities:
  (.o identity: ModuleIdentityContract
      imports: ModuleImportsContract
      capabilities: ModuleCapabilitiesContract
      profiles: ModuleProfilesContract
      authoring: ModuleAuthoringProfileContract))
