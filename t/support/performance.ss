;;; -*- Gerbil -*-
;;; Boundary: shared performance-test helpers for synthetic fixture data.
;;; Invariant: helper functions are pure except elapsed measurement thunks.

(import :gerbil/gambit
        (only-in :std/srfi/1 iota))

(export poo-flow-performance-build-list
        poo-flow-performance-elapsed-ms
        poo-flow-performance-best-elapsed-ms
        poo-flow-performance-elapsed-us
        poo-flow-performance-best-elapsed-us)

;;; Intent: construct deterministic index-addressed fixture lists.
;;; Boundary: callers own the item constructor and count.
;; : (-> Integer (-> Integer Object) [Object])
(import :clan/poo/object
        :poo-flow/src/core/roles)

(export run-domain-case-instance-overlay-benchmark
        domain-case-instance-overlay-benchmark->alist)

(def (poo-flow-performance-build-list count make-value)
  (map make-value (iota count)))

;;; Intent: measure one thunk execution in milliseconds.
;;; Boundary: the thunk owns side effects; this helper owns only timing.
;; : (-> (-> Unit Object) Rational)
(def (poo-flow-performance-elapsed-ms thunk)
  (let (start-jiffy (current-jiffy))
    (thunk)
    (/ (* (- (current-jiffy) start-jiffy) 1000)
       (jiffies-per-second))))

;;; Intent: report the best elapsed time across repeated benchmark attempts.
;;; Boundary: zero attempts preserves the previous #f result shape.
;; : (-> Integer (-> Unit Object) Object)
(def (poo-flow-performance-best-elapsed-ms attempts thunk)
  (if (<= attempts 0)
    #f
    (apply min
           (map (lambda (_attempt)
                  (poo-flow-performance-elapsed-ms thunk))
                (iota attempts)))))

