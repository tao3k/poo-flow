;;; -*- Gerbil -*-
;;; Boundary: lazy loader tests cover deferred source loading only.
;;; Invariant: lazy plans never call loader handlers until explicitly forced.

(import :std/test
        :modules/module-system)

(export module-system-lazy-loader-test)

;; : (-> Unit PooModuleSourceRef)
(def loader-standard-library-source
  (poo-flow-standard-library-source 'standard/kernel))

;; : (-> Unit Integer)
(def lazy-loader-call-count 0)

;; : (-> Unit PooModuleDescriptor)
(def loader-standard-library-module
  (make-empty-poo-flow-module-descriptor
   'standard-kernel
   '()
   '((standard-library . #t))))

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

;; : (-> Unit TestSuite)
(def module-system-lazy-loader-test
  (test-suite "poo-flow module system lazy loader"
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
                        'standard-kernel))))

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
        (check-equal? lazy-loader-call-count 0)))

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
        (check-equal? lazy-loader-call-count 0)))

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
        (check-equal? lazy-loader-call-count 0)))))

(run-tests! module-system-lazy-loader-test)
