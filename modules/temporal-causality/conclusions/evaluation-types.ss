;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?) (only-in :std/list/list every))
(export PooFlowTemporalEvaluation poo-flow-temporal-evaluation?)
(def (shape? v)
  (and (object? v)
       (every (lambda (s) (.slot? v s)) '(kind identity profile model query model-digest query-digest statement-digest
         subject scope cut projection policy generation classification exhausted? admitted? action-authorized?))
       (eq? (.ref v 'kind) 'temporal/evaluation)
       (memq (.ref v 'profile) '(finite-hypothesis-v2 finite-behavior-v1))
       (every (lambda (s) (let (v (.ref v s)) (and (string? v) (> (string-length v) 0))))
              '(identity model-digest query-digest statement-digest subject scope cut projection policy generation))
       (memq (.ref v 'classification) '(necessary possible refuted unknown))
       (boolean? (.ref v 'exhausted?)) (boolean? (.ref v 'admitted?))
       (eq? (.ref v 'action-authorized?) #f)))
(define-type (PooFlowTemporalEvaluation @ Type.) .element?: shape?)
(def (poo-flow-temporal-evaluation? v) (element? PooFlowTemporalEvaluation v))
