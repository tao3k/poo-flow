(import :std/test
        :gslph/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/cli-support/process-memory-guard)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def child "t/fixtures/process-memory-guard-child.ss")
(def (run-guard label max-mib timeout mode)
  (poo-flow-process-memory-guard-run
   label (* max-mib 1024 1024) timeout
   (list "gxi" child mode) 0.01))

(def process-memory-guard-test
  (test-suite "Scheme process memory guard"
    (test-case "preserves successful child status and emits POO receipt"
      (let (receipt (run-guard 'complete 256 2 "complete"))
        (check (.ref receipt 'kind) => +poo-flow-process-memory-guard-schema+)
        (check (.ref receipt 'outcome) => 'completed)
        (check (.ref receipt 'exit-code) => 0)
        (check (> (.ref receipt 'peak-rss-bytes) 0) => #t)))
    (test-case "terminates allocating gxi before host OOM"
      (let (receipt (run-guard 'allocate 128 4 "allocate"))
        (check (.ref receipt 'outcome) => 'rss-limit-exceeded)
        (check (.ref receipt 'exit-code) => 70)
        (check (> (.ref receipt 'peak-rss-bytes)
                  (.ref receipt 'max-rss-bytes)) => #t)))
    (test-case "terminates stalled gxi at elapsed timeout"
      (let (receipt (run-guard 'timeout 256 0.1 "sleep"))
        (check (.ref receipt 'outcome) => 'timeout)
        (check (.ref receipt 'exit-code) => 71)))))

(run-tests! process-memory-guard-test)
