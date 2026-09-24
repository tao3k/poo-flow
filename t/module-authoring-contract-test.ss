;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .cc .o .ref)
        (only-in :clan/poo/mop TypeError?)
        (only-in :std/test check-equal? check-exception test-case test-suite)
        :poo-flow/src/module-system/authoring/interface
        (only-in :poo-flow/src/module-system/poo-clos/interface
                 poo-clos-call
                 poo-clos-call-next-method
                 poo-clos-compose-method-bundle
                 poo-clos-compute-applicable-methods
                 poo-clos-generic-function
                 poo-clos-method
                 poo-clos-method-bundle
                 poo-clos-prototype-specializer
                 poo-clos-any-specializer)
        (only-in :poo-flow/src/module-system/observability/module-presentation
                 poo-flow-poo-slot-authoring-file-observations
                 poo-flow-poo-slot-authoring-diagnostics)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface
                 poo-flow-module-interface-authoring
                 poo-flow-module-interface-prototype)
        (only-in :poo-flow/src/module-system/loader/collection
                 make-poo-flow-module-source-collection
                 poo-flow-module-source-collection-role-entrypoints)
        (only-in :poo-flow/src/module-system/semantic-module/objects
                 ModuleAuthoringExecutor.
                 ModuleSourceRole.
                 ObjectsSourceRole.
                 poo-flow-default-module-authoring-profile))

(export module-authoring-contract-test)

