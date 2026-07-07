;;; -*- Gerbil -*-
;;; Input: strategy profiles are copied through each combinator step.

(def base-profile
  '((name . research-agent)
    (tool-policy . scoped)
    (memory . session)
    (handoff . runtime)))

(def (strategy-profile-extend profile key value)
  (cons (cons key value) profile))

(def (strategy-compose profile)
  (strategy-profile-extend
   (strategy-profile-extend profile 'proof 'required)
   'retry 'bounded))

(def (strategy-profile-hot-loop profile rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (loop (+ round 1)
            (if (assoc 'tool-policy profile)
              (+ accepted 1)
              accepted)))))
