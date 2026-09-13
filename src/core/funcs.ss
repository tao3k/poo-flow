;;; -*- Gerbil -*-
;;; Reusable algorithmic functions for the POO Flow core.

(export poo-flow-memoize
        poo-flow-make-value-index
        poo-flow-value-index-put!
        poo-flow-value-index-ref
        poo-flow-make-frontier-state
        poo-flow-frontier-state-ready-ids
        poo-flow-frontier-state-complete!)

;; Presence is checked separately so an explicitly cached #f remains cached.
(def (poo-flow-memoize key-of compute)
  (let (entries (make-hash-table))
    (lambda (input)
      (let (key (key-of input))
        (if (hash-key? entries key)
          (hash-get entries key)
          (let (value (compute input))
            (hash-put! entries key value)
            value))))))

;; Runner-local DAG values use structural node ids and may legitimately hold
;; #f, so lookup reports presence separately from the stored value.
(def (poo-flow-make-value-index)
  (make-hash-table))

(def (poo-flow-value-index-put! index id value)
  (hash-put! index id value)
  index)

(def (poo-flow-value-index-ref index id)
  (if (hash-key? index id)
    (values #t (hash-get index id))
    (values #f #f)))

;; Incremental frontier state keeps graph traversal proportional to the graph
;; plus the frontier payloads emitted by receipts. Node order remains the
;; canonical plan order through ordinal insertion.
(defstruct poo-flow-frontier-state
  (ready dependents remaining ordinals)
  transparent: #t)

(def (poo-flow-frontier-state-ready-ids state)
  (poo-flow-frontier-state-ready state))

(def (poo-flow-make-frontier-state nodes id-of ordinal-of dependencies-of)
  (let ((dependents (make-hash-table))
        (remaining (make-hash-table))
        (ordinals (make-hash-table)))
    (let loop ((rest nodes) (ready-rev '()))
      (if (null? rest)
        (make-poo-flow-frontier-state
         (reverse ready-rev) dependents remaining ordinals)
        (let* ((node (car rest))
               (id (id-of node))
               (dependencies (dependencies-of node)))
          (hash-put! ordinals id (ordinal-of node))
          (hash-put! remaining id (length dependencies))
          (for-each
           (lambda (dependency-id)
             (hash-put! dependents dependency-id
                        (cons id (or (hash-get dependents dependency-id) '()))))
           dependencies)
          (loop (cdr rest)
                (if (null? dependencies) (cons id ready-rev) ready-rev)))))))

(def (poo-flow-frontier-insert id ids ordinals)
  (cond
   ((null? ids) (list id))
   ((< (hash-get ordinals id) (hash-get ordinals (car ids)))
    (cons id ids))
   (else
    (cons (car ids)
          (poo-flow-frontier-insert id (cdr ids) ordinals)))))

(def (poo-flow-frontier-remove id ids)
  (cond
   ((null? ids) '())
   ((equal? id (car ids)) (cdr ids))
   (else (cons (car ids) (poo-flow-frontier-remove id (cdr ids))))))

(def (poo-flow-frontier-state-complete! state completed-id)
  (let ((remaining (poo-flow-frontier-state-remaining state))
        (ordinals (poo-flow-frontier-state-ordinals state)))
    (let loop
        ((dependents
          (reverse
           (or (hash-get
                (poo-flow-frontier-state-dependents state) completed-id)
               '())))
         (ready
          (poo-flow-frontier-remove
           completed-id (poo-flow-frontier-state-ready state))))
      (if (null? dependents)
        (begin
          (poo-flow-frontier-state-ready-set! state ready)
          state)
        (let* ((dependent-id (car dependents))
               (next-count (- (hash-get remaining dependent-id) 1)))
          (hash-put! remaining dependent-id next-count)
          (loop (cdr dependents)
                (if (zero? next-count)
                  (poo-flow-frontier-insert dependent-id ready ordinals)
                  ready)))))))
