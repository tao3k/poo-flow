;;; -*- Gerbil -*-
;;; Boundary: custom user-interface scenarios keep a real performance fixture.
;;; Invariant: user modules stay POO-native; benchmark contracts live under t/.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :std/sugar foldl)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :clan/poo/object .ref .slot? object?)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection?)
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/modules/session/config
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-case
                 poo-flow-custom-my-module-funflow-cicd-case
                 poo-flow-custom-my-module-loop-engine-case
                 poo-flow-custom-my-module-poo-introspection-case
                 poo-flow-custom-my-module-tool-core-case
                 poo-flow-custom-my-module-memory-core-case
                 poo-flow-custom-my-module-durable-runtime-store-handoff-case
                 poo-flow-custom-my-module-durable-runtime-store-operations-case
                 poo-flow-custom-my-module-durable-operation-bridge-case))

(export user-interface-custom-scenario-batch-performance-test)

(load! "../user-interface/custom/my-module/cases/session-policy")
(load! "../user-interface/custom/my-module/cases/session-transform")
(load! "../user-interface/custom/my-module/cases/session-registry")
(load! "../user-interface/custom/my-module/cases/session-agent-graph")
(load! "../user-interface/custom/my-module/cases/session-communication")
(load! "../user-interface/custom/my-module/cases/session-selector")
(load! "../user-interface/custom/my-module/cases/session-materialization")
(load! "../user-interface/custom/my-module/cases/session-agent-param")
(load! "../user-interface/custom/my-module/cases/session-memory-durable")
(load! "../user-interface/custom/my-module/cases/durable-recovery")

;; : String
(def user-interface-custom-scenario-batch-fixture-path
  "t/scenarios/performance/user-interface-custom-scenario-batch/benchmark.ss")

;; : CustomScenarioBatchFixture
(def user-interface-custom-scenario-batch-fixture
  (call-with-input-file user-interface-custom-scenario-batch-fixture-path read))

