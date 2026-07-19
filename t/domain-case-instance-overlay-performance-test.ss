(import :std/test
        :clan/poo/object
        ./support/performance)

(export domain-case-instance-overlay-performance-test)

(def domain-case-instance-overlay-performance-test
  (test-suite "DomainCase instance overlay hot path"
    (test-case "constant-slot overlay removes per-Agent C3 mix"
      (let (receipts (run-domain-case-instance-overlay-benchmark))
        (check (map (lambda (receipt) (.ref receipt 'shared-slot-count))
                    receipts)
               => '(8 32 64))
        (for-each
         (lambda (receipt)
           (check (.ref receipt 'agent-count) => 1000)
           (check (.ref receipt 'materialized-slot-count)
                  => (+ (.ref receipt 'shared-slot-count) 4))
           (check (.ref receipt 'baseline-mix-count) => 1000)
           (check (.ref receipt 'overlay-mix-count) => 0)
           (check (.ref receipt 'resolver-depth) => 1)
           (check (.ref receipt 'construction-complexity)
                  => 'linear-in-visible-slots)
           (check (.ref receipt 'lookup-source-depth)
                  => 'constant-source-depth)
           (check (.ref receipt 'correct?) => #t)
           (check (.ref receipt 'shared-prototype-retained?) => #t)
           (check (.ref receipt 'local-precedence-valid?) => #t)
           (check (.ref receipt 'timing-pass?) => #t)
           (check (.ref receipt 'pass?) => #t))
         receipts)))))
