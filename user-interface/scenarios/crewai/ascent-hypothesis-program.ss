;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A graph-free Scheme experiment: native Ascent candidate closure can revise
;;; a POO Agent society. Neither closure nor successor has MRR or Host authority.

(import (only-in :clan/poo/object .o .ref .call object?)
        (only-in :clan/poo/trie UIntTrieSet)
        (only-in :poo-flow/src/semantic/organization-bundle
                 poo-flow-organization-principal
                 poo-flow-organization-agent
                 poo-flow-organization-delegation
                 poo-flow-organization-context-projection
                 poo-flow-organization-organization-facet
                 poo-flow-organization-authority-facet
                 poo-flow-organization-context-facet
                 poo-flow-organization-bundle
                 poo-flow-organization-bundle?
                 poo-flow-organization-bundle-identity
                 poo-flow-organization-bundle-validate
                 poo-flow-organization-validation-accepted?))

(export poo-flow-ascent-prediction
        poo-flow-ascent-hypothesis-program
        poo-flow-ascent-hypothesis-demand
        poo-flow-ascent-hypothesis-revise)

(def (valid-organization? value)
  (and (poo-flow-organization-bundle? value)
       (poo-flow-organization-validation-accepted?
        (poo-flow-organization-bundle-validate value))))

(def (source-pairs expression)
  (.call UIntTrieSet .list<- (.ref expression 'source-pairs)))

(def (poo-flow-ascent-prediction pair-value expected-value?)
  (unless (and (exact-integer? pair-value) (>= pair-value 0)
               (boolean? expected-value?))
    (error "Ascent prediction requires a pair and expected membership"))
  (.o kind: 'poo-flow.ascent-prediction.v1
      pair: pair-value
      expected-reachable?: expected-value?))

(def (prediction-projection predictions)
  (map (lambda (prediction)
         (list (.ref prediction 'pair)
               (.ref prediction 'expected-reachable?)))
       predictions))

(def (valid-prediction-projection? rows radix)
  (let loop ((remaining rows) (seen '()))
    (if (null? remaining)
      #t
      (let* ((row (car remaining))
             (pair-value (car row)))
        (and (exact-integer? pair-value)
             (<= 0 pair-value)
             (< pair-value (* radix radix))
             (boolean? (cadr row))
             (not (member pair-value seen))
             (loop (cdr remaining) (cons pair-value seen)))))))

(def (poo-flow-ascent-hypothesis-program identity-value source-id-value
                                         expression prediction-values
                                         organization-value limit-value)
  (unless (and (symbol? identity-value)
               (string? source-id-value)
               (> (string-length source-id-value) 0)
               (object? expression)
               (pair? prediction-values)
               (valid-organization? organization-value)
               (exact-integer? limit-value)
               (<= 1 limit-value 8))
    (error "Ascent hypothesis requires bounded POO inputs"))
  (let* ((radix-value (.ref expression 'radix))
         (pairs (source-pairs expression))
         (projection (prediction-projection prediction-values))
         (organization-digest-value
          (.ref (poo-flow-organization-bundle-identity organization-value)
                'digest)))
    (unless (and (exact-integer? radix-value)
                 (> radix-value 1)
                 (valid-prediction-projection? projection radix-value))
      (error "Ascent predictions must be distinct in the source radix"))
    (.o kind: 'poo-flow.ascent-hypothesis-candidate.v1
        identity: identity-value
        generation: 0
        predecessor-identity: #f
        source-identity: source-id-value
        source-pair-values: pairs
        radix: radix-value
        predictions: prediction-values
        prediction-projection: projection
        organization-digest: organization-digest-value
        max-derived-agents: limit-value
        activation-authority?: #f
        mrr-admitted?: #f)))

(def (poo-flow-ascent-hypothesis-demand program)
  (unless (and (object? program)
               (eq? (.ref program 'kind)
                    'poo-flow.ascent-hypothesis-candidate.v1))
    (error "Ascent demand requires a hypothesis program"))
  (let ((demand-id
         (list 'poo-flow.ascent-hypothesis-demand.v1
               (.ref program 'identity)
               (.ref program 'generation)
               (.ref program 'source-identity)
               (.ref program 'source-pair-values)
               (.ref program 'radix)
               (.ref program 'prediction-projection)
               (.ref program 'organization-digest)
               (.ref program 'max-derived-agents))))
    (.o kind: 'poo-flow.ascent-hypothesis-demand.v1
        identity: demand-id
        activation-authority?: #f)))

(def (derive-society base source-id generation-value failed-pairs limit)
  (let* ((organization-facet (.ref base 'organization))
         (authority-facet (.ref base 'authority))
         (context-facet (.ref base 'context))
         (agents
          (filter (lambda (value) (eq? (.ref value 'kind) 'agent))
                  (.ref organization-facet 'entities)))
         (roots (filter (lambda (value) (not (.ref value 'parent-id))) agents))
         (children (filter (lambda (value) (.ref value 'parent-id)) agents)))
    (unless (and (= (length roots) 1) (pair? children))
      (error "derived society requires a root and child template"))
    (let* ((root-id (.ref (car roots) 'id))
           (template (car children))
           (authorities (.ref template 'authorities))
           (visible (.ref template 'context-visible))
           (selected-pairs
            (let loop ((remaining failed-pairs) (index 0) (selected '()))
              (if (or (null? remaining) (= index limit))
                (reverse selected)
                (loop (cdr remaining) (+ index 1)
                      (cons (car remaining) selected)))))
           (agent-ids
            (map (lambda (pair-value)
                   (string-append "ascent-review/" source-id "/"
                                  (number->string generation-value) "/"
                                  (number->string pair-value)))
                 selected-pairs))
           (principal-ids
            (map (lambda (agent-id)
                   (string-append "principal/" agent-id))
                 agent-ids))
           (new-members
            (apply append
                   (map (lambda (agent-id principal-id)
                          (list
                           (poo-flow-organization-principal principal-id)
                           (poo-flow-organization-agent
                            agent-id principal-id (.ref template 'role-id)
                            root-id authorities visible)))
                        agent-ids principal-ids)))
           (new-delegations
            (apply append
                   (map (lambda (agent-id)
                          (map (lambda (capability-id)
                                 (poo-flow-organization-delegation
                                  root-id agent-id capability-id))
                               authorities))
                        agent-ids)))
           (new-contexts
            (map (lambda (agent-id)
                   (poo-flow-organization-context-projection agent-id visible))
                 agent-ids))
           (derived
            (poo-flow-organization-bundle
             (+ 1 (.ref base 'epoch))
             (poo-flow-organization-organization-facet
              (append (.ref organization-facet 'entities) new-members)
              (.ref organization-facet 'relations)
              (.ref organization-facet 'constraints))
             (poo-flow-organization-authority-facet
              (.ref authority-facet 'entities)
              (append (.ref authority-facet 'relations) new-delegations)
              (.ref authority-facet 'constraints))
             (poo-flow-organization-context-facet
              (append (.ref context-facet 'entities) new-contexts)
              (.ref context-facet 'constraints))
             (.ref base 'protocol)
             (.ref base 'evidence))))
      (unless (valid-organization? derived)
        (error "derived Ascent society failed Bundle validation"))
      derived)))

(def (poo-flow-ascent-hypothesis-revise program demand expression organization)
  (unless (and (object? program)
               (eq? (.ref program 'kind)
                    'poo-flow.ascent-hypothesis-candidate.v1)
               (object? demand)
               (equal? (.ref demand 'identity)
                       (.ref (poo-flow-ascent-hypothesis-demand program)
                             'identity))
               (eq? (.ref demand 'activation-authority?) #f)
               (valid-organization? organization)
               (equal? (.ref (poo-flow-organization-bundle-identity organization)
                             'digest)
                       (.ref program 'organization-digest))
               (equal? (source-pairs expression)
                       (.ref program 'source-pair-values))
               (equal? (.ref expression 'radix) (.ref program 'radix)))
    (error "Ascent revision requires exact candidate source and society"))
  (let* ((contains? (.ref expression 'closure-contains?))
         (failures
          (filter (lambda (prediction)
                    (not (eq? (contains? (.ref prediction 'pair))
                              (.ref prediction 'expected-reachable?))))
                  (.ref program 'predictions)))
         (failed-pair-values
          (map (lambda (value) (.ref value 'pair)) failures))
         (next-generation (+ 1 (.ref program 'generation)))
         (source-id (.ref program 'source-identity))
         (selected-organization
          (if (null? failed-pair-values)
            organization
            (derive-society organization source-id next-generation
                            failed-pair-values
                            (.ref program 'max-derived-agents))))
         (selected-digest
          (.ref (poo-flow-organization-bundle-identity selected-organization)
                'digest))
         (predecessor (.ref program 'identity))
         (source-values (.ref program 'source-pair-values))
         (radix-value (.ref program 'radix))
         (prediction-values (.ref program 'predictions))
         (prediction-rows (.ref program 'prediction-projection))
         (limit-value (.ref program 'max-derived-agents))
         (verdict-value (if (null? failures) 'matched 'falsified)))
    (values
     (.o kind: 'poo-flow.ascent-hypothesis-candidate.v1
         identity: (list predecessor next-generation source-id failed-pair-values)
         generation: next-generation
         predecessor-identity: predecessor
         source-identity: source-id
         source-pair-values: source-values
         radix: radix-value
         predictions: prediction-values
         prediction-projection: prediction-rows
         prediction-verdict: verdict-value
         failed-pairs: failed-pair-values
         organization-digest: selected-digest
         max-derived-agents: limit-value
         activation-authority?: #f
         mrr-admitted?: #f)
     selected-organization)))
