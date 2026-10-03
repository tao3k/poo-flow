;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Emit independently model-checked instances. Each instance compares TLC's
;;; terminal classification with a native result; no result text is parsed
;;; back into the semantic model.
(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :poo-flow/modules/temporal-causality/objects
                 poo-flow-temporal-clock-domain poo-flow-temporal-model-observation
                 poo-flow-temporal-hypothesis poo-flow-temporal-constraint poo-flow-temporal-query)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model poo-flow-temporal-overlapping-model)
        (only-in :poo-flow/modules/tla-plus/emission-funs poo-flow-tla-emit-temporal-model)
        (only-in :poo-flow/modules/tla-plus/funs
                 poo-flow-tla-parse-source poo-flow-tla-project-temporal-model))
(export main)
(def (save path text)
  (call-with-output-file path (lambda (port) (display text port))))
(def (main root)
  (create-directory* root)
  (let (n 0)
    (for-each
     (lambda (vocabulary)
       (for-each
        (lambda (overlap?)
          (for-each
           (lambda (scenario)
             (for-each
              (lambda (limit)
                (set! n (+ n 1))
                (displayln "EMIT-CASE " n " " vocabulary " " overlap? " " scenario " " limit)
                (force-output)
                (let* ((cause (string-append vocabulary "/cause"))
                       (alternative (string-append vocabulary "/alternative"))
                       (effect (string-append vocabulary "/effect"))
                       (model
                        ((if overlap? poo-flow-temporal-overlapping-model poo-flow-temporal-model)
                         vocabulary
                         (list (poo-flow-temporal-clock-domain "local" 'logical-version)
                               (poo-flow-temporal-clock-domain "remote" 'logical-version))
                         (list (poo-flow-temporal-model-observation cause "local" 1 "ledger" 'observed)
                               (poo-flow-temporal-model-observation
                                alternative (if (eq? scenario 'incomparable) "remote" "local")
                                (case scenario ((after) 4) ((equal) 3) (else 2)) "ledger"
                                (if (eq? scenario 'declared) 'declared 'observed))
                               (poo-flow-temporal-model-observation effect "local" 3 "ledger" 'observed))
                         (list (poo-flow-temporal-hypothesis "via-a" cause effect
                                (if (eq? scenario 'constraint-refuted)
                                  (list (poo-flow-temporal-constraint "extra" 'before effect cause)) '()))
                               (poo-flow-temporal-hypothesis "via-b" alternative effect '()))
                         (not (eq? scenario 'incomplete))))
                       (query (poo-flow-temporal-query "why" "via-a" limit))
                       (emission (poo-flow-tla-emit-temporal-model model query))
                       (dir (path-expand (number->string n) root))
                       (projection (poo-flow-tla-project-temporal-model
                                    (poo-flow-tla-parse-source (.ref emission 'data-source)))))
                  (unless (equal? (.ref projection 'semantic-digest) (.ref model 'semantic-digest))
                    (error "source-to-POO identity differs" n))
                  (poo-flow-tla-parse-source (.ref emission 'check-source))
                  (create-directory* dir)
                  (save (path-expand "TemporalComposition.tla" dir) (.ref emission 'data-source))
                  (save (path-expand "TemporalCompositionCheck.tla" dir) (.ref emission 'check-source))
                  (save (path-expand "TemporalCompositionCheck.cfg" dir) (.ref emission 'config-source))
                  (for-each
                   (lambda (name)
                     (save (path-expand name dir)
                           (call-with-input-file
                            (path-expand name "packages/proofs/tla/temporal-causality")
                            read-all-as-string)))
                   '("TemporalFamilyExplorer.tla" "TemporalFamilySemantics.tla" "TemporalOrder.tla"))
                  (displayln "EMIT-CASE-OK " n) (force-output))) '(#f 1)))
           '(before after equal incomparable declared incomplete constraint-refuted))) '(#f #t)))
     '("care" "release"))
    (displayln "EMISSION-CORPUS-OK " n)))
