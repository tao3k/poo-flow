;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Reusable indexing algorithms for stable POO object families.

(export poo-object-family-position-index)

;; Leftmost duplicate wins, matching the former alist/assoc behavior.
(def (poo-object-family-position-index identities)
  (let (index (make-hash-table-eq))
    (let loop ((rest identities) (position 0))
      (unless (null? rest)
        (unless (hash-key? index (car rest))
          (hash-put! index (car rest) position))
        (loop (cdr rest) (+ position 1))))
    index))
