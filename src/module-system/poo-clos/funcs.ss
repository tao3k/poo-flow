;;; -*- Gerbil -*-
;;; Reusable linear-time list and initarg algorithms for the POO CLOS module.
;;; Domain files own policy; this factor owns traversal and indexing mechanics.

(import (only-in :std/misc/plist plist?)
        (only-in :std/misc/list delete-duplicates/hash)
        (only-in :std/misc/hash
                 hash-ref/default hash-ensure-modify!
                 invert-hash<-vector)
        (only-in :std/srfi/1 filter))

(export poo-clos-initarg-list? poo-clos-initarg-names
        poo-clos-initarg-ref poo-clos-initarg-index
        poo-clos-initarg-index-first-of poo-clos-identity-index
        poo-clos-leftmost-index-by poo-clos-first-invalid-initarg
        poo-clos-position-index/identity
        poo-clos-natural-permutation?
        poo-clos-topological-order/identity)

(def (poo-clos-initarg-list? values)
  (and (plist? values)
       (let loop ((rest values))
         (or (null? rest)
             (and (let (name (car rest))
                    (or (symbol? name) (keyword? name)))
                  (loop (cddr rest)))))))

(def (poo-clos-initarg-names values)
  (let loop ((rest values) (result-rev '()))
    (if (null? rest)
      (reverse result-rev)
      (loop (cddr rest) (cons (car rest) result-rev)))))

;; A presence flag keeps an explicit #f value distinct from absence.
(def (poo-clos-initarg-ref arguments name)
  (let loop ((rest arguments))
    (cond ((null? rest) (values #f #f))
          ((eq? (car rest) name) (values #t (cadr rest)))
          (else (loop (cddr rest))))))

;; Retain each key's leftmost position and value, matching CLOS semantics.
(def (poo-clos-initarg-index arguments)
  (let (index (make-hash-table-eq))
    (let loop ((rest arguments) (position 0))
      (unless (null? rest)
        (unless (hash-key? index (car rest))
          (hash-put! index (car rest) (cons position (cadr rest))))
        (loop (cddr rest) (+ position 1))))
    index))

;; A slot can name several initargs; call order decides which value wins.
(def (poo-clos-initarg-index-first-of index names)
  (let (selected #f)
    (for-each
     (lambda (name)
       (let (entry (hash-get index name))
         (when (and entry
                    (or (not selected) (< (car entry) (car selected))))
           (set! selected entry))))
     names)
    (if selected (values #t (cdr selected)) (values #f #f))))

(def (poo-clos-identity-index values)
  (let (index (make-hash-table-eq))
    ;; The supplied table is populated by Gerbil std's O(n) identity-deduper.
    ;; Its returned list is intentionally unnecessary for this set projection.
    (delete-duplicates/hash values table: index from-end?: #t)
    index))

;; Index domain objects once while preserving the first declaration selected
;; by the former linear `find` traversal.
(def (poo-clos-leftmost-index-by key-of values)
  (let ((seen (make-hash-table-eq))
        (index (make-hash-table-eq)))
    (for-each
     (lambda (value)
       (hash-put! index (key-of value) value))
     ;; std owns identity deduplication; this second linear projection records
     ;; the domain object rather than the boolean stored in `seen`.
     (delete-duplicates/hash values table: seen key: key-of from-end?: #t))
    index))

(def (poo-clos-position-index/identity values)
  ;; CLOS precedence inputs are uniqueness-admitted. Gerbil std performs the
  ;; vector inversion; callers outside that contract receive the last position.
  (invert-hash<-vector (list->vector values) to: (make-hash-table-eq)))

;; One bounded vector pass proves that values are exactly 0..size-1.
(def (poo-clos-natural-permutation? values size)
  (and (= (length values) size)
       (let (seen (make-vector size #f))
         (let loop ((rest values))
           (cond
            ((null? rest) #t)
            ((or (not (exact-integer? (car rest)))
                 (< (car rest) 0) (>= (car rest) size)
                 (vector-ref seen (car rest))) #f)
            (else
             (vector-set! seen (car rest) #t)
             (loop (cdr rest))))))))

;; Preserve the first invalid supplied key for stable diagnostics.
(def (poo-clos-first-invalid-initarg arguments valid-index exempt?)
  (let loop ((rest arguments))
    (cond ((null? rest) #f)
          ((or (exempt? (car rest)) (hash-key? valid-index (car rest)))
           (loop (cddr rest)))
          (else (car rest)))))

;; Identity graph ordering indexes outgoing edges and indegrees once.  The
;; caller owns domain-specific ambiguity selection; #f means a cycle or an
;; ambiguity for which the caller supplied no admissible next node.
;; : (forall (a) (-> [a] [(Pair a a)]
;;        (-> (-> a Boolean) [a] (Maybe a)) (Maybe [a])))
(def (poo-clos-topological-order/identity nodes edges select-ambiguous)
  (let ((outgoing (make-hash-table-eq))
        (indegree (make-hash-table-eq))
        (candidate-index (make-hash-table-eq)))
    (for-each (lambda (node) (hash-put! indegree node 0)) nodes)
    (for-each
     (lambda (edge)
       (let ((source (car edge)) (target (cdr edge)))
         (hash-ensure-modify! outgoing source (lambda () '())
                              (lambda (targets) (cons target targets)))
         (hash-ensure-modify! indegree target (lambda () 0) 1+)))
     edges)
    (def initial-candidates
      (filter (lambda (node) (= (hash-get indegree node) 0)) nodes))
    (for-each (lambda (node) (hash-put! candidate-index node #t))
              initial-candidates)
    (def (candidate? node) (hash-key? candidate-index node))
    ;; Selected candidates may remain below the frontier head.  Discard each
    ;; stale entry at most once instead of searching and rebuilding the list.
    (def (active-frontier frontier)
      (if (and (pair? frontier) (not (candidate? (car frontier))))
        (active-frontier (cdr frontier)) frontier))
    (let loop ((remaining (length nodes))
               (candidate-count (length initial-candidates))
               (frontier initial-candidates)
               (result-rev '()))
      (cond
       ((= remaining 0) (reverse result-rev))
       ((= candidate-count 0) #f)
       (else
        (let* ((frontier (active-frontier frontier))
               (next
                (if (= candidate-count 1)
                  (and (pair? frontier) (car frontier))
                  (select-ambiguous candidate? result-rev))))
          (if (not (and next (candidate? next)))
            #f
            (let ((next-count (- candidate-count 1))
                  (next-frontier frontier))
              (hash-remove! candidate-index next)
              (for-each
               (lambda (target)
                 (let (degree (- (hash-get indegree target) 1))
                   (hash-put! indegree target degree)
                   (when (= degree 0)
                     (hash-put! candidate-index target #t)
                     (set! next-count (+ next-count 1))
                     (set! next-frontier (cons target next-frontier)))))
               (hash-ref/default outgoing next (lambda () '())))
              (loop (- remaining 1) next-count next-frontier
                    (cons next result-rev))))))))))
