;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Pure host handoff. Issuer verification and atomic publication remain in
;;; Runtime C/Python; an opaque proof identity never grants authority here.
(import (only-in :clan/poo/object .ref)
        (only-in :std/list/list every find take drop)
        (only-in :poo-flow/modules/temporal-causality/funs poo-flow-temporal-model-replay)
        (only-in "types.ss" poo-flow-temporal-conclusion-revision?)
        (only-in "funs.ss" poo-flow-temporal-conclusion-journal-replay
                 poo-flow-temporal-selection-plan-replay)
        (only-in "evaluation-funs.ss" poo-flow-temporal-evaluation-admit)
        (only-in "publication-types.ss" poo-flow-temporal-publication?)
        (only-in "publication-objects.ss" poo-flow-temporal-publication-value))
(export poo-flow-temporal-publication poo-flow-temporal-publication-replay)
(def +fields+ '(subject scope predecessor revision proof policy generation cut projection
                       journal model nonce operation expected-version expires-unix))
(def (wire values)
  (call-with-output-string
   (lambda (port)
     (for-each (lambda (value)
                 (let (text (if (exact-integer? value) (number->string value) value))
                   (unless (string? text) (error "invalid publication wire field"))
                   (display (u8vector-length (string->utf8 text)) port)
                   (display ":" port) (display text port) (display "," port)))
               (cons "poo-flow.temporal.publish.v1" values)))))
(def (valid-fields? values)
  (and (= (length values) 15)
       (every (lambda (s)
                (and (string? s) (not (memv #\nul (string->list s)))
                     (<= (u8vector-length (string->utf8 s)) 512)))
              (take values 13))
       (every (lambda (s) (> (string-length s) 0))
              (append (take values 2) (take (drop values 3) 10)))
       (every (lambda (v) (and (exact-integer? v) (>= v 0) (< v (expt 2 63))))
              (drop values 13))
       (< (list-ref values 13) (- (expt 2 63) 1))))
(def (poo-flow-temporal-publication journal revision model nonce expires
      plan: (plan #f) observation: (observation #f) evaluation: (evaluation #f) prior-evaluation: (prior #f))
  (unless (poo-flow-temporal-conclusion-revision? revision)
    (error "publication requires a conclusion revision"))
  (poo-flow-temporal-conclusion-journal-replay journal)
  (poo-flow-temporal-evaluation-admit evaluation revision model journal prior: prior)
  (let (stored (find (lambda (r) (equal? (.ref r 'identity) (.ref revision 'identity)))
                    (.ref journal 'revisions)))
    (unless (and stored
                 (every (lambda (slot) (equal? (.ref stored slot) (.ref revision slot)))
                        '(identity subject-identity scope-identity cut-digest projection-digest
                                   policy-identity generation-identity operation predecessor-identity
                                   result-identity proof-identity invalidation-index-digest)))
      (error "publication revision differs from journal")))
  (let* ((root? (eq? (.ref revision 'operation) 'assert))
         (version
          (if root?
            (begin (when (or plan observation) (error "root publication cannot reuse a selection plan")) 0)
            (let (canonical
                  (poo-flow-temporal-selection-plan-replay plan journal revision observation))
              (unless (eq? (.ref canonical 'status) 'cas-ready)
                (error "conflicting selection plan cannot be published"))
              (unless (> (.ref canonical 'expected-version) 0)
                (error "publication predecessor has no committed runtime version"))
              (.ref canonical 'expected-version))))
         (values
          (list (.ref revision 'subject-identity) (.ref revision 'scope-identity)
                (or (.ref revision 'predecessor-identity) "") (.ref revision 'identity)
                (.ref revision 'proof-identity) (.ref revision 'policy-identity)
                (.ref revision 'generation-identity) (.ref revision 'cut-digest)
                (.ref revision 'projection-digest) (.ref journal 'semantic-digest)
                (.ref model 'semantic-digest) nonce (symbol->string (.ref revision 'operation)) version expires)))
    (unless (valid-fields? values) (error "invalid publication envelope"))
    (apply poo-flow-temporal-publication-value (append values (list (wire values))))))
(def (poo-flow-temporal-publication-replay publication journal revision model
      plan: (plan #f) observation: (observation #f) evaluation: (evaluation #f) prior-evaluation: (prior #f))
  (unless (poo-flow-temporal-publication? publication) (error "invalid publication envelope"))
  (let (canonical (poo-flow-temporal-publication journal revision model
                   (.ref publication 'nonce) (.ref publication 'expires-unix)
                   plan: plan observation: observation evaluation: evaluation prior-evaluation: prior))
    (unless (every (lambda (slot) (equal? (.ref canonical slot) (.ref publication slot)))
                   (append +fields+ '(wire-payload)))
      (error "publication envelope differs from replayed conclusion inputs"))
    canonical))
