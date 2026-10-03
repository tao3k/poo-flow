;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Import progress is reported only at real dependency boundaries. The outer
;;; watchdog owns both startup and idle limits; no timer emits keepalive text.
(for-each
 (lambda (module)
   (displayln "IMPORT " module) (force-output)
   (eval `(import ,module))
   (displayln "IMPORT-OK " module) (force-output))
 '(:clan/poo/object
   :clan/poo/mop
   :core/types
   :core/module-system/schema/slot-contracts
   :poo-flow/src/utilities/product-syntax
   :poo-flow/src/utilities/final-projection-syntax
   :poo-flow/src/graph/types-core
   :poo-flow/src/graph/types-contracts
   :poo-flow/src/graph/types
   :poo-flow/modules/temporal-causality/types
   :poo-flow/modules/temporal-causality/objects
   :poo-flow/modules/temporal-causality/funs
   :poo-flow/modules/temporal-causality/time/types
   :poo-flow/modules/temporal-causality/time/objects
   :poo-flow/modules/temporal-causality/time/uncertainty-types
   :poo-flow/modules/temporal-causality/time/uncertainty-objects
   :poo-flow/modules/temporal-causality/time/uncertainty-funs
   :gerbil-ascent/table/expression
   :gerbil-ascent/table/funs
   :gerbil-ascent/table/eqrel
   :gerbil-ascent/table/trrel
   :gerbil-ascent/table/provider
   :gerbil-ascent/table/storage
   :gerbil-ascent/table/interface
   :gerbil-ascent/program/types
   :gerbil-ascent/program/objects
   :gerbil-ascent/program/aggregators
   :gerbil-ascent/program/syntax
   :gerbil-ascent/program/planning
   :gerbil-ascent/program/scheme-checked
   :gerbil-ascent/program/scheme-admission
   :gerbil-ascent/program/scheme-language
   :gerbil-ascent/program/operator
   :gerbil-ascent/program/operator-change
   :gerbil-ascent/program/operator-session
   :gerbil-ascent/program/funs
   :gerbil-ascent/program/analysis
   :gerbil-ascent/program/summary
   :gerbil-ascent/program/evaluate
   :gerbil-ascent/program/session
   :gerbil-ascent/program/interface
   :gerbil-ascent/core/binary-program
   :gerbil-ascent/candidate/closure
   :gerbil-ascent/candidate/types
   :gerbil-ascent/candidate/program
   :gerbil-ascent/candidate/funs
   :gerbil-ascent/candidate/provenance
   :gerbil-ascent/candidate/nonmembership
   :gerbil-ascent/candidate/finite-evidence
   :gerbil-ascent/candidate/stratified-proof
   :gerbil-ascent/candidate/stratified-producer
   :gerbil-ascent/candidate/reasoning
   :gerbil-ascent/temporal/lens
   :gerbil-ascent/interface/request
   :poo-flow/modules/temporal-causality/ascent-exchange
   :poo-flow/src/graph/algorithms
   :poo-flow/src/ffi/semantic-v1))
(displayln "MODULE-OK semantic-v1")
(displayln "HARNESS-OK semantic-worker")
(displayln "READY") (force-output)
(let loop ()
  (let (line (read-line))
    (unless (eof-object? line)
      (displayln (poo-flow/src/ffi/semantic-v1#semantic-call "temporal.solve" line))
      (force-output)
      (loop))))
(displayln "OK") (force-output)
