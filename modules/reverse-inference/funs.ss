;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Bounded, source-preserving reverse explanation. It infers candidate
;;; support and explicit conflicts; it never authenticates sources or admits
;;; actions. The caller owns domain claim names and step topology.
(import (only-in :clan/poo/object .o .ref object?)
        (only-in :std/list/list every find)
        (only-in :poo-flow/modules/query/scheme-select
                 poo-flow-query-select-scheme-nodes)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program))

(export poo-flow-reverse-inference-evaluate
        poo-flow-inference-hypothesis-result)

(def (poo-flow-inference-hypothesis-result receipt hypothesis-id)
  (let (result
        (find (lambda (item)
                (eq? (.ref item 'identity) hypothesis-id))
              (.ref receipt 'hypothesis-results)))
    (or result (error "unknown reverse inference hypothesis" hypothesis-id))))

(def (claim? value allowed)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.reverse-inference.claim)
       (symbol? (.ref value 'identity))
       (memq (.ref value 'identity) allowed)
       (symbol? (.ref value 'value))
       (not (eq? (.ref value 'value) 'absent))
       (symbol? (.ref value 'source))))

(def (step? value allowed)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.reverse-inference.step)
       (symbol? (.ref value 'from))
       (symbol? (.ref value 'to))
       (memq (.ref value 'first) allowed)
       (memq (.ref value 'second) allowed)
       (memq (.ref value 'join) '(presence equal-value))))

(def (hypothesis? value allowed)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.reverse-inference.hypothesis)
       (symbol? (.ref value 'identity))
       (symbol? (.ref value 'from))
       (symbol? (.ref value 'to))
       (list? (.ref value 'required-claims))
       (every (lambda (claim) (memq claim allowed))
              (.ref value 'required-claims))))

(def (poo-flow-reverse-inference-evaluate case-value)
  (unless (and (object? case-value)
               (eq? (.ref case-value 'kind)
                    'poo-flow.reverse-inference.case))
    (error "reverse evidence requires a POO Case" case-value))
  (let* ((claims (.ref case-value 'claims))
         (steps (.ref case-value 'steps))
         (hypotheses (.ref case-value 'hypotheses))
         (query (.ref case-value 'query))
         (allowed (.ref query 'selected-element-identities)))
    (unless (and (list? claims) (<= (length claims) 64)
                 (every (lambda (claim) (claim? claim allowed)) claims)
                 (list? steps) (<= (length steps) 64)
                 (every (lambda (step) (step? step allowed)) steps)
                 (list? hypotheses) (pair? hypotheses)
                 (<= (length hypotheses) 32)
                 (every (lambda (hypothesis)
                          (hypothesis? hypothesis allowed)) hypotheses))
      (error "invalid bounded reverse evidence Case" case-value))
    (let* ((nodes
            (map (lambda (claim)
                   (.o label: 'EvidenceClaim
                       identity: (.ref claim 'identity)
                       value: (.ref claim 'value)
                       evidenceSource: (.ref claim 'source)))
                 claims))
           (query-result (poo-flow-query-select-scheme-nodes query nodes))
           (selected (.ref query-result 'rows))
           (presence-steps
            (map (lambda (step)
                   (list (.ref step 'from) (.ref step 'to)
                         (.ref step 'first) (.ref step 'second)))
                 (filter (lambda (step)
                           (eq? (.ref step 'join) 'presence)) steps)))
           (equal-steps
            (map (lambda (step)
                   (list (.ref step 'from) (.ref step 'to)
                         (.ref step 'first) (.ref step 'second)))
                 (filter (lambda (step)
                           (eq? (.ref step 'join) 'equal-value)) steps)))
           (equal-claim-kinds
            (map list
                 (append (map caddr equal-steps)
                         (map cadddr equal-steps))))
           (result
            (gerbil-ascent-evaluate-program
             (ascent
              (relation claim (name value source) selected)
              (relation step (from to first second) presence-steps)
              (relation equal-step (from to first second) equal-steps)
              (relation equal-claim (name) equal-claim-kinds)
              (relation required (name))
              (relation seen (name))
              (relation missing (name))
              (relation mismatch
                (first first-value first-source
                 second second-value second-source))
              (relation conflict
                (name first-value first-source second-value second-source))
              (relation supported-step
                (from to first first-source second second-source))
              (relation reverse-reach (from to))
              ((required first) <-- (step from to first second))
              ((required second) <-- (step from to first second))
              ((required first) <-- (equal-step from to first second))
              ((required second) <-- (equal-step from to first second))
              ((seen name) <-- (claim name value source))
              ((missing name) <-- (required name) (not (seen name)))
              ((mismatch first first-value first-source
                         second second-value second-source)
               <-- (equal-step from to first second)
                   (claim first first-value first-source)
                   (claim second second-value second-source)
                   (guard (first-value second-value)
                          (lambda (left right) (not (equal? left right)))))
              ((conflict name first-value first-source
                         second-value second-source)
               <-- (equal-claim name)
                   (claim name first-value first-source)
                   (claim name second-value second-source)
                   (guard (first-value second-value)
                          (lambda (left right) (not (equal? left right)))))
              ((supported-step from to first first-source
                               second second-source)
               <-- (step from to first second)
                   (claim first first-value first-source)
                   (claim second second-value second-source))
              ((supported-step from to first first-source
                               second second-source)
               <-- (equal-step from to first second)
                   (claim first value first-source)
                   (claim second value second-source))
              ((reverse-reach from to)
               <-- (supported-step from to first first-source
                                   second second-source))
              ((reverse-reach from end)
               <-- (reverse-reach from middle)
                   (supported-step middle end first first-source
                                   second second-source))
              (bounds 64 256 512))))
           (rows-of (.ref result 'rows-of))
           (reach (rows-of 'reverse-reach))
           (mismatches (rows-of 'mismatch))
           (conflicts (rows-of 'conflict))
           (consistent? (and (null? mismatches) (null? conflicts)))
           (evaluated-hypotheses
            (map
             (lambda (hypothesis)
               (let* ((required (.ref hypothesis 'required-claims))
                      (absent
                       (filter (lambda (claim-id)
                                 (not (member (list claim-id)
                                              (rows-of 'seen))))
                               required))
                      (route-reachable?
                       (and (member (list (.ref hypothesis 'from)
                                          (.ref hypothesis 'to)) reach) #t))
                      (relevant-mismatches
                       (filter (lambda (row)
                                 (and (memq (car row) required)
                                      (memq (cadddr row) required)))
                               mismatches))
                      (relevant-conflicts
                       (filter (lambda (row)
                                 (memq (car row) required)) conflicts))
                      (result-status
                       (cond ((or (pair? relevant-mismatches)
                                  (pair? relevant-conflicts)) 'conflicted)
                             ((and route-reachable? (null? absent)) 'supported)
                             (else 'needs-evidence))))
                 (.o kind: 'poo-flow.reverse-inference.hypothesis-result
                     identity: (.ref hypothesis 'identity)
                     status: result-status
                     reachable?: route-reachable?
                     missing-claims: absent
                     equality-mismatches: relevant-mismatches
                     value-conflicts: relevant-conflicts)))
             hypotheses)))
      (.o kind: 'poo-flow.reverse-inference.receipt
          query-selected-claims: selected
          query-source-identity: (.ref query-result 'query-source-identity)
          query-executed-in-scheme?: #t
          supported-inference-steps: (rows-of 'supported-step)
          reachable-candidates: reach
          missing-claims: (rows-of 'missing)
          equality-mismatches: mismatches
          value-conflicts: conflicts
          evidence-consistent?: consistent?
          hypothesis-results: evaluated-hypotheses
          unresolved-witnesses: (.ref case-value 'unresolved)
          historical-attribution-verified?: #f
          source-authenticity-verified?: #f
          action-authority?: #f))))
