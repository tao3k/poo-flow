;;; -*- Gerbil -*-
;;; Boundary: foundational session policy family projection performance gate.
;;; Invariant: POO-native policy constructors project to bounded rows before
;;; effective validation, without runtime, tool, hook, provider, or sandbox work.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        :poo-flow/t/support/performance
        :poo-flow/src/modules/session/config)

(export session-policy-family-performance-test)

;; : String
(def session-policy-family-fixture-path
  "t/scenarios/performance/session-policy-family/benchmark.ss")

;; : Alist
(def session-policy-family-fixture
  (call-with-input-file session-policy-family-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (session-policy-family-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (session-policy-family-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] session-policy-family ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> String Integer Symbol)
(def (session-policy-family-performance-id prefix index)
  (string->symbol
   (string-append prefix "/" (number->string index))))

;; : (-> Integer [PooSessionToolGrant])
(def (session-policy-family-performance-tool-grants index)
  (list
   (poo-flow-session-tool-grant
    (session-policy-family-performance-id "grant/read" index)
    'read-workspace-file
    '(read)
    '(project-workspace)
    '(agent-turn hook/pre-check))
   (poo-flow-session-tool-grant
    (session-policy-family-performance-id "grant/build" index)
    'run-build-command
    '(run)
    '(project-workspace build-cache)
    '(agent-turn))))

;; : (-> Integer [PooSessionPolicy])
(def (session-policy-family-performance-policies index)
  (let* ((scope-ref
          (session-policy-family-performance-id "session/perf" index))
         (agent-ref
          (session-policy-family-performance-id "agent/perf" index))
         (tool-grants
          (session-policy-family-performance-tool-grants index))
         (isolation-ref
          (session-policy-family-performance-id "policy/isolation" index))
         (sandbox-ref
          (session-policy-family-performance-id "policy/sandbox" index))
         (context-ref
          (session-policy-family-performance-id "policy/context" index))
         (resource-ref
          (session-policy-family-performance-id "policy/resource" index))
         (model-ref
          (session-policy-family-performance-id "policy/model" index))
         (prompt-ref
          (session-policy-family-performance-id "policy/prompt" index))
         (tool-ref
          (session-policy-family-performance-id "policy/tools" index))
         (hook-ref
          (session-policy-family-performance-id "policy/hooks" index)))
    (list
     (poo-flow-session-isolation-policy
      isolation-ref
      scope-ref
      'strict
      'deny
      'append-summary
      'via-supervisor)
     (poo-flow-session-sandbox-policy
      sandbox-ref
      scope-ref
      'sandbox/nono-build
      'parent-profile
      'isolated-filesystem)
     (poo-flow-session-context-policy
      context-ref
      scope-ref
      'parent-summary-only
      '(session/root session/audit))
     (poo-flow-session-history-policy
      (session-policy-family-performance-id "policy/history" index)
      scope-ref
      'bounded
      '(record/last-failure record/build-log))
     (poo-flow-session-communication-policy
      (session-policy-family-performance-id "policy/communication" index)
      scope-ref
      '(channel/build-root channel/build-audit)
      '(session/root session/audit))
     (poo-flow-session-sharing-policy
      (session-policy-family-performance-id "policy/sharing" index)
      scope-ref
      '(memory/project)
      '(artifact/build-log)
      '(tool-result/test-summary)
      '("build/" "reports/"))
     (poo-flow-session-resource-policy
      resource-ref
      scope-ref
      '(budget/build-agent)
      '(capability/cache-read capability/cache-write)
      scope-ref)
     (poo-flow-session-model-policy
      model-ref
      scope-ref
      'marlin/provider
      'marlin/model/build-review
      '(tool-calling structured-output)
      'budget/build-agent)
     (poo-flow-session-prompt-policy
      prompt-ref
      scope-ref
      'session/system
      '(system-instruction build-contract)
      'parent-summary-only)
     (poo-flow-session-tool-permission-policy
      tool-ref
      scope-ref
      tool-grants
      '(write-workspace-file)
      'deny)
     (poo-flow-session-hook-tool-permission-policy
      hook-ref
      scope-ref
      '(hook/pre-check)
      (list (car tool-grants))
      'human-approval-on-escalation
      'deny)
     (poo-flow-session-resource-sharing-policy
      (session-policy-family-performance-id "policy/resource-sharing" index)
      scope-ref
      '((project-workspace
         (access . read)
         (accounting . session/root))
        (build-cache
         (access . read-write)
         (accounting . session/perf)))
      'deny)
     (poo-flow-session-agent-execution-policy
      (session-policy-family-performance-id "policy/execution" index)
      agent-ref
      scope-ref
      model-ref
      prompt-ref
      tool-ref
      hook-ref
      context-ref
      resource-ref))))

;; : (-> [PooSessionPolicy] [Alist] [Alist])
(def (session-policy-family-performance-project/rev policies rows)
  (if (null? policies)
    rows
    (session-policy-family-performance-project/rev
     (cdr policies)
     (cons (poo-flow-session-policy->alist (car policies)) rows))))

;; : (-> Integer [Alist])
(def (session-policy-family-performance-rows count)
  (let loop ((index 0)
             (rows []))
    (if (= index count)
      (reverse rows)
      (loop (+ index 1)
            (session-policy-family-performance-project/rev
             (session-policy-family-performance-policies index)
             rows)))))

;; : (-> [Alist] Symbol Integer)
(def (session-policy-family-performance-count-kind rows policy-kind)
  (let loop ((remaining rows)
             (count 0))
    (cond
     ((null? remaining) count)
     ((eq? (session-policy-family-performance-ref
            (car remaining)
            'policy-kind)
           policy-kind)
      (loop (cdr remaining) (+ count 1)))
     (else (loop (cdr remaining) count)))))

;; : (-> Integer Alist)
(def (session-policy-family-performance-summary family-count)
  (let* ((rows (session-policy-family-performance-rows family-count))
         (policy-count (length rows))
         (first-row (car rows))
         (last-row (list-ref rows (- policy-count 1))))
    (list
     (cons 'family-count family-count)
     (cons 'policy-count policy-count)
     (cons 'first-kind
           (session-policy-family-performance-ref first-row 'policy-kind))
     (cons 'last-kind
           (session-policy-family-performance-ref last-row 'policy-kind))
     (cons 'sandbox-count
           (session-policy-family-performance-count-kind
            rows
            'session-sandbox))
     (cons 'sharing-count
           (session-policy-family-performance-count-kind
            rows
            'session-sharing))
     (cons 'runtime-executed
           (session-policy-family-performance-ref
            first-row
            'runtime-executed)))))

;; : TestSuite
(def session-policy-family-performance-test
  (test-suite "session policy family performance"
    (test-case "keeps foundational policy projection inside benchmark contract"
      (let* ((family-count 96)
             (summary
              (session-policy-family-performance-summary family-count))
             (receipt
              (benchmark-run
               session-policy-family-fixture
               (lambda ()
                 (session-policy-family-performance-summary
                  family-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? session-policy-family-fixture)
         #t)
        (check-equal?
         (session-policy-family-performance-ref summary 'family-count)
         family-count)
        (check-equal?
         (session-policy-family-performance-ref summary 'policy-count)
         (* family-count 13))
        (check-equal?
         (session-policy-family-performance-ref summary 'first-kind)
         'session-isolation)
        (check-equal?
         (session-policy-family-performance-ref summary 'last-kind)
         'agent-execution)
        (check-equal?
         (session-policy-family-performance-ref summary 'sandbox-count)
         family-count)
        (check-equal?
         (session-policy-family-performance-ref summary 'sharing-count)
         family-count)
        (check-equal?
         (session-policy-family-performance-ref summary 'runtime-executed)
         #f)
        (session-policy-family-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
