;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: invalid sandbox-agreement presentation qualification.
;;; Invariant: this gate expands only the sandbox and loop fixture it diagnoses.

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

(export user-interface-presentation-sandbox-doctor-test)

(def (sandbox-doctor-alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else (sandbox-doctor-alist-value key (cdr entries)))))

(def (sandbox-doctor-diagnostic-code-member? code diagnostics)
  (cond
   ((null? diagnostics) #f)
   ((equal? code
            (sandbox-doctor-alist-value 'code (car diagnostics)))
    #t)
   (else
    (sandbox-doctor-diagnostic-code-member? code (cdr diagnostics)))))

;;; This profile is resolvable but not handoff-ready: it declares filesystem
;;; capability without a filesystem resource boundary.
(def user-interface-invalid-sandbox-resource-policy
  '((cpu . 2)
    (memory . "4Gi")
    (timeout-ms . 300000)))

(def user-interface-invalid-sandbox-metadata
  '((intent . invalid-sandbox-profile)
    (scope . test)))

(def user-interface-invalid-sandbox-profile-module
  (use-module nono-sandbox
    (.def (ci/build @ nono-sandbox-profile
                    network capabilities resources metadata)
      network: (deny-network)
      capabilities: '(filesystem-read process-run)
      resources: user-interface-invalid-sandbox-resource-policy
      metadata: => (lambda (super-metadata)
                     (append super-metadata
                             user-interface-invalid-sandbox-metadata)))))

(def user-interface-invalid-sandbox-loop-module
  (use-module loop-engine
    :config
    (.def (invalid-sandbox-loop @ loop-engine-use-case name workflow)
      name: 'invalid-sandbox-loop
      workflow: 'funflow-cicd)
    (.def (invalid-sandbox-loop-sandbox @ loop-engine-sandbox profile)
      profile: 'ci/build)
    (.def (invalid-sandbox-loop-runtime @ loop-engine-runtime capabilities)
      capabilities: '(+manifest-handoff))
    (.def (invalid-sandbox-loop-profile @ loop-engine-profile
                                        use-case sandbox runtime)
      use-case: invalid-sandbox-loop
      sandbox: invalid-sandbox-loop-sandbox
      runtime: invalid-sandbox-loop-runtime)))

(def user-interface-invalid-sandbox-profile
  (pooFlowUserProfile
   'invalid-sandbox
   (list user-interface-invalid-sandbox-profile-module
         user-interface-invalid-sandbox-loop-module)
   (pooFlowDefaultUserSettings 'invalid-sandbox)
   poo-flow-default-user-setting-keys))

(def user-interface-presentation-sandbox-doctor-test
  (test-suite "poo-flow sandbox-agreement presentation doctor"
    (test-case "doctors invalid loop-engine sandbox profile agreements"
      (let* ((doctor-report
              (pooFlowUserProfileDoctor
               user-interface-invalid-sandbox-profile))
             (presentation
              (pooFlowUserProfileDoctorPresentation
               user-interface-invalid-sandbox-profile))
             (diagnostics (.ref presentation 'profile-diagnostics))
             (sandbox-agreement
              (car (.ref presentation
                         'loop-engine-sandbox-handoff-agreements))))
        (check-equal? (.ref doctor-report 'doctor-status) 'error)
        (check-equal? (.ref doctor-report 'doctor-ok) #f)
        (check-equal? (.ref doctor-report 'diagnostic-count) 1)
        (check-equal? (.ref presentation 'doctor-status) 'error)
        (check-equal? (.ref presentation 'diagnostic-count) 1)
        (check-equal?
         (sandbox-doctor-diagnostic-code-member?
          'invalid-loop-engine-sandbox-handoff diagnostics)
         #t)
        (check-equal?
         (sandbox-doctor-alist-value 'valid? sandbox-agreement)
         #f)
        (check-equal?
         (sandbox-doctor-alist-value
          'invalid-runtime-summary-count sandbox-agreement)
         1)
        (check-equal?
         (map (lambda (row) (sandbox-doctor-alist-value 'code row))
              (sandbox-doctor-alist-value 'diagnostics sandbox-agreement))
         '(invalid-sandbox-runtime-summaries))
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))))
