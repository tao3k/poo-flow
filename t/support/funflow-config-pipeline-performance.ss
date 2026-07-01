;;; -*- Gerbil -*-
;;; Boundary: Funflow user-interface pipeline benchmark helpers.

(import (only-in :clan/poo/object .ref)
        :poo-flow/t/support/performance
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/src/module-system/presentation-config
                 pooFlowUserConfigPresentation))

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

;; : (-> [[PooUserModuleSelection]] PooUserConfig)
(def (funflow-performance-user-config module-bundles)
  (pooFlowUserConfig
   module-bundles
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

;; : (-> [[PooUserModuleSelection]] Integer Alist)
(def (funflow-performance-summary module-bundles count)
  (let (config (funflow-performance-user-config module-bundles))
    (let loop ((index 0)
               (pipeline-count 0)
               (runtime-command-manifest-map-count 0)
               (runtime-command-manifest-summary-count 0)
               (marlin-runtime-handoff-abi-count 0)
               (receipt-count 0)
               (runtime-executed-values-rev '()))
      (if (>= index count)
        (list
         (cons 'config-count count)
         (cons 'pipeline-count pipeline-count)
         (cons 'runtime-command-manifest-map-count
               runtime-command-manifest-map-count)
         (cons 'runtime-command-manifest-summary-count
               runtime-command-manifest-summary-count)
         (cons 'marlin-runtime-handoff-abi-count
               marlin-runtime-handoff-abi-count)
         (cons 'receipt-count receipt-count)
         (cons 'runtime-executed-values
               (reverse runtime-executed-values-rev)))
        (let (summary
              (funflow-performance-presentation-summary
               (funflow-performance-presentation config index)))
          (loop
           (+ index 1)
           (+ pipeline-count
              (funflow-performance-ref summary 'pipeline-count))
           (+ runtime-command-manifest-map-count
              (funflow-performance-ref
               summary
               'runtime-command-manifest-map-count))
           (+ runtime-command-manifest-summary-count
              (funflow-performance-ref
               summary
               'runtime-command-manifest-summary-count))
           (+ marlin-runtime-handoff-abi-count
              (funflow-performance-ref
               summary
               'marlin-runtime-handoff-abi-count))
           (+ receipt-count
              (funflow-performance-ref summary 'receipt-count))
           (cons (funflow-performance-ref summary 'runtime-executed)
                 runtime-executed-values-rev)))))))

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
