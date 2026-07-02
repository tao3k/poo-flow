;;; -*- Gerbil -*-
;;; Boundary: hygienic helpers for agent-sandbox final row projections.
;;; Invariant: generated rows remain plain alists at request, validation,
;;; profile, and Marlin handoff boundaries.

(export agent-sandbox-rows/tail
        agent-sandbox-rows-into/rev
        agent-sandbox-field-rows
        agent-sandbox-field-rows/tail)

;;; Agent sandbox projection helpers stay syntax-only and projection-only:
;;; callers assemble ABI rows here, while runtime execution remains elsewhere.
;; agent-sandbox-rows/tail
;;   : (-> Alist Alist Alist)
;;   | contract: ordered sandbox projection rows followed by caller-owned tail rows
;;   | result: a fresh ordered alist preserving row order before the tail
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (agent-sandbox-rows/tail '((kind . sandbox)) '((metadata)))
;;       ;; => ((kind . sandbox) (metadata))
;;       ```
;;     %
(def (agent-sandbox-rows/tail rows tail)
  (append rows tail))

;; agent-sandbox-rows-into/rev
;;   : (-> Alist Alist Alist)
;;   | contract: fold ordered rows into an existing reversed accumulator
;;   | result: reversed rows prepended onto the supplied accumulator
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (agent-sandbox-rows-into/rev '((a . 1) (b . 2)) '((tail)))
;;       ;; => ((b . 2) (a . 1) (tail))
;;       ```
;;     %
(def (agent-sandbox-rows-into/rev rows rows-rev)
  (foldl cons rows-rev rows))

;; agent-sandbox-field-rows
;;   : (-> Syntax Alist)
;;   | contract: lower fixed field clauses into literal sandbox alist rows
;;   | result: ordered alist rows with symbols matching field names
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (agent-sandbox-field-rows (kind 'sandbox) (status 'ok))
;;       ;; => ((kind . sandbox) (status . ok))
;;       ```
;;     %
(defrules agent-sandbox-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; agent-sandbox-field-rows/tail
;;   : (-> Syntax Alist)
;;   | contract: lower fixed field clauses and append caller-owned tail rows
;;   | result: ordered field rows followed by the supplied tail alist
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (agent-sandbox-field-rows/tail '((metadata)) (kind 'sandbox))
;;       ;; => ((kind . sandbox) (metadata))
;;       ```
;;     %
(defrules agent-sandbox-field-rows/tail ()
  ((_ tail (field value) ...)
   (agent-sandbox-rows/tail
    (agent-sandbox-field-rows (field value) ...)
    tail)))
