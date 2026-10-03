;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Emit actual dependency admission progress; no timer heartbeat.
(def loaded-temporal-modules '())
(def (temporal-module-file name suffix)
  (let loop ((roots (cons (path-expand "lib" (gerbil-home)) (load-path))))
    (and (pair? roots)
      (let (path (path-expand (string-append name suffix) (car roots)))
        (if (file-exists? path) path (loop (cdr roots)))))))
(def (temporal-module-dependencies form)
  (cond ((and (pair? form) (eq? (car form) 'load-module) (pair? (cdr form)) (string? (cadr form))) (list (cadr form)))
        ((pair? form) (append (temporal-module-dependencies (car form)) (temporal-module-dependencies (cdr form))))
        (else '())))
(def (temporal-preload-module name)
  (unless (member name loaded-temporal-modules)
    (set! loaded-temporal-modules (cons name loaded-temporal-modules))
    (unless (string-contains name "~")
      (let (path (temporal-module-file name ".scm"))
        (when path
          (call-with-input-file path
            (lambda (port)
              (let loop ((form (read port)))
                (unless (eof-object? form)
                  (for-each temporal-preload-module (temporal-module-dependencies form))
                  (loop (read port)))))))))
    (displayln "MODULE-LOAD " name) (force-output)
    (load-module name)
    (displayln "MODULE-LOADED " name) (force-output)
    (when (and (not (string-contains name "~")) (temporal-module-file name ".ssi"))
      (displayln "MODULE-IMPORT " name) (force-output)
      (gx#import-module (string->symbol (string-append ":" name)) #f #t)
      (displayln "MODULE-IMPORTED " name) (force-output))))
