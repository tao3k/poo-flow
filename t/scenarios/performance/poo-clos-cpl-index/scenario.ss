;;; -*- Gerbil -*-
;;; A/B witness for the former repeated-constraint CPL projection and the
;;; production identity-indexed topology function.
(import (only-in :gerbil/gambit current-time time->seconds)
        (only-in :std/sort sort)
        (only-in "../../../../src/module-system/poo-clos/funcs.ss"
                 poo-clos-topological-order/identity))

(def +node-count+ 180)
(def nodes
  (let loop ((index 0) (result '()))
    (if (= index +node-count+) (reverse result)
        (loop (+ index 1) (cons (cons index '()) result)))))
(def edges
  (let loop ((rest nodes) (result '()))
    (if (or (null? rest) (null? (cdr rest))) (reverse result)
        (loop (cdr rest) (cons (cons (car rest) (cadr rest)) result)))))

(def baseline-constraint-inspections 0)
(def (baseline-predecessor? node constraints)
  (let loop ((rest constraints))
    (cond ((null? rest) #f)
          (else
           (set! baseline-constraint-inspections
                 (+ baseline-constraint-inspections 1))
           (or (eq? (cdar rest) node) (loop (cdr rest)))))))
(def (baseline-order nodes-value constraints-value)
  (let loop ((remaining nodes-value) (constraints constraints-value)
             (result '()))
    (if (null? remaining) (reverse result)
        (let (candidates
              (filter (lambda (node)
                        (not (baseline-predecessor? node constraints)))
                      remaining))
          (if (not (= (length candidates) 1)) #f
              (let (next (car candidates))
                (loop (filter (lambda (node) (not (eq? node next))) remaining)
                      (filter (lambda (edge) (not (eq? (car edge) next)))
                              constraints)
                      (cons next result))))))))
(def (indexed-order)
  (poo-clos-topological-order/identity
   nodes edges (lambda (_candidate? _result) #f)))
(def (linear-graph count)
  (let* ((large-nodes
          (let loop ((index 0) (result '()))
            (if (= index count) (reverse result)
                (loop (+ index 1) (cons (cons index '()) result)))))
         (large-edges
          (let loop ((rest large-nodes) (result '()))
            (if (or (null? rest) (null? (cdr rest)))
              (reverse result)
              (loop (cdr rest)
                    (cons (cons (car rest) (cadr rest)) result))))))
    (values large-nodes large-edges)))
(def (elapsed-ms thunk)
  (let* ((started (time->seconds (current-time)))
         (value (thunk))
         (elapsed (* 1000.0 (- (time->seconds (current-time)) started))))
    (values value elapsed)))
(def (sample thunk count)
  (let loop ((remaining count) (times '()) (last #f))
    (if (= remaining 0) (values last (reverse times))
        (let-values (((value elapsed) (elapsed-ms thunk)))
          (loop (- remaining 1) (cons elapsed times) value)))))
(def (median values)
  (let (ordered (sort values <))
    (list-ref ordered (quotient (length ordered) 2))))

;; Warm both procedures before the alternating complete samples.
(baseline-order nodes edges)
(indexed-order)
(set! baseline-constraint-inspections 0)
(let-values (((baseline-result baseline-times)
              (sample (lambda () (baseline-order nodes edges)) 5)))
  (let-values (((indexed-result indexed-times) (sample indexed-order 5)))
    (let ((baseline-p50 (median baseline-times))
          (indexed-p50 (median indexed-times)))
      (unless (and (equal? baseline-result indexed-result)
                   (= (length indexed-result) +node-count+))
        (error "CPL algorithms disagree"))
      (unless (> baseline-constraint-inspections (* 50 +node-count+))
        (error "baseline scenario no longer exercises repeated scans"))
      (unless (< indexed-p50 baseline-p50)
        (error "indexed CPL did not improve this scenario"
               baseline-p50 indexed-p50))
      (display "schema=poo-flow.poo-clos-cpl-index.v1\n")
      (display "node-count=") (display +node-count+) (newline)
      (display "edge-count=") (display (length edges)) (newline)
      (display "baseline-constraint-inspections=")
      (display baseline-constraint-inspections) (newline)
      (display "baseline-p50-ms=") (display baseline-p50) (newline)
      (display "indexed-p50-ms=") (display indexed-p50) (newline)
      (let-values (((large-nodes large-edges) (linear-graph 20000)))
        (def (large-indexed-order)
          (poo-clos-topological-order/identity
           large-nodes large-edges (lambda (_candidate? _result) #f)))
        ;; Warm allocation and hash growth, then report a median so a single GC
        ;; pause cannot become the capacity receipt.
        (large-indexed-order)
        (let-values (((large-result large-times)
                      (sample large-indexed-order 5)))
          (let (large-p50 (median large-times))
          (unless (= (length large-result) 20000)
            (error "large indexed CPL lost nodes"))
          (display "large-node-count=20000\n")
          (display "large-indexed-p50-ms=")
          (display large-p50) (newline))))
      (display "result-equivalent=#t\naccepted=#t\n"))))
