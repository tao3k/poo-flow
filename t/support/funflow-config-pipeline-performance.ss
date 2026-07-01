;;; -*- Gerbil -*-
;;; Boundary: Funflow user-interface pipeline benchmark helpers.

(import (only-in :clan/poo/object .ref)
        :poo-flow/t/support/performance
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/src/module-system/presentation-config
                 pooFlowUserConfigPresentation))

(load "user-interface/custom/my-module/config.ss")

(export funflow-config-pipeline-scenario-count
        funflow-performance-ref
        funflow-performance-summary
        funflow-performance-expected-runtime-values
        funflow-performance-summary-contract-pass?)

;; : Integer
(def funflow-config-pipeline-scenario-count 32)

;; : (-> Alist Symbol MaybeValue)
(def (funflow-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> [Integer] Integer)
(def (funflow-performance-sum values)
  (cond
   ((null? values) 0)
   (else (+ (car values)
            (funflow-performance-sum (cdr values))))))

;; : (-> Unit PooUserConfig)
(def (funflow-performance-user-config)
  (pooFlowUserConfig
   (append (eval 'poo-flow-custom-my-module-cicd-module)
           (eval 'poo-flow-custom-my-module-funflow-cicd-case))
   (poo-flow-settings)))

;; : (-> PooUserConfig Integer POOObject)
(def (funflow-performance-presentation config _index)
  (pooFlowUserConfigPresentation config))

;; : (-> POOObject Alist)
(def (funflow-performance-presentation-summary presentation)
  (let* ((bundle
          (.ref presentation
                'workflow-cicd-marlin-handoff-receipt-bundle)))
    (list
     (cons 'pipeline-count
           (.ref presentation 'workflow-cicd-pipeline-count))
     (cons 'runtime-command-manifest-map-count
           (.ref presentation
                 'workflow-cicd-runtime-command-manifest-map-count))
     (cons 'runtime-command-manifest-summary-count
           (.ref presentation
                 'workflow-cicd-runtime-command-manifest-summary-count))
     (cons 'marlin-runtime-handoff-abi-count
           (.ref presentation
                 'workflow-cicd-marlin-runtime-handoff-abi-count))
     (cons 'receipt-count
           (funflow-performance-ref bundle 'receipt-count))
     (cons 'runtime-executed
           (.ref presentation 'runtime-executed)))))

;; : (-> Integer [Boolean])
(def (funflow-performance-expected-runtime-values count)
  (poo-flow-performance-build-list count (lambda (_index) #f)))

;; : (-> Integer Alist)
(def (funflow-performance-summary count)
  (let* ((config (funflow-performance-user-config))
         (presentations
          (poo-flow-performance-build-list
           count
           (lambda (index)
             (funflow-performance-presentation config index))))
         (summaries
          (map funflow-performance-presentation-summary presentations)))
    (list
     (cons 'config-count count)
     (cons 'pipeline-count
           (funflow-performance-sum
            (map (lambda (summary)
                   (funflow-performance-ref summary 'pipeline-count))
                 summaries)))
     (cons 'runtime-command-manifest-map-count
           (funflow-performance-sum
            (map (lambda (summary)
                   (funflow-performance-ref
                    summary
                    'runtime-command-manifest-map-count))
                 summaries)))
     (cons 'runtime-command-manifest-summary-count
           (funflow-performance-sum
            (map (lambda (summary)
                   (funflow-performance-ref
                    summary
                    'runtime-command-manifest-summary-count))
                 summaries)))
     (cons 'marlin-runtime-handoff-abi-count
           (funflow-performance-sum
            (map (lambda (summary)
                   (funflow-performance-ref summary
                                            'marlin-runtime-handoff-abi-count))
                 summaries)))
     (cons 'receipt-count
           (funflow-performance-sum
            (map (lambda (summary)
                   (funflow-performance-ref summary 'receipt-count))
                 summaries)))
     (cons 'runtime-executed-values
           (map (lambda (summary)
                  (funflow-performance-ref summary 'runtime-executed))
                summaries)))))

;; : (-> Alist Boolean)
(def (funflow-performance-summary-contract-pass? summary)
  (and (equal? (funflow-performance-ref summary 'config-count)
               funflow-config-pipeline-scenario-count)
       (equal? (funflow-performance-ref summary 'pipeline-count)
               funflow-config-pipeline-scenario-count)
       (equal? (funflow-performance-ref
                summary
                'runtime-command-manifest-map-count)
               funflow-config-pipeline-scenario-count)
       (equal? (funflow-performance-ref
                summary
                'runtime-command-manifest-summary-count)
               (* funflow-config-pipeline-scenario-count 3))
       (equal? (funflow-performance-ref summary
                                        'marlin-runtime-handoff-abi-count)
               funflow-config-pipeline-scenario-count)
       (equal? (funflow-performance-ref summary 'receipt-count)
               (* funflow-config-pipeline-scenario-count 3))
       (equal? (funflow-performance-ref summary 'runtime-executed-values)
               (funflow-performance-expected-runtime-values
                funflow-config-pipeline-scenario-count))))