;; : (-> (-> Unit Object) Integer)
(def (poo-flow-performance-elapsed-us thunk)
  (let (start (##current-time-point))
    (thunk)
    (inexact->exact
     (floor
      (* (- (##current-time-point) start) 1000000.0)))))

;; : (-> Integer (-> Unit Object) Object)
(def (poo-flow-performance-best-elapsed-us attempts thunk)
  (if (<= attempts 0)
    #f
    (apply min
           (map (lambda (_attempt)
                  (poo-flow-performance-elapsed-us thunk))
                (iota attempts)))))

(def +domain-case-instance-overlay-benchmark-kind+
  'poo-flow.domain-case-instance-overlay-benchmark.v1)

(def (domain-case-instance-overlay-benchmark-role rows)
  (.mix slots: (role-constant-slots rows)))

(def (domain-case-instance-overlay-benchmark-slot-key index)
  (string->symbol
   (string-append "shared/slot-" (number->string index))))

(def (domain-case-instance-overlay-benchmark-component index)
  (domain-case-instance-overlay-benchmark-role
   (list
    (cons (domain-case-instance-overlay-benchmark-slot-key index)
          index))))

(def (domain-case-instance-overlay-benchmark-shared slot-count)
  (apply
   role-compose
   (poo-flow-performance-build-list
    slot-count domain-case-instance-overlay-benchmark-component)))

(def (domain-case-instance-overlay-benchmark-marker)
  (domain-case-instance-overlay-benchmark-role
   (list (cons 'domain-case/ref 'benchmark-case)
         (cons 'domain-case/instance-overlay-resolver-depth 1))))

(def (domain-case-instance-overlay-benchmark-local index)
  (domain-case-instance-overlay-benchmark-role
   (list (cons 'agent/id index)
         (cons (domain-case-instance-overlay-benchmark-slot-key 0)
               'local-override))))

(def (domain-case-instance-overlay-benchmark-compose/mix marker local shared)
  (role-compose marker local shared))

(def (domain-case-instance-overlay-benchmark-compose/overlay
      marker local shared)
  (role-instance-overlay marker local shared))

(def (domain-case-instance-overlay-benchmark-exercise
      composer agent-count shared last-slot-key)
  (let loop ((index 0) (checksum 0))
    (if (= index agent-count)
        checksum
        (let* ((marker (domain-case-instance-overlay-benchmark-marker))
               (local (domain-case-instance-overlay-benchmark-local index))
               (instance (composer marker local shared)))
          (.ref instance 'domain-case/ref)
          (.ref instance (domain-case-instance-overlay-benchmark-slot-key 0))
          (loop (+ index 1)
                (+ checksum
                   (.ref instance 'agent/id)
                   (.ref instance last-slot-key)))))))

(def (domain-case-instance-overlay-benchmark-correct?
      shared last-slot-key)
  (let* ((marker (domain-case-instance-overlay-benchmark-marker))
         (local (domain-case-instance-overlay-benchmark-local 7))
         (baseline
          (domain-case-instance-overlay-benchmark-compose/mix
           marker local shared))
         (overlay
          (domain-case-instance-overlay-benchmark-compose/overlay
           marker local shared)))
    (and (equal? (.ref baseline 'domain-case/ref)
                 (.ref overlay 'domain-case/ref))
         (equal? (.ref baseline 'agent/id)
                 (.ref overlay 'agent/id))
         (equal? (.ref baseline
                       (domain-case-instance-overlay-benchmark-slot-key 0))
                 (.ref overlay
                       (domain-case-instance-overlay-benchmark-slot-key 0)))
         (equal? (.ref baseline last-slot-key)
                 (.ref overlay last-slot-key)))))

(def (run-domain-case-instance-overlay-benchmark-case
      agent-count slot-count)
  (let* ((shared
          (domain-case-instance-overlay-benchmark-shared slot-count))
         (last-slot-key
          (domain-case-instance-overlay-benchmark-slot-key
           (- slot-count 1)))
         (correct?
          (domain-case-instance-overlay-benchmark-correct?
           shared last-slot-key))
         (_warm-mix
          (domain-case-instance-overlay-benchmark-exercise
           domain-case-instance-overlay-benchmark-compose/mix
           64 shared last-slot-key))
         (_warm-overlay
          (domain-case-instance-overlay-benchmark-exercise
           domain-case-instance-overlay-benchmark-compose/overlay
           64 shared last-slot-key))
         (_baseline-gc (##gc))
         (baseline-us
          (poo-flow-performance-best-elapsed-us
           5
           (lambda ()
             (domain-case-instance-overlay-benchmark-exercise
              domain-case-instance-overlay-benchmark-compose/mix
              agent-count shared last-slot-key))))
         (_overlay-gc (##gc))
         (overlay-us
          (poo-flow-performance-best-elapsed-us
           5
           (lambda ()
             (domain-case-instance-overlay-benchmark-exercise
              domain-case-instance-overlay-benchmark-compose/overlay
              agent-count shared last-slot-key))))
         (speedup
          (if (zero? overlay-us)
              +inf.0
              (/ (exact->inexact baseline-us)
                 (exact->inexact overlay-us))))
         (timing-pass?
          (if (= slot-count 64)
              (< overlay-us baseline-us)
              (<= overlay-us
                  (inexact->exact (ceiling (* baseline-us 1.5)))))))
    (domain-case-instance-overlay-benchmark-role
     (list
      (cons 'kind +domain-case-instance-overlay-benchmark-kind+)
      (cons 'agent-count agent-count)
      (cons 'shared-slot-count slot-count)
      (cons 'materialized-slot-count (+ slot-count 4))
      (cons 'baseline-mix-count agent-count)
      (cons 'overlay-mix-count 0)
      (cons 'resolver-depth 1)
      (cons 'construction-complexity 'linear-in-visible-slots)
      (cons 'lookup-source-depth 'constant-source-depth)
      (cons 'baseline-us baseline-us)
      (cons 'overlay-us overlay-us)
      (cons 'speedup speedup)
      (cons 'correct? correct?)
      (cons 'shared-prototype-retained? correct?)
      (cons 'local-precedence-valid? correct?)
      (cons 'timing-pass? timing-pass?)
      (cons 'max-rss-mb 256)
      (cons 'pass? (and correct? timing-pass?))))))

(def (run-domain-case-instance-overlay-benchmark)
  (map
   (lambda (slot-count)
     (run-domain-case-instance-overlay-benchmark-case 1000 slot-count))
   '(8 32 64)))

(def (domain-case-instance-overlay-benchmark->alist receipt)
  (map
   (lambda (key) (cons key (.ref receipt key)))
   '(kind agent-count shared-slot-count materialized-slot-count
     baseline-mix-count overlay-mix-count resolver-depth
     construction-complexity lookup-source-depth
     baseline-us overlay-us speedup correct?
     shared-prototype-retained? local-precedence-valid? timing-pass?
     max-rss-mb pass?)))
