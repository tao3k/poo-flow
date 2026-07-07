;;; -*- Gerbil -*-
;;; Boundary: executable exercise for tool-calling object-list performance.

(import :poo-flow/src/module-system/tool-calling-control)

(def (tool-calling-performance-symbol prefix index)
  (string->symbol (string-append prefix "-" (number->string index))))

(def (tool-calling-performance-pair index)
  (let* ((session (tool-calling-performance-symbol "session" index))
         (tool (tool-calling-performance-symbol "search-tool" index))
         (runtime
          (tool-calling-performance-symbol "python-runtime-tool-plane" index))
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

(def (tool-calling-performance-pairs count)
  (let loop ((index 0) (pairs-rev '()))
    (if (>= index count)
      (reverse pairs-rev)
      (loop (+ index 1)
            (cons (tool-calling-performance-pair index) pairs-rev)))))

(def (tool-calling-performance-valid-proof-count pairs rounds)
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
                  (and (poo-flow-tool-call-fact-ref facts 'plan-valid)
                       (poo-flow-tool-call-fact-ref
                        facts
                        'runtime-receipt-matches-tool-plan)
                       (poo-flow-tool-call-fact-ref
                        facts
                        'tool-output-cannot-authorize-policy))))
            (pair-loop (cdr rest)
                       (if valid?
                         (+ round-accepted 1)
                         round-accepted))))))))

(def pairs
  (tool-calling-performance-pairs 96))

(def first-pair
  (car pairs))

(def first-facts
  (poo-flow-tool-call-runtime-validation-proof-facts
   (car first-pair)
   (cdr first-pair)))

(unless (poo-flow-tool-call-fact-ref first-facts 'plan-valid)
  (error "tool-calling performance plan should be valid"))

(unless (poo-flow-tool-call-fact-ref first-facts
                                     'runtime-receipt-matches-tool-plan)
  (error "tool-calling performance receipt should match the plan"))

(unless (= (tool-calling-performance-valid-proof-count pairs 4) 384)
  (error "tool-calling performance proof count drifted"))

(void)
