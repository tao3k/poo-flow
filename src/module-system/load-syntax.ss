;;; -*- Gerbil -*-
;;; Boundary: user config fragment loading syntax.
;;; Invariant: `load!` resolves and reads declaration fragments at macro time;
;;; runtime module selection and descriptor realization stay in other owners.

(import (only-in :gerbil/expander/core
                 current-expander-context
                 expander-context-id)
        (only-in :gerbil/expander/stx stx-source))

(export load!)

(begin-syntax
  ;; Compile-time path and naming helpers keep `load!` focused on expansion.
  (def (poo-flow-load-source-path value)
    (cond
     ((string? value) value)
     ((and (pair? value) (string? (car value))) (car value))
     (else #f)))

  (def (poo-flow-load-absolute-path? value)
    (and (> (string-length value) 0)
         (char=? (string-ref value 0) #\/)))

  (def (poo-flow-load-string-prefix? prefix value)
    (let ((prefix-length (string-length prefix))
          (value-length (string-length value)))
      (and (>= value-length prefix-length)
           (string=? (substring value 0 prefix-length) prefix))))

  (def (poo-flow-load-drop-prefix prefix value)
    (let ((prefix-length (string-length prefix))
          (value-length (string-length value)))
      (if (and (>= value-length prefix-length)
               (string=? (substring value 0 prefix-length) prefix))
        (substring value prefix-length value-length)
        value)))

  (def (poo-flow-load-drop-suffix suffix value)
    (let ((value-length (string-length value))
          (suffix-length (string-length suffix)))
      (if (and (>= value-length suffix-length)
               (string=? (substring value
                                    (- value-length suffix-length)
                                    value-length)
                         suffix))
        (substring value 0 (- value-length suffix-length))
        value)))

  (def (poo-flow-load-path-segments value)
    (let ((length (string-length value)))
      (let loop ((index 0) (start 0) (segments '()))
        (cond
         ((= index length)
          (reverse (cons (substring value start index) segments)))
         ((char=? (string-ref value index) #\/)
          (loop (+ index 1)
                (+ index 1)
                (cons (substring value start index) segments)))
         (else
          (loop (+ index 1) start segments))))))

  (def (poo-flow-load-member-tail needle values)
    (let loop ((rest values))
      (cond
       ((null? rest) #f)
       ((equal? (car rest) needle) rest)
       (else (loop (cdr rest))))))

  (def (poo-flow-load-last-segment segments fallback)
    (let loop ((rest segments) (last fallback))
      (if (null? rest) last (loop (cdr rest) (car rest)))))

  (def (poo-flow-load-segment-member? names segments)
    (let loop ((rest segments))
      (cond
       ((null? rest) #f)
       ((member (car rest) names) #t)
       (else (loop (cdr rest))))))

  (def (poo-flow-load-object-fragment-path? segments)
    (poo-flow-load-segment-member? ["objects" "objects.ss"] segments))

  (def (poo-flow-load-case-fragment-path? segments)
    (poo-flow-load-segment-member? ["cases" "cases.ss"] segments))

  (def (poo-flow-load-include-source-path path-value)
    (let (path-length
          (and (string? path-value) (string-length path-value)))
      (cond
       ((not (string? path-value))
        (error "load! expects a string path"))
       ((and (>= path-length 3)
             (string=? (substring path-value
                                  (- path-length 3)
                                  path-length)
                       ".ss"))
        path-value)
       (else
        (string-append path-value ".ss")))))

  (def (poo-flow-load-module-context-source-path)
    (let* ((context-id
            (expander-context-id (current-expander-context)))
           (context-name
            (and (symbol? context-id)
                 (symbol->string context-id)))
           (package-prefix "poo-flow/"))
      (and context-name
           (let (relative-context-name
                 (if (poo-flow-load-string-prefix? package-prefix context-name)
                   (substring context-name
                              (string-length package-prefix)
                              (string-length context-name))
                   context-name))
             (string-append relative-context-name ".ss")))))

  (def (poo-flow-load-candidate-fragment-paths include-source-path
                                               call-source-path)
    (if (poo-flow-load-absolute-path? include-source-path)
      [include-source-path]
      (let* ((source-base
              (path-directory (or call-source-path (current-directory))))
             (owner-path
              (path-expand include-source-path source-base))
             (cwd-path
              (path-expand include-source-path (current-directory)))
             (root-parent-path
              (and (poo-flow-load-string-prefix? "../" include-source-path)
                   (path-expand
                    (poo-flow-load-drop-prefix "../" include-source-path)
                    (current-directory)))))
        (append [owner-path cwd-path]
                (if root-parent-path [root-parent-path] [])))))

  (def (poo-flow-load-first-existing-path candidates)
    (let loop ((rest candidates))
      (cond
       ((null? rest) (car candidates))
       ((file-exists? (car rest)) (car rest))
       (else (loop (cdr rest))))))

  (def (poo-flow-load-fragment-info path-value
                                    path-source
                                    form-source)
    (let* ((include-source-path
            (poo-flow-load-include-source-path path-value))
           (call-source-path/raw
            (or (poo-flow-load-source-path path-source)
                (poo-flow-load-source-path form-source)
                (poo-flow-load-module-context-source-path)))
           (call-source-path
            (and call-source-path/raw
                 (path-expand call-source-path/raw (current-directory))))
           (fragment-source-path
            (poo-flow-load-first-existing-path
             (poo-flow-load-candidate-fragment-paths include-source-path
                                                     call-source-path)))
           (source-segments
            (if call-source-path
              (poo-flow-load-path-segments call-source-path)
              (poo-flow-load-path-segments fragment-source-path)))
           (custom-tail
            (poo-flow-load-member-tail "custom" source-segments))
           (custom-module-name
            (if (and custom-tail (pair? (cdr custom-tail)))
              (cadr custom-tail)
              "module"))
           (load-name
            (poo-flow-load-drop-suffix
             ".ss"
             (poo-flow-load-last-segment
              (poo-flow-load-path-segments include-source-path)
              "config")))
           (include-segments
            (poo-flow-load-path-segments include-source-path))
           (objects-fragment?
            (or (poo-flow-load-object-fragment-path? source-segments)
                (poo-flow-load-object-fragment-path? include-segments)
                (string=? load-name "objects")))
           (case-fragment?
            (or (poo-flow-load-case-fragment-path? source-segments)
                (poo-flow-load-case-fragment-path? include-segments)))
           (binding-suffix
            (if case-fragment? "-case" "-module"))
           (binding-name
            (string->symbol
             (string-append "poo-flow-custom-"
                            custom-module-name
                            "-"
                            load-name
                            binding-suffix))))
      (list binding-name
            objects-fragment?
            fragment-source-path))))

;;; Doom-style config fragments are declaration includes, not runtime module
;;; loading. Extensionless paths mirror Doom's `load!` surface; the macro wraps
;;; the fragment result in a generated binding so user files only write the
;;; declaration form, such as `(use-module ...)`.
;; load!
;;   : (-> String Syntax...)
;;   | contract: loads a user config fragment relative to the current module
;;       and exports a generated binding for the fragment result
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (load! "profiles/session")
;;       ;; => exports poo-flow-custom-<module>-session-module
;;       ```
;;     %
(defsyntax (load! stx)
  (syntax-case stx ()
    ((ctx path)
     (let* ((path-value (syntax->datum (syntax path)))
            (fragment-info
             (poo-flow-load-fragment-info path-value
                                          (stx-source (syntax path))
                                          (stx-source stx)))
            (binding-name (car fragment-info))
            (objects-fragment? (cadr fragment-info))
            (fragment-source-path (caddr fragment-info)))
       (with-syntax ((binding (datum->syntax (syntax ctx)
                                             binding-name))
                     (fragment-source
                      (datum->syntax (syntax ctx) fragment-source-path)))
         (if objects-fragment?
           (syntax
            (begin
              (import :poo-flow/src/module-system/object-core)
              (def binding
                (begin (include fragment-source)))
              (export binding)))
            (syntax
             (begin
               (import :poo-flow/src/modules/session/config-session-syntax
                       :poo-flow/src/modules/session/config-policy-syntax
                       :poo-flow/src/modules/session/config
                       :poo-flow/src/modules/session/objects)
               (def binding
                 (begin (include fragment-source)))
               (export binding)))))))))
