;;; -*- Gerbil -*-
;;; Boundary: module-system tests cover descriptor activation, not loading.

(import :std/test
        (only-in :clan/poo/object .o .ref)
        :poo-flow/src/core/api
        :poo-flow/src/modules/module-system)

(export module-system-test)

;; : (-> Thunk Value)
(def (capture-module-failure thunk)
  (with-catch (lambda (failure) failure)
              thunk))

(def module-system-test
  (test-suite "poo-flow module system"
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
              (make-poo-flow-module-descriptor
               'remote-runtime
               '()
               (make-task-family-registry 'remote-runtime-tasks
                                          (list task-descriptor))
               (make-flow-declaration-registry 'remote-runtime-flows
                                               (list flow-descriptor))
               (list (cons 'source 'test-module))))
             (activation (activate-poo-flow-modules (list module)))
             (config (poo-flow-module-activation->run-config
                      'with-remote-runtime
                      (make-local-eager-strategy)
                      (make-request-only-adapter)
                      activation)))
        (check-equal? (poo-flow-module-descriptor? module) #t)
        (check-equal? (poo-flow-module-name module) 'remote-runtime)
        (check-equal? (cdr (assoc 'poo-flow-modules
                                  (poo-flow-module-activation-options activation)))
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
      (let* ((module (make-empty-poo-flow-module-descriptor
                      'feature
                      '(foundation)
                      '()))
             (failure (capture-module-failure
                       (lambda ()
                         (activate-poo-flow-modules (list module)))))
             (missing (cdr (assoc 'missing
                                  (execution-failure-detail failure)))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-owner failure) 'module-system)
        (check-equal? (execution-failure-code failure) 'missing-module-imports)
        (check-equal? (cdr (assoc 'module (car missing))) 'feature)
        (check-equal? (cdr (assoc 'import (car missing))) 'foundation)))
    (test-case "normalizes source refs as inspectable metadata"
      (let* ((local (make-poo-flow-module-local-source "modules/remote-runtime.ss"))
             (package (make-poo-flow-module-package-source 'remote-runtime))
             (standard-library
              (make-poo-flow-module-standard-library-source 'kernel-profile))
             (registry (make-poo-flow-module-registry-source 'kernel-profile))
             (generated (make-poo-flow-module-generated-source 'generated-runtime))
             (custom-entrypoint
              (poo-flow-module-custom-config-entrypoint "./custom/my-module"))
             (custom
              (make-poo-flow-module-custom-config-source "./custom/my-module"))
             (custom-metadata
              (poo-flow-module-source-ref-metadata custom))
             (local-shape (poo-flow-module-source-ref->alist local)))
        (check-equal? (poo-flow-module-source-ref? local) #t)
        (check-equal? (poo-flow-module-source-ref-kind package) 'package)
        (check-equal? (poo-flow-module-source-ref-kind standard-library)
                      'standard-library)
        (check-equal? (cdr (assoc 'library
                                  (poo-flow-module-source-ref-metadata
                                   standard-library)))
                      'standard)
        (check-equal? (poo-flow-module-source-ref-value registry) 'kernel-profile)
        (check-equal? (poo-flow-module-source-ref=? generated
                                               (make-poo-flow-module-generated-source
                                                'generated-runtime))
                      #t)
        (check-equal? (cdr (assoc 'kind local-shape)) 'local)
        (check-equal? (cdr (assoc 'value local-shape))
                      "modules/remote-runtime.ss")
        (check-equal? custom-entrypoint
                      "./custom/my-module/config.ss")
        (check-equal? (poo-flow-module-source-ref-kind custom) 'local)
        (check-equal? (poo-flow-module-source-ref-value custom)
                      "./custom/my-module/config.ss")
        (check-equal? (cdr (assoc 'entrypoint custom-metadata))
                      "./custom/my-module/config.ss")))
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
              (poo-flow-module macro-runtime
                (imports foundation)
                (tasks task-descriptor)
                (flows flow-descriptor)
                (options (cons 'source 'macro-test)))))
        (check-equal? (poo-flow-module-name module) 'macro-runtime)
        (check-equal? (poo-flow-module-imports module) '(foundation))
        (check-equal? (task-family-name (car (poo-flow-module-task-descriptors module)))
                      'macro-job)
        (check-equal? (flow-declaration-kind
                       (car (poo-flow-module-flow-descriptors module)))
                      'macro)
        (check-equal? (cdr (assoc 'source (poo-flow-module-options module)))
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
              (make-poo-flow-module-descriptor
               'foundation
               '()
               (make-task-family-registry 'foundation-tasks
                                          (list task-a task-b))
               (make-flow-declaration-registry 'foundation-flows
                                               (list flow-a flow-b))
               (list (cons 'source 'first)
                     (cons 'source 'second))))
             (empty (make-empty-poo-flow-module-descriptor
                     'empty
                     '(foundation)
                     '()))
             (report (poo-flow-module-doctor (list foundation empty)))
             (shape (poo-flow-module-doctor-report->alist report)))
        (check-equal? (poo-flow-module-doctor-ok? report) #f)
        (check-equal? (poo-flow-module-doctor-report-status report) 'warning)
        (check-equal? (length (poo-flow-module-doctor-report-diagnostics report)) 4)
        (check-equal? (cdr (assoc 'modules shape)) '(foundation empty))
        (check-equal? (poo-flow-module-diagnostic-code
                       (car (poo-flow-module-doctor-report-diagnostics report)))
                      'duplicate-task-family)))
    (test-case "resolves catalog source refs before doctor and activation"
      (let* ((source (make-poo-flow-module-generated-source 'remote-runtime))
             (task-descriptor
              (make-task-family-descriptor 'catalog-job
                                           'catalog-job
                                           'adapter
                                           'rust-or-external-runtime
                                           'submit))
             (module
              (make-poo-flow-module-descriptor
               'remote-runtime
               '()
               (make-task-family-registry 'catalog-tasks
                                          (list task-descriptor))
               (make-flow-declaration-registry 'catalog-flows '())
               (list (cons 'source source))))
             (entry (make-poo-flow-module-catalog-entry source module))
             (catalog (make-poo-flow-module-catalog 'test-catalog (list entry)))
             (doctor (poo-flow-module-resolve-doctor catalog (list source)))
             (activation (poo-flow-module-resolve-and-activate catalog (list source)))
             (catalog-shape (poo-flow-module-catalog->alist catalog)))
        (check-equal? (poo-flow-module-catalog? catalog) #t)
        (check-equal? (cdr (assoc 'module (poo-flow-module-catalog-entry->alist entry)))
                      'remote-runtime)
        (check-equal? (poo-flow-module-doctor-report-status doctor) 'ok)
        (check-equal? (task-family-name
                       (task-family-for-kind-in
                        (poo-flow-module-activation-task-registry activation)
                        'catalog-job))
                      'catalog-job)
        (check-equal? (cdr (assoc 'name catalog-shape)) 'test-catalog)))
    (test-case "raises typed failure for missing catalog sources"
      (let* ((catalog (make-poo-flow-module-catalog 'empty-catalog '()))
             (source (make-poo-flow-module-local-source "missing.ss"))
             (failure (capture-module-failure
                       (lambda ()
                         (resolve-poo-flow-module-source catalog source))))
             (detail (execution-failure-detail failure))
             (source-shape (cdr (assoc 'source detail))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-owner failure) 'module-system)
        (check-equal? (execution-failure-code failure) 'missing-module-source)
        (check-equal? (cdr (assoc 'catalog detail)) 'empty-catalog)
        (check-equal? (cdr (assoc 'value source-shape)) "missing.ss")))))

(run-tests! module-system-test)
