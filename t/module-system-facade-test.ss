;;; -*- Gerbil -*-
;;; Boundary: Marlin-style module facade tests stay separate from activation tests.

(import :std/test
        (only-in :clan/poo/object .o .ref)
        :core/api
        :modules/module-system)

(export module-system-facade-test)

(def module-system-facade-test
  (test-suite "poo module system facade"
    (test-case "builds Marlin-style interface config descriptors"
      (let* ((interface
              (poo-module-interface
               "WorkspaceProfile"
               (.o workspace-root: (poo-string-default "workspace")
                   surface: (poo-string-constant "poo-flow"))
               '((owner . "poo-flow") (surface . "module-system"))))
             (source (poo-local-source "modules/workspace.ss"))
             (module
              (pooModules
               interface
               (.o id: 'workspace
                   imports: '()
                   config:
                   (.o workspace-root: "demo"
                       surface: "poo-flow")
                   extensions: (poo-extensions 'workspace-extension)
                   scripts: (list 'workspace-script)
                   metadata: '((layer . "base"))
                   group: 'tools
                   flags: '(+fast +gerbil)
                   features: '(poo c3)
                   depth: (cons -10 10)
                   phase-files:
                   '((init . "init.ss")
                     (config . "config.ss")
                     (packages . "packages.ss"))
                   hooks:
                   '((before-init . (prepare-workspace))
                     (after-config . (publish-workspace)))
                   source-ref: source)))
             (schemas (poo-module-option-schemas module))
             (configs (poo-module-option-configs module))
             (receipts (poo-module-option-validation-receipts module)))
        (check-equal? (poo-module-descriptor? module) #t)
        (check-equal? (poo-module-name module) 'workspace)
        (check-equal? (poo-module-interface? (poo-module-interface-object module)) #t)
        (check-equal? (cdr (assoc 'workspace-root (poo-module-options module)))
                      "demo")
        (check-equal? (poo-module-extensions module) '(workspace-extension))
        (check-equal? (poo-module-scripts module) '(workspace-script))
        (check-equal? (poo-module-metadata module) '((layer . "base")))
        (check-equal? (poo-module-group module) 'tools)
        (check-equal? (poo-module-flags module) '(+fast +gerbil))
        (check-equal? (poo-module-features module) '(poo c3))
        (check-equal? (poo-module-depth-value module 'init) -10)
        (check-equal? (poo-module-depth-value module 'config) 10)
        (check-equal? (poo-module-phase-file module 'config) "config.ss")
        (check-equal? (poo-module-hook-values module 'before-init)
                      '(prepare-workspace))
        (check-equal? (poo-module-flag-enabled? module '+fast) #t)
        (check-equal? (poo-module-active? module '+fast '-slow) #t)
        (check-equal? (poo-module-active? module '+missing) #f)
        (check-equal? (poo-module-source-ref=?
                       (poo-module-descriptor-source-ref module)
                       source)
                      #t)
        (check-equal? (length schemas) 2)
        (check-equal? (length configs) 2)
        (check-equal? (map poo-module-option-validation-receipt-code receipts)
                      '(ok ok))))
    (test-case "inline imports join activation closure and workflow receipts"
      (let* ((child-task
              (make-task-family-descriptor 'inline-job
                                           'inline-job
                                           'adapter
                                           'rust-or-external-runtime
                                           'submit))
             (child
              (make-poo-module-descriptor
               'child
               '()
               (make-task-family-registry 'child-tasks (list child-task))
               (make-flow-declaration-registry 'child-flows '())
               '((layer . "child"))))
             (interface
              (poo-module-interface
               "RootProfile"
               (.o surface: (poo-string-default "root"))
               '((owner . "poo-flow"))))
             (root
              (pooModules
               interface
               (.o id: 'root
                   imports:
                   (poo-imports
                    (poo-import ":modules/root#child" child))
                   config: (.o surface: "root")
                   flags: '(+root)
                   depth: (cons 10 10)
                   hooks: '((before-init . (root-hook)))
                   extensions: (poo-extensions 'root-extension)
                   scripts: (list 'root-script))))
             (activation (activate-poo-modules (list root)))
             (catalog (pooModuleCatalog root))
             (eval-result (pooEvalModules catalog 'root '("runtime-hook")))
             (evaluation (poo-module-evaluate root))
             (presentation (pooModuleSystemPresentation
                            catalog
                            'root
                            '("runtime-hook"))))
        (check-equal? (poo-module-names (poo-module-activation-modules activation))
                      '(root child))
        (check-equal? (task-family-name
                       (task-family-for-kind-in
                        (poo-module-activation-task-registry activation)
                        'inline-job))
                      'inline-job)
        (check-equal? (.ref eval-result 'module-count) 2)
        (check-equal? (.ref eval-result 'hook-count) 1)
        (check-equal? (.ref evaluation 'init-module-ids) '(child root))
        (check-equal? (pooModuleActive? catalog 'root '+root) #t)
        (check-equal? (pooModuleActive? catalog 'root '+missing) #f)
        (check-equal? (.ref eval-result 'extension-count) 1)
        (check-equal? (.ref presentation 'kind)
                      poo-module-system-presentation-kind)
        (check-equal? (.ref presentation 'import-graph-owner)
                      "poo-module-system")))))

(run-tests! module-system-facade-test)
