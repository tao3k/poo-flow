;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: Doom-like User Interface config discovery.
;;; Invariant: folders contribute ordinary Gerbil modules; final compositions
;;; still lower through the sole public use-composition grammar.

(import (only-in :gerbil/expander/core
                 current-expander-context
                 expander-context-id)
        (only-in :gerbil/expander/stx stx-source)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-suffix?)
        (rename-in :poo-flow/src/module-system/profile-composition/use-syntax
                   (use-composition poo-flow-use-composition/expression))
        (for-syntax
         (only-in :poo-flow/src/core/funcs
                  poo-flow-directory-files-recursive)))

(export use-composition)

(begin-syntax
  ;; One config module may declare many compositions. Discovery and generated
  ;; imports happen once per expander context, keeping the cost O(files + uses).
  (def poo-flow-ui-discovered-contexts (make-hash-table))

  (def (poo-flow-ui-source-path value)
    (cond
     ((string? value) value)
     ((and (pair? value) (string? (car value))) (car value))
     (else #f)))

  (def (poo-flow-ui-drop-suffix suffix value)
    (substring value 0 (- (string-length value) (string-length suffix))))

  (def (poo-flow-ui-string-prefix? prefix value)
    (let ((prefix-length (string-length prefix))
          (value-length (string-length value)))
      (and (>= value-length prefix-length)
           (string=? (substring value 0 prefix-length) prefix))))

  (def (poo-flow-ui-context-name)
    (let (context-id (expander-context-id (current-expander-context)))
      (and (symbol? context-id) (symbol->string context-id))))

  (def (poo-flow-ui-package-name)
    (let* ((package-path (path-expand "gerbil.pkg" (current-directory)))
           (package-data
            (and (file-exists? package-path)
                 (call-with-input-file package-path read))))
      (let loop ((rest package-data))
        (if (and (pair? rest) (pair? (cdr rest)))
          (if (eq? (car rest) 'package:)
            (let (name (cadr rest))
              (cond
               ((symbol? name) (symbol->string name))
               ((string? name) name)
               (else #f)))
            (loop (cdr rest)))
          #f))))

  (def (poo-flow-ui-context-base)
    (let* ((context-name (poo-flow-ui-context-name))
           (config-suffix "/config"))
      (unless (and context-name (string-suffix? config-suffix context-name))
        (error "configuration use-composition must expand from user-interface/config.ss"
               context-name))
      (poo-flow-ui-drop-suffix config-suffix context-name)))

  (def (poo-flow-ui-context-source-path)
    (let* ((context-name (poo-flow-ui-context-name))
           (package-name (poo-flow-ui-package-name))
           (package-prefix
            (and package-name (string-append package-name "/")))
           (relative
            (if (and context-name package-prefix
                     (poo-flow-ui-string-prefix? package-prefix context-name))
              (substring context-name
                         (string-length package-prefix)
                         (string-length context-name))
              context-name)))
      (and relative
           (path-expand (string-append relative ".ss")
                        (current-directory)))))

  (def (poo-flow-ui-discovery-root source)
    (let* ((cwd (current-directory))
           (user-interface-root (path-expand "user-interface" cwd)))
      (cond
       ((and (file-exists? (path-expand "profiles" cwd))
             (file-exists? (path-expand "scenarios" cwd)))
        cwd)
       ((and (file-exists? (path-expand "profiles" user-interface-root))
             (file-exists? (path-expand "scenarios" user-interface-root)))
        user-interface-root)
       (else
        (path-directory source)))))

  (def (poo-flow-ui-discovery-files root role)
    (let (directory (path-expand role root))
      (unless (file-exists? directory)
        (error "missing User Interface discovery directory" directory))
      (filter (lambda (path) (string-suffix? ".ss" path))
              (poo-flow-directory-files-recursive directory))))

  (def (poo-flow-ui-discovery-module root base path)
    (let* ((root-length (string-length root))
           (relative-start
            (if (and (> root-length 0)
                     (char=? (string-ref root (- root-length 1)) #\/))
              root-length
              (+ root-length 1)))
           (relative
            (substring path relative-start (string-length path)))
           (module-tail (poo-flow-ui-drop-suffix ".ss" relative)))
      (string->symbol (string-append ":" base "/" module-tail))))

  (def (poo-flow-ui-discovery-modules stx)
    (let* ((source (or (poo-flow-ui-source-path (stx-source stx))
                       (poo-flow-ui-context-source-path)))
           (root (and source (poo-flow-ui-discovery-root source))))
      (unless root
        (error "use-composition could not resolve its config.ss source" stx))
      (let (base (poo-flow-ui-context-base))
        (map (lambda (path)
               (poo-flow-ui-discovery-module root base path))
             (append (poo-flow-ui-discovery-files root "profiles")
                     (poo-flow-ui-discovery-files root "scenarios")))))))

(begin-syntax
  (def (poo-flow-ui-claim-discovery! stx)
    (let (context (current-expander-context))
      (if (hash-key? poo-flow-ui-discovered-contexts context)
        '()
        (let (modules (poo-flow-ui-discovery-modules stx))
          (hash-put! poo-flow-ui-discovered-contexts context #t)
          modules)))))

;;; In config.ss, the canonical use-composition form is a direct declaration.
;;; Its lexical scope receives every Profile and reusable Scenario discovered
;;; under the sibling folders. No second wrapper or hand-written import list is
;;; part of the user surface.
(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((ctx name clause ...)
     (unless (identifier? #'name)
       (raise-syntax-error #f "use-composition name must be an identifier" #'name))
     (let (module-symbols (poo-flow-ui-claim-discovery! stx))
       (if (null? module-symbols)
         #'(begin
             (def name
               (poo-flow-use-composition/expression name clause ...))
             (export name))
         (with-syntax
             (((module-id ...)
               (map (lambda (module-symbol)
                      (datum->syntax #'ctx module-symbol))
                    module-symbols)))
           #'(begin
               (import module-id ...)
               (export (import: module-id) ...)
               (def name
                 (poo-flow-use-composition/expression name clause ...))
               (export name))))))))
