;;; -*- Gerbil -*-
;;; Package imports deliberately require the freshly compiled qualification library.
(import (only-in :std/test run-tests! test-report-summary! set-test-verbose!)
        (only-in :clan/poo/object .ref)
        :poo-flow/t/poo-method-combination-test
        :poo-flow/t/poo-method-combination-contract-test
        :poo-flow/t/poo-method-combination-next-test
        :poo-flow/t/poo-method-combination-observation-test
        :poo-flow/t/poo-method-combination-performance-test
        :poo-flow/t/observability-framework-test
        :poo-flow/t/gerbil-poo-debug-admission-test
        :poo-flow/t/scenarios/research/poo-method-combination/performance
        "artifacts.ss")
(def artifact-count (verify-combination-artifacts!))
(def dependency-snapshot (combination-dependency-snapshot))
;; std/test emits per-case assertion counts even with expression tracing off.
(set-test-verbose! #f)
(force-output)
(def suites (list poo-method-combination-test poo-method-combination-contract-test
                  poo-method-combination-next-test poo-method-combination-observation-test
                  poo-method-combination-performance-test observability-framework-test
                  gerbil-poo-debug-admission-test))
(when (null? suites) (error "Empty qualification suites"))
(def success? (apply run-tests! suites))
(test-report-summary!)
(force-output (current-error-port))
(unless success? (exit 42))
;; Human-facing projection of an already computed native timing receipt.
(let (receipt (combination-performance-scenario))
  (write (cons 'compiled-method-combination
           (map (lambda (key) (list key (.ref receipt key)))
                '(iterations depth construction-ms first-demand-ms warm-ms native-ms
                  checksum expected plan-reused? within-budget?))))
  (newline)
  (unless (.ref receipt 'within-budget?) (exit 42)))

;; Wire rows are explicit projections of native POO measurements.
(def trials (combination-performance-matrix))
(for-each
 (lambda (row)
   (write (cons 'performance-trial
     (append
       (map (lambda (key) (list key (.ref row key)))
            '(depth from qualifiers iterations trial order expected plan-reused?))
       (map (lambda (name)
              (cons name (map (lambda (key) (list key (.ref (.ref row name) key)))
                              '(checksum wall-ms gc-ms gc-count allocated-bytes))))
            '(combination functional)))))
   (newline))
 trials)
(verify-combination-dependencies! dependency-snapshot)
(write (list 'qualification-complete 'schema 'v2 'producer 'poo-flow/research
             'artifact-count artifact-count 'suites (length suites) 'tests-passed #t
             'performance-trials (length trials)))
(newline)
