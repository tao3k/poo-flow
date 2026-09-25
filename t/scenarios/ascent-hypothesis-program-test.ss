;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test check check-exception test-case test-suite)
        (only-in :clan/poo/object .o .mix .ref .call)
        (only-in :clan/poo/trie UIntTrieSet)
        (only-in :poo-flow/src/qualification/ascent-table-expression
                 poo-flow-ascent-table-expression-prototype)
        :poo-flow/src/semantic/organization-bundle
        :poo-flow/user-interface/scenarios/crewai/ascent-hypothesis-program)

(export ascent-hypothesis-program-test)

(def (research-organization)
  (poo-flow-organization-bundle
   1
   (poo-flow-organization-organization-facet
    (list (poo-flow-organization-principal 'parent-principal)
          (poo-flow-organization-principal 'worker-principal)
          (poo-flow-organization-role 'role/researcher)
          (poo-flow-organization-role 'role/worker)
          (poo-flow-organization-agent
           'researcher 'parent-principal 'role/researcher #f
           '(search review) '(public))
          (poo-flow-organization-agent
           'worker 'worker-principal 'role/worker 'researcher
           '(search) '(public))))
   (poo-flow-organization-authority-facet
    (list (poo-flow-organization-capability 'search #t)
          (poo-flow-organization-capability 'review #t))
    (list (poo-flow-organization-delegation
           'researcher 'worker 'search)))
   (poo-flow-organization-context-facet
    (list (poo-flow-organization-context-projection
           'worker '(public))))
   (poo-flow-organization-protocol-facet
    (list (poo-flow-organization-tool-effect
           'search-tool 'search 'external-tool))
    '())
   (poo-flow-organization-empty-evidence-facet)))

(def (expression-from-pairs pairs)
  (.mix poo-flow-ascent-table-expression-prototype
        (.o source-pairs: (.call UIntTrieSet .<-list pairs)
            radix: 8)))

(def (agent-count bundle)
  (length
   (filter (lambda (value) (eq? (.ref value 'kind) 'agent))
           (.ref (.ref bundle 'organization) 'entities))))

(def ascent-hypothesis-program-test
  (test-suite "Scheme Ascent candidate revises an Agent society"
   (test-case "source withdrawal falsifies a predicted closure pair"
     (let* ((base (research-organization))
            (cycle (expression-from-pairs '(10 19 28 34 11)))
            (withdrawn (expression-from-pairs '(10 19 28 11)))
            (predictions
             (list (poo-flow-ascent-prediction 11 #t)
                   (poo-flow-ascent-prediction 36 #t)))
            (cycle-program
             (poo-flow-ascent-hypothesis-program
              'research-cycle "source/cycle" cycle predictions base 3))
            (withdrawn-program
             (poo-flow-ascent-hypothesis-program
              'research-withdrawn "source/withdrawn" withdrawn
              predictions base 3)))
       (let-values
        (((cycle-successor cycle-organization)
          (poo-flow-ascent-hypothesis-revise
           cycle-program (poo-flow-ascent-hypothesis-demand cycle-program)
           cycle base))
         ((withdrawn-successor withdrawn-organization)
          (poo-flow-ascent-hypothesis-revise
           withdrawn-program
           (poo-flow-ascent-hypothesis-demand withdrawn-program)
           withdrawn base)))
        (check (.ref cycle-successor 'prediction-verdict) => 'matched)
        (check (eq? cycle-organization base) => #t)
        (check (.ref withdrawn-successor 'prediction-verdict) => 'falsified)
        (check (.ref withdrawn-successor 'failed-pairs) => '(36))
        (check (agent-count withdrawn-organization) => 3)
        (check (poo-flow-organization-validation-accepted?
                (poo-flow-organization-bundle-validate
                 withdrawn-organization)) => #t)
        (check (.ref withdrawn-successor 'activation-authority?) => #f)
        (check (.ref withdrawn-successor 'mrr-admitted?) => #f)
        (check (.ref cycle 'closure-pairs)
               => '(10 11 12 18 19 20 26 27 28 34 35 36))
        (check (.ref withdrawn 'closure-pairs)
               => '(10 11 12 19 20 28))
        (check-exception
         (poo-flow-ascent-hypothesis-revise
          cycle-program (poo-flow-ascent-hypothesis-demand cycle-program)
          withdrawn base)
         true))))

   (test-case "prediction count is bounded and demand is generation-bound"
     (let* ((base (research-organization))
            (expression (expression-from-pairs '(10 19 28 11)))
            (predictions
             (list (poo-flow-ascent-prediction 36 #t)
                   (poo-flow-ascent-prediction 35 #t)))
            (program
             (poo-flow-ascent-hypothesis-program
              'bounded-research "source/withdrawn" expression
              predictions base 1))
            (demand (poo-flow-ascent-hypothesis-demand program)))
       (let-values
        (((successor organization)
          (poo-flow-ascent-hypothesis-revise
           program demand expression base)))
        (check (.ref successor 'failed-pairs) => '(36 35))
        (check (agent-count organization) => 3)
        (check (.ref organization 'epoch) => 2)
        (check-exception
         (poo-flow-ascent-hypothesis-revise
          successor demand expression organization)
         true)
        (check-exception
         (poo-flow-ascent-hypothesis-revise
          program demand expression organization)
         true))))

   (test-case "duplicate pair predictions cannot define a program"
     (let ((base (research-organization))
           (expression (expression-from-pairs '(10 19))))
       (check-exception
        (poo-flow-ascent-hypothesis-program
         'duplicate "source/duplicate" expression
         (list (poo-flow-ascent-prediction 11 #t)
               (poo-flow-ascent-prediction 11 #f))
         base 2)
        true)))))
