;;; -*- Gerbil -*-
;;; Input: proof facts are rebuilt and scanned as ad hoc alists.

(def proof-facts
  '(((name . tool-scope) (status . passed) (source . policy))
    ((name . runtime-handoff) (status . passed) (source . runtime))
    ((name . artifact-boundary) (status . passed) (source . durable))))

(def (proof-fact-name entry)
  (cdr (assoc 'name entry)))

(def (proof-fact-status facts fact-name)
  (let loop ((remaining facts))
    (if (null? remaining)
      #f
      (let (entry (car remaining))
        (if (eq? (proof-fact-name entry) fact-name)
          (cdr (assoc 'status entry))
          (loop (cdr remaining)))))))

(def (proof-fact-hot-loop facts rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (loop (+ round 1)
            (if (eq? (proof-fact-status facts 'tool-scope) 'passed)
              (+ accepted 1)
              accepted)))))
