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
        (only-in :std/srfi/13 string-trim-right)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/source this-source-file)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-value)
        (only-in :poo-flow/src/module-system/loader/collection
                 make-poo-flow-contribution-module-source
                 poo-flow-module-required-role-files
                 poo-flow-load-modules))

(def +package-root+ (path-directory (this-source-file)))

(def +contribution-module-source+
  (make-poo-flow-contribution-module-source
   'lambda-episteme "lambda-episteme"))

(def (relative-entry->source-stage label entry)
  (let (directory (path-directory entry))
    (make-package-source-stage
     label
     (path-normalize (path-expand directory +package-root+))
     (string-append "poo-flow/" (string-trim-right directory #\/))
     [(path-strip-directory entry)]
     #t)))

(def (module-source-ref->stage source-ref)
  (let (entry (poo-flow-module-source-ref-value source-ref))
    (relative-entry->source-stage
     (string-append "lambda-episteme-module:" entry)
     entry)))

;;; These are contributor-level public facilities rather than domain modules.
;;; They stay explicit while every modules/<name>/interface.ss is discovered
;;; from the POO source collection.
(def +contribution-foundation-stages+
  (list
   (relative-entry->source-stage
    "lambda-episteme-registration" "lambda-episteme/interface.ss")
   (relative-entry->source-stage
    "lambda-episteme-governance" "lambda-episteme/governance/interface.ss")))

(def +contribution-module-stages+
  (map module-source-ref->stage
       (poo-flow-load-modules +contribution-module-source+)))

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

(def (load-user-interface)
  (validate-contribution-user-interface-layout!)
  (list
   (relative-entry->source-stage
    "lambda-episteme-user-interface:init"
    (contribution-user-interface-path "init.ss"))
   (relative-entry->source-stage
    "lambda-episteme-user-interface:config"
    (contribution-user-interface-path "config.ss"))))

(def +contribution-source-stages+
  (append +contribution-foundation-stages+
          +contribution-module-stages+
          (load-user-interface)))

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
               (length +contribution-source-stages+)
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
