;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        (only-in :std/encoding/json read-json JSONReadOptions current-json-read-options)
        :poo-flow/modules/temporal-causality/funs
        :poo-flow/modules/temporal-causality/time/interface
        "fixtures/temporal-late-reconciliation.ss")
(export temporal-late-reconciliation-test)
(def temporal-late-reconciliation-test
  (test-suite "authenticated late reconciliation"
    (poo-flow-test-case "late correction produces a refutation and leaves history intact"
      (check (.ref old-proof 'classification) => 'necessary)
      (check (.ref new-proof 'classification) => 'refuted)
      (check (.ref late-publication 'operation) => "retract")
      (let (stored (parameterize ((current-json-read-options (JSONReadOptions object-as-hash: #t)))
                    (call-with-input-file "packages/python-runtime/tests/fixtures/temporal-late-publication.json" read-json)))
        (check (hash-get stored "root_payload") => (.ref root-publication 'wire-payload))
        (check (hash-get stored "late_payload") => (.ref late-publication 'wire-payload)))
      (check (.ref (poo-flow-temporal-model-replay old-model) 'semantic-digest) => (.ref old-model 'semantic-digest))
      (check (.ref (poo-flow-temporal-watermark-replay watermark) 'semantic-digest) => (.ref watermark 'semantic-digest))
      (check-exception (poo-flow-temporal-model-reconcile-late old-model watermark "source" "partition" 21 late
                         coverage (.o (:: @ assertion) signature: (make-u8vector 32 0)) authority as-of) true)
      (check-exception (poo-flow-temporal-model-reconcile-late old-model watermark "source" "partition" 20 late
                         coverage assertion authority as-of) true))))
