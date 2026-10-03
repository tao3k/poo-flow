;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Authenticated replacement of one observation in a fresh immutable finite
;;; model. The old model/watermark remains replayable; publication is separate.
(import (only-in :clan/poo/object .ref)
        (only-in :std/list/list find)
        (only-in :poo-flow/modules/temporal-causality/objects poo-flow-temporal-model-observation)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model poo-flow-temporal-overlapping-model poo-flow-temporal-model-replay)
        "authority-funs.ss")
(export poo-flow-temporal-model-reconcile-late)
(def (poo-flow-temporal-model-reconcile-late model watermark source partition sequence event
      coverage event-assertion authority as-of)
  (poo-flow-temporal-model-replay model)
  (unless (and (exact-integer? sequence) (> sequence (.ref watermark 'last-sequence))
               (eq? (poo-flow-temporal-watermark-late-disposition watermark source partition sequence event
                      coverage event-assertion authority as-of) 'reevaluate-cut))
    (error "late reconciliation lacks authenticated new source evidence"))
  (let (previous (find (lambda (observation) (equal? (.ref observation 'identity) (.ref event 'identity))) (.ref model 'observations)))
    (unless (and previous (equal? (.ref previous 'provenance-identity) source)
                 (equal? (.ref previous 'domain-identity) (.ref event 'domain-identity)))
      (error "late observation differs from model source or clock domain"))
    ((if (eq? (.ref model 'family-semantics) 'overlapping-mechanisms)
       poo-flow-temporal-overlapping-model poo-flow-temporal-model)
     (.ref model 'identity) (.ref model 'domains)
     (map (lambda (observation)
            (if (equal? (.ref observation 'identity) (.ref event 'identity))
              (poo-flow-temporal-model-observation (.ref event 'identity) (.ref event 'domain-identity)
                (.ref event 'coordinate) source 'observed) observation)) (.ref model 'observations))
     (.ref model 'hypotheses) (.ref model 'family-complete?))))
