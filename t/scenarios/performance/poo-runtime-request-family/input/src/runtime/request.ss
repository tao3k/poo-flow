;;; -*- Gerbil -*-
;;; Input: runtime request data is repeatedly scanned as alists.

(def runtime-request
  '((request-id . request-42)
    (runtime . rust)
    (operation . tool-call)
    (policy . proof-gated)
    (artifact . artifact-42)))

(def (runtime-request-ref request key default-value)
  (let (entry (assoc key request))
    (if entry (cdr entry) default-value)))

(def (runtime-request-hot-loop request rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (let ((runtime (runtime-request-ref request 'runtime #f))
            (operation (runtime-request-ref request 'operation #f))
            (policy (runtime-request-ref request 'policy #f)))
        (loop (+ round 1)
              (if (and runtime operation policy)
                (+ accepted 1)
                accepted))))))
