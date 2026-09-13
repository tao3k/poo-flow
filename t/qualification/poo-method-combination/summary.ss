;;; -*- Gerbil -*-
;;; Pure POO projection: native performance trial receipts -> summaries.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 delete-duplicates))
(export combination-performance-summaries)

(def (trial-key row)
  (map (lambda (key) (.ref row key)) '(depth from qualifiers)))

(def (metric row owner name)
  (let* ((measurement (.ref row owner))
         (value (.ref measurement name)))
    (unless (and (real? value) (>= value 0))
      (error "Invalid performance metric" owner name value))
    value))

(def (distribution values)
  (when (null? values) (error "Empty performance distribution"))
  (let* ((ordered (sort values <))
         (count-value (length ordered))
         (middle (quotient count-value 2))
         (median-value
          (if (odd? count-value)
            (list-ref ordered middle)
            (/ (+ (list-ref ordered (- middle 1))
                  (list-ref ordered middle))
               2))))
    (.o count: count-value
        min: (car ordered)
        median: median-value
        max: (car (reverse ordered)))))

(def (summary rows)
  (let* ((head (car rows))
         (key-value (trial-key head))
         (iterations-value (.ref head 'iterations))
         (trial-values (map (lambda (row) (.ref row 'trial)) rows))
         (combination-value
          (distribution
           (map (lambda (row) (metric row 'combination 'wall-ms)) rows)))
         (functional-value
          (distribution
           (map (lambda (row) (metric row 'functional 'wall-ms)) rows)))
         (gc-value
          (distribution
           (map (lambda (row) (metric row 'combination 'gc-ms)) rows)))
         (allocation-value
          (distribution
           (map (lambda (row) (metric row 'combination 'allocated-bytes)) rows))))
    (unless (and (>= (length rows) 2)
                 (= (length trial-values)
                    (length (delete-duplicates trial-values)))
                 (andmap
                  (lambda (row)
                    (and (= iterations-value (.ref row 'iterations))
                         (.ref row 'plan-reused?)
                         (= (.ref row 'expected)
                            (metric row 'combination 'checksum))
                         (= (.ref row 'expected)
                            (metric row 'functional 'checksum))))
                  rows))
      (error "Incomplete or inconsistent performance trials" key-value))
    (.o kind: 'poo-combination/performance-summary
        schema: 'v1
        producer: 'poo-flow/module-system/poo-method-combination
        key: key-value
        iterations: iterations-value
        trials: (length rows)
        combination-ms: combination-value
        functional-ms: functional-value
        combination-gc-ms: gc-value
        combination-allocated-bytes: allocation-value
        median-ratio:
        (and (> (.ref functional-value 'median) 0)
             (/ (.ref combination-value 'median)
                (.ref functional-value 'median))))))

(def (combination-performance-summaries rows)
  (let loop ((remaining rows) (summaries '()))
    (if (null? remaining)
      (if (null? summaries)
        (error "No performance trial receipts")
        (reverse summaries))
      (let* ((key (trial-key (car remaining)))
             (matches? (lambda (row) (equal? (trial-key row) key))))
        (loop (filter (lambda (row) (not (matches? row))) remaining)
              (cons (summary (filter matches? remaining)) summaries))))))
