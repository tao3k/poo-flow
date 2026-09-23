;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/test check-equal? test-case test-suite)
        :poo-flow/src/module-system/authoring/interface
        (only-in :poo-flow/src/module-system/poo-clos/interface
                 poo-clos-compute-applicable-methods)
        (only-in :poo-flow/src/module-system/observability/module-presentation
                 poo-flow-poo-slot-authoring-file-observations
                 poo-flow-poo-slot-authoring-diagnostics)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface
                 poo-flow-module-interface-authoring))

(export module-authoring-contract-test)

(def test-module-interface
  (poo-flow-module-interface
   "test-module"
   (.o)
   '((owner . module-authoring-contract-test))))

(def (first-diagnostic admission)
  (car (poo-flow-module-authoring-admission-diagnostics admission)))

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

   (test-case "the authoring Contract passes its own lazy-slot observation"
     (check-equal?
      (poo-flow-poo-slot-authoring-diagnostics
       (poo-flow-poo-slot-authoring-file-observations
        'module-authoring-contract
        "src/module-system/authoring/contracts.ss"))
      '()))))
