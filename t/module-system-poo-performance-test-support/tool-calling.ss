;;; -*- Gerbil -*-
;;; Boundary: POO performance cases for tool-calling control-plane objects.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-ref
                 benchmark-receipt-pass?)
        :poo-flow/t/support/poo-performance
        :poo-flow/src/module-system/tool-calling-control)

(export module-system-poo-performance-tool-calling-test)

;; : (-> Alist Unit)
(def (module-system-poo-performance-tool-calling-display-receipt receipt)
  (display "[poo-flow-benchmark] ")
  (write (benchmark-fixture-ref receipt 'feature))
  (display " ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> String Integer Symbol)
(def (module-system-poo-performance-tool-calling-symbol prefix index)
  (string->symbol (string-append prefix "-" (number->string index))))

;; : (-> Integer Pair)
(def (module-system-poo-performance-tool-calling-pair index)
  (let* ((session
          (module-system-poo-performance-tool-calling-symbol "session" index))
         (tool
          (module-system-poo-performance-tool-calling-symbol "search-tool"
                                                            index))
         (runtime
          (module-system-poo-performance-tool-calling-symbol
           "python-runtime-tool-plane"
           index))
         (trace '(tool-request
                  permission-check
                  argument-validation
                  runtime-call
                  tool-result))
         (plan
          (poo-flow-tool-call-plan
           'tool-calling-agent-loop
           session
           tool
           '(query limit cursor)
           '(query)
           'allow-search
           'sandbox-readonly
           'retry-after-policy-window
           'search-result
           runtime
           trace))
         (runtime-receipt
          (poo-flow-tool-call-runtime-receipt
           'tool-calling-agent-loop
           session
           tool
           '(query limit)
           #t
           #t
           #t
           #t
           #t
           runtime
           trace
           #f
           'completed)))
    (cons plan runtime-receipt)))

;; : (-> Integer [Pair])
(def (module-system-poo-performance-tool-calling-pairs count)
  (poo-performance-build-list
   count
   module-system-poo-performance-tool-calling-pair))

;; : (-> [Pair] Integer Integer)
(def (module-system-poo-performance-tool-calling-valid-proof-count pairs rounds)
  (let ((fact-family
         (poo-flow-tool-call-fact-family
          'poo-flow-tool-call-runtime-validation-proof-facts
          'poo-flow.tool-calling.control.runtime)))
    (let round-loop ((round 0) (accepted 0))
      (if (>= round rounds)
        accepted
        (let pair-loop ((rest pairs) (round-accepted accepted))
          (if (null? rest)
            (round-loop (+ round 1) round-accepted)
            (let* ((pair (car rest))
                   (plan (car pair))
                   (runtime-receipt (cdr pair))
                   (facts
                    (poo-flow-tool-call-runtime-validation-proof-facts
                     plan
                     runtime-receipt))
                   (valid?
                    (and
                     (poo-flow-tool-call-fact-family-ref
                      fact-family
                      facts
                      'plan-valid)
                     (poo-flow-tool-call-fact-family-ref
                      fact-family
                      facts
                      'runtime-receipt-matches-tool-plan)
                     (poo-flow-tool-call-fact-family-ref
                      fact-family
                      facts
                      'tool-output-cannot-authorize-policy))))
              (pair-loop (cdr rest)
                         (if valid?
                           (+ round-accepted 1)
                           round-accepted)))))))))

;; : TestCase
(def module-system-poo-performance-tool-calling-object-list-control-case
  (test-case "validates tool-call proof objects through stable POO lists"
    (let* ((pair-count 96)
           (rounds 4)
           (pairs
            (module-system-poo-performance-tool-calling-pairs pair-count))
           (expected (* pair-count rounds))
           (first-pair (car pairs))
           (first-plan (car first-pair))
           (first-runtime-receipt (cdr first-pair))
           (first-facts
            (poo-flow-tool-call-runtime-validation-proof-facts
             first-plan
             first-runtime-receipt))
           (receipt
            (poo-performance-run-gate
             (poo-performance-tool-calling-object-list-control-fixture)
             (lambda ()
               (module-system-poo-performance-tool-calling-valid-proof-count
                pairs
                rounds)))))
      (check-equal? (poo-flow-tool-call-fact-ref first-facts 'plan-valid)
                    #t)
      (check-equal?
       (poo-flow-tool-call-fact-ref first-facts 'fact-family)
       'poo-flow-tool-call-runtime-validation-proof-facts)
      (check-equal?
       (poo-flow-tool-call-fact-ref first-facts
                                    'runtime-receipt-matches-tool-plan)
       #t)
      (check-equal?
       (module-system-poo-performance-tool-calling-valid-proof-count
        pairs
        rounds)
       expected)
      (module-system-poo-performance-tool-calling-display-receipt receipt)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestSuite
(def module-system-poo-performance-tool-calling-test
  (test-suite "poo-flow module system POO tool-calling performance"
    module-system-poo-performance-tool-calling-object-list-control-case))
