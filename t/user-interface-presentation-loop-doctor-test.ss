;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: invalid loop-result presentation qualification.
;;; Invariant: this gate expands only the loop-engine fixture it diagnoses.

(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/user-interface/init-syntax
        (only-in :poo-flow/src/user-interface/profile-core
                 poo-flow-default-user-setting-keys
                 pooFlowDefaultUserSettings
                 pooFlowUserProfile)
        (only-in :poo-flow/src/user-interface/profile-doctor
                 pooFlowUserProfileDoctor)
        (only-in :poo-flow/src/user-interface/profile-presentation-config
                 pooFlowUserProfileDoctorPresentation))

(export user-interface-presentation-loop-doctor-test)

(def (loop-doctor-alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else (loop-doctor-alist-value key (cdr entries)))))

(def (loop-doctor-diagnostic-code-member? code diagnostics)
  (cond
   ((null? diagnostics) #f)
   ((equal? code
            (loop-doctor-alist-value 'code (car diagnostics)))
    #t)
   (else
    (loop-doctor-diagnostic-code-member? code (cdr diagnostics)))))

;;; Invalid loop-engine result contracts exercise the profile doctor path,
;;; independently of the broad valid presentation fixture.
(def user-interface-invalid-loop-result-module
  (use-module loop-engine
    :config
    (.def (invalid-loop-result @ loop-engine-use-case name workflow)
      name: 'invalid-loop-result
      workflow: 'funflow-cicd)
    (.def (invalid-loop-result-human-audit @ loop-engine-human-audit actions)
      actions: '(+manual-gate))
    (.def (invalid-loop-result-contract @ loop-engine-result
                                        human-audit format required-fields)
      human-audit: 'bad-contract
      format: 'structured-alist
      required-fields: '())
    (.def (invalid-loop-result-runtime @ loop-engine-runtime capabilities)
      capabilities: '(+manifest-handoff))
    (.def (invalid-loop-result-profile @ loop-engine-profile
                                       use-case human-audit result runtime)
      use-case: invalid-loop-result
      human-audit: invalid-loop-result-human-audit
      result: invalid-loop-result-contract
      runtime: invalid-loop-result-runtime)))

(def user-interface-invalid-loop-result-profile
  (pooFlowUserProfile
   'invalid-loop-result
   (list user-interface-invalid-loop-result-module)
   (pooFlowDefaultUserSettings 'invalid-loop-result)
   poo-flow-default-user-setting-keys))

(def user-interface-presentation-loop-doctor-test
  (test-suite "poo-flow loop-result presentation doctor"
    (test-case "doctors invalid loop-engine result contracts"
      (let* ((doctor-report
              (pooFlowUserProfileDoctor
               user-interface-invalid-loop-result-profile))
             (presentation
              (pooFlowUserProfileDoctorPresentation
               user-interface-invalid-loop-result-profile))
             (diagnostics (.ref presentation 'profile-diagnostics))
             (result-contract
              (car (.ref presentation 'loop-engine-result-contracts))))
        (check-equal? (.ref doctor-report 'doctor-status) 'error)
        (check-equal? (.ref doctor-report 'doctor-ok) #f)
        (check-equal? (.ref doctor-report 'diagnostic-count) 1)
        (check-equal? (.ref presentation 'doctor-status) 'error)
        (check-equal? (.ref presentation 'diagnostic-count) 1)
        (check-equal?
         (loop-doctor-diagnostic-code-member?
          'invalid-loop-engine-result-contract diagnostics)
         #t)
        (check-equal? (loop-doctor-alist-value 'valid? result-contract) #f)
        (check-equal?
         (loop-doctor-alist-value 'diagnostic-count result-contract)
         1)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))))
