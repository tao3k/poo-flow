;;; -*- Gerbil -*-
;;; Boundary: runtime materialization receipt performance gate.
;;; Invariant: defstruct receipts project to bounded ABI rows in one pass.

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

(export session-materialization-receipt-performance-test)

;; : String
(def session-materialization-receipt-fixture-path
  "t/scenarios/performance/session-materialization-receipt/benchmark.ss")

;; : Alist
(def session-materialization-receipt-fixture
  (call-with-input-file session-materialization-receipt-fixture-path read))

;; : (-> Alist Symbol MaybeValue)
(def (materialization-performance-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Alist Void)
(def (materialization-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] session-materialization-receipt ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> String Integer Symbol)
(def (materialization-performance-symbol prefix index)
  (string->symbol
   (string-append prefix "/" (number->string index))))

;; : (-> Integer Symbol)
(def (materialization-performance-state index)
  (cond
   ((= (modulo index 3) 0) 'pending)
   ((= (modulo index 3) 1) 'materialized)
   (else 'failed)))

;; : (-> Integer MaybeSymbol)
(def (materialization-performance-sandbox-handle index)
  (if (= (modulo index 3) 2)
    #f
    (materialization-performance-symbol "sandbox/handle" index)))

;; : (-> Integer Alist)
(def (materialization-performance-token-usage index)
  (if (= (modulo index 3) 1)
    (list (cons 'prompt-tokens index)
          (cons 'completion-tokens 2)
          (cons 'total-tokens (+ index 2)))
    '()))

;; : (-> Integer MaybeAlist)
(def (materialization-performance-error index)
  (if (= (modulo index 3) 2)
    (list (cons 'error-kind 'RuntimeError)
          (cons 'message "runtime materialization failed")
          (cons 'request-index index))
    #f))

;; : (-> Integer Alist)
(def (materialization-performance-metadata index)
  (let* ((session-ref (materialization-performance-symbol "session/child"
                                                          index))
         (sandbox-handle-ref
          (materialization-performance-symbol "sandbox/handle" index)))
    (list (cons 'source 'performance)
          (cons 'declared-session-refs
                (list 'session/root session-ref))
          (cons 'declared-parent-session-refs
                '(session/root session/system))
          (cons 'declared-sandbox-handle-refs
                (list sandbox-handle-ref)))))

;; : (-> Integer Alist)
(def (materialization-performance-row index)
  (poo-flow-session-materialization-receipt->alist
   (poo-flow-session-runtime-materialization-receipt
    (materialization-performance-symbol "runtime/request" index)
    'project/materialization
    'session/root
    (materialization-performance-symbol "session/child" index)
    '(session/root session/system)
    (materialization-performance-state index)
    (materialization-performance-symbol "runtime/future" index)
    (materialization-performance-sandbox-handle index)
    (materialization-performance-token-usage index)
    (materialization-performance-error index)
    (materialization-performance-metadata index))))

;; : (-> [Alist] Integer)
(def (materialization-performance-valid-count rows)
  (let loop ((remaining-rows rows)
             (count 0))
    (cond
     ((null? remaining-rows) count)
     ((materialization-performance-ref (car remaining-rows) 'valid?)
      (loop (cdr remaining-rows) (+ count 1)))
     (else
      (loop (cdr remaining-rows) count)))))

;; : (-> [Alist] Integer)
(def (materialization-performance-diagnostic-count rows)
  (let loop ((remaining-rows rows)
             (count 0))
    (if (null? remaining-rows)
      count
      (loop (cdr remaining-rows)
            (+ count
               (materialization-performance-ref
                (car remaining-rows)
                'diagnostic-count))))))

;; : (-> Integer Alist)
(def (materialization-performance-summary count)
  (let (rows
        (poo-flow-performance-build-list
         count
         materialization-performance-row))
    (list (cons 'receipt-count (length rows))
          (cons 'first-state
                (materialization-performance-ref
                 (car rows)
                 'materialization-state))
          (cons 'last-state
                (materialization-performance-ref
                 (list-ref rows (- count 1))
                 'materialization-state))
          (cons 'valid-count
                (materialization-performance-valid-count rows))
          (cons 'diagnostic-count
                (materialization-performance-diagnostic-count rows))
          (cons 'declaration-checked?
                (materialization-performance-ref
                 (car rows)
                 'declaration-checked?))
          (cons 'sandbox-handle-declared?
                (materialization-performance-ref
                 (car rows)
                 'sandbox-handle-declared?))
          (cons 'runtime-executed
                (materialization-performance-ref
                 (car rows)
                 'runtime-executed)))))

;; : TestSuite
(def session-materialization-receipt-performance-test
  (test-suite "session materialization receipt performance"
    (test-case "keeps materialization receipt batch projection inside benchmark contract"
      (let* ((receipt-count 300)
             (summary (materialization-performance-summary receipt-count))
             (receipt
              (benchmark-run
               session-materialization-receipt-fixture
               (lambda ()
                 (materialization-performance-summary receipt-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass?
          session-materialization-receipt-fixture)
         #t)
        (check-equal?
         (materialization-performance-ref summary 'receipt-count)
         receipt-count)
        (check-equal? (materialization-performance-ref summary 'first-state)
                      'pending)
        (check-equal? (materialization-performance-ref summary 'last-state)
                      'failed)
        (check-equal?
         (materialization-performance-ref summary 'valid-count)
         receipt-count)
        (check-equal?
         (materialization-performance-ref summary 'diagnostic-count)
         0)
        (check-equal?
         (materialization-performance-ref summary 'declaration-checked?)
         #t)
        (check-equal?
         (materialization-performance-ref summary 'sandbox-handle-declared?)
         #t)
        (check-equal?
         (materialization-performance-ref summary 'runtime-executed)
         #f)
        (materialization-performance-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
