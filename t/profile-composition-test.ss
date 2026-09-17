;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later


(import :std/test
        (only-in :clan/poo/object .call .o .ref .ref/cached)
        :gerbil/gambit
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition/interface
        (only-in :poo-flow/src/module-system/profile-composition/funcs
                 poo-flow-leftmost-index-by))

;;; Test protocol: construction and identity projection must not force any
;;; listed derived slot.  Keep the macro small and expand to ordinary checks.
(defrule (check-unforced-slots object slot ...)
  (begin
    (check-equal? (.ref/cached object 'slot (lambda () 'not-forced))
                  'not-forced)
    ...))

(def base-report
  (.o (kind 'report)
      (scope '(session))
      (storage '(object))
      (analysis '(checksum))
      (publish '(proof-gated))
      (retention '(session))
      (guard '(provenance sealed))))

(def existing-native-profile
  (.o (kind 'native-profile)
      (scope '(project))))

(def (with-audit-retention profile)
  (.o (:extends profile)
      (retention '(project-retained audit-log))))

(def canonical-composition
  (use-composition canonical-composition
    (use-module artifact-catalog as artifact
      (profiles imported-report)
      (profile existing-native-profile)
      (profile audited-report
        :extends base-report
        :with (with-audit-retention)
        :kind report
        :scope (session human-handoff)
        :storage (file object)
        :analysis (checksum provenance)
        :publish (human-approved proof-gated)))
    (compose
      (profiles artifact
        imported-report
        existing-native-profile
        audited-report))
    (stage production
      (graph artifact-publish-graph)
      (loop #:fuel 3 #:exit published)
      (prove audit-before-publish)
      (handoff marlin-runtime))))

(def hygiene-composition
  (let (artifact 'outer-binding)
    (use-composition hygiene-composition
      (use-module artifact-catalog as artifact
        (profile local-report
          :kind hygienic-profile
          :scope (session)))
      (compose (profile artifact local-report)))))

(def plan-composition
  (use-composition plan-composition
    (use-module research as research
      (profile researcher :kind agent :scope research)
      (profile verifier :kind authority :scope evidence))
    (compose
      (profile research researcher)
      (profile research verifier))
    (stage collect
      (step researcher)
      (handoff verifier)
      (edges (researcher verifier)))
    (stage scenario
      (step collect))))

(def github-profile (.o kind: 'github-actions name: 'github-workflow))
(def nasa-sdlc-profile (.o kind: 'sdlc-standard name: 'nasa-7150-2d))
(def multi-module-composition
  (use-composition github-workflow
    (modules
      (use-module github as github
        (profile github-profile))
      (use-module sdlc as sdlc
        (profile nasa-sdlc-profile)))
    (compose
      (profile github github-profile)
      (profile sdlc nasa-sdlc-profile))
    (stage production
      (prove nasa-release-gates)
      (handoff github-actions))))

(export profile-composition-test)

(def profile-composition-test
  (test-suite
   "profile composition"
   (test-case
    "target indexes retain the first source declaration"
    (let* ((first '(profile report step))
           (second '(case report handoff))
           (index
            (poo-flow-leftmost-index-by
             cadr (list first second))))
      (check (hash-get index 'report) => first)))
   (test-case
    "canonical grammar lowers to reusable POO objects"
    (let* ((profiles (.ref canonical-composition 'profiles))
           (profile-bindings
            (.ref canonical-composition 'profile-bindings))
           (stages (.ref canonical-composition 'stages))
           (stage (car stages))
           (audited (list-ref profiles 2)))
      (check-equal? (.ref canonical-composition 'kind)
                    +poo-flow-scenario-case-kind+)
      (check-equal? (.ref canonical-composition 'name)
                    'canonical-composition)
      (check-equal? (length (.ref canonical-composition 'modules)) 1)
      (check-equal? (length profiles) 3)
      (check-equal? (length profile-bindings) 3)
      (check-equal? (.ref (car profile-bindings) 'alias) 'artifact)
      (check-equal? (.ref (car profile-bindings) 'slot)
                    'imported-report)
      (check-equal? (.ref (car profiles) 'kind)
                    'poo-flow.scenario.imported-profile.v1)
      (check-equal? (.ref (car profiles) 'module) 'artifact-catalog)
      (check-equal? (.ref (list-ref profiles 1) 'kind) 'native-profile)
      (check-equal? (.ref audited 'kind) 'report)
      (check-equal? (.ref audited 'scope) '(session human-handoff))
      (check-equal? (.ref audited 'retention)
                    '(project-retained audit-log))
      (check-equal? (.ref audited 'guard)
                    '(provenance sealed))
      (check-equal? (length stages) 1)
      (check-equal? (.ref stage 'name) 'production)
      (check-equal? (length (.ref stage 'clauses)) 4)))
   (test-case
    "one composition declares and selects multiple POO modules"
    (let ((bindings (.ref multi-module-composition 'modules))
          (profiles (.ref multi-module-composition 'profiles)))
      (check-equal? (map (lambda (value) (.ref value 'alias)) bindings)
                    '(github sdlc))
      (check-equal? (length profiles) 2)
      (check-equal? (car profiles) github-profile)
      (check-equal? (cadr profiles) nasa-sdlc-profile)))
   (test-case
    "composition multiplicity uses compact launch ranges"
    (let* ((alpha
            (poo-flow-scenario-case
             'alpha
             '()
             '()
             '()
             '()))
           (beta
            (poo-flow-scenario-case
             'beta
             '()
             '()
             '()
             '()))
           (gamma
            (poo-flow-scenario-case
             'gamma
             '()
             '()
             '()
             '()))
           (workload
            (poo-flow-scenario-case-workload
             (list (poo-flow-scenario-case-multiplicity alpha 5000)
                   (poo-flow-scenario-case-multiplicity beta 10000)
                   (poo-flow-scenario-case-multiplicity gamma 25000))))
           (launch-ranges (.ref workload 'launch-ranges))
           (alpha-tail
            (poo-flow-scenario-case-workload/ref workload 4999))
           (beta-head
            (poo-flow-scenario-case-workload/ref workload 5000))
           (beta-tail
            (poo-flow-scenario-case-workload/ref workload 14999))
           (gamma-head
            (poo-flow-scenario-case-workload/ref workload 15000))
           (gamma-tail
            (poo-flow-scenario-case-workload/ref workload 39999)))
      (check-equal? (.ref workload 'kind)
                    'poo-flow.scenario.workload.v1)
      (check-equal? (.ref workload 'total-count) 40000)
      (check-equal? (vector-length launch-ranges) 3)
      (check-equal? (.ref (vector-ref launch-ranges 0) 'start) 0)
      (check-equal? (.ref (vector-ref launch-ranges 0) 'end) 5000)
      (check-equal? (.ref (vector-ref launch-ranges 1) 'start) 5000)
      (check-equal? (.ref (vector-ref launch-ranges 1) 'end) 15000)
      (check-equal? (.ref (vector-ref launch-ranges 2) 'start) 15000)
      (check-equal? (.ref (vector-ref launch-ranges 2) 'end) 40000)
      (check-equal? (.ref alpha-tail 'local-ordinal) 4999)
      (check-equal? (.ref beta-head 'local-ordinal) 0)
      (check-equal? (.ref beta-tail 'local-ordinal) 9999)
      (check-equal? (.ref gamma-head 'local-ordinal) 0)
      (check-equal? (.ref gamma-tail 'local-ordinal) 24999)
      (check-equal? (.ref (.ref alpha-tail 'composition) 'name) 'alpha)
      (check-equal? (.ref (.ref beta-head 'composition) 'name) 'beta)
      (check-equal? (.ref (.ref gamma-head 'composition) 'name) 'gamma)))
   (test-case
    "composition multiplicity rejects invalid counts ranges and ordinals"
    (let ((composition
           (poo-flow-scenario-case
            'bounded
            '()
            '()
            '()
            '())))
      (check-exception
       (poo-flow-scenario-case-multiplicity composition 0)
       true)
      (check-exception
       (poo-flow-scenario-case-launch-range composition -1 1)
       true)
      (check-exception
       (poo-flow-scenario-case-workload '())
       true)
      (let ((workload
             (poo-flow-scenario-case-workload
              (list (poo-flow-scenario-case-multiplicity composition 1)))))
        (check-exception
         (poo-flow-scenario-case-workload/ref workload -1)
         true)
        (check-exception
         (poo-flow-scenario-case-workload/ref workload 1)
         true))))
   (test-case
    "generated alias binding does not capture the surrounding binding"
    (let (profile (car (.ref hygiene-composition 'profiles)))
      (check-equal? (.ref profile 'kind) 'hygienic-profile)
      (check-equal? (.ref profile 'scope) '(session))))
   (test-case
    "composition lowers to the canonical execution plan and dependency DAG"
    (let* ((plan (poo-flow-scenario-case->execution-plan plan-composition))
           (nodes (execution-plan-nodes plan))
           (dependency-edges (execution-plan-dependency-edges plan))
           (researcher (list-ref nodes 3))
           (verifier (list-ref nodes 4)))
      (check-equal? (execution-plan? plan) #t)
      (check-equal? (length nodes) 5)
      (check-equal?
       (if (member (list (plan-node-id researcher)
                         (plan-node-id verifier))
                   dependency-edges)
           #t
           #f)
       #t)))
   (test-case
    "closed composition is a Scenario Case"
    (check-equal? (poo-flow-scenario-case? plan-composition) #t)
    (check-equal? (.ref plan-composition 'kind)
                  +poo-flow-scenario-case-kind+)
    (check-unforced-slots
     plan-composition execution-plan admission presentation))
   (test-case
    "Scenario Case memoizes its lazy execution plan"
    (let (prepared (.ref plan-composition 'execution-plan))
      (check-equal? (execution-plan? prepared) #t)
      (check-equal? (eq? prepared (.ref plan-composition 'execution-plan)) #t)))
   (test-case
    "Scenario Case exposes preparation behavior"
    (let (prepared (.call plan-composition prepare))
      (check-equal? (eq? prepared (.ref plan-composition 'execution-plan)) #t)
      (check-equal? (execution-plan? prepared) #t)))
   (test-case
    "Scenario Case exposes admission behavior"
    (let (admission (.call plan-composition admit))
      (check-equal? (.ref admission 'accepted?) #t)
      (check-equal? (execution-plan? (.ref admission 'plan)) #t)
      (check-equal? (eq? (.ref admission 'plan)
                         (.ref plan-composition 'execution-plan))
                    #t)))
   (test-case
    "case projection preserves lazy derived slots"
    (let (composition
          (poo-flow-scenario-case 'lazy-projection '() '() '() '()))
      (check-equal? (eq? (.call composition project 'case) composition) #t)
      (check-unforced-slots
       composition execution-plan admission presentation)))
   (test-case
    "Scenario Case exposes presentation and projection behavior"
    (let ((prepared (.ref plan-composition 'execution-plan))
          (presentation (.call plan-composition present)))
      (check-equal? (.ref presentation 'kind)
                    +poo-flow-scenario-presentation-kind+)
      (check-equal? (.ref presentation 'case-name) 'plan-composition)
      (check-equal? (.ref presentation 'plan-node-count) 5)
      (check-equal? (.call plan-composition project 'execution-plan)
                    prepared)))
   (test-case
    "fresh Scenario Sessions own ordered run-local transitions"
    (let ((session (.call plan-composition new-session))
          (sibling (.call plan-composition new-session)))
      (check-equal? (poo-flow-scenario-session? session) #t)
      (check-equal? (poo-flow-scenario-session-state session) 'created)
      (check-equal? (execution-plan? (.call session prepare!)) #t)
      (check-equal? (poo-flow-scenario-session-state session) 'prepared)
      (check-equal? (.ref (.call session admit!) 'accepted?) #t)
      (check-equal? (poo-flow-scenario-session-state session) 'admitted)
      (check-equal? (.ref (.call session project! 'summary) 'case-name)
                    'plan-composition)
      (check-equal? (poo-flow-scenario-session-state session) 'projected)
      (check-equal? (length (poo-flow-scenario-session-events session)) 3)
      (check-equal? (poo-flow-scenario-session-state sibling) 'created)
      (check-equal? (poo-flow-scenario-session-events sibling) '())
      (check-exception (.call session admit!) true)))))