(def test-module-interface
  (poo-flow-module-interface
   "test-module"
   (.o)
   '((owner . module-authoring-contract-test))))

(def (first-diagnostic admission)
  (car (poo-flow-module-authoring-admission-diagnostics admission)))

;;; A vertical package refines native prototypes and contributes one CLOS
;;; method bundle.  It does not register a parallel role table or evaluator.
(def ClinicalAuthoringExecutor.
  (.o (:: @ ModuleAuthoringExecutor.)
      identity: 'module-authoring/clinical-executor))

(def ClinicalObjectsSourceRole.
  (.o (:: @ ObjectsSourceRole.)
      identity: 'clinical-objects))

(def ClinicalModuleInterface.
  (.o (:: @ poo-flow-module-interface-prototype)))

(def ClinicalAuthoringMethod
  (poo-clos-method
   'module-authoring/clinical
   (list (poo-clos-prototype-specializer ClinicalAuthoringExecutor.)
         (poo-clos-prototype-specializer ClinicalObjectsSourceRole.)
         (poo-clos-prototype-specializer ClinicalModuleInterface.)
         (poo-clos-any-specializer))
   (lambda (frame _executor _role _interface _datum)
     (.cc (poo-clos-call-next-method frame)
          'vertical-owner 'clinical))))

(def TestAuthoringCommonMethod
  (poo-clos-method
   'module-authoring/test-common
   (list (poo-clos-prototype-specializer ModuleAuthoringExecutor.)
         (poo-clos-prototype-specializer ModuleSourceRole.)
         (poo-clos-prototype-specializer poo-flow-module-interface-prototype)
         (poo-clos-any-specializer))
   (lambda (_frame _executor role interface _datum)
     (.o kind: 'poo-flow.module-authoring.admission.v1
         module: (.ref interface 'id)
         role: (.ref role 'identity)
         accepted?: #t
         diagnostics: '()
         runtime-executed?: #f))))

(def TestAuthoringCoreMethods
  (poo-clos-method-bundle
   'module-authoring/test-core
   ModuleAuthoringAdmissionProtocol
   (list TestAuthoringCommonMethod)))

(def ClinicalAuthoringMethods
  (poo-clos-method-bundle
   'module-authoring/clinical
   ModuleAuthoringAdmissionProtocol
   (list ClinicalAuthoringMethod)))

(def module-authoring-contract-test
  (test-suite
   "POO Module Interface role authoring Contract"

   (test-case "native Interface, executor, and role axes are CLOS-applicable"
     (let* ((authoring (poo-flow-module-interface-authoring
                        test-module-interface))
            (arguments
             (list (.ref authoring 'executor)
                   (poo-flow-module-authoring-role
                    test-module-interface 'objects)
                   test-module-interface
                   '(.o))))
       (check-equal?
        (length
         (apply poo-clos-compute-applicable-methods
                ModuleAuthoringAdmissionGeneric arguments))
        1)))

   (test-case "a vertical method bundle refines all three native POO axes"
     (let* ((authoring
             (.cc (poo-flow-default-module-authoring-profile)
                  'executor (.o (:: @ ClinicalAuthoringExecutor.))
                  'objects (.o (:: @ ClinicalObjectsSourceRole.))))
            (interface
             (.o (:: @ ClinicalModuleInterface.)
                 id: "clinical-module"
                 schemas: (.o)
                 authoring: authoring
                 metadata: '()))
            (generic
             (poo-clos-generic-function
              'module-authoring-admit/clinical 4
              protocol: ModuleAuthoringAdmissionProtocol)))
       (poo-clos-compose-method-bundle generic TestAuthoringCoreMethods)
       (poo-clos-compose-method-bundle generic ClinicalAuthoringMethods)
       (let (admission
             (poo-clos-call
              generic
              (.ref authoring 'executor)
              (.ref authoring 'objects)
              interface
              '(.def ClinicalCase (events =>.+ (.o review: required)))))
         (check-equal?
          (poo-flow-module-authoring-admission-accepted? admission) #t)
         (check-equal? (.ref admission 'vertical-owner) 'clinical))))

   (test-case "Interface rejects an invalid authoring Profile immediately"
     (check-exception
      (poo-flow-module-interface
       "invalid-authoring" (.o) '() authoring: (.o))
      TypeError?))

   (test-case "admits native noun slots and leaves algorithms open"
     (let (admission
           (poo-flow-module-authoring-admit-datum
            test-module-interface
            'objects
            '(.def (ReviewedCase @ PrescriptionCase)
               (events =>.+ (.o review: ClinicalReviewEvent)))))
       (check-equal?
        (poo-flow-module-authoring-admission-accepted? admission) #t)
       (check-equal?
        (poo-flow-module-authoring-admission-diagnostics admission) '())))

   (test-case "rejects a command-shaped domain slot with an actionable repair"
     (let* ((admission
             (poo-flow-module-authoring-admit-datum
              test-module-interface
              'objects
              '(.def BrokenCase
                 (.add-event (.o prescription: PrescriptionEvent)))))
            (diagnostic (first-diagnostic admission)))
       (check-equal?
        (poo-flow-module-authoring-admission-accepted? admission) #f)
       (check-equal? (.ref diagnostic 'code)
                     'poo-domain-slot-must-be-noun)
       (check-equal? (.ref diagnostic 'role) 'objects)
       (check-equal? (.ref diagnostic 'subject) '.add-event)
       (check-equal? (.ref diagnostic 'repair-operators)
                     '(? => =>.+ override))
       (check-equal? (.ref diagnostic 'freedom) 'open-native-poo)))

   (test-case "config role adds its own composition-only method"
     (let* ((admission
             (poo-flow-module-authoring-admit-datum
              test-module-interface
              'config
              '(stage production)))
            (diagnostic (first-diagnostic admission)))
       (check-equal?
        (poo-flow-module-authoring-admission-accepted? admission) #f)
       (check-equal? (.ref diagnostic 'code)
                     'poo-config-must-compose-maintained-values)
       (check-equal? (.ref diagnostic 'subject) 'stage)
       (check-equal? (.ref diagnostic 'freedom) 'composition-only)))

   (test-case "unknown roles fail at the Interface Profile boundary"
     (check-equal?
      (with-catch
       (lambda (_failure) #t)
       (lambda ()
         (poo-flow-module-authoring-admit-datum
          test-module-interface 'unknown '(.o))
         #f))
      #t))

   (test-case "loader blocks a command-slot module before exposing its Interface"
     (let (collection
           (make-poo-flow-module-source-collection
            'invalid-authoring-fixture 'test
            "t/fixtures/module-authoring-invalid" "modules"))
       (check-exception
        (poo-flow-module-source-collection-role-entrypoints
         collection 'interface)
        true)))

   (test-case "the authoring Contract passes its own lazy-slot observation"
     (check-equal?
      (poo-flow-poo-slot-authoring-diagnostics
       (poo-flow-poo-slot-authoring-file-observations
        'module-authoring-contract
        "src/module-system/authoring/contracts.ss"))
      '()))))