;; : [CustomScenarioCasePair]
(def (custom-user-interface-scenario-cases)
  (list
   (cons 'cicd poo-flow-custom-my-module-cicd-case)
   (cons 'funflow-cicd poo-flow-custom-my-module-funflow-cicd-case)
   (cons 'loop-engine poo-flow-custom-my-module-loop-engine-case)
   (cons 'poo-introspection poo-flow-custom-my-module-poo-introspection-case)
   (cons 'session-transform poo-flow-custom-module-session-transform-case)
   (cons 'session-policy poo-flow-custom-module-session-policy-case)
   (cons 'session-registry poo-flow-custom-module-session-registry-case)
   (cons 'session-agent-graph poo-flow-custom-module-session-agent-graph-case)
   (cons 'session-communication
         poo-flow-custom-module-session-communication-case)
   (cons 'session-selector poo-flow-custom-module-session-selector-case)
   (cons 'session-materialization
         poo-flow-custom-module-session-materialization-case)
   (cons 'session-agent-param
         poo-flow-custom-module-session-agent-param-case)
   (cons 'session-memory-durable
         poo-flow-custom-module-session-memory-durable-case)
   (cons 'tool-core poo-flow-custom-my-module-tool-core-case)
   (cons 'memory-core poo-flow-custom-my-module-memory-core-case)
   (cons 'durable-recovery poo-flow-custom-module-durable-recovery-case)
   (cons 'durable-runtime-store-handoff
         poo-flow-custom-my-module-durable-runtime-store-handoff-case)
   (cons 'durable-runtime-store-operations
         poo-flow-custom-my-module-durable-runtime-store-operations-case)
   (cons 'durable-operation-bridge
         poo-flow-custom-my-module-durable-operation-bridge-case)))

;; : (-> CustomScenarioRowValue Bool)
(def (custom-scenario-alist-row? value)
  (and (list? value)
       (pair? value)
       (pair? (car value))
       (symbol? (caar value))))

;; : (-> CustomScenarioRowValue Bool)
(def (custom-scenario-row? value)
  (or (object? value)
      (custom-scenario-alist-row? value)))

;; : (-> CustomScenarioRow CustomScenarioRowKey MaybeValue)
(def (custom-scenario-row-ref value key)
  (cond
   ((and (object? value) (.slot? value key))
    (.ref value key))
   ((custom-scenario-alist-row? value)
    (let (entry (assoc key value))
      (and entry (cdr entry))))
   (else #f)))

;; : (-> CustomScenarioRowValue MaybeList)
(def (custom-scenario-module-config-rows value)
  (if (and (pair? value)
           (poo-flow-user-module-selection? (car value)))
    (let (entry
          (poo-flow-user-module-selection-flag-entry (car value) ':config))
      (and entry (cdr entry)))
    #f))

;; : (-> CustomScenarioRowValue Integer)
(def (custom-scenario-row-count value)
  (let (config-rows (custom-scenario-module-config-rows value))
    (cond
     (config-rows (custom-scenario-row-count/list config-rows))
     ((custom-scenario-row? value) 1)
     ((pair? value) (custom-scenario-row-count/list value))
     (else 0))))

;; : (-> [CustomScenarioRowValue] Integer)
(def (custom-scenario-row-count/list values)
  (foldl (lambda (value count)
           (+ count (custom-scenario-row-count value)))
         0
         values))

;; : (-> CustomScenarioRowValue [Bool])
(def (custom-scenario-runtime-flags value)
  (let (config-rows (custom-scenario-module-config-rows value))
    (cond
     (config-rows
      (custom-scenario-runtime-flags/list config-rows))
     ((and (object? value) (.slot? value 'runtime-executed))
      (list (.ref value 'runtime-executed)))
     ((custom-scenario-alist-row? value)
      (let (entry (assoc 'runtime-executed value))
        (if entry
          (list (cdr entry))
          '())))
     ((list? value)
      (custom-scenario-runtime-flags/list value))
     (else '()))))

;; : (-> [CustomScenarioRowValue] [Bool])
(def (custom-scenario-runtime-flags/list values)
  (foldl (lambda (value flags)
           (append flags (custom-scenario-runtime-flags value)))
         '()
         values))

;; : (-> [Bool] Bool)
(def (custom-scenario-runtime-clean? flags)
  (cond
   ((null? flags) #t)
   ((car flags) #f)
   (else (custom-scenario-runtime-clean? (cdr flags)))))

;; : (-> [CustomScenarioCasePair] Integer)
(def (custom-scenario-case-row-count cases)
  (foldl (lambda (entry count)
           (+ count (custom-scenario-row-count (cdr entry))))
         0
         cases))

;; : (-> [CustomScenarioCasePair] [Bool])
(def (custom-scenario-case-runtime-flags cases)
  (foldl (lambda (entry flags)
           (append flags (custom-scenario-runtime-flags (cdr entry))))
         '()
         cases))

;; : (-> [CustomScenarioCasePair] [CustomScenarioCaseName])
(def (custom-scenario-case-names cases)
  (map car cases))

;; : (-> CustomScenarioSummary CustomScenarioSummaryKey MaybeValue)
(def (custom-scenario-summary-ref row key)
  (let (entry (assoc key row))
    (and entry (cdr entry))))

;; : (-> CustomScenarioBatchSummary)
(def (custom-user-interface-scenario-batch-summary)
  (let* ((cases (custom-user-interface-scenario-cases))
         (runtime-flags (custom-scenario-case-runtime-flags cases)))
    (list
     (cons 'case-count (length cases))
     (cons 'case-names (custom-scenario-case-names cases))
     (cons 'row-count (custom-scenario-case-row-count cases))
     (cons 'runtime-flag-count (length runtime-flags))
     (cons 'runtime-executed?
           (not (custom-scenario-runtime-clean? runtime-flags)))
     (cons 'benchmark-surface 't/scenarios/performance)
     (cons 'user-interface-benchmark-payload? #f))))

;; : (-> CustomScenarioBatchSummary ReceiptDisplayResult)
(def (custom-scenario-display-receipt receipt)
  (display "[poo-flow-benchmark] user-interface-custom-scenario-batch ")
  (write receipt)
  (newline)
  (force-output))

;; : TestSuite
(def user-interface-custom-scenario-batch-performance-test
  (test-suite "custom user-interface scenario batch performance"
    (test-case "keeps custom scenario aggregation inside benchmark contract"
      (let* ((summary (custom-user-interface-scenario-batch-summary))
             (receipt
              (benchmark-run
               user-interface-custom-scenario-batch-fixture
               custom-user-interface-scenario-batch-summary)))
        (check-equal?
         (benchmark-fixture-contract-pass?
          user-interface-custom-scenario-batch-fixture)
         #t)
        (check-equal? (custom-scenario-summary-ref summary 'case-count) 19)
        (check-equal?
         (custom-scenario-summary-ref summary 'runtime-executed?)
         #f)
        (check-equal?
         (custom-scenario-summary-ref summary 'benchmark-surface)
         't/scenarios/performance)
        (check-equal?
         (custom-scenario-summary-ref summary 'user-interface-benchmark-payload?)
         #f)
        (custom-scenario-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))
    (test-case "ignores dotted selection-count rows as runtime flags"
      (check-equal?
       (custom-scenario-runtime-flags '((memory/project) . 1))
       '()))))
