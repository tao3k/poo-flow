#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; POO Flow-owned build lane for contribution test fixtures.

(import (only-in :asp-gerbil-scheme/src/build-api/framework
                 make-package-source-stage
                 package-source-stage-prefix
                 package-source-stage-source
                 package-source-stages-clean!
                 package-source-stages-run!
                 package-source-stages-spec)
        (only-in :std/srfi/13 string-trim-right)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sort sort)
        (only-in :std/source this-source-file)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-directory-files-recursive)
        (only-in :poo-flow/src/module-system/loader/collection
                 make-poo-flow-contribution-module-source
                 poo-flow-module-source-collection-identity
                 poo-flow-module-source-collection-source-root))

(def +package-root+
  (path-directory (this-source-file)))

(def +contribution+
  (make-poo-flow-contribution-module-source
   'lambda-episteme "lambda-episteme"))

(def +contribution-identity+
  (symbol->string
   (poo-flow-module-source-collection-identity +contribution+)))

(def +contribution-source-root+
  (poo-flow-module-source-collection-source-root +contribution+))

(def +test-module+
  (getenv "POO_FLOW_CONTRIBUTE_TEST_MODULE" "all"))
(def +test-file+
  (let (value (getenv "POO_FLOW_CONTRIBUTE_TEST_FILE" #f))
    (and value (> (string-length value) 0) value)))

(def (contribution-test-module-root module-name)
  (string-append +contribution-source-root+ "/t/" module-name
                 "/build-root.ss"))

(def (contribution-test-module-names)
  (let* ((test-root (string-append +contribution-source-root+ "/t"))
         (test-root-path (path-expand test-root +package-root+))
         (module-names
          (filter
           (lambda (name)
             (and (not (equal? name "support"))
                  (file-exists?
                   (path-expand
                    (string-append name "/build-root.ss")
                    test-root-path))))
           (sort (directory-files test-root-path) string<?))))
    module-names))

(def (contribution-test-module-entries)
  (append (map contribution-test-module-root
               (contribution-test-module-names))
          [(contribution-test-module-root "support")]))

(def +test-entry-modules+
  (cond
   (+test-file+
    (let (entry (string-append +contribution-source-root+ "/t/" +test-module+ "/"
                               +test-file+))
      (unless (file-exists? entry)
        (error "unknown contribution atomic test" +test-module+ +test-file+))
      (list entry)))
   ((equal? +test-module+ "all")
    (contribution-test-module-entries))
   (else
    (let (entry (contribution-test-module-root +test-module+))
      (unless (file-exists? entry)
        (error "unknown contribution test module" +test-module+))
      (list entry)))))

;;; Each declared test root is its own std/make source stage.  This keeps the
;;; target source visible while production imports resolve from GERBIL_LOADPATH
;;; instead of being shadowed by the complete POO Flow checkout.
(def (entry->source-stage entry)
  (let (directory (path-directory entry))
    (make-package-source-stage
     (string-append +contribution-identity+ "-test:" entry)
     (path-normalize (path-expand directory +package-root+))
     (string-append "poo-flow/" (string-trim-right directory #\/))
     [(path-strip-directory entry)]
     #t)))

(def (path-under-root->relative root path)
  (substring path (+ (string-length root) 1) (string-length path)))

;;; Module scope means the complete t/<module-name>/ test tree. The file list
;;; is derived once by the shared core tree walk and passed as one std/make
;;; stage; build-root remains the explicit support closure.
(def (module->source-stage module-name)
  (let* ((module-root
          (string-append +contribution-source-root+ "/t/" module-name))
         (test-files
          (filter (lambda (path) (string-suffix? "-test.ss" path))
                  (poo-flow-directory-files-recursive module-root)))
         (entries
          (cons "build-root.ss"
                (map (lambda (path)
                       (path-under-root->relative module-root path))
                     test-files))))
    (make-package-source-stage
     (string-append +contribution-identity+ "-test-module:" module-name)
     (path-normalize (path-expand module-root +package-root+))
     (string-append "poo-flow/" module-root)
     entries
     #t)))

(def +test-source-stages+
  (cond
   (+test-file+ (map entry->source-stage +test-entry-modules+))
   ((equal? +test-module+ "all")
    (append (map module->source-stage (contribution-test-module-names))
            (list (entry->source-stage
                   (contribution-test-module-root "support")))))
   (else (list (module->source-stage +test-module+)))))

(def (parse-build-options arguments)
  (let loop ((rest arguments) (options []))
    (match rest
      ([] options)
      (["--release" . tail]
       (loop tail (cons* build-release: #t options)))
      (["--optimized" . tail]
       (loop tail (cons* build-optimized: #t options)))
      (["--debug" . tail]
       (loop tail (cons* debug: #t options)))
      (else
       (error "unexpected contribution test build options" rest)))))

(def (compile-contribution-tests! options)
  (let (started (current-jiffy))
    (displayln "[poo-flow-contribute] phase=source-stages-start owner=lambda-episteme lane=test module="
               +test-module+ " scope=" (if +test-file+ "file" "module")
               " target-count=" (length +test-source-stages+)
               " executor=asp-build-api/std-make")
    (for-each
     (lambda (stage)
       (displayln "[poo-flow-contribute] phase=source-stage-declared source="
                  (package-source-stage-source stage)
                  " prefix=" (package-source-stage-prefix stage)))
     +test-source-stages+)
    (force-output)
    (let (receipts
          (package-source-stages-run! +test-source-stages+ options))
      (displayln
       "[poo-flow-contribute] phase=source-stages-complete owner=lambda-episteme lane=test module="
       +test-module+ " scope=" (if +test-file+ "file" "module")
       " receipt-count=" (length receipts)
       " executor=asp-build-api/std-make elapsed-ms="
       (quotient (* (- (current-jiffy) started) 1000)
                 (jiffies-per-second)))
      (force-output)
      receipts)))

;;; Preserve the command contract expected by gxpkg and `gerbil build`; only
;;; source-root ownership changes. Compilation and cleaning remain delegated to
;;; ASP Building API and upstream std/make.
(def (main . arguments)
  (match arguments
    (["meta"]
     (write '("spec" "compile" "clean"))
     (newline))
    (["spec"]
     (pretty-print (package-source-stages-spec +test-source-stages+)))
    (["compile" . options]
     (compile-contribution-tests! (parse-build-options options)))
    (["clean"]
     (package-source-stages-clean! +test-source-stages+))
    ([]
     (compile-contribution-tests! []))
    (else
     (error "unexpected contribution test build command" arguments))))
