;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: native gxtest prepares the declared entry files before this POO
;;; extension runs. Gerbil's import model then projects those cached contexts;
;;; this extension only observes the resulting source set.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/build-api/native-import-closure
                 asp-gerbil-scheme-native-import-closure)
        (only-in :asp-gerbil-scheme/src/support/time
                 duration-micros monotonic-micros)
        (only-in :clan/poo/object make-object $constant-slot-spec)
        (only-in :std/sort sort)
        (only-in "module-presentation.ss"
                 poo-flow-poo-slot-authoring-file-observations
                 poo-flow-poo-slot-authoring-observation-ok?))

(export poo-flow-source-admission)

(def (poo-flow-source-admission-slot name value)
  (cons name ($constant-slot-spec value)))

(def (poo-flow-source-admission-phase thunk)
  (let (started-at (monotonic-micros))
    (let (result (thunk))
      (values result
              (duration-micros started-at (monotonic-micros))))))

(def (poo-flow-source-admission-prepared-sources root entries)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory root))
      (lambda ()
        (asp-gerbil-scheme-native-import-closure root entries))
      (lambda () (current-directory previous-directory)))))

;;; Fold observations as each file is read.  The admission receipt needs only
;;; counts and diagnostics, so successful observation rows are never retained.
(def (poo-flow-source-admission-scan root sources)
  (foldl
   (lambda (source state)
     (let (path (path-expand source root))
       (foldl
        (lambda (observation inner-state)
          (cons (+ (car inner-state) 1)
                (if (poo-flow-poo-slot-authoring-observation-ok? observation)
                  (cdr inner-state)
                  (cons observation (cdr inner-state)))))
        state
        (poo-flow-poo-slot-authoring-file-observations
         (string->symbol path) path))))
   (cons 0 [])
   sources))

;; poo-flow-source-admission
;;   : (-> Path [Path] POOObject)
;;   | contract: observe exactly the Gerbil-native import closure of entries
;;   | result: a bounded POO receipt with no retained successful source rows
(def (poo-flow-source-admission root entries)
  (let* ((normalized-root (path-normalize (path-expand root)))
         (started-at (monotonic-micros)))
    (let-values (((sources prepared-graph-elapsed-us)
                  (poo-flow-source-admission-phase
                   (lambda ()
                     (sort
                      (poo-flow-source-admission-prepared-sources
                       normalized-root entries)
                      string<?)))))
      (let-values (((scan-result policy-elapsed-us)
                    (poo-flow-source-admission-phase
                     (lambda ()
                       (poo-flow-source-admission-scan
                        normalized-root sources)))))
        (let (diagnostics (reverse (cdr scan-result)))
          (make-object
           slots:
           (list
            (poo-flow-source-admission-slot
             'kind 'poo-flow-source-admission)
            (poo-flow-source-admission-slot 'root normalized-root)
            (poo-flow-source-admission-slot 'file-count (length sources))
            (poo-flow-source-admission-slot
             'observation-count (car scan-result))
            (poo-flow-source-admission-slot 'diagnostics diagnostics)
            (poo-flow-source-admission-slot
             'diagnostic-count (length diagnostics))
            (poo-flow-source-admission-slot
             'prepared-graph-elapsed-us prepared-graph-elapsed-us)
            (poo-flow-source-admission-slot
             'authoring-policy-elapsed-us policy-elapsed-us)
            (poo-flow-source-admission-slot
             'elapsed-us
             (duration-micros started-at (monotonic-micros)))
            (poo-flow-source-admission-slot
             'admitted? (null? diagnostics))
            (poo-flow-source-admission-slot 'runtime-executed? #f))))))))
