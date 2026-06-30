;;; -*- Gerbil -*-
;;; Boundary: Funflow user-interface pipeline scenario performance gate.
;;; Invariant: public authoring stays POO-native; handoff payloads serialize at
;;; presentation/ABI boundaries only.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module
                 poo-flow-custom-my-module-funflow-cicd-case))

(export funflow-config-pipeline-performance-test)

;; : String
(def funflow-config-pipeline-fixture-path
  "t/scenarios/performance/funflow-config-pipeline/benchmark.ss")

;; : Alist
(def funflow-config-pipeline-fixture
  (call-with-input-file funflow-config-pipeline-fixture-path read))

;; : Integer
(def funflow-config-pipeline-scenario-count 32)

;; : (-> Alist Symbol MaybeValue)
(def (funflow-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (funflow-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] funflow-config-pipeline ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> [Integer] Integer)
(def (funflow-performance-sum values)
  (cond
   ((null? values) 0)
   (else (+ (car values)
            (funflow-performance-sum (cdr values))))))

;; : (-> Unit PooUserConfig)
(def (funflow-performance-user-config)
  (pooFlowUserConfig
   (append poo-flow-custom-my-module-cicd-module
           poo-flow-custom-my-module-funflow-cicd-case)
   (poo-flow-settings)))

;; : (-> PooUserConfig Integer POOObject)
(def (funflow-performance-presentation config _index)
  (pooFlowUserConfigPresentation
   config))

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
                   (funflow-performance-ref
                    summary
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

;; : TestSuite
(def funflow-config-pipeline-performance-test
  (test-suite "funflow config pipeline performance"
    (test-case "keeps user-interface Funflow pipeline scenario inside benchmark contract"
      (let* ((summary
              (funflow-performance-summary
               funflow-config-pipeline-scenario-count))
             (receipt
              (benchmark-run
               funflow-config-pipeline-fixture
               (lambda ()
                 (funflow-performance-summary
                  funflow-config-pipeline-scenario-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? funflow-config-pipeline-fixture)
         #t)
        (check-equal?
         (funflow-performance-ref summary 'config-count)
         funflow-config-pipeline-scenario-count)
        (check-equal?
         (funflow-performance-ref summary 'pipeline-count)
         funflow-config-pipeline-scenario-count)
        (check-equal?
         (funflow-performance-ref summary
                                  'runtime-command-manifest-map-count)
         funflow-config-pipeline-scenario-count)
        (check-equal?
         (funflow-performance-ref summary
                                  'runtime-command-manifest-summary-count)
         (* funflow-config-pipeline-scenario-count 3))
        (check-equal?
         (funflow-performance-ref summary 'marlin-runtime-handoff-abi-count)
         funflow-config-pipeline-scenario-count)
        (check-equal?
         (funflow-performance-ref summary 'receipt-count)
         (* funflow-config-pipeline-scenario-count 3))
        (check-equal?
         (funflow-performance-ref summary 'runtime-executed-values)
         (poo-flow-performance-build-list
          funflow-config-pipeline-scenario-count
          (lambda (_index) #f)))
        (funflow-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
