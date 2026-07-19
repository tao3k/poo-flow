(import :std/test
        :gslph/src/testing/memory-profile
        :gslph/src/building/facade
        :clan/poo/object
        "../src/build-api/process-memory-guard.ss"
        :poo-flow/src/build-api/guarded-stage-syntax)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def child "t/fixtures/process-memory-guard-child.ss")
(define-guarded-gxi-stage guarded-complete-stage
  label: "guarded-complete"
  file: "t/fixtures/process-memory-guard-complete.ss"
  max-rss-mib: 256
  timeout-seconds: 2)
(def (run-guard label max-mib timeout mode)
  (poo-flow-process-memory-guard-run
   label (* max-mib 1024 1024) timeout
   (list "gxi" child mode) 0.01))

(def process-memory-guard-test
  (test-suite "Scheme process memory guard"
    (test-case "preserves successful child status and emits POO receipt"
      (let (receipt (run-guard 'complete 256 #f "complete"))
        (check (.ref receipt 'kind) => +poo-flow-process-memory-guard-schema+)
        (check (.ref receipt 'outcome) => 'completed)
        (check (.ref receipt 'exit-code) => 0)
        (check (.ref receipt 'timeout-ms) => #f)
        (check (exact-integer? (.ref receipt 'peak-rss-bytes)) => #t)
        (check (>= (.ref receipt 'peak-rss-bytes) 0) => #t)))
    (test-case "macro lowers guard policy to Building Framework stage"
      (let* ((stage-receipt (build-stage-run! guarded-complete-stage #f))
             (guard-receipt (build-stage-receipt-result stage-receipt)))
        (check (build-stage? guarded-complete-stage) => #t)
        (check (build-stage-kind guarded-complete-stage) => 'guarded-gxi-test)
        (check (.ref guard-receipt 'outcome) => 'completed)
        (check (.ref guard-receipt 'exit-code) => 0)))
    (test-case "terminates allocating gxi before host OOM"
      (let (receipt (run-guard 'allocate 256 4 "allocate"))
        (check (.ref receipt 'outcome) => 'rss-limit-exceeded)
        (check (.ref receipt 'exit-code) => 70)
        (check (> (.ref receipt 'peak-rss-bytes)
                  (.ref receipt 'max-rss-bytes)) => #t)
        (let* ((pid (##os-getpid))
               (rows
                (poo-flow/src/build-api/process-memory-guard#guard-process-table))
               (expected-rss
                (let lp ((rest rows))
                  (cond
                   ((null? rest) 0)
                   ((= (caar rest) pid) (caddar rest))
                   (else (lp (cdr rest))))))
               (observed-rss (poo-flow-current-process-memory-bytes)))
          (check (> expected-rss 0) => #t)
          (check (< (abs (- observed-rss expected-rss))
                    (* 16 1024 1024)) => #t))))
    (test-case "keeps RSS guard active without a parent wall-clock deadline"
      (let* ((guard
              (poo-flow-current-process-memory-guard-start!
               'control-plane (* 256 1024 1024) #f 0.01))
             (receipt
              (poo-flow-current-process-memory-guard-stop! guard)))
        (check (.ref receipt 'outcome) => 'completed)
        (check (.ref receipt 'timeout-ms) => #f)))
    (test-case "terminates stalled gxi at elapsed timeout"
      (let (receipt (run-guard 'timeout 256 0.1 "sleep"))
        (check (.ref receipt 'outcome) => 'timeout)
        (check (.ref receipt 'exit-code) => 71)))))

(run-tests! process-memory-guard-test)
