;;; Boundary: Scheme POO canonically owns Batched Merkle evidence semantics.
(import :clan/poo/object
        :std/crypto/digest
        :std/text/hex)

(export poo-flow-batched-evidence-leaf
        poo-flow-batched-merkle-root
        poo-flow-batched-merkle-proof
        poo-flow-batched-merkle-proof-verify?)

(def (canonical-field value)
  (cond
   ((string? value) value)
   ((symbol? value) (symbol->string value))
   ((and (integer? value) (>= value 0)) (number->string value))
   (else (error "non-canonical Batched Merkle field" value))))

(def (canonical-packet domain fields)
  (foldl
   (lambda (value packet)
     (let (text (canonical-field value))
       (string-append packet
                      (number->string (u8vector-length (string->utf8 text)))
                      ":" text)))
   domain
   fields))

(def (merkle-digest domain fields)
  (hex-encode (sha256 (canonical-packet domain fields))))

(def (poo-flow-batched-evidence-leaf
      identity leaf-index token-nonce first-seq last-seq payload-hash
      semantic-hash previous-root observation-hash effect-outcome)
  (let* ((canonical
          (list 'poo-flow.batched-evidence-leaf.draft.1 identity leaf-index
                token-nonce first-seq last-seq payload-hash semantic-hash
                previous-root observation-hash effect-outcome))
         (leaf-hash
          (merkle-digest "poo-flow.batched-evidence-leaf.draft.1|"
                         (cdr canonical))))
    (.o (kind 'poo-flow-batched-evidence-leaf)
        (schema 'poo-flow.batched-evidence-leaf.draft.1)
        (leaf-id identity) (index leaf-index) (nonce token-nonce)
        (first-sequence first-seq) (last-sequence last-seq)
        (payload-digest payload-hash) (semantic-root semantic-hash)
        (previous-execution-root previous-root)
        (observation-digest observation-hash) (outcome effect-outcome)
        (digest leaf-hash))))

(def (node-digest left right)
  (merkle-digest "poo-flow.batched-merkle-node.draft.1|" (list left right)))

(def (next-level digests)
  (let loop ((remaining digests) (next '()))
    (cond
     ((null? remaining) (reverse next))
     ((null? (cdr remaining))
      (reverse (cons (node-digest (car remaining) (car remaining)) next)))
     (else
      (loop (cddr remaining)
            (cons (node-digest (car remaining) (cadr remaining)) next))))))

(def (root-digest digests)
  (cond
   ((null? digests) (error "Batched Merkle tree requires at least one leaf"))
   ((null? (cdr digests)) (car digests))
   (else (root-digest (next-level digests)))))

(def (poo-flow-batched-merkle-root leaves)
  (let* ((digests (map (lambda (leaf) (.ref leaf 'digest)) leaves))
         (root-hash (root-digest digests)))
    (.o (kind 'poo-flow-batched-merkle-root)
        (schema 'poo-flow.batched-merkle-root.draft.1)
        (leaf-count (length leaves))
        (digest root-hash))))

(def (proof-step step-direction sibling)
  (.o (kind 'poo-flow-batched-merkle-proof-step)
      (direction step-direction) (sibling-digest sibling)))

(def (level-proof digests index)
  (let* ((count (length digests))
         (right? (even? index))
         (sibling-index
          (if right?
            (if (< (+ index 1) count) (+ index 1) index)
            (- index 1))))
    (proof-step (if right? 'right 'left)
                (list-ref digests sibling-index))))

(def (poo-flow-batched-merkle-proof leaves target-index)
  (unless (and (integer? target-index)
               (>= target-index 0)
               (< target-index (length leaves)))
    (error "Batched Merkle proof index out of bounds" target-index))
  (let loop ((digests (map (lambda (leaf) (.ref leaf 'digest)) leaves))
             (index target-index)
             (proof-steps '()))
    (if (null? (cdr digests))
      (.o (kind 'poo-flow-batched-merkle-proof)
          (schema 'poo-flow.batched-merkle-proof.draft.1)
          (leaf-index target-index) (leaf-count (length leaves))
          (steps (reverse proof-steps)) (root-digest (car digests)))
      (loop (next-level digests) (quotient index 2)
            (cons (level-proof digests index) proof-steps)))))

(def (poo-flow-batched-merkle-proof-verify? leaf proof)
  (let ((computed
         (foldl
          (lambda (step current)
            (let (sibling (.ref step 'sibling-digest))
              (case (.ref step 'direction)
                ((left) (node-digest sibling current))
                ((right) (node-digest current sibling))
                (else #f))))
          (.ref leaf 'digest)
          (.ref proof 'steps))))
    (and computed (equal? computed (.ref proof 'root-digest)))))
