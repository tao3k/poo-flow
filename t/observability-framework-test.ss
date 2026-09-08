;;; -*- Gerbil -*-
;;; Real Module admission -> native observation -> explanation -> upstream debug.
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :std/srfi/13 string-contains)
        (only-in :clan/base λ)
        (only-in :clan/poo/object .o .cc .ref .slot? .all-slots)
        (only-in :clan/poo/mop element? validate TypeError?)
        "../src/observability/interface.ss"
        "../src/observability/debug.ss"
        (only-in "../src/observability/types.ss" PooFlowObservabilityDiagnosticContract)
        (only-in "../src/observability/objects.ss" poo-flow-observability-diagnostic-record)
        (only-in "../src/module-system/types.ss"
                 poo-flow-contract-admit poo-flow-predicate-contract)
        "../src/module-system/semantic-module/objects.ss")
(export observability-framework-test)

(def (framework-id name) (poo-flow-observation-identity 'test name 'v1))
(def (framework-context (budget 256))
  (poo-flow-observation-context
   (framework-id 'event) (framework-id 'module) (framework-id 'generation)
   (list (framework-id 'parent))
   (poo-flow-observation-provenance
    (framework-id 'module-admission) (framework-id 'gerbil-poo) 'admission)
   detail-budget: budget))
(def (framework-module)
  (poo-flow-semantic-module (poo-flow-semantic-identity 'test 'module)))
(def (framework-contains? text value) (if (string-contains text value) #t #f))

(def observability-framework-test
  (test-suite "upstream-based POO observability framework"
    (test-case "real successful Module admission preserves correlation without raw subject"
      (let* ((context (framework-context)) (module (framework-module))
             (event (poo-flow-observe-contract-admission context SemanticModuleContract module))
             (facts (.ref event 'evidence)) (summary (poo-flow-observation-summary event)))
        (check-equal? (element? PooFlowObservationContract event) #t)
        (check-equal? (element? PooFlowAdmissionObservationContract event) #t)
        (check-equal? (element? SemanticModuleContract event) #f)
        (check-equal? (length (.all-slots module)) 4)
        (check-equal? (eq? (.ref event 'source) (.ref context 'source)) #t)
        (check-equal? (eq? (.ref event 'generation) (.ref context 'generation)) #t)
        (check-equal? (eq? (.ref event 'causes) (.ref context 'causes)) #t)
        (check-equal? (eq? (.ref event 'provenance) (.ref context 'provenance)) #t)
        (check-equal? (.ref facts 'accepted?) #t)
        (check-equal? (.slot? facts 'candidate) #f)
        (check-equal? (.slot? facts 'context) #f)
        (check-equal? (.ref summary 'failure-count) 0)))

    (test-case "missing and invalid responsibilities have native explanation paths"
      (let* ((context (framework-context))
             (missing (.o (:: @ SemanticModule.)
                          imports: (poo-flow-empty-imports)
                          capabilities: (poo-flow-empty-capabilities)
                          profiles: (poo-flow-empty-profiles)))
             (event (poo-flow-observe-contract-admission context SemanticModuleContract missing))
             (explanation (poo-flow-observation-explain event))
             (failure (car (.ref explanation 'failures))))
        (check-equal? (.ref explanation 'accepted?) #f)
        (check-equal? (.ref failure 'path) '(identity))
        (check-equal? (.ref failure 'code) 'missing-responsibility))
      (let* ((bad (.cc (framework-module) 'imports 'raw-list))
             (event (poo-flow-observe-contract-admission
                     (framework-context) SemanticModuleContract bad))
             (failure (car (.ref (poo-flow-observation-explain event) 'failures))))
        (check-equal? (.ref failure 'path) '(imports))
        (check-equal? (.ref failure 'code) 'prototype-mismatch)))

    (test-case "native ancestry rejection is not disguised as a field failure"
      (let* ((event (poo-flow-observe-contract-admission
                     (framework-context) SemanticModuleContract (.o identity: 'lookalike)))
             (failure (car (.ref (poo-flow-observation-explain event) 'failures))))
        (check-equal? (.ref failure 'path) '())
        (check-equal? (.ref failure 'code) 'prototype-mismatch)))

    (test-case "existing diagnostic API feeds the same observation framework"
      (let* ((diagnostic (poo-flow-observability-diagnostic-record
                          'error 'contract 'validator #f #f 'domain-denied
                          "synthetic diagnostic text" 'author))
             (good (poo-flow-observe-contract-admission
                    (framework-context) PooFlowObservabilityDiagnosticContract diagnostic))
             (bad (poo-flow-observe-contract-admission
                   (framework-context) PooFlowObservabilityDiagnosticContract
                   (.cc diagnostic 'severity 42)))
             (explanation (poo-flow-observation-explain bad)))
        (check-equal? (.ref (poo-flow-observation-summary good) 'accepted?) #t)
        (check-equal? (.ref explanation 'accepted?) #f)
        (check-equal? (.ref explanation 'contract) 'observability/diagnostic)
        (check-equal? (.ref (car (.ref explanation 'failures)) 'code)
                      'poo-flow.contract.obligation-failure)))

    (test-case "nested responsibility rejection retains the full path"
      (let* ((module (framework-module))
             (bad (.cc module 'identity (.cc (.ref module 'identity) 'name 42)))
             (event (poo-flow-observe-contract-admission
                     (framework-context) SemanticModuleContract bad))
             (failure (car (.ref (poo-flow-observation-explain event) 'failures))))
        (check-equal? (.ref failure 'path) '(identity name))
        (check-equal? (.ref failure 'contract) 'semantic-symbol)
        (check-equal? (.ref failure 'code) 'expected-symbol)))

    (test-case "source-owned obligation code survives without a central code registry"
      (let* ((contract (poo-flow-predicate-contract
                        'domain-specific symbol? (λ (_c _x) '(domain-policy-denied))))
             (event (poo-flow-observe-contract-admission (framework-context) contract 'value))
             (explanation (poo-flow-observation-explain event))
             (failure (car (.ref explanation 'failures))))
        (check-equal? (.ref failure 'code) 'domain-policy-denied)
        (check-equal? (.ref explanation 'obligation-count) 1)
        (check-equal? (.ref explanation 'classification-accepted?) #t)))

    (test-case "bounded detail inspection cannot change the semantic verdict"
      (let* ((bad (.cc (framework-module) 'imports 'invalid))
             (event (poo-flow-observe-contract-admission
                     (framework-context 0) SemanticModuleContract bad))
             (summary (poo-flow-observation-summary event)))
        (check-equal? (.ref summary 'accepted?) #f)
        (check-equal? (.ref summary 'detail-complete?) #f)
        (check-equal? (.ref summary 'inspected-count) 0)
        (check-equal? (.ref summary 'failure-count) 0)))

    (test-case "observation and explanation never evaluate lazy imports"
      (let* ((lazy-imports (.o (:: @ SemanticImports.)
                              (contributions (error "inspection forced imports"))))
             (module (poo-flow-semantic-module
                      (poo-flow-semantic-identity 'test 'lazy) imports: lazy-imports))
             (event (poo-flow-observe-contract-admission
                     (framework-context) SemanticModuleContract module))
             (port (open-output-string)))
        (check-equal? (.ref (poo-flow-observation-explain event) 'accepted?) #t)
        (check-equal? (.ref (poo-flow-observation-debug event port trace?: #t) 'accepted?) #t)))

    (test-case "producer is evaluated once and native explanation can be refined"
      (let* ((count 0)
             (contract (poo-flow-predicate-contract
                        'counted symbol? (λ (_candidate _context) (set! count (1+ count)) '())))
             (event (poo-flow-observe-contract-admission (framework-context) contract 'value))
             (specialized (.o (:: @ event) (.explain 'domain-specific-explanation))))
        (poo-flow-observation-explain event)
        (poo-flow-observation-summary event)
        (check-equal? count 1)
        (check-equal? (poo-flow-observation-explain specialized) 'domain-specific-explanation)
        (check-equal? (element? PooFlowObservationContract specialized) #t)))

    (test-case "forged verdicts and incomplete producer metadata are rejected"
      (let* ((receipt (poo-flow-contract-admit SemanticModuleContract 'invalid #f))
             (event (poo-flow-observe-admission-evidence (framework-context) receipt)))
        (check-exception
         (poo-flow-observe-admission-evidence (framework-context) (.cc receipt 'accepted? #t)) TypeError?)
        (check-exception
         (poo-flow-observe-admission-evidence (framework-context) (.cc receipt 'contract-identity 'forged)) TypeError?)
        (check-exception
         (validate PooFlowAdmissionObservationContract
                   (.cc event 'evidence (.cc (.ref event 'evidence) 'accepted? #t))) TypeError?)
        (check-exception
         (validate PooFlowAdmissionObservationContract
                   (.cc event 'evidence (.cc (.ref event 'evidence) 'failures '()))) TypeError?)
        (check-exception
         (poo-flow-observe-contract-admission (.o) SemanticModuleContract (framework-module)) TypeError?)))

    (test-case "cyclic supplied evidence is incomplete inspection, not a Module cycle verdict"
      (let* ((contract (poo-flow-predicate-contract 'denied symbol? (λ (_c _x) '(denied))))
             (receipt (poo-flow-contract-admit contract 'value #f))
             (cyclic (.o (:: self receipt) responsibility: 'cycle
                         (responsibility-evidence (list self))))
             (event (poo-flow-observe-admission-evidence (framework-context) cyclic))
             (summary (poo-flow-observation-summary event)))
        (check-equal? (.ref summary 'accepted?) #f)
        (check-equal? (.ref summary 'detail-complete?) #f)
        (check-equal? (.ref summary 'inspected-count) 1)))

    (test-case "upstream debug receives aggregates, never private candidate or custom renderer"
      (let* ((canary "SYNTHETIC-FRAMEWORK-PRIVATE-CANARY")
             (event (poo-flow-observe-contract-admission
                     (framework-context) SemanticModuleContract canary evaluation-context: canary))
             (specialized (.o (:: @ event)
                              (.summary (error canary))
                              (.explain canary)))
             (port (open-output-string)))
        (check-equal? (.ref (poo-flow-observation-debug specialized port trace?: #t) 'accepted?) #f)
        (let (output (get-output-string port))
          (check-equal? (framework-contains? output "admission-observation") #t)
          (check-equal? (framework-contains? output ">>>") #t)
          (check-equal? (framework-contains? output canary) #f)
          (check-equal? (framework-contains? output "generation") #f))))

    (test-case "invalid debug input fails closed before any output"
      (let ((port (open-output-string)))
        (check-exception (poo-flow-observation-debug "SYNTHETIC-PRIVATE" port)
                         PooFlowObservationProjectionError?)
        (check-equal? (get-output-string port) "")))

    (test-case "memory policy comparison is a pure native POO receipt"
      (let* ((policy
              (poo-flow-debug-memory-policy
               'unit heap-limit-bytes: 1000 live-growth-limit-bytes: 50))
             (before (poo-flow-debug-memory-sample 'unit 100 200 80 70 10))
             (within (poo-flow-debug-memory-sample 'unit 120 240 100 90 10))
             (growing (poo-flow-debug-memory-sample 'unit 180 400 160 140 20))
             (good (poo-flow-debug-memory-receipt policy before within))
             (bad (poo-flow-debug-memory-receipt policy before growing)))
        (check-equal? (element? PooFlowDebugMemoryPolicyContract policy) #t)
        (check-equal? (element? PooFlowDebugMemoryReceiptContract good) #t)
        (check-equal? (.ref good 'accepted?) #t)
        (check-equal? (.ref good 'live-growth-bytes) 20)
        (check-equal? (.ref bad 'accepted?) #f)
        (check-equal? (.ref bad 'reason) 'live-growth-limit-exceeded)))

    (test-case "effectful memory span emits only bounded scalar diagnostics"
      (let* ((limit 1152921504606846976)
             (policy
              (poo-flow-debug-memory-policy
               'native-span heap-limit-bytes: limit
               live-growth-limit-bytes: limit))
             (port (open-output-string)))
        (call-with-values
          (lambda ()
            (call-with-poo-flow-debug-memory-span
             policy 'native-span (lambda () 'completed) port: port emit?: #t))
          (lambda (value receipt)
            (check-equal? value 'completed)
            (check-equal? (.ref receipt 'accepted?) #t)
            (check-equal? (framework-contains?
                           (get-output-string port) "debug-memory-observation")
                          #t)))))

    (test-case "native memory monitor samples a running Scheme operation"
      (let* ((limit 1152921504606846976)
             (policy
              (poo-flow-debug-memory-policy
               'native-monitor heap-limit-bytes: limit
               live-growth-limit-bytes: limit
               sample-interval-milliseconds: 1))
             (port (open-output-string)))
        (call-with-values
          (lambda ()
            (call-with-poo-flow-debug-memory-monitor
             policy
             'native-monitor
             (lambda () (thread-sleep! 0.01) 'completed)
             port: port
             emit?: #t))
          (lambda (value receipt)
            (check-equal? value 'completed)
            (check-equal? (.ref receipt 'accepted?) #t)
            (check-equal? (.ref receipt 'phase) 'native-monitor)
            (check-equal? (framework-contains?
                           (get-output-string port) "debug-memory-observation")
                          #t)))))

    (test-case "native memory monitor stops a non-returning debug worker"
      (let* ((policy
              (poo-flow-debug-memory-policy
               'native-monitor-rejected
               heap-limit-bytes: 0
               live-growth-limit-bytes: 0
               sample-interval-milliseconds: 1))
             (captured #f))
        (with-catch
         (lambda (failure) (set! captured failure))
         (lambda ()
           (call-with-poo-flow-debug-memory-monitor
            policy
            'native-monitor-rejected
            (lambda ()
              (let loop ()
                (thread-sleep! 0.01)
                (loop))))))
        (check-equal? (PooFlowDebugMemoryAnomaly? captured) #t)
        (check-equal?
         (.ref (PooFlowDebugMemoryAnomaly-receipt captured) 'phase)
         'native-monitor-rejected)
        (check-equal?
         (.ref (PooFlowDebugMemoryAnomaly-receipt captured) 'reason)
         'heap-limit-exceeded)))

    (test-case "native memory monitor contains a lazy POO self-slot cycle"
      (let* ((initial (poo-flow-debug-memory-snapshot 'poo-self-slot-cycle))
             (policy
              (poo-flow-debug-memory-policy
               'poo-self-slot-cycle
               heap-limit-bytes: (+ (.ref initial 'heap-size-bytes) 67108864)
               live-growth-limit-bytes: 8388608
               sample-interval-milliseconds: 1))
             (captured #f))
        (with-catch
         (lambda (failure) (set! captured failure))
         (lambda ()
           (call-with-poo-flow-debug-memory-monitor
            policy
            'poo-self-slot-cycle
            (lambda ()
              (let (cycle (.o project-id: project-id))
                (.ref cycle 'project-id))))))
        (check-equal? (PooFlowDebugMemoryAnomaly? captured) #t)
        (check-equal?
         (.ref (PooFlowDebugMemoryAnomaly-receipt captured) 'accepted?)
         #f)
        (check-equal?
         (.ref (PooFlowDebugMemoryAnomaly-receipt captured) 'phase)
         'poo-self-slot-cycle)))

    (test-case "fail-closed checkpoint preserves its typed receipt"
      (let* ((policy
              (poo-flow-debug-memory-policy
               'rejected heap-limit-bytes: 0 live-growth-limit-bytes: 0))
             (baseline (poo-flow-debug-memory-snapshot 'rejected))
             (captured #f))
        (with-catch
         (lambda (failure) (set! captured failure))
         (lambda ()
           (poo-flow-debug-memory-checkpoint policy baseline 'rejected)))
        (check-equal? (PooFlowDebugMemoryAnomaly? captured) #t)
        (check-equal?
         (.ref (PooFlowDebugMemoryAnomaly-receipt captured) 'reason)
         'heap-limit-exceeded)))))
