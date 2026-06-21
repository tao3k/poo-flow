;;; -*- Gerbil -*-
;;; Boundary: sandbox-core profile derivation follows module-system POO merge.
;;; Invariant: derived profiles are inert recipes; no backend runtime executes.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/modules/nono-sandbox/config
        :poo-flow/src/modules/nono-sandbox/objects
        :poo-flow/src/modules/sandbox-core/profile)

;;; Fixture alist reads stay local to the derivation receipt assertions so the
;;; test does not depend on profile projection internals for metadata lookup.
;; | DerivationMetadata = Alist
;; | DerivationMetadataKey = Symbol
;; : (-> DerivationMetadata DerivationMetadataKey Value Value)
(def (derivation-test-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;;; Lineage order is the behavior under test: the final step must describe the
;;; task derivation, not an intermediate project/session parent.
;; | DerivationLineage = (cons Alist [Alist])
;; : (-> DerivationLineage Alist)
(def (derivation-test-last values)
  (if (null? (cdr values))
    (car values)
    (derivation-test-last (cdr values))))

;;; Negative cases assert that malformed rows fail before backend realization;
;;; the helper keeps the suite focused on the validation boundary.
;; | DerivationValidationThunk = (-> Unit Value)
;; : (-> DerivationValidationThunk Boolean)
(def (derivation-test-error? thunk)
  (with-catch (lambda (_failure) #t)
              (lambda ()
                (thunk)
                #f)))

(run-tests!
 (test-suite "sandbox-core profile derivation"
   (test-case "derives session and task profiles through POO row merges"
     (let* ((project-profile
             (poo-flow-nono-sandbox-profile-config
              'project/dev
              '((capabilities :append project-tool)
                (metadata (project . marlin)))))
            (session-profile
             (poo-flow-sandbox-profile-object-derive
              poo-flow-nono-sandbox-profile-object
              project-profile
              'session/dev
              '((capabilities :append session-tool)
                (metadata (session . "s-1")))
              '((scope . session) (scope-ref . "s-1"))))
            (task-profile
             (poo-flow-sandbox-profile-object-derive
              poo-flow-nono-sandbox-profile-object
              session-profile
              'task/build
              '((capabilities :append task-tool)
                (capabilities :remove project-tool)
                (metadata (task . build)))
              '((scope . task) (scope-ref . build))))
            (metadata (poo-flow-sandbox-profile-metadata task-profile))
            (lineage
             (derivation-test-alist-ref metadata 'derivation-path '()))
            (last-step (derivation-test-last lineage)))
       (check-equal? (poo-flow-sandbox-profile-name task-profile)
                     'task/build)
       (check-equal? (poo-flow-sandbox-profile-backend-kind task-profile)
                     'nono)
       (check-equal? (poo-flow-sandbox-profile-backend-ref task-profile)
                     'task/build)
       (check-equal? (poo-flow-sandbox-profile-capabilities task-profile)
                     '(process filesystem tmpdir session-tool task-tool))
       (check-equal? (length lineage) 2)
       (check-equal? (derivation-test-alist-ref last-step
                                                'parent-profile
                                                #f)
                     'session/dev)
       (check-equal? (derivation-test-alist-ref last-step 'scope #f)
                     'task)
       (check-equal? (derivation-test-alist-ref last-step 'scope-ref #f)
                     'build)
       (check-equal? (derivation-test-alist-ref metadata 'runtime-executed #t)
                     #f)))
   (test-case "rejects backend rows during derivation"
     (let (project-profile
           (poo-flow-nono-sandbox-profile-config
            'project/dev
            '((metadata (project . marlin)))))
       (check-equal?
        (derivation-test-error?
         (lambda ()
           (poo-flow-sandbox-profile-object-derive
            poo-flow-nono-sandbox-profile-object
            project-profile
            'session/bad
            '((backend docker)))))
        #t)))
   (test-case "rejects non-symbol names before profile resolution"
     (let (project-profile
           (poo-flow-nono-sandbox-profile-config
            'project/dev
            '((metadata (project . marlin)))))
       (check-equal?
        (derivation-test-error?
         (lambda ()
           (poo-flow-sandbox-profile-object-derive
            poo-flow-nono-sandbox-profile-object
            project-profile
            "session/bad"
            '((metadata (session . bad))))))
        #t)
       (check-equal?
        (derivation-test-error?
         (lambda ()
           (poo-flow-nono-sandbox-profile-config
            "project/bad"
            '((metadata (project . bad))))))
        #t)))
   (test-case "rejects non-profile parents during derivation"
     (check-equal?
      (derivation-test-error?
       (lambda ()
         (poo-flow-sandbox-profile-object-derive
          poo-flow-nono-sandbox-profile-object
          'not-a-profile
          'session/bad-parent
          '((metadata (session . bad-parent))))))
      #t))
   (test-case "rejects unknown rows through POO field validation"
     (let (project-profile
           (poo-flow-nono-sandbox-profile-config
            'project/dev
            '((metadata (project . marlin)))))
       (check-equal?
        (derivation-test-error?
         (lambda ()
           (poo-flow-sandbox-profile-object-derive
            poo-flow-nono-sandbox-profile-object
            project-profile
            'session/unknown-row
            '((unknown-row value)))))
        #t)))
   (test-case "rejects unsafe filesystem resources before runtime handoff"
     (let (project-profile
           (poo-flow-nono-sandbox-profile-config
            'project/dev
            '((metadata (project . marlin)))))
       (check-equal?
        (derivation-test-error?
         (lambda ()
           (poo-flow-sandbox-profile-object-derive
            poo-flow-nono-sandbox-profile-object
            project-profile
            'session/unsafe-filesystem
            '((resources filesystem)))))
        #t)))))
