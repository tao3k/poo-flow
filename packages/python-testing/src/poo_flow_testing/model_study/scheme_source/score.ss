;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;;
;;; Read data only. The caller restricts the model answer to a small
;;; S-expression alphabet; this program never evaluates it.
(export main)

(def (read-one path)
  (call-with-input-file path
    (lambda (port)
      (let ((datum (read port)))
        (if (eof-object? (read port)) datum #f)))))

(def (row-set=? left right)
  (and (list? left) (list? right)
       (= (length left) (length right))
       (andmap (lambda (row) (and (list? row) (member row right equal?))) left)
       (andmap (lambda (row) (and (list? row) (member row left equal?))) right)))

(def (score expected-path answer-path)
  (let* ((expected (read-one expected-path))
         (answer (read-one answer-path))
         (valid (and (list? answer)
                     (pair? answer)
                     (eq? (car answer) 'answer)
                     (andmap list? (cdr answer))))
         (correct (and valid
                       (list? expected)
                       (= (length answer) (length expected))
                       (andmap row-set=? (cdr answer) (cdr expected)))))
    (write (list 'score (list 'valid (if valid #t #f))
                 (list 'correct (if correct #t #f))))
    (newline)
    (force-output)))

(def (main . paths)
  (if (= (length paths) 2)
    (score (car paths) (cadr paths))
    (let loop ()
      (let (expected-path (read))
        (unless (or (eof-object? expected-path) (eq? expected-path 'quit))
          (score expected-path (read))
          (loop))))))
