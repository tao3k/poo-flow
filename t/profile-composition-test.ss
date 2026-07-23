;;; -*- Gerbil -*-

(import :std/test
        :std/srfi/13
        (only-in :clan/poo/object .o .ref)
        :gerbil/gambit
        (only-in :gerbil/expander datum->syntax)
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        (only-in :poo-flow/src/module-system/profile-composition-syntax-plan
                 parse-poo-flow-composition-syntax-plan))

(def base-report
  (.o (kind 'report)
      (scope '(session))
      (storage '(object))
      (analysis '(checksum))
      (publish '(proof-gated))
      (retention '(session))))

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

(def (composition-syntax-error-message module-datum)
  (let (module-form (datum->syntax #f module-datum))
    (with-exception-catcher
     (lambda (exn)
       (call-with-output-string
        (lambda (port) (display-exception exn port))))
     (lambda ()
       (parse-poo-flow-composition-syntax-plan
        (datum->syntax #f 'invalid-composition)
        module-form
        '()
        module-form)
       #f))))

(def profile-composition-tests
  (test-suite
   "profile composition"
   (test-case
    "canonical grammar lowers to reusable POO objects"
    (let* ((profiles (.ref canonical-composition 'profiles))
           (profile-bindings
            (.ref canonical-composition 'profile-bindings))
           (stages (.ref canonical-composition 'stages))
           (stage (car stages))
           (audited (list-ref profiles 2)))
      (check-equal? (.ref canonical-composition 'kind)
                    'poo-flow.composition)
      (check-equal? (.ref canonical-composition 'name)
                    'canonical-composition)
      (check-equal? (length (.ref canonical-composition 'modules)) 1)
      (check-equal? (length profiles) 3)
      (check-equal? (length profile-bindings) 3)
      (check-equal? (.ref (car profile-bindings) 'alias) 'artifact)
      (check-equal? (.ref (car profile-bindings) 'slot)
                    'imported-report)
      (check-equal? (.ref (car profiles) 'kind)
                    'poo-flow.composition.imported-profile)
      (check-equal? (.ref (car profiles) 'module) 'artifact-catalog)
      (check-equal? (.ref (list-ref profiles 1) 'kind) 'native-profile)
      (check-equal? (.ref audited 'kind) 'report)
      (check-equal? (.ref audited 'scope) '(session human-handoff))
      (check-equal? (.ref audited 'retention)
                    '(project-retained audit-log))
      (check-equal? (length stages) 1)
      (check-equal? (.ref stage 'name) 'production)
      (check-equal? (length (.ref stage 'clauses)) 4)))
   (test-case
    "composition multiplicity uses compact launch ranges"
    (let* ((alpha
            (poo-flow-composition-object/profiles
             'alpha
             '()
             '()
             '()))
           (beta
            (poo-flow-composition-object/profiles
             'beta
             '()
             '()
             '()))
           (gamma
            (poo-flow-composition-object/profiles
             'gamma
             '()
             '()
             '()))
           (workload
            (poo-flow-composition-workload
             (list (poo-flow-composition-multiplicity alpha 5000)
                   (poo-flow-composition-multiplicity beta 10000)
                   (poo-flow-composition-multiplicity gamma 25000))))
           (launch-ranges (.ref workload 'launch-ranges))
           (alpha-tail
            (poo-flow-composition-workload/ref workload 4999))
           (beta-head
            (poo-flow-composition-workload/ref workload 5000))
           (beta-tail
            (poo-flow-composition-workload/ref workload 14999))
           (gamma-head
            (poo-flow-composition-workload/ref workload 15000))
           (gamma-tail
            (poo-flow-composition-workload/ref workload 39999)))
      (check-equal? (.ref workload 'kind)
                    'poo-flow.composition.workload)
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
           (poo-flow-composition-object/profiles
            'bounded
            '()
            '()
            '())))
      (check-exception
       (poo-flow-composition-multiplicity composition 0)
       true)
      (check-exception
       (poo-flow-composition-launch-range composition -1 1)
       true)
      (check-exception
       (poo-flow-composition-workload '())
       true)
      (let ((workload
             (poo-flow-composition-workload
              (list (poo-flow-composition-multiplicity composition 1)))))
        (check-exception
         (poo-flow-composition-workload/ref workload -1)
         true)
        (check-exception
         (poo-flow-composition-workload/ref workload 1)
         true))))
   (test-case
    "generated alias binding does not capture the surrounding binding"
    (let (profile (car (.ref hygiene-composition 'profiles)))
      (check-equal? (.ref profile 'kind) 'hygienic-profile)
      (check-equal? (.ref profile 'scope) '(session))))
   (test-case
    "composition lowers to the canonical execution plan and dependency DAG"
    (let* ((plan (poo-flow-composition->execution-plan plan-composition))
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
    "non-canonical module grammar reports the single canonical diagnostic"
    (check-equal?
     (integer?
      (string-contains
       (composition-syntax-error-message '(module artifact))
       "composition-invalid-module-form"))
     #t))
   (test-case
    "duplicate profile declarations are rejected during parsing"
    (check-equal?
     (integer?
      (string-contains
       (composition-syntax-error-message
        '(use-module artifact-catalog as artifact
           (profile report :kind report)
           (profile report :kind report)))
       "composition-duplicate-profile"))
     #t))))

(run-tests! profile-composition-tests)
