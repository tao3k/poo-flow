;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Emit actual dependency admission progress; no timer heartbeat.
(def loaded-runtime-modules '())
(def (runtime-module-file name suffix)
  (let loop ((roots (cons (path-expand "lib" (gerbil-home)) (load-path))))
    (and (pair? roots)
      (let (path (path-expand (string-append name suffix) (car roots)))
        (if (file-exists? path) path (loop (cdr roots)))))))
(def (runtime-module-dependencies form)
  (cond ((and (pair? form) (eq? (car form) 'load-module) (pair? (cdr form)) (string? (cadr form))) (list (cadr form)))
        ((pair? form) (append (runtime-module-dependencies (car form)) (runtime-module-dependencies (cdr form))))
        (else '())))
(def (runtime-preload-module! name)
  (unless (member name loaded-runtime-modules)
    (set! loaded-runtime-modules (cons name loaded-runtime-modules))
    (unless (string-contains name "~")
      (let (path (runtime-module-file name ".scm"))
        (when path
          (call-with-input-file path
            (lambda (port)
              (let loop ((form (read port)))
                (unless (eof-object? form)
                  (for-each runtime-preload-module! (runtime-module-dependencies form))
                  (loop (read port)))))))))
    (displayln "MODULE-LOAD " name) (force-output)
    (load-module name)
    (displayln "MODULE-LOADED " name) (force-output)
    (when (and (not (string-contains name "~")) (runtime-module-file name ".ssi"))
      (displayln "MODULE-IMPORT " name) (force-output)
      (gx#import-module (string->symbol (string-append ":" name)) #f #t)
      (displayln "MODULE-IMPORTED " name) (force-output))))
