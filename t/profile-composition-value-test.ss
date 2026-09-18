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

(def official-catalog
  (poo-flow-composition-catalog
   (list official-composition)
   '(gitops sdlc)))

(def profile-composition-value-test
  (test-suite "POO Flow Composition value selection"
    (test-case "short use-composition form selects one closed Case"
      (let* ((before selection-count)
             (selected-case
              (parameterize
                  ((current-poo-flow-composition-catalog official-catalog))
                (use-composition official))))
        (check (poo-flow-composition? official-composition) => #t)
        (check (poo-flow-composition-catalog? official-catalog) => #t)
        (check (.ref official-catalog 'selectors) => '(official))
        (check (.ref official-composition 'runtime-executed?) => #f)
        (check selection-count => (+ before 1))
        (check (poo-flow-scenario-case? selected-case) => #t)
        (check (.ref selected-case 'name) => 'official)
        (check (eq? (car (.ref selected-case 'profiles))
                    default-project-profile)
               => #t)))
    (test-case "single-expression file loads without import or export"
      (let (loaded
            (poo-flow-load-composition-value
             "t/fixtures/composition-value/official.ss"
             official-catalog))
        (check (poo-flow-scenario-case? loaded) => #t)
        (check (.ref loaded 'name) => 'official)))
    (test-case "catalog and file boundaries fail closed"
      (check-exception
       (poo-flow-composition-catalog
        (list official-composition official-composition)
        '(gitops sdlc))
       true)
      (check-exception
       (poo-flow-composition-catalog
        (list official-composition)
        '(official gitops))
       true)
      (check-exception
       (poo-flow-load-composition-value
        "t/fixtures/composition-value/multiple.ss"
        official-catalog)
       true)
      (check-exception
       (poo-flow-load-composition-value
        "t/fixtures/composition-value/import.ss"
        official-catalog)
       true))))

(run-tests! profile-composition-value-test)
