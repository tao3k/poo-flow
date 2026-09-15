#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Reader-native observability preflight for one contribution-owned atomic test.

(import :gerbil/gambit
        (only-in :std/sort sort)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-directory-files-recursive)
        (only-in :poo-flow/src/module-system/observability/module-presentation
                 poo-flow-poo-slot-authoring-file-observations
                 poo-flow-poo-slot-authoring-observation-ok?))

(def (scheme-source-files path)
  (filter (lambda (file) (string-suffix? ".ss" file))
          (poo-flow-directory-files-recursive path)))

(def (observation-ref observation key)
  (let (entry (assq key observation))
    (and entry (cdr entry))))

(def (contribution-module-source-paths contribution module)
  (let ((module-tree
         (path-expand (string-append "modules/" module) contribution))
        (top-level-tree (path-expand module contribution))
        (collection-root (path-expand "modules" contribution)))
    (cond
     ((file-exists? module-tree) (scheme-source-files module-tree))
     ((and (string=? module "modules") (file-exists? collection-root))
      (filter
       file-exists?
       (map (lambda (name) (path-expand name collection-root))
            '("source.ss" "init.ss"))))
     ((file-exists? top-level-tree) (scheme-source-files top-level-tree))
     (else '()))))

(def (observe-contribution-test contribution module test-file)
  (let* ((test-path (path-expand (string-append "t/" module "/" test-file)
                                 contribution)))
    (unless (file-exists? test-path)
      (error "invalid contribution observability target"
             contribution module test-file))
    (let* ((paths (sort (cons test-path
                              (contribution-module-source-paths
                               contribution module))
                        string<?))
           (observations
            (apply append
                   (map (lambda (path)
                          (poo-flow-poo-slot-authoring-file-observations
                           (string->symbol path) path))
                        paths)))
           (failures
            (filter (lambda (observation)
                      (not (poo-flow-poo-slot-authoring-observation-ok?
                            observation)))
                    observations)))
      (displayln "[poo-flow-observability] phase=source-scanned owner=" contribution
                 " module=" module " files=" (length paths)
                 " observations=" (length observations)
                 " diagnostics=" (length failures))
      (for-each
       (lambda (failure)
         (display "[poo-flow-observability] phase=diagnostic ")
         (write (list (cons 'source (observation-ref failure 'scope))
                      (cons 'status (observation-ref failure 'status))
                      (cons 'slot (observation-ref failure 'slot))
                      (cons 'initializer
                            (observation-ref failure 'initializer))
                      (cons 'detail (observation-ref failure 'detail))))
         (newline))
       failures)
      (force-output)
      (unless (null? failures) (exit 2))
      (displayln "[poo-flow-observability] phase=source-admitted owner=" contribution
                 " module=" module " test=" test-file)
      (force-output))))

(let (arguments (cddr (command-line)))
  (unless (= (length arguments) 3)
    (error "usage: observe-contribute-test.ss <contribution> <module> <test-file>"))
  (apply observe-contribution-test arguments))
