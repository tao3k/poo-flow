(import :std/test
        :gslph/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/qualification/runner)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def registry (poo-flow-agentic-control-plane-gate-registry))

(def qualification-runner-test
  (test-suite "AC-10 S4 cross-language qualification runner"
    (test-case "registry declares exact release owners and installed gates"
      (check (map (lambda (gate) (.ref gate 'gate-id)) registry)
             => +poo-flow-ac10-release-gates+)
      (check (map (lambda (id)
                    (.ref (find (lambda (gate)
                                  (eq? id (.ref gate 'gate-id))) registry)
                          'installed-consumer?))
                  '(runtime-v0-installed-consumer proof-case-installed-consumer
                    python-proof-installed-wheel lean-ffi-smoke))
             => '(#t #t #t #t)))
    (test-case "focused mode executes only canonical Scheme owner"
      (let* ((run (poo-flow-qualification-run registry "revision" 'focused))
             (verified (poo-flow-qualification-verify-run registry run)))
        (check (map (lambda (receipt) (.ref receipt 'gate-id))
                    (.ref run 'gate-receipts))
               => '(scheme-canonical-fixture))
        (check (.ref run 'accepted?) => #t)
        (check (.ref verified 'accepted?) => #t)))
    (test-case "missing and stale release receipts fail closed"
      (let* ((focused (poo-flow-qualification-run registry "revision" 'focused))
             (fake-release
              (object<-alist
               (list (cons 'kind 'poo-flow.qualification-run-receipt.v1)
                     (cons 'mode 'release)
                     (cons 'source-revision "other-revision")
                     (cons 'gate-receipts (.ref focused 'gate-receipts))
                     (cons 'accepted? #f))))
             (verified
              (poo-flow-qualification-verify-run registry fake-release)))
        (check (.ref verified 'accepted?) => #f)
        (let (codes (map (lambda (entry) (cdr (assq 'code entry)))
                         (.ref verified 'diagnostics)))
          (check (car codes) => 'stale-source-revision)
          (check (length codes) => (length +poo-flow-ac10-release-gates+)))))))

(run-tests! qualification-runner-test)
