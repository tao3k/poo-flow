;;; -*- Gerbil -*-
;;; Boundary: module-system tests cover descriptor activation, not loading.

(import :std/test
        (only-in :clan/poo/object .o .ref)
        :core/api
        :modules/module-system)

(export module-system-test)

;; Value <- Thunk
(def (capture-module-failure thunk)
  (with-catch (lambda (failure) failure)
              thunk))

(def module-system-test
  (test-suite "poo module system"
    (test-case "activates module descriptor registries into run config"
      (let* ((task-descriptor
              (make-task-family-descriptor 'remote-job
                                           'remote-job
                                           'adapter
                                           'rust-or-external-runtime
                                           'submit))
             (flow-descriptor
              (make-flow-declaration-descriptor 'remote-flow
                                                'remote
                                                'linear-dag
                                                'extension))
             (module
              (make-poo-module-descriptor
               'remote-runtime
               '()
               (make-task-family-registry 'remote-runtime-tasks
                                          (list task-descriptor))
               (make-flow-declaration-registry 'remote-runtime-flows
                                               (list flow-descriptor))
               (list (cons 'source 'test-module))))
             (activation (activate-poo-modules (list module)))
             (config (poo-module-activation->run-config
                      'with-remote-runtime
                      (make-local-eager-strategy)
                      (make-request-only-adapter)
                      activation)))
        (check-equal? (poo-module-descriptor? module) #t)
        (check-equal? (poo-module-name module) 'remote-runtime)
        (check-equal? (cdr (assoc 'poo-modules
                                  (poo-module-activation-options activation)))
                      '(remote-runtime))
        (check-equal? (task-family-name
                       (task-family-for-kind-in
                        (run-config-task-registry config)
                        'remote-job))
                      'remote-job)
        (check-equal? (flow-declaration-name
                       (flow-declaration-for-kind-in
                        (run-config-flow-registry config)
                        'remote))
                      'remote-flow)))
    (test-case "rejects missing module imports before activation"
      (let* ((module (make-empty-poo-module-descriptor
                      'feature
                      '(foundation)
                      '()))
             (failure (capture-module-failure
                       (lambda ()
                         (activate-poo-modules (list module)))))
             (missing (cdr (assoc 'missing
                                  (execution-failure-detail failure)))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-owner failure) 'module-system)
        (check-equal? (execution-failure-code failure) 'missing-module-imports)
        (check-equal? (cdr (assoc 'module (car missing))) 'feature)
        (check-equal? (cdr (assoc 'import (car missing))) 'foundation)))
    (test-case "normalizes source refs as inspectable metadata"
      (let* ((local (make-poo-module-local-source "modules/remote-runtime.ss"))
             (package (make-poo-module-package-source 'remote-runtime))
             (registry (make-poo-module-registry-source 'default-modules))
             (generated (make-poo-module-generated-source 'generated-runtime))
             (local-shape (poo-module-source-ref->alist local)))
        (check-equal? (poo-module-source-ref? local) #t)
        (check-equal? (poo-module-source-ref-kind package) 'package)
        (check-equal? (poo-module-source-ref-value registry) 'default-modules)
        (check-equal? (poo-module-source-ref=? generated
                                               (make-poo-module-generated-source
                                                'generated-runtime))
                      #t)
        (check-equal? (cdr (assoc 'kind local-shape)) 'local)
        (check-equal? (cdr (assoc 'value local-shape))
                      "modules/remote-runtime.ss")))
    (test-case "macro syntax expands to the same descriptor contract"
      (let* ((task-descriptor
              (make-task-family-descriptor 'macro-job
                                           'macro-job
                                           'adapter
                                           'rust-or-external-runtime
                                           'submit))
             (flow-descriptor
              (make-flow-declaration-descriptor 'macro-flow
                                                'macro
                                                'linear-dag
                                                'extension))
             (module
              (poo-module macro-runtime
                (imports foundation)
                (tasks task-descriptor)
                (flows flow-descriptor)
                (options (cons 'source 'macro-test)))))
        (check-equal? (poo-module-name module) 'macro-runtime)
        (check-equal? (poo-module-imports module) '(foundation))
        (check-equal? (task-family-name (car (poo-module-task-descriptors module)))
                      'macro-job)
        (check-equal? (flow-declaration-kind
                       (car (poo-module-flow-descriptors module)))
                      'macro)
        (check-equal? (cdr (assoc 'source (poo-module-options module)))
                      'macro-test)))
    (test-case "doctor reports duplicate and empty module diagnostics"
      (let* ((task-a (make-task-family-descriptor 'dup-job
                                                  'dup-job
                                                  'adapter
                                                  'rust-or-external-runtime
                                                  'submit))
             (task-b (make-task-family-descriptor 'dup-job
                                                  'dup-job
                                                  'adapter
                                                  'rust-or-external-runtime
                                                  'submit))
             (flow-a (make-flow-declaration-descriptor 'dup-flow-a
                                                       'dup-flow
                                                       'linear-dag
                                                       'extension))
             (flow-b (make-flow-declaration-descriptor 'dup-flow-b
                                                       'dup-flow
                                                       'linear-dag
                                                       'extension))
             (foundation
              (make-poo-module-descriptor
               'foundation
               '()
               (make-task-family-registry 'foundation-tasks
                                          (list task-a task-b))
               (make-flow-declaration-registry 'foundation-flows
                                               (list flow-a flow-b))
               (list (cons 'source 'first)
                     (cons 'source 'second))))
             (empty (make-empty-poo-module-descriptor
                     'empty
                     '(foundation)
                     '()))
             (report (poo-module-doctor (list foundation empty)))
             (shape (poo-module-doctor-report->alist report)))
        (check-equal? (poo-module-doctor-ok? report) #f)
        (check-equal? (poo-module-doctor-report-status report) 'warning)
        (check-equal? (length (poo-module-doctor-report-diagnostics report)) 4)
        (check-equal? (cdr (assoc 'modules shape)) '(foundation empty))
        (check-equal? (poo-module-diagnostic-code
                       (car (poo-module-doctor-report-diagnostics report)))
                      'duplicate-task-family)))
    (test-case "resolves catalog source refs before doctor and activation"
      (let* ((source (make-poo-module-generated-source 'remote-runtime))
             (task-descriptor
              (make-task-family-descriptor 'catalog-job
                                           'catalog-job
                                           'adapter
                                           'rust-or-external-runtime
                                           'submit))
             (module
              (make-poo-module-descriptor
               'remote-runtime
               '()
               (make-task-family-registry 'catalog-tasks
                                          (list task-descriptor))
               (make-flow-declaration-registry 'catalog-flows '())
               (list (cons 'source source))))
             (entry (make-poo-module-catalog-entry source module))
             (catalog (make-poo-module-catalog 'test-catalog (list entry)))
             (doctor (poo-module-resolve-doctor catalog (list source)))
             (activation (poo-module-resolve-and-activate catalog (list source)))
             (catalog-shape (poo-module-catalog->alist catalog)))
        (check-equal? (poo-module-catalog? catalog) #t)
        (check-equal? (cdr (assoc 'module (poo-module-catalog-entry->alist entry)))
                      'remote-runtime)
        (check-equal? (poo-module-doctor-report-status doctor) 'ok)
        (check-equal? (task-family-name
                       (task-family-for-kind-in
                        (poo-module-activation-task-registry activation)
                        'catalog-job))
                      'catalog-job)
        (check-equal? (cdr (assoc 'name catalog-shape)) 'test-catalog)))
    (test-case "raises typed failure for missing catalog sources"
      (let* ((catalog (make-poo-module-catalog 'empty-catalog '()))
             (source (make-poo-module-local-source "missing.ss"))
             (failure (capture-module-failure
                       (lambda ()
                         (resolve-poo-module-source catalog source))))
             (detail (execution-failure-detail failure))
             (source-shape (cdr (assoc 'source detail))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-owner failure) 'module-system)
        (check-equal? (execution-failure-code failure) 'missing-module-source)
        (check-equal? (cdr (assoc 'catalog detail)) 'empty-catalog)
        (check-equal? (cdr (assoc 'value source-shape)) "missing.ss")))))

(run-tests! module-system-test)
