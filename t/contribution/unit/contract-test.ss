(import :std/test :poo-flow/src/module-system/contribution/interface)
(export contract-test)

(def sample (make-contribution "test/sample" "1" "test-owner"
                              (.o value: 42) '(test-facet) '(test-read)))
(def contract-test
  (test-suite "independent core contribution contract"
    (test-case "admission preserves values without executing"
      (let ((receipt (admit-contributions (list sample) '(test-read))))
        (check-equal? (.ref receipt 'accepted?) #t)
        (check-equal? (eq? (car (.ref receipt 'selected)) sample) #t)
        (check-equal? (.ref receipt 'runtime-executed?) #f)))
    (test-case "missing requirements and duplicates fail closed"
      (check-equal? (.ref (admit-contributions (list sample) '()) 'accepted?) #f)
      (check-equal? (.ref (admit-contributions (list sample sample) '(test-read))
                         'accepted?) #f))
    (test-case "wrong shape and unsupported contract fail closed"
      (check-equal? (.ref (admit-contributions (list (.o)) '()) 'accepted?) #f)
      (check-equal? (.ref (admit-contributions
                          (list (.o (:: @ sample) core-contract: 'future))
                          '(test-read)) 'reasons)
                    '(incompatible-core-contract)))
    (test-case "existing composition syntax keeps explicit profile values"
      (let ((selection
             (use-composition selection
               (use-module test as contribution (profile sample))
               (compose (profile contribution sample)))))
        (check-equal? (eq? (car (poo-flow-composition-profiles selection)) sample) #t)))))
