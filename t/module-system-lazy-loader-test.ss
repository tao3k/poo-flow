;;; -*- Gerbil -*-
;;; Boundary: lazy loader tests cover deferred source loading only.
;;; Invariant: lazy plans never call loader handlers until explicitly forced.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 test-case
                 test-error
                 test-suite)
        :poo-flow/t/support/performance
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/descriptor
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/loader
        :poo-flow/src/module-system/loader-tree)

(export module-system-lazy-loader-test)

;;; Source reference fixture names the standard-library module without touching
;;; filesystem-backed module loading.
;; : (-> Unit PooModuleSourceRef)
(def loader-standard-library-source
  (poo-flow-standard-library-source 'standard/kernel))

;;; Mutable call count is scoped to this owner to prove deferred loading without
;;; reaching into loader internals.
;; : (-> Unit Integer)
(def lazy-loader-call-count 0)

;;; Module fixture is inert descriptor data used by the test loader backend.
;; : (-> Unit PooModuleDescriptor)
(def loader-standard-library-module
  (make-empty-poo-flow-module-descriptor
   'standard-kernel
   '()
   '((standard-library . #t))))

;;; Loader backend fixture records calls and returns only the known standard
;;; library module source.
;; : (-> Unit PooModuleLoaderBackend)
(def user-standard-library-loader
  (make-poo-flow-module-loader-backend
   'user-standard-library-loader
   'standard-library
   (lambda (source-ref)
     (set! lazy-loader-call-count (+ lazy-loader-call-count 1))
     (if (poo-flow-module-source-ref=? source-ref loader-standard-library-source)
       loader-standard-library-module
       #f))
   '((library . standard))))

;;; Plan predicate keeps assertions about deferred receipts compact and local to
;;; the lazy-loader policy owner.
;; : (-> [PooFlowLazyLoadPlan] Boolean)
(def (lazy-loader-plans-deferred? plans)
  (cond
   ((null? plans) #t)
   ((and (not (poo-flow-lazy-load-plan-forced? (car plans)))
         (eq? (poo-flow-module-load-receipt-code
               (poo-flow-lazy-load-plan-receipt (car plans)))
              'deferred))
    (lazy-loader-plans-deferred? (cdr plans)))
   (else #f)))

;; : (forall (a) (-> [a] [a] [a]))
(def (lazy-loader-values/rev-onto values values-rev)
  (let loop ((remaining-values values)
             (result values-rev))
    (if (null? remaining-values)
      result
      (loop (cdr remaining-values)
            (cons (car remaining-values) result)))))

;; : (-> [String] [PooModuleSourceRef])
(def (lazy-loader-module-tree-source-refs module-roots)
  (let loop ((remaining-roots module-roots)
             (refs-rev '()))
    (if (null? remaining-roots)
      (reverse refs-rev)
      (loop (cdr remaining-roots)
            (lazy-loader-values/rev-onto
             (poo-flow-module-tree-source-refs (car remaining-roots))
             refs-rev)))))

;;; This suite keeps lazy-loader planning observable without forcing modules to
;;; load eagerly during configuration parsing.
;; : TestSuite
;; : TestCase
(def module-system-lazy-loader-large-registry-case
  (test-case "expands large module registry manifests without loading modules"
        (let* ((module-count 500)
               (module-roots
                (poo-flow-performance-build-list
                 module-count
                 (lambda (index)
                   (string-append "src/modules/generated-"
                                  (number->string index)))))
               (source-refs
                (lazy-loader-module-tree-source-refs module-roots))
               (best-ms
                (poo-flow-performance-best-elapsed-ms
                 5
                 (lambda ()
                   (lazy-loader-module-tree-source-refs module-roots)))))
          (check-equal? (length source-refs) (* module-count 2))
          (check-equal? (poo-flow-module-source-ref-value (car source-refs))
                        "src/modules/generated-0/config.ss")
          (check-equal? (< best-ms 50) #t))))

;; : TestCase
(def module-system-lazy-loader-deferred-standard-library-case
  (test-case "defers standard-library module loading until forced"
        (set! lazy-loader-call-count 0)
        (let* ((backends (list user-standard-library-loader))
               (deferred
                (poo-flow-lazy-load-source-receipt
                 backends
                 loader-standard-library-source))
               (plan
                (poo-flow-make-lazy-load-plan
                 backends
                 loader-standard-library-source
                 '((owner . standard-library))))
               (deferred-metadata
                (poo-flow-module-load-receipt-metadata deferred)))
          (check-equal? (poo-flow-module-source-ref-kind loader-standard-library-source)
                        'standard-library)
          (check-equal? (poo-flow-module-load-receipt-code deferred)
                        'deferred)
          (check-equal? (poo-flow-module-load-receipt-loaded? deferred)
                        #f)
          (check-equal? (cdr (assoc 'mode deferred-metadata))
                        'lazy)
          (check-equal? (cdr (assoc 'enabled? deferred-metadata))
                        #f)
          (check-equal? lazy-loader-call-count 0)
          (check-equal? (poo-flow-lazy-load-plan-forced? plan)
                        #f)
          (let* ((forced-plan
                  (poo-flow-force-lazy-load-plan plan))
                 (forced-receipt
                  (poo-flow-lazy-load-plan-receipt forced-plan)))
            (check-equal? (poo-flow-lazy-load-plan-forced? forced-plan)
                          #t)
            (check-equal? lazy-loader-call-count 1)
            (check-equal? (poo-flow-module-load-receipt-code forced-receipt)
                          'loaded)
            (check-equal? (poo-flow-module-name
                           (poo-flow-module-load-receipt-module forced-receipt))
                          'standard-kernel)))))

;; : TestCase
(def module-system-lazy-loader-module-tree-case
  (test-case "projects config and objects entrypoints from a module tree"
        (set! lazy-loader-call-count 0)
        (let* ((module-root "src/modules/nono-sandbox")
               (source-refs
                (poo-flow-module-tree-source-refs module-root))
               (config-source (car source-refs))
               (objects-source (cadr source-refs))
               (objects-metadata
                (poo-flow-module-source-ref-metadata objects-source))
               (plans
                (poo-flow-module-tree-lazy-load-plans
                 (list user-standard-library-loader)
                 module-root
                 '((owner . module-tree)))))
          (check-equal? (length source-refs) 2)
          (check-equal? (poo-flow-module-source-ref-kind config-source) 'local)
          (check-equal? (poo-flow-module-source-ref-value config-source)
                        "src/modules/nono-sandbox/config.ss")
          (check-equal? (poo-flow-module-source-ref-value objects-source)
                        "src/modules/nono-sandbox/objects.ss")
          (check-equal? (cdr (assoc 'entrypoint-role objects-metadata))
                        'objects)
          (check-equal? (length plans) 2)
          (check-equal? (poo-flow-lazy-load-plan-forced? (car plans)) #f)
          (check-equal? (poo-flow-module-load-receipt-code
                         (poo-flow-lazy-load-plan-receipt (cadr plans)))
                        'deferred)
          (check-equal? lazy-loader-call-count 0))))

;; : TestCase
(def module-system-lazy-loader-src-modules-case
  (test-case "projects src/modules entrypoints as lazy load plans"
        (set! lazy-loader-call-count 0)
        (let* ((plans
                (poo-flow-src-modules-lazy-load-plans
                 (list user-standard-library-loader)
                 '((owner . src-modules))))
               (source-values
                (map (lambda (plan)
                       (poo-flow-module-source-ref-value
                        (poo-flow-lazy-load-plan-source plan)))
                     plans))
               (first-receipt
                (poo-flow-lazy-load-plan-receipt (car plans)))
               (first-metadata
                (poo-flow-module-load-receipt-metadata first-receipt)))
          (check-equal? (length plans) 14)
          (check-equal? (car source-values)
                        "src/modules/agent-sandbox/config.ss")
          (check-equal? (if (member "src/modules/sandbox-core/objects.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/modules/nono-sandbox/objects.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/module-system/profile-config.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/module-system/init-syntax.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/module-system/root-profile.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/module-system/declaration-case.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/modules/workflow/flows.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (if (member "src/modules/workflow/syntax.ss"
                                    source-values)
                          #t
                          #f)
                        #t)
          (check-equal? (lazy-loader-plans-deferred? plans) #t)
          (check-equal? (cdr (assoc 'mode first-metadata)) 'lazy)
          (check-equal? (cdr (assoc 'owner first-metadata)) 'src-modules)
          (check-equal? lazy-loader-call-count 0))))

;; : TestCase
(def module-system-lazy-loader-entrypoint-conflicts-case
  (test-case "reports module names that collide with loader categories"
        (let ((conflicts
               (poo-flow-module-tree-entrypoint-conflicts
                '(("sandbox" objects)
                  ("sandbox-core" objects)
                  ("flow" config)
                  ("nono-sandbox" objects config)))))
          (check-equal? (poo-flow-src-module-tree-entrypoint-conflicts) '())
          (check-equal? (length conflicts) 2)
          (check-equal? (cdr (assoc 'module-name (car conflicts))) 'sandbox)
          (check-equal? (cdr (assoc 'module-name (cadr conflicts)))
                        'flow))))

;; : TestCase
(def module-system-lazy-loader-user-root-case
  (test-case "projects user-root init objects config and module helpers"
        (set! lazy-loader-call-count 0)
        (let* ((user-root "user-interface")
               (source-refs
                (poo-flow-user-tree-source-refs user-root))
               (init-source (car source-refs))
               (objects-source (cadr source-refs))
               (config-source (caddr source-refs))
               (modules-config-source (cadddr source-refs))
               (init-metadata
                (poo-flow-module-source-ref-metadata init-source))
               (objects-metadata
                (poo-flow-module-source-ref-metadata objects-source))
               (plans
                (poo-flow-user-tree-lazy-load-plans
                 (list user-standard-library-loader)
                 user-root
                 '((owner . user-root-tree)))))
          (check-equal? (length source-refs) 4)
          (check-equal? (poo-flow-module-source-ref-value init-source)
                        "user-interface/init.ss")
          (check-equal? (poo-flow-module-source-ref-value objects-source)
                        "user-interface/objects.ss")
          (check-equal? (poo-flow-module-source-ref-value config-source)
                        "user-interface/config.ss")
          (check-equal? (poo-flow-module-source-ref-value modules-config-source)
                        "user-interface/modules/config.ss")
          (check-equal? (cdr (assoc 'kind objects-metadata))
                        'user-tree)
          (check-equal? (cdr (assoc 'policy init-metadata))
                        'init-switches-only)
          (check-equal? (poo-flow-user-tree-source-allows?
                         init-source
                         'module-switch)
                        #t)
          (check-equal? (poo-flow-user-tree-source-allows?
                         init-source
                         'feature-switch)
                        #t)
          (check-equal? (poo-flow-user-tree-source-allows?
                         init-source
                         'sandbox-profile-recipe)
                        #f)
          (check-equal? (poo-flow-user-tree-source-valid?
                         init-source
                         '(profile-selection module-switch feature-switch))
                        #t)
          (check-equal? (poo-flow-user-tree-source-policy-violations
                         init-source
                         '(module-switch object-contract runtime-execution))
                        '(object-contract runtime-execution))
          (check-equal? (cdr (assoc 'entrypoint-role objects-metadata))
                        'objects)
          (check-equal? (poo-flow-user-tree-source-allows?
                         objects-source
                         'poo-object)
                        #t)
          (check-equal? (poo-flow-user-tree-source-valid?
                         objects-source
                         '(poo-object object-contract field-contract
                           object-inheritance))
                        #t)
          (check-equal? (poo-flow-user-tree-source-allows?
                         objects-source
                         'sandbox-profile-recipe)
                        #f)
          (check-equal? (poo-flow-user-tree-source-allows?
                         objects-source
                         'module-switch)
                        #f)
          (check-equal? (length plans) 4)
          (check-equal? (poo-flow-module-load-receipt-code
                         (poo-flow-lazy-load-plan-receipt (car plans)))
                        'deferred)
          (check-equal? lazy-loader-call-count 0))))

;; : TestCase
(def module-system-lazy-loader-auto-import-removal-case
  (test-case "removes auto-imported entrypoints through POO extension"
        (set! lazy-loader-call-count 0)
        (let* ((source-refs
                (poo-flow-user-tree-source-refs "user-interface"))
               (disable-config
                (poo-flow-module-extension-contribution
                 poo-flow-module-auto-import-root-identity
                 (list
                  (poo-flow-module-extension-node-remove
                   "user-interface/config.ss"))))
               (result
                (poo-flow-module-auto-imports-mk-merge
                 source-refs
                 (list disable-config)))
               (resolved-source-values
                (map poo-flow-module-source-ref-value
                     (poo-flow-module-auto-imports-result-source-refs result))))
          (check-equal? (poo-flow-module-extension-result-stable? result) #t)
          (check-equal? (length resolved-source-values) 3)
          (check-equal? (member "user-interface/config.ss"
                                resolved-source-values)
                        #f)
          (check-equal? (member "user-interface/objects.ss"
                                resolved-source-values)
                        '("user-interface/objects.ss"
                          "user-interface/modules/config.ss"))
          (check-equal? lazy-loader-call-count 0))))

;; : TestSuite
(def module-system-lazy-loader-test
  (test-suite "poo-flow module system lazy loader"
    module-system-lazy-loader-large-registry-case
    module-system-lazy-loader-deferred-standard-library-case
    module-system-lazy-loader-module-tree-case
    module-system-lazy-loader-src-modules-case
    module-system-lazy-loader-entrypoint-conflicts-case
    module-system-lazy-loader-user-root-case
    module-system-lazy-loader-auto-import-removal-case))
