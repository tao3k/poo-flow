(import (only-in :std/srfi/1 every find)
        :std/test)

	(export build-cache-performance-test
	        build-cache-performance-fixture-path
	        build-cache-performance-load-fixture
	        build-cache-performance-ref
	        build-cache-noop-receipt
	        build-cache-noop-current-receipt
	        build-cache-noop-repaired-receipt
	        build-cache-single-stale-receipt
	        build-cache-single-stale-current-receipt
	        build-cache-single-stale-target-receipt
	        build-cache-noop-receipt-pass?)

;; : String
(def build-cache-performance-fixture-path
  "t/scenarios/performance/build-noop-cache-stability/benchmark.ss")

;; : (-> Alist)
(def (build-cache-performance-load-fixture)
  (call-with-input-file build-cache-performance-fixture-path read))

;; : (-> Alist Symbol Object)
(def (build-cache-performance-ref receipt key)
  (let (cell (find (lambda (entry)
                     (equal? key (car entry)))
                   receipt))
    (and cell (cdr cell))))

;; : (-> Number Number Boolean)
(def (build-cache-performance-within-budget? observed target)
  (and (every number? (list observed target))
       (<= observed target)))

;; : (-> Object Boolean)
(def (build-cache-performance-empty-list? value)
  (not (and value
            (not (null? value)))))

;; : (-> Symbol Object Pair)
(def (build-cache-performance-row key value)
  (cons key value))

