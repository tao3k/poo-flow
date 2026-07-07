;;; -*- Gerbil -*-
;;; Input: durable receipts are scanned repeatedly for identity fields.

(def durable-receipt
  '((job-id . job-42)
    (operation . checkpoint)
    (store . turso)
    (artifact . artifact-42)
    (status . committed)))

(def (durable-receipt-ref receipt key)
  (cdr (assoc key receipt)))

(def (durable-receipt-hot-loop receipt rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (let ((job-id (durable-receipt-ref receipt 'job-id))
            (artifact (durable-receipt-ref receipt 'artifact)))
        (loop (+ round 1)
              (if (and job-id artifact) (+ accepted 1) accepted))))))
