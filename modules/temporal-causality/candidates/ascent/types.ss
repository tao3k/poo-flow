;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object object? .slot? .ref)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))
(export PooFlowAscentCandidateRequest PooFlowAscentCandidateExecution PooFlowAscentCandidateAdmission
        poo-flow-ascent-candidate-request? poo-flow-ascent-candidate-execution? poo-flow-ascent-candidate-admission?)
(def (shape? v kind slots)
  (and (object? v) (.slot? v 'kind) (eq? (.ref v 'kind) kind)
       (every (lambda (s) (.slot? v s)) slots)))
(def (request-shape? v) (shape? v 'temporal/ascent-request
 '(identity semantic-digest profile provider-pin scope model query source-identity binding-digest iterations derived-limit output-limit proof-work proof-nodes)))
(def (execution-shape? v) (shape? v 'temporal/ascent-execution '(request-digest native-receipt)))
(def (admission-shape? v) (shape? v 'temporal/ascent-admission '(exchange source-verified? evaluation admitted?)))
(define-type (PooFlowAscentCandidateRequest @ Type.) .element?: request-shape?)
(define-type (PooFlowAscentCandidateExecution @ Type.) .element?: execution-shape?)
(define-type (PooFlowAscentCandidateAdmission @ Type.) .element?: admission-shape?)
(def (poo-flow-ascent-candidate-request? v) (element? PooFlowAscentCandidateRequest v))
(def (poo-flow-ascent-candidate-execution? v) (element? PooFlowAscentCandidateExecution v))
(def (poo-flow-ascent-candidate-admission? v) (element? PooFlowAscentCandidateAdmission v))
