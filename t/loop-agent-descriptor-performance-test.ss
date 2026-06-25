;;; -*- Gerbil -*-
;;; Boundary: loop descriptor performance gates cover POO slot projection.
;;; Invariant: descriptor contract projection stays data-only and bounded.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :std/srfi/1 fold)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/loops/descriptor
                 make-loop-pattern-descriptor
                 loop-pattern-descriptor->contract))

(export loop-agent-descriptor-performance-test)

;; : String
(def loop-descriptor-contract-projection-fixture-path
  "t/scenarios/performance/loop-descriptor-contract-projection/benchmark.ss")

;; : Alist
(def loop-descriptor-contract-projection-fixture
  (call-with-input-file loop-descriptor-contract-projection-fixture-path read))

;; : (-> Alist (-> Value) Alist)
(def (loop-descriptor-performance-run-gate fixture thunk)
  (if (benchmark-fixture-contract-pass? fixture)
    (benchmark-run fixture thunk)
    (error "loop descriptor performance fixture contract failed" fixture)))

;; : (-> Integer Symbol)
(def (loop-descriptor-performance-name index)
  (string->symbol
   (string-append "loop-descriptor-" (number->string index))))

;; : (-> Integer Alist)
(def (loop-descriptor-performance-overrides index)
  (list (cons 'level (if (= (modulo index 3) 0) 'l1 'l2))
        (cons 'priority (+ 10 index))
        (cons 'watched-scope '(pull-requests ci docs))
        (cons 'budget '((max-attempts . 2)
                        (token-cap . 200000)))
        (cons 'isolation '((mode . worktree)))
        (cons 'maker '((agent . implementer)
                       (can-write . #t)))
        (cons 'checker '((agent . verifier)
                         (required . #t)))
        (cons 'safety
              '((human-gates . (security dependency-upgrade repeated-failure))
                (denylist . ("infra/**" "secrets/**"))
                (auto-merge . #f)))
        (cons 'observability '((receipt . required)
                               (timeline . compact)))
        (cons 'metadata (list (cons 'index index)))))

;; : (-> Integer LoopPatternDescriptor)
(def (loop-descriptor-performance-descriptor index)
  (make-loop-pattern-descriptor
   (loop-descriptor-performance-name index)
   "Project loop descriptor contract data without runtime side effects."
   (loop-descriptor-performance-overrides index)))

;; : (-> Integer [LoopPatternDescriptor])
(def (loop-descriptor-performance-descriptors count)
  (poo-flow-performance-build-list
   count
   loop-descriptor-performance-descriptor))

;; : (-> Alist Symbol Value)
(def (loop-descriptor-performance-ref alist key)
  (cdr (assoc key alist)))

;; : (-> LoopPatternDescriptor Integer)
(def (loop-descriptor-performance-contract-priority descriptor)
  (loop-descriptor-performance-ref
   (loop-pattern-descriptor->contract descriptor)
   'priority))

;; : (-> [LoopPatternDescriptor] Pair)
(def (loop-descriptor-performance-summary-state descriptors)
  (fold (lambda (descriptor state)
          (cons (+ (car state) 1)
                (+ (cdr state)
                   (loop-descriptor-performance-contract-priority
                    descriptor))))
        (cons 0 0)
        descriptors))

;;; Intent: summarize contract projection over a large descriptor list.
;;; Boundary: fold state is internal; callers receive an alist fixture summary.
;; : (-> [LoopPatternDescriptor] Alist)
(def (loop-descriptor-performance-project-contract-summary descriptors)
  (let (state (loop-descriptor-performance-summary-state descriptors))
    (list (cons 'count (car state))
          (cons 'priority-sum (cdr state)))))

;; : TestSuite
(def loop-agent-descriptor-performance-test
  (test-suite "loop-agent descriptor performance"
    (test-case "keeps loop descriptor performance fixture inside benchmark contract"
      (check-equal?
       (benchmark-fixture-contract-pass?
        loop-descriptor-contract-projection-fixture)
       #t))

    (test-case "projects many loop descriptor contracts with one slot sampling pass"
      (let* ((descriptor-count 1200)
             (descriptors
              (loop-descriptor-performance-descriptors descriptor-count))
             (first-contract
              (loop-pattern-descriptor->contract (car descriptors)))
             (summary
              (loop-descriptor-performance-project-contract-summary descriptors))
             (receipt
              (loop-descriptor-performance-run-gate
               loop-descriptor-contract-projection-fixture
               (lambda ()
                 (loop-descriptor-performance-project-contract-summary
                  descriptors)))))
        (check-equal?
         (loop-descriptor-performance-ref summary 'count)
         descriptor-count)
        (check-equal?
         (loop-descriptor-performance-ref summary 'priority-sum)
         731400)
        (check-equal?
         (loop-descriptor-performance-ref first-contract 'name)
         'loop-descriptor-0)
        (check-equal?
         (loop-descriptor-performance-ref first-contract 'priority)
         10)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
