;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/profile-composition/interface)

(export profile-composition-value-test)

(def selection-count 0)

(def official-identity
  (poo-flow-official-composition-identity 'official))

(def default-project-profile
  (.o (kind 'test.project-profile)
      (name 'default-software-engineering-project)))

(def official-composition
  (poo-flow-composition
   official-identity
   default-project-profile
   (lambda (profile)
     (set! selection-count (+ selection-count 1))
     (poo-flow-scenario-case
      'official
      '()
      (list profile)
      '()
      '()))))

(def selected-case
  (use-composition official-composition))

(def profile-composition-value-test
  (test-suite "POO Flow Composition value selection"
    (test-case "short use-composition form selects one closed Case"
      (check (poo-flow-composition? official-composition) => #t)
      (check (.ref official-composition 'runtime-executed?) => #f)
      (check selection-count => 1)
      (check (poo-flow-scenario-case? selected-case) => #t)
      (check (.ref selected-case 'name) => 'official)
      (check (eq? (car (.ref selected-case 'profiles))
                  default-project-profile)
             => #t))))

(run-tests! profile-composition-value-test)
