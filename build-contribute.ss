#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; POO Flow-owned production build lane for an ordered contributor source.
;;; POO objects select module entrypoints; ASP Build API and std/make compile.

(import (only-in :asp-gerbil-scheme/src/build-api/framework
                 make-package-source-stage
                 package-source-stages-clean!
                 package-source-stages-run!
                 package-source-stages-spec)
        (only-in :asp-gerbil-scheme/src/build-api/native-import-closure
                 asp-gerbil-scheme-native-import-closure)
        (only-in :std/srfi/13 string-trim-right)
        (only-in :std/srfi/1 append-map filter)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/source this-source-file)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-directory-files-recursive)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-value)
        (only-in :poo-flow/src/module-system/loader/collection
                 make-poo-flow-contribution-module-source
                 poo-flow-module-required-role-files
                 poo-flow-load-modules))

(def +package-root+ (path-directory (this-source-file)))
(def +contribution-root-entry+ "lambda-episteme")
(def +contribution-root-path+
  (path-normalize
   (path-expand +contribution-root-entry+ +package-root+)))

(def +contribution-module-source+
  (make-poo-flow-contribution-module-source
   'lambda-episteme "lambda-episteme"))

(def (contribution-entry->relative entry)
  (let (prefix (string-append +contribution-root-entry+ "/"))
    (unless (and (> (string-length entry) (string-length prefix))
                 (string=? prefix
                           (substring entry 0 (string-length prefix))))
      (error "contribution entry is outside source root" entry))
    (substring entry (string-length prefix) (string-length entry))))

(def (module-source-ref->entry source-ref)
  (contribution-entry->relative
   (poo-flow-module-source-ref-value source-ref)))

(def +contribution-user-interface-root+
  "lambda-episteme/user-interface")

;;; The user-interface repository surface is intentionally closed. init.ss
;;; selects modules, config.ss owns final User Compositions, and reusable
;;; Profiles/Scenarios are discovered from their role directories.
(def +contribution-user-interface-directories+
  '((modules . "modules")
    (profiles . "profiles")
    (scenarios . "scenarios")))

(def (contribution-user-interface-path leaf)
  (string-append +contribution-user-interface-root+ "/" leaf))

(def (validate-user-interface-modules! root-path)
  (let* ((modules-root (path-expand "modules" root-path))
         (entries (directory-files modules-root))
         (root-scheme
          (filter (lambda (name) (string-suffix? ".ss" name)) entries))
         (module-names
          (filter
           (lambda (name)
             (eq? (file-info-type
                   (file-info (path-expand name modules-root)))
                  'directory))
           entries)))
    (unless (null? root-scheme)
      (error "POO-FLOW-UI-E004 user modules must use modules/<module-name>/"
             root-scheme))
    (for-each
     (lambda (module-name)
       (let* ((module-root (path-expand module-name modules-root))
              (missing
               (filter
                (lambda (role)
                  (not (file-exists? (path-expand role module-root))))
                poo-flow-module-required-role-files)))
         (unless (null? missing)
           (error "POO-FLOW-UI-E005 user module is missing required roles"
                  module-name missing))))
     module-names)))

(def (validate-contribution-user-interface-layout!)
  (let* ((root-path
          (path-normalize
           (path-expand +contribution-user-interface-root+ +package-root+)))
         (top-level-scheme
          (filter (lambda (name) (string-suffix? ".ss" name))
                  (directory-files root-path)))
         (unexpected
          (filter (lambda (name)
                    (not (member name '("init.ss" "config.ss"))))
                  top-level-scheme)))
    (unless (file-exists? (path-expand "init.ss" root-path))
      (error "POO-FLOW-UI-E001 missing user-interface/init.ss" root-path))
    (unless (file-exists? (path-expand "config.ss" root-path))
      (error "POO-FLOW-UI-E001 missing user-interface/config.ss" root-path))
    (unless (null? unexpected)
      (error "POO-FLOW-UI-E002 top-level Scheme files must be init.ss or config.ss"
             unexpected))
    (for-each
     (lambda (role)
       (unless (file-exists? (path-expand (cdr role) root-path))
         (error "POO-FLOW-UI-E003 missing required user-interface role directory"
                (car role) (cdr role))))
     +contribution-user-interface-directories+)
    (validate-user-interface-modules! root-path)))

(def (load-user-interface-specs)
  (validate-contribution-user-interface-layout!)
  (let* ((root +contribution-root-path+)
         (root-prefix (string-append (string-trim-right root #\/) "/"))
         (root-prefix-length (string-length root-prefix))
         (all
          (sort
           (map (lambda (path)
                  (substring path root-prefix-length (string-length path)))
                (filter
                 (lambda (path) (string-suffix? ".ss" path))
                 (poo-flow-directory-files-recursive
                  (path-expand "user-interface" root))))
           string<?))
         (support
          (filter
           (lambda (path)
             (not (member path
                          '("user-interface/init.ss"
                            "user-interface/config.ss"))))
           all)))
    (append support
            '("user-interface/init.ss" "user-interface/config.ss"))))

;;; Gerbil's native Import Model owns the production closure. The declared
;;; roots are contributor-owned public entrypoints; ASP projects their native
;;; dependency order before one std/make invocation schedules the build.
(def +contribution-public-entry-modules+
  (append
   '("interface.ss" "governance/interface.ss")
   (map module-source-ref->entry
        (poo-flow-load-modules +contribution-module-source+))
   (load-user-interface-specs)))

(def +contribution-production-specs+
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory +contribution-root-path+))
      (lambda ()
        (asp-gerbil-scheme-native-import-closure
         +contribution-root-path+
         +contribution-public-entry-modules+))
      (lambda () (current-directory previous-directory)))))

(def +contribution-source-stages+
  (list
   (make-package-source-stage
    "lambda-episteme-production"
    +contribution-root-path+
    "poo-flow/lambda-episteme"
    +contribution-production-specs+
    #t)))

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
       (error "unexpected contribution build options" rest)))))

(def (elapsed-ms started)
  (quotient (* (- (current-jiffy) started) 1000)
            (jiffies-per-second)))

(def (compile-contribution! options)
  (let (started (current-jiffy))
    (displayln "[poo-flow-contribute] phase=spec-projected owner=lambda-episteme lane=production target-count="
               (length +contribution-production-specs+)
               " executor=asp-build-api/std-make")
    (force-output)
    (let (receipts
          (package-source-stages-run! +contribution-source-stages+ options))
      (displayln "[poo-flow-contribute] phase=build-complete owner=lambda-episteme lane=production receipt-count="
                 (length receipts) " elapsed-ms=" (elapsed-ms started))
      (force-output)
      receipts)))

(def (main . arguments)
  (match arguments
    (["meta"]
     (write '("spec" "compile" "clean"))
     (newline))
    (["spec"]
     (pretty-print (package-source-stages-spec +contribution-source-stages+)))
    (["compile" . options]
     (compile-contribution! (parse-build-options options)))
    (["clean"]
     (package-source-stages-clean! +contribution-source-stages+))
    ([]
     (compile-contribution! []))
    (else
     (error "unexpected contribution build command" arguments))))
