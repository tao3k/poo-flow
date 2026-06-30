;;; -*- Gerbil -*-
;;; Boundary: loop-engine to session-agent graph projection performance gate.
;;; Invariant: projection stays report-only and does not duplicate topology
;;; outside the session module graph owner.

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
        (only-in :poo-flow/src/modules/cubeSandbox/config
                 poo-flow-cubeSandbox-module-bundles)
        (only-in :poo-flow/src/modules/nono-sandbox/config
                 poo-flow-nono-sandbox-module-bundles)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-loop-engine-case))

(export loop-engine-session-agent-graph-performance-test)

(def loop-engine-session-agent-graph-performance-fixture-path
  "t/scenarios/performance/loop-engine-session-agent-graph/benchmark.ss")

(def loop-engine-session-agent-graph-performance-fixture
  (call-with-input-file
   loop-engine-session-agent-graph-performance-fixture-path
   read))

;; : (-> Alist Symbol MaybeValue)
(def (loop-engine-session-agent-graph-performance-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (loop-engine-session-agent-graph-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] loop-engine-session-agent-graph ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> Alist)
(def (loop-engine-session-agent-graph-performance-summary)
  (let* ((presentation
          (pooFlowUserConfigPresentation
           (pooFlowUserConfig
            (poo-flow-user-module-bundles->modules
             (append poo-flow-nono-sandbox-module-bundles
                     poo-flow-cubeSandbox-module-bundles
                     (list poo-flow-custom-my-module-loop-engine-case)))
            (poo-flow-settings))))
         (intent (car (.ref presentation 'loop-engine-intents)))
         (graph (loop-engine-session-agent-graph-performance-ref
                 intent
                 'session-agent-graph)))
    (list
     (cons 'agent-count
           (loop-engine-session-agent-graph-performance-ref graph
                                                            'agent-count))
     (cons 'session-count
           (loop-engine-session-agent-graph-performance-ref graph
                                                            'session-count))
     (cons 'registry-entry-count
           (loop-engine-session-agent-graph-performance-ref
            (loop-engine-session-agent-graph-performance-ref
             graph
             'registry-receipt)
            'entry-count))
     (cons 'presentation-count
           (length (.ref presentation 'loop-engine-session-agent-graphs)))
     (cons 'runtime-executed
           (loop-engine-session-agent-graph-performance-ref
            graph
            'runtime-executed)))))

(def loop-engine-session-agent-graph-performance-test
  (test-suite "loop-engine session-agent graph performance"
    (test-case "keeps loop-engine topology projection inside benchmark contract"
      (let* ((summary
              (loop-engine-session-agent-graph-performance-summary))
             (receipt
              (benchmark-run
               loop-engine-session-agent-graph-performance-fixture
               loop-engine-session-agent-graph-performance-summary)))
        (check-equal?
         (benchmark-fixture-contract-pass?
          loop-engine-session-agent-graph-performance-fixture)
         #t)
        (check-equal?
         (loop-engine-session-agent-graph-performance-ref summary
                                                          'agent-count)
         4)
        (check-equal?
         (loop-engine-session-agent-graph-performance-ref summary
                                                          'session-count)
         6)
        (check-equal?
         (loop-engine-session-agent-graph-performance-ref
          summary
          'registry-entry-count)
         6)
        (check-equal?
         (loop-engine-session-agent-graph-performance-ref
          summary
          'presentation-count)
         1)
        (check-equal?
         (loop-engine-session-agent-graph-performance-ref
          summary
          'runtime-executed)
         #f)
        (loop-engine-session-agent-graph-performance-display-receipt
         receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
