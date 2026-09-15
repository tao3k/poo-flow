;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Input: Marlin handoff data is rebuilt per runtime adapter.

(def marlin-handoff-profile
  '((profile . marlin-runtime)
    (abi . rust)
    (threading . shared)
    (handoff . request-response)
    (proof . required)))

(def (marlin-handoff-ref profile key default-value)
  (let (entry (assoc key profile))
    (if entry (cdr entry) default-value)))

(def (marlin-handoff-hot-loop profile rounds)
  (let loop ((round 0) (accepted 0))
    (if (>= round rounds)
      accepted
      (loop (+ round 1)
            (if (marlin-handoff-ref profile 'abi #f)
              (+ accepted 1)
              accepted)))))
