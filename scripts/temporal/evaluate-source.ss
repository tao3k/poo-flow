;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Fixed host entry point. JSON transports literals only; it never executes
;;; caller-provided Scheme. Evaluation keys remain in the trusted Python host.
(import (only-in :clan/poo/object .ref)
        (only-in :std/encoding/json read-json write-json JSONReadOptions current-json-read-options)
        (only-in :std/misc/ports read-all-as-string)
        :poo-flow/modules/tla-plus/interface
        (only-in :poo-flow/modules/temporal-causality/objects poo-flow-temporal-query)
        (only-in :poo-flow/modules/temporal-causality/behavior/objects poo-flow-temporal-behavior-query)
        (only-in :poo-flow/modules/temporal-causality/conclusions/evaluation-funs
                 poo-flow-temporal-evaluate poo-flow-temporal-evaluation-replay)
        (only-in :poo-flow/modules/temporal-causality/conclusions/funs
                 poo-flow-temporal-conclusion-root poo-flow-temporal-conclusion-journal)
        (only-in :poo-flow/modules/temporal-causality/conclusions/publication-funs
                 poo-flow-temporal-publication poo-flow-temporal-publication-replay))
(export main)
(def (main request-path)
  (let* ((request (parameterize ((current-json-read-options (JSONReadOptions object-as-hash: #t)))
                    (call-with-input-file request-path read-json)))
         (document (poo-flow-tla-parse-source (hash-get request "source")))
         (profile (hash-get request "profile"))
         (projection (cond ((equal? profile "finite-hypothesis-v2") (poo-flow-tla-project-temporal-model document))
                           ((equal? profile "finite-behavior-v1") (poo-flow-tla-project-behavior-model document))
                           (else (error "unsupported evaluator profile"))))
         (model (.ref projection 'model))
         (query (if (equal? profile "finite-hypothesis-v2")
                  (poo-flow-temporal-query (hash-get request "query") (hash-get request "target") (hash-get request "limit"))
                  (poo-flow-temporal-behavior-query (hash-get request "query") (.ref projection 'property)
                    (hash-get request "limit") node-limit: (hash-get request "node_limit"))))
         (evaluation (poo-flow-temporal-evaluation-replay
                       (apply poo-flow-temporal-evaluate
                         (append (list model query) (map (lambda (key) (hash-get request key))
                                                      '("subject" "scope" "cut" "projection" "policy" "generation"))))))
         (result (make-hash-table)))
    (for-each (lambda (pair) (hash-put! result (car pair) (.ref evaluation (cdr pair))))
      '(("proof" . identity) ("model" . model-digest) ("admitted" . admitted?) ("exhausted" . exhausted?)))
    (hash-put! result "classification" (symbol->string (.ref evaluation 'classification)))
    (let (descriptor (hash-get request "publication"))
      (hash-put! result "publication" #f)
      (when (and descriptor (.ref evaluation 'admitted?))
        (let* ((revision (poo-flow-temporal-conclusion-root
                          (hash-get descriptor "revision")
                          (.ref evaluation 'subject) (.ref evaluation 'scope)
                          (.ref evaluation 'cut) (.ref evaluation 'projection)
                          (.ref evaluation 'policy) (.ref evaluation 'generation)
                          (symbol->string (.ref evaluation 'classification)) (.ref evaluation 'identity)))
               (journal (poo-flow-temporal-conclusion-journal (hash-get descriptor "journal") (list revision)))
               (handoff (poo-flow-temporal-publication journal revision model
                          (hash-get descriptor "nonce") (hash-get descriptor "expires") evaluation: evaluation)))
          (poo-flow-temporal-publication-replay handoff journal revision model evaluation: evaluation)
          (hash-put! result "publication" (.ref handoff 'wire-payload)))))
    (display "POO-EVALUATION ") (write-json (current-output-port) result) (newline) (force-output)))
