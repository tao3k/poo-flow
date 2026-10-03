;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/encoding/json write-json read-json JSONReadOptions current-json-read-options)
        :poo-flow/modules/temporal-causality/objects
        :poo-flow/modules/temporal-causality/funs
        :poo-flow/modules/temporal-causality/time/interface
        :poo-flow/modules/temporal-causality/truth-maintenance/interface
        :poo-flow/modules/temporal-causality/conclusions/interface
        (only-in :poo-flow/modules/tla-plus/emission-funs poo-flow-tla-emit-temporal-model))
(export main old-model old-proof new-proof watermark root-publication late-publication coverage assertion authority as-of late new-model query)
(def old-model
  (poo-flow-temporal-model "late-model" (list (poo-flow-temporal-clock-domain "clock" 'logical-version))
    (list (poo-flow-temporal-model-observation "cause" "clock" 1 "source" 'observed)
          (poo-flow-temporal-model-observation "effect" "clock" 2 "source" 'observed))
    (list (poo-flow-temporal-hypothesis "target" "cause" "effect" '())) #t))
(def (instant id domain position) (poo-flow-temporal-instant id domain position "source" 'observed))
(def authority (poo-flow-temporal-source-authority "owner" "issuer" "source" "key" "knowledge" (make-u8vector 32 7)))
(def as-of (instant "as-of" "knowledge" 5))
(def bound (poo-flow-temporal-bounded-observation "wm-time" 'event "source"
             (instant "lower" "clock" 10) (instant "upper" "clock" 12) 2 as-of "receipt" #f "attempt" "schema"))
(def watermark (poo-flow-temporal-watermark "wm" "source" "partition" 0 20 bound "issuer" "coverage" "late-revision" "receipt"))
(def coverage (poo-flow-temporal-source-attest authority "coverage" 'watermark-completeness (.ref watermark 'semantic-digest) 0 10))
(def late (instant "cause" "clock" 3))
(def assertion (poo-flow-temporal-source-attest authority "late-evidence" 'event-observation
                 (poo-flow-temporal-event-source-digest "source" "partition" 21 late) 0 10))
(def new-model (poo-flow-temporal-model-reconcile-late old-model watermark "source" "partition" 21 late coverage assertion authority as-of))
(def query (poo-flow-temporal-query "q" "target" #f))
(def (evaluate model cut generation)
  (poo-flow-temporal-evaluate model query "subject" "scope" cut "projection" "policy" generation))
(def old-proof (evaluate old-model "cut-1" "generation-1"))
(def new-proof (evaluate new-model "cut-2" "generation-2"))
(def root (poo-flow-temporal-conclusion-root "root" "subject" "scope" "cut-1" "projection" "policy" "generation-1" "necessary" (.ref old-proof 'identity)))
(def index (poo-flow-temporal-dependency-index "index" "cut-1" "projection" #t
             (list (poo-flow-temporal-derivation "root" "cut-1" "projection" "policy" '("cause") '()))))
(def impact (poo-flow-temporal-reverse-dependency-plan index "cut-2" "projection" '("cause")))
(def withdrawn (poo-flow-temporal-conclusion-change "withdrawn" root impact 'retract #f (.ref new-proof 'identity) "policy" "generation-2"))
(def root-journal (poo-flow-temporal-conclusion-journal "journal" (list root)))
(def new-journal (poo-flow-temporal-conclusion-journal "journal" (list root withdrawn)))
(def observed (poo-flow-temporal-selection-observation "signed-host-observation" "subject" "scope" 1 "root"))
(def plan (poo-flow-temporal-selection-prepare new-journal withdrawn observed 1))
(def root-publication (poo-flow-temporal-publication root-journal root old-model "root-nonce" 2000000000 evaluation: old-proof))
(def late-publication (poo-flow-temporal-publication new-journal withdrawn new-model "late-nonce" 2000000000
                        evaluation: new-proof prior-evaluation: old-proof plan: plan observation: observed))
(def (main path)
  (let (output (make-hash-table))
    (hash-put! output "root_payload" (.ref root-publication 'wire-payload))
    (hash-put! output "late_payload" (.ref late-publication 'wire-payload))
    (hash-put! output "root_source" (.ref (poo-flow-tla-emit-temporal-model old-model query) 'data-source))
    (hash-put! output "late_source" (.ref (poo-flow-tla-emit-temporal-model new-model query) 'data-source))
    (call-with-output-file path (lambda (port) (write-json port output)))
    (displayln "LATE-RECONCILIATION-FIXTURE-OK") (force-output)))
