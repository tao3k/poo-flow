;;; -*- Gerbil -*-
;;; Boundary: tests inspect Funflow CI/CD runtime projection from user config.
;;; Invariant: projection remains declarative; no runtime adapter is executed.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module
                 poo-flow-custom-my-module-funflow-cicd-case)
        :poo-flow/t/user-interface-fixtures)

(export user-interface-cicd-runtime-projection-test)

;; : (-> Alist Symbol Value)
(def (user-interface-cicd-runtime-alist-ref entries key)
  (let (entry (assoc key entries))
    (if entry (cdr entry) #f)))

;; : (-> [Alist] Symbol MaybeAlist)
(def (user-interface-cicd-runtime-trace-stage trace stage)
  (cond
   ((null? trace) #f)
   ((equal? (user-interface-cicd-runtime-alist-ref (car trace) 'stage) stage)
    (car trace))
   (else
    (user-interface-cicd-runtime-trace-stage (cdr trace) stage))))

;; : (-> Unit PooUserConfig)
(def (user-interface-cicd-runtime-funflow-config)
  (pooFlowUserConfig
   (append poo-flow-custom-my-module-cicd-module
           poo-flow-custom-my-module-funflow-cicd-case)
   (poo-flow-settings)))

;;; This suite owns presentation-stage accounting and agreement failure shape;
;;; dependency graph row fidelity lives in the separate runtime graph owner.
;; : TestSuite
(def user-interface-cicd-runtime-projection-test
  (test-suite "poo-flow user interface cicd runtime projection"
    (test-case "traces workflow CI/CD projection stages"
      (let* ((presentation
              (pooFlowUserConfigPresentation
               (user-interface-cicd-runtime-funflow-config)))
             (trace (.ref presentation 'presentation-trace))
             (pipeline-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-pipelines))
             (readiness-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-runtime-readiness))
             (manifest-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-runtime-command-manifest-maps))
             (summary-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-runtime-command-manifest-summaries))
             (agreement-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-runtime-command-manifest-agreement))
             (receipt-step
              (user-interface-cicd-runtime-trace-stage
               trace
               'workflow-cicd-receipts)))
        (check-equal?
         (user-interface-cicd-runtime-alist-ref pipeline-step 'count)
         1)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref readiness-step 'count)
         1)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref manifest-step 'count)
         1)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref summary-step 'count)
         3)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref agreement-step 'count)
         1)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref receipt-step 'count)
         3)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref summary-step 'runtime-executed)
         #f)))
    (test-case "flags manifest summary mismatch before handoff"
      (let* ((presentation
              (pooFlowUserConfigPresentation
               (user-interface-cicd-runtime-funflow-config)))
             (manifest-maps
              (.ref presentation 'workflow-cicd-runtime-command-manifests))
             (manifest-summaries
              (.ref presentation
                    'workflow-cicd-runtime-command-manifest-summaries))
             (bad-summary
              (cons (cons 'argv '("wrong-gxpkg" "build"))
                    (car manifest-summaries)))
             (bad-agreement
              (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
               manifest-maps
               (cons bad-summary (cdr manifest-summaries))))
             (bad-row
              (car (user-interface-cicd-runtime-alist-ref bad-agreement 'rows)))
             (diagnostics
              (user-interface-cicd-runtime-alist-ref bad-agreement 'diagnostics))
             (row-diagnostics
              (user-interface-cicd-runtime-alist-ref bad-row 'diagnostics)))
        (check-equal?
         (user-interface-cicd-runtime-alist-ref bad-agreement 'valid?)
         #f)
        (check-equal?
         (user-interface-cicd-runtime-alist-ref bad-row 'argv-match?)
         #f)
        (check-equal? (not (not (member 'argv-mismatch diagnostics))) #t)
        (check-equal?
         (not (not (member 'argv-mismatch row-diagnostics)))
         #t)))))

(run-tests! user-interface-cicd-runtime-projection-test)
