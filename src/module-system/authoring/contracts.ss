;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: role-aware source admission for one loaded POO Module Interface.
;;; Invariant: source is read as inert data; this owner never expands or runs it.

(import (only-in :clan/poo/object .def .o .ref .slot? object?)
        (only-in :std/list/list filter-map find)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface-prototype
                 poo-flow-module-interface?
                 poo-flow-module-interface-id
                 poo-flow-module-interface-authoring)
        (only-in :poo-flow/src/module-system/observability/module-presentation
                 poo-flow-poo-slot-authoring-datum-bindings)
        :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/src/module-system/semantic-module/objects
                 ModuleAuthoringExecutor. ModuleSourceRole.
                 ConfigSourceRole.))

(export ModuleAuthoringAdmissionProtocol
        ModuleAuthoringAdmissionGeneric
        ModuleAuthoringCoreMethods
        poo-flow-module-authoring-role
        poo-flow-module-authoring-admit-datum
        poo-flow-module-authoring-admit-port
        poo-flow-module-authoring-admission?
        poo-flow-module-authoring-admission-accepted?
        poo-flow-module-authoring-admission-diagnostics)

(.def ModuleAuthoringDiagnostic
  kind: 'poo-flow.module-authoring.diagnostic.v1
  module: #f
  role: #f
  code: #f
  subject: #f
  rule: #f
  recommendation: #f
  repair-operators: '()
  freedom: #f
  runtime-executed?: #f)

(.def ModuleAuthoringAdmission
  kind: 'poo-flow.module-authoring.admission.v1
  module: #f
  role: #f
  accepted?: #f
  diagnostics: '()
  runtime-executed?: #f)

;; : (-> Symbol [Symbol] (Maybe Symbol))
(def (poo-flow-module-authoring-forbidden-slot-verb slot verbs)
  (and (symbol? slot)
       (let* ((name (symbol->string slot))
              (plain (if (string-prefix? "." name)
                       (substring name 1 (string-length name))
                       name)))
         (find (lambda (verb)
                 (string-prefix?
                  (string-append (symbol->string verb) "-")
                  plain))
               verbs))))

;; : (-> PooModuleInterface PooModuleSourceRole Symbol PooModuleAuthoringDiagnostic)
(def (poo-flow-module-authoring-slot-diagnostic interface source-role slot)
  (.o (:: @ ModuleAuthoringDiagnostic)
      module: (poo-flow-module-interface-id interface)
      role: (.ref source-role 'identity)
      code: 'poo-domain-slot-must-be-noun
      subject: slot
      rule: 'native-poo-slot-algebra-only
      recommendation: 'rename-as-domain-noun-and-refine-native-slot
      repair-operators: (.ref source-role 'repair-operators)
      freedom: (.ref source-role 'freedom)))

;; : (-> PooModuleInterface PooModuleSourceRole SchemeDatum [PooModuleAuthoringDiagnostic])
(def (poo-flow-module-authoring-slot-diagnostics interface role datum)
  (filter-map
   (lambda (binding)
     (and (poo-flow-module-authoring-forbidden-slot-verb
           (car binding)
           (.ref role 'forbidden-slot-verbs))
          (poo-flow-module-authoring-slot-diagnostic
           interface role (car binding))))
   (poo-flow-poo-slot-authoring-datum-bindings datum)))

;; : (-> SchemeDatum [Symbol] (Maybe Symbol))
(def (poo-flow-module-authoring-forbidden-root-form datum forbidden)
  (cond
   ((not (pair? datum)) #f)
   ((memq (car datum) '(quote quasiquote syntax quasisyntax)) #f)
   ((and (symbol? (car datum)) (memq (car datum) forbidden)) (car datum))
   (else #f)))

;; : (-> PooModuleInterface PooModuleSourceRole SchemeDatum [PooModuleAuthoringDiagnostic])
(def (poo-flow-module-authoring-root-diagnostics interface source-role datum)
  (let (form
        (poo-flow-module-authoring-forbidden-root-form
         datum (.ref source-role 'forbidden-root-forms)))
    (if form
      (list
       (.o (:: @ ModuleAuthoringDiagnostic)
           module: (poo-flow-module-interface-id interface)
           role: (.ref source-role 'identity)
           code: 'poo-config-must-compose-maintained-values
           subject: form
           rule: 'root-config-composition-only
           recommendation: 'move-responsibility-to-selected-profile-owner
           repair-operators: (.ref source-role 'repair-operators)
           freedom: (.ref source-role 'freedom)))
      '())))

;; : (-> PooModuleInterface PooModuleSourceRole [PooModuleAuthoringDiagnostic] PooModuleAuthoringAdmission)
(def (poo-flow-module-authoring-admission interface source-role diagnostic-values)
  (.o (:: @ ModuleAuthoringAdmission)
      module: (poo-flow-module-interface-id interface)
      role: (.ref source-role 'identity)
      accepted?: (null? diagnostic-values)
      diagnostics: diagnostic-values))

(def (poo-flow-module-authoring-admit/common interface role datum)
  (poo-flow-module-authoring-admission
   interface role
   (poo-flow-module-authoring-slot-diagnostics interface role datum)))

(def (poo-flow-module-authoring-admit/config interface role datum)
  (poo-flow-module-authoring-admission
   interface role
   (append
    (poo-flow-module-authoring-slot-diagnostics interface role datum)
    (poo-flow-module-authoring-root-diagnostics interface role datum))))

;;; Executor strategy and SourceRole are independently extensible. Module
;;; packages can contribute a method bundle for a refined executor/role pair
;;; without extending a central role switch.
(def ModuleAuthoringAdmissionProtocol
  (poo-clos-generic-protocol 'module-system/authoring-admission))

(def ModuleAuthoringAdmissionGeneric
  (poo-clos-generic-function
   'module-authoring-admit 4
   protocol: ModuleAuthoringAdmissionProtocol))

(def ModuleAuthoringCommonMethod
  (poo-clos-method
   'module-authoring/common
   (list (poo-clos-prototype-specializer ModuleAuthoringExecutor.)
         (poo-clos-prototype-specializer ModuleSourceRole.)
         (poo-clos-prototype-specializer poo-flow-module-interface-prototype)
         (poo-clos-any-specializer))
   (lambda (_frame _executor role interface datum)
     (poo-flow-module-authoring-admit/common interface role datum))))

(def ModuleAuthoringConfigMethod
  (poo-clos-method
   'module-authoring/config
   (list (poo-clos-prototype-specializer ModuleAuthoringExecutor.)
         (poo-clos-prototype-specializer ConfigSourceRole.)
         (poo-clos-prototype-specializer poo-flow-module-interface-prototype)
         (poo-clos-any-specializer))
   (lambda (_frame _executor role interface datum)
     (poo-flow-module-authoring-admit/config interface role datum))))

(.defmethod-bundle ModuleAuthoringCoreMethods
  ModuleAuthoringAdmissionProtocol
  ModuleAuthoringCommonMethod
  ModuleAuthoringConfigMethod)

(poo-clos-compose-method-bundle
 ModuleAuthoringAdmissionGeneric
 ModuleAuthoringCoreMethods)

;; : (-> PooModuleInterface Symbol PooModuleSourceRole)
(def (poo-flow-module-authoring-role interface role-name)
  (unless (poo-flow-module-interface? interface)
    (error "module authoring admission requires a POO Module Interface"
           interface))
  (let (authoring (poo-flow-module-interface-authoring interface))
    (unless (.slot? authoring role-name)
      (error "module authoring Profile does not define the requested source role"
             role-name))
    (.ref authoring role-name)))

;; : (-> PooModuleInterface Symbol SchemeDatum PooModuleAuthoringAdmission)
(def (poo-flow-module-authoring-admit-datum interface role-name datum)
  (let* ((authoring (poo-flow-module-interface-authoring interface))
         (executor (.ref authoring 'executor))
         (role (poo-flow-module-authoring-role interface role-name)))
    (poo-clos-call ModuleAuthoringAdmissionGeneric
                   executor role interface datum)))

;; : (-> PooModuleInterface Symbol InputPort PooModuleAuthoringAdmission)
(def (poo-flow-module-authoring-admit-port interface role-name port)
  (let loop ((diagnostics '()))
    (let (datum (read port))
      (if (eof-object? datum)
        (poo-flow-module-authoring-admission
         interface
         (poo-flow-module-authoring-role interface role-name)
         (reverse diagnostics))
        (let (admission
              (poo-flow-module-authoring-admit-datum
               interface role-name datum))
          (loop
           (foldl cons diagnostics
                  (.ref admission 'diagnostics))))))))

(def (poo-flow-module-authoring-admission? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) 'poo-flow.module-authoring.admission.v1)))

(def (poo-flow-module-authoring-admission-accepted? admission)
  (.ref admission 'accepted?))

(def (poo-flow-module-authoring-admission-diagnostics admission)
  (.ref admission 'diagnostics))
