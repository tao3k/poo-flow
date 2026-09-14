;;; -*- Gerbil -*-
;;; Boundary: workflow presentation uses one native POO projection constructor.

(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :asp-gerbil-scheme/benchmark-api
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run/result)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-settings
                 pooFlowUserConfig)
        (only-in :poo-flow/src/user-interface/presentation-config
                 pooFlowUserConfigPresentation)
        (only-in :poo-flow/user-interface/custom/my-module/cases/cicd-owner
                 poo-flow-custom-my-module-cicd-module
                 poo-flow-custom-my-module-funflow-cicd-case))

(export workflow-presentation-native-projection-performance-test)

(def workflow-presentation-native-projection-fixture
  (call-with-input-file
   "t/scenarios/performance/workflow-presentation-native-projection/benchmark.ss"
   read))

(def (workflow-presentation-native-projection-summary)
  (let (presentation
        (pooFlowUserConfigPresentation
         (pooFlowUserConfig
          (append poo-flow-custom-my-module-cicd-module
                  poo-flow-custom-my-module-funflow-cicd-case)
          (poo-flow-settings))))
    (list
     (cons 'pipeline-count
           (.ref presentation 'workflow-cicd-pipeline-count))
     (cons 'manifest-count
           (.ref presentation
                 'workflow-cicd-runtime-command-manifest-summary-count))
     (cons 'handoff-abi-count
           (.ref presentation
                 'workflow-cicd-marlin-runtime-handoff-abi-count))
     (cons 'agreement-valid?
           (.ref presentation
                 'workflow-cicd-runtime-command-manifest-agreement-valid?))
     (cons 'runtime-executed (.ref presentation 'runtime-executed)))))

(def (workflow-presentation-native-projection-ref row key)
  (let (entry (assq key row))
    (and entry (cdr entry))))

(def workflow-presentation-native-projection-performance-test
  (test-suite "workflow presentation native projection performance"
    (test-case "keeps one native workflow projection inside the fixed gate"
      (let-values (((receipt summary)
                    (benchmark-run/result
                     workflow-presentation-native-projection-fixture
                     workflow-presentation-native-projection-summary)))
        (check-equal?
         (benchmark-fixture-contract-pass?
          workflow-presentation-native-projection-fixture)
         #t)
        (check-equal?
         (workflow-presentation-native-projection-ref summary 'pipeline-count)
         1)
        (check-equal?
         (workflow-presentation-native-projection-ref summary 'manifest-count)
         3)
        (check-equal?
         (workflow-presentation-native-projection-ref summary 'handoff-abi-count)
         1)
        (check-equal?
         (workflow-presentation-native-projection-ref summary 'agreement-valid?)
         #t)
        (check-equal?
         (workflow-presentation-native-projection-ref summary 'runtime-executed)
         #f)
        (display "[poo-flow-benchmark] workflow-presentation-native-projection ")
        (write receipt)
        (newline)
        (force-output)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