;; : (-> Alist Integer Integer Integer Integer Integer [Object] Alist)
(def (build-cache-noop-receipt fixture
                               elapsed-ms
                               max-rss-mb
                               compiled-targets
                               runtime-bootstrap-targets
                               runtime-targets
                               stage-warnings)
  (let* ((elapsed-target
          (build-cache-performance-ref fixture 'targetNoopElapsedMs))
         (rss-target
          (build-cache-performance-ref fixture 'targetMaxRssMb))
         (compiled-target
          (build-cache-performance-ref fixture 'targetCompiledTargets))
         (runtime-bootstrap-target
          (build-cache-performance-ref
           fixture
           'targetRuntimeBootstrapCompiledTargets))
         (runtime-target
          (build-cache-performance-ref fixture 'targetRuntimeCompiledTargets))
         (pass?
          (and (build-cache-performance-within-budget?
                elapsed-ms
                elapsed-target)
               (build-cache-performance-within-budget?
                max-rss-mb
                rss-target)
               (= compiled-targets compiled-target)
               (= runtime-bootstrap-targets runtime-bootstrap-target)
               (= runtime-targets runtime-target)
               (build-cache-performance-empty-list? stage-warnings))))
    (map (lambda (row)
           (build-cache-performance-row (car row) (cdr row)))
         (list (cons 'source 'poo-flow.performance.build-cache.noop)
               (cons 'feature (build-cache-performance-ref fixture 'feature))
               (cons 'elapsed-ms elapsed-ms)
               (cons 'target-elapsed-ms elapsed-target)
               (cons 'max-rss-mb max-rss-mb)
               (cons 'target-max-rss-mb rss-target)
               (cons 'compiled-targets compiled-targets)
               (cons 'target-compiled-targets compiled-target)
               (cons 'runtime-bootstrap-compiled-targets
                     runtime-bootstrap-targets)
               (cons 'target-runtime-bootstrap-compiled-targets
                     runtime-bootstrap-target)
               (cons 'runtime-compiled-targets runtime-targets)
               (cons 'target-runtime-compiled-targets runtime-target)
               (cons 'stage-warnings stage-warnings)
               (cons 'status (if pass? 'pass 'fail))))))

;; : (-> Alist Alist)
(def (build-cache-noop-current-receipt fixture)
  (apply build-cache-noop-receipt
         fixture
         (map (lambda (key)
                (build-cache-performance-ref fixture key))
              '(observedNoopElapsedMs
                observedMaxRssMb
                observedCompiledTargets
                observedRuntimeBootstrapCompiledTargets
                observedRuntimeCompiledTargets
                observedStageWarnings))))

;; : (-> Alist Alist)
(def (build-cache-noop-repaired-receipt fixture)
  (apply build-cache-noop-receipt
         fixture
         (map (lambda (key)
                (build-cache-performance-ref fixture key))
              '(targetNoopElapsedMs
                targetMaxRssMb
                targetCompiledTargets
                targetRuntimeBootstrapCompiledTargets
                targetRuntimeCompiledTargets
                targetStageWarnings))))

	;; : (-> Alist Boolean)
	(def (build-cache-noop-receipt-pass? receipt)
	  (eq? (build-cache-performance-ref receipt 'status) 'pass))

	;; : (-> Alist Integer Integer Symbol Alist)
	(def (build-cache-single-stale-receipt fixture
	                                      elapsed-ms
	                                      compiled-targets
	                                      engine)
	  (let* ((elapsed-target
	          (build-cache-performance-ref fixture 'targetSingleStaleElapsedMs))
	         (compiled-target
	          (build-cache-performance-ref
	           fixture
	           'targetSingleStaleCompiledTargets))
	         (engine-target
	          (build-cache-performance-ref fixture 'targetSingleStaleEngine))
	         (pass?
	          (and (build-cache-performance-within-budget?
	                elapsed-ms
	                elapsed-target)
	               (= compiled-targets compiled-target)
	               (eq? engine engine-target))))
	    (map (lambda (row)
	           (build-cache-performance-row (car row) (cdr row)))
	         (list (cons 'source 'poo-flow.performance.build-cache.single-stale)
	               (cons 'feature (build-cache-performance-ref fixture 'feature))
	               (cons 'elapsed-ms elapsed-ms)
	               (cons 'target-elapsed-ms elapsed-target)
	               (cons 'compiled-targets compiled-targets)
	               (cons 'target-compiled-targets compiled-target)
	               (cons 'engine engine)
	               (cons 'target-engine engine-target)
	               (cons 'status (if pass? 'pass 'fail))))))

	;; : (-> Alist Alist)
	(def (build-cache-single-stale-current-receipt fixture)
	  (apply build-cache-single-stale-receipt
	         fixture
	         (map (lambda (key)
	                (build-cache-performance-ref fixture key))
	              '(observedSingleStaleElapsedMs
	                observedSingleStaleCompiledTargets
	                observedSingleStaleEngine))))

	;; : (-> Alist Alist)
	(def (build-cache-single-stale-target-receipt fixture)
	  (apply build-cache-single-stale-receipt
	         fixture
	         (map (lambda (key)
	                (build-cache-performance-ref fixture key))
	              '(targetSingleStaleElapsedMs
	                targetSingleStaleCompiledTargets
	                targetSingleStaleEngine))))

;; : (-> Alist Void)
(def (build-cache-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] build-cache-noop ")
  (write receipt)
  (newline)
  (force-output))

;; : TestSuite
(def (build-cache-live-warm-stage-results)
  (poo-flow-gxc-stage
   "testing-bootstrap"
   +poo-flow-testing-bootstrap-build-spec+
   (poo-flow-entry-options #f #f #f #f #f #f #f)))

(def build-cache-performance-test
  (test-suite "build-cache-performance"
    (test-case "fixture fixes observed and target no-op parameters"
      (let (fixture (build-cache-performance-load-fixture))
        (check-equal?
         (build-cache-performance-ref fixture 'feature)
         'build-noop-cache-stability)
        (check-equal?
         (build-cache-performance-ref fixture 'observedNoopElapsedMs)
         2440)
        (check-equal?
         (build-cache-performance-ref fixture 'targetNoopElapsedMs)
         5000)
        (check-equal?
         (build-cache-performance-ref fixture 'observedCompiledTargets)
         0)
        (check-equal?
         (build-cache-performance-ref fixture 'targetCompiledTargets)
         0)))
	    (test-case "classifier accepts current no-op and tightened target receipt"
	      (let* ((fixture (build-cache-performance-load-fixture))
	             (current (build-cache-noop-current-receipt fixture))
	             (target (build-cache-noop-repaired-receipt fixture)))
        (build-cache-performance-display-receipt current)
        (build-cache-performance-display-receipt target)
        (check-equal?
         (build-cache-performance-ref current 'status)
         'pass)
	        (check-equal?
	         (build-cache-performance-ref target 'status)
	         'pass)))
	    (test-case "classifier accepts single-stale direct-gxc repair"
	      (let* ((fixture (build-cache-performance-load-fixture))
	             (current (build-cache-single-stale-current-receipt fixture))
	             (target (build-cache-single-stale-target-receipt fixture)))
	        (build-cache-performance-display-receipt current)
	        (build-cache-performance-display-receipt target)
	        (check-equal?
	         (build-cache-performance-ref current 'status)
	         'pass)
	        (check-equal?
	         (build-cache-performance-ref current 'engine)
	         'direct-gxc)
	        (check-equal?
	         (build-cache-performance-ref target 'status)
         'pass))
    (test-case "live warm stage returns a POO-native skip receipt"
      (let* ((fixture (build-cache-performance-load-fixture))
             (results (build-cache-live-warm-stage-results))
             (result (car results)))
        (check-equal? (length results) 1)
        (check-equal? (poo-flow-stage-result? result) #t)
        (check-equal? (poo-flow-stage-result-outcome result) 'skip)
        (check-equal? (poo-flow-stage-result-reason result)
                      'stage-cache-valid)
        (check-equal?
         (<= (poo-flow-stage-result-elapsed-micros result)
             (* (build-cache-performance-ref fixture 'targetNoopElapsedMs)
                1000))
         #t)
        (check-equal? (poo-flow-stage-result-cache-status result)
                      'current))))))
(import (only-in :poo-flow/src/cli-support/package-build-support/engine
                 poo-flow-gxc-stage)
        (only-in :poo-flow/src/cli-support/package-build-support/options
                 poo-flow-entry-options)
        (only-in :poo-flow/src/cli-support/package-build-support/specs
                 +poo-flow-testing-bootstrap-build-spec+)
        (only-in :poo-flow/src/cli-support/package-build-support/stage-result
                 poo-flow-stage-result?
                   poo-flow-stage-result-cache-status
                   poo-flow-stage-result-elapsed-micros
                 poo-flow-stage-result-outcome
                 poo-flow-stage-result-reason))
