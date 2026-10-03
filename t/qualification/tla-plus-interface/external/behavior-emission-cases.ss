;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-all-as-string)
        :poo-flow/modules/temporal-causality/behavior/interface
        (only-in :poo-flow/modules/tla-plus/emission-funs poo-flow-tla-emit-behavior-model)
        (only-in :poo-flow/modules/tla-plus/funs poo-flow-tla-parse-source poo-flow-tla-project-behavior-model)
        "../../../fixtures/temporal-behaviors.ss")
(export main)
(def (save path text) (call-with-output-file path (lambda (p) (display text p))))
(def (main root)
  (create-directory* root)
  (let (n 0)
    (for-each
     (lambda (care?)
       (let ((builder (if care? medication-model software-release-model))
             (cause (if care? "prescription" "commit"))
             (cause-off (if care? "none" "absent"))
             (cause-on (if care? "issued" "built"))
             (effect (if care? "administration" "deployment"))
             (effect-on (if care? "given" "new"))
             (control (if care? "control-measurement" "protected-service"))
             (control-value (if care? "baseline" "stable")))
         (for-each
          (lambda (mode)
            (let* ((interventions
                    (case mode
                      ((none) '())
                      ((suppress)
                       (list (poo-flow-temporal-intervention "suppress" 0
                               (list (poo-flow-temporal-assignment "clamp" cause cause-off)) (list control) "suppression-assumption")))
                      ((force)
                       (list (poo-flow-temporal-intervention "force" 1
                               (list (poo-flow-temporal-assignment "clamp" effect effect-on)) (list control) "forced-outcome-assumption")))
                      (else
                       (list (poo-flow-temporal-intervention "late-source" (if care? 2 3)
                               (list (poo-flow-temporal-assignment "clamp" cause cause-on)) (list control) "late-intervention-assumption")))))
                   (model (builder interventions)))
              (for-each
               (lambda (question)
                 (set! n (+ n 1)) (displayln "BEHAVIOR-EMIT " n " " care? " " mode " " question) (force-output)
                 (let* ((property (poo-flow-temporal-property
                                   "property" question
                                   (list (poo-flow-temporal-condition "goal"
                                           (if (eq? question 'safety) control effect)
                                           (if (eq? question 'safety) control-value effect-on)))
                                   (if (eq? question 'bounded-progress) 1 (.ref model 'horizon))))
                        (emission (poo-flow-tla-emit-behavior-model model property))
                        (projection (poo-flow-tla-project-behavior-model
                                     (poo-flow-tla-parse-source (.ref emission 'data-source))))
                        (dir (path-expand (number->string n) root)))
                   (unless (and (equal? (.ref (.ref projection 'model) 'semantic-digest) (.ref model 'semantic-digest))
                                (eq? (.ref (.ref projection 'property) 'question) question))
                     (error "behavior source projection differs" n))
                   (poo-flow-tla-parse-source (.ref emission 'check-source))
                   (create-directory* dir)
                   (save (path-expand "TemporalBehaviorComposition.tla" dir) (.ref emission 'data-source))
                   (save (path-expand "TemporalBehaviorCompositionCheck.tla" dir) (.ref emission 'check-source))
                   (save (path-expand "TemporalBehaviorCompositionCheck.cfg" dir) (.ref emission 'config-source))
                   (save (path-expand "TemporalBehaviorSemantics.tla" dir)
                         (call-with-input-file "packages/proofs/tla/temporal-causality/TemporalBehaviorSemantics.tla" read-all-as-string))
                   (displayln "BEHAVIOR-EMIT-OK " n) (force-output)))
               '(safety reachability bounded-progress))))
          '(none suppress force late)))) '(#t #f))
    (displayln "BEHAVIOR-EMISSION-CORPUS-OK " n)))
