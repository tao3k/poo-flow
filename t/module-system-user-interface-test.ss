;;; -*- Gerbil -*-
;;; Boundary: user-interface tests import only the public module-system facade.
;;; Invariant: leaf owner names must not become part of the user contract.
;;; Intent: this file protects the surface that module authors actually call.

(import :std/test
        (only-in :clan/poo/object .o .ref)
        :modules/module-system)

(export module-system-user-interface-test)

;; PooModuleInterface <- Unit
(def user-child-interface
  (poo-module-interface
   "UserChildProfile"
   (poo-module-option-block
    surface: (poo-string-constant "poo-flow")
    child-mode: (poo-string-default "helper")
    layers: (poo-option-append 'List '("base"))
    priority: (poo-option-override 'String "base")
    mode-lock: (poo-option-conflict 'String))
   '((audience . user))))

;; PooModuleDescriptor <- Unit
(def user-child-module
  (pooModules
   user-child-interface
   (.o id: 'user-child
       group: 'tools
       flags: '(+helper)
       features: '(child-profile)
       depth: (cons -20 20)
       phase-files: '((init . "child/init.ss")
                      (config . "child/config.ss"))
       config: (poo-module-option-block
                surface: "poo-flow"
                child-mode: "helper"
                layers: '("child")
                priority: "child"
                mode-lock: "stable")
       hooks: (poo-module-hook-block
               (after-config child-ready)))))

;; PooModuleInterface <- Unit
(def user-root-interface
  (poo-module-interface
   "UserRootProfile"
   (poo-module-option-block
    surface: (poo-string-constant "poo-flow")
    mode: (poo-string-default "interactive")
    layers: (poo-option-append 'List '("base"))
    priority: (poo-option-override 'String "base")
    mode-lock: (poo-option-conflict 'String))
   '((audience . user)
     (surface . module-system))))

;; PooModuleDescriptor <- Unit
(defpoo-module user-root-module
  user-root-interface
  (id 'user-root)
  (imports (poo-import ":user/root#child" user-child-module))
  (config (poo-module-option-block
           surface: "poo-flow"
           mode: "interactive"
           layers: '("root")
           priority: "root"
           mode-lock: "stable"))
  (extensions 'root-extension)
  (scripts 'root-script)
  (metadata '((audience . user)
              (owner . public-interface))))

;; PooModuleDescriptor <- Unit
(def invalid-user-module
  (pooModules
   user-root-interface
   (.o id: 'invalid-user
       config: (poo-module-option-block
                surface: "wrong-surface"
                unknown-option: "left-unclaimed"))))

;; PooModuleDescriptor <- Unit
(def merge-conflict-module
  (pooModules
   user-root-interface
   (.o id: 'merge-conflict
       imports: (list (poo-import ":merge/conflict#child"
                                  user-child-module))
       config: (poo-module-option-block
                surface: "poo-flow"
                mode-lock: "divergent"))))

;; PooModuleSourceRef <- Unit
(def loader-child-source
  (poo-local-source "loaded/child.ss"))

;; PooModuleSourceRef <- Unit
(def loader-root-source
  (poo-local-source "loaded/root.ss"))

;; PooModuleDescriptor <- Unit
(def loader-child-module
  (make-empty-poo-module-descriptor
   'loaded-child
   '()
   '((loaded-child . #t))))

;; PooModuleDescriptor <- Unit
(def loader-root-module
  (make-empty-poo-module-descriptor
   'loaded-root
   '(loaded-child)
   '((loaded-root . #t))))

;; PooModuleLoaderBackend <- Unit
(def user-static-loader
  (poo-module-static-loader
   'user-static-loader
   'local
   (list (make-poo-module-loader-entry loader-root-source
                                       loader-root-module)
         (make-poo-module-loader-entry loader-child-source
                                       loader-child-module))))

;; PooModuleValueCatalog <- Unit
(def user-catalog
  (pooModuleCatalog user-root-module invalid-user-module))

;; PooModuleValueCatalog <- Unit
(defpoo-module-set user-macro-catalog
  (modules user-root-module)
  (poo-module-when #t user-child-module)
  (poo-module-when #f invalid-user-module))

;; Boolean <- UserInterfaceEntry [UserInterfaceEntry]
(def (has-member? value values)
  (not (not (member value values))))

;; MaybeValue <- UserInterfaceEntry Alist
(def (alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (alist-value key (cdr entries)))))

;; TestSuite <- Unit
(def module-system-user-interface-test
  (test-suite "poo module system user interface"
    (test-case "declares modules through the public facade only"
      (check-equal? (poo-module-descriptor? user-root-module) #t)
      (check-equal? (poo-module-name user-root-module) 'user-root)
      (check-equal? (poo-module-interface-id
                     (poo-module-interface-object user-root-module))
                    "UserRootProfile")
      (let* ((imports (poo-module-imports user-root-module))
             (first-import (car imports))
             (source-ref (.ref first-import 'source-ref)))
        (check-equal? (length imports) 1)
        (check-equal? (poo-import? first-import) #t)
        (check-equal? (poo-module-source-ref-kind source-ref) 'local)
        (check-equal? (poo-module-source-ref-value source-ref)
                      ":user/root#child")
        (check-equal? (.ref first-import 'profile) user-child-module))
      (check-equal? (poo-module-extensions user-root-module)
                    '(root-extension))
      (check-equal? (poo-module-scripts user-root-module)
                    '(root-script))
      (check-equal? (poo-module-metadata user-root-module)
                    '((audience . user)
                      (owner . public-interface))))
    (test-case "exposes Doom-style user predicates as explicit data checks"
      (check-equal? (poo-module-group user-child-module) 'tools)
      (check-equal? (poo-module-flags user-child-module) '(+helper))
      (check-equal? (poo-module-features user-child-module)
                    '(child-profile))
      (check-equal? (poo-module-depth-value user-child-module 'init) -20)
      (check-equal? (poo-module-depth-value user-child-module 'config) 20)
      (check-equal? (poo-module-phase-file user-child-module 'config)
                    "child/config.ss")
      (check-equal? (poo-module-hook-values user-child-module 'after-config)
                    '(child-ready))
      (check-equal? (poo-module-active? user-child-module '+helper '-missing)
                    #t)
      (check-equal? (poo-module-active? user-child-module '+missing)
                    #f)
      (check-equal? (pooModuleActive? user-catalog 'user-root)
                    #t)
      (check-equal? (pooModuleActive? user-catalog 'user-child)
                    #f)
      (check-equal? (pooModuleActive? user-catalog 'invalid-user '+helper)
                    #f))
    (test-case "projects catalog eval and presentation for users"
      (let* ((workflow (poo-module-workflow user-root-module '("after-config")))
             (evaluation (poo-module-evaluate user-root-module))
             (eval-result (pooEvalModules user-catalog 'user-root '("after-config")))
             (presentation
              (pooModuleSystemPresentation
               user-catalog
               'user-root
               '("after-config"))))
        (check-equal? (.ref workflow 'kind) poo-module-workflow-kind)
        (check-equal? (.ref evaluation 'module-ids) '(user-root user-child))
        (check-equal? (.ref evaluation 'init-module-ids)
                      '(user-child user-root))
        (check-equal? (.ref eval-result 'root-module-id) 'user-root)
        (check-equal? (.ref eval-result 'module-count) 2)
        (check-equal? (.ref eval-result 'hook-count) 1)
        (check-equal? (.ref presentation 'catalog-module-count) 2)
        (check-equal? (.ref presentation 'root-module-id) 'user-root)
        (check-equal? (has-member? "pooModuleActive?"
                                   (.ref presentation 'user-entrypoints))
                      #t)))
    (test-case "returns validation receipts for user config mistakes"
      (let* ((receipts
              (poo-module-option-validation-receipts invalid-user-module))
             (codes
              (map poo-module-option-validation-receipt-code receipts)))
        (check-equal? (length receipts) 2)
        (check-equal? (has-member? 'constant-mismatch codes) #t)
        (check-equal? (has-member? 'missing-schema codes) #t)))
    (test-case "merges Nix-style option receipts before runtime"
      (let* ((receipts
              (poo-module-option-merge-receipts user-root-module))
             (layers
              (poo-module-find-merge-receipt receipts "layers"))
             (priority
              (poo-module-find-merge-receipt receipts "priority"))
             (mode-lock
              (poo-module-find-merge-receipt receipts "mode-lock"))
             (alist
              (poo-module-merged-option-alist user-root-module)))
        (check-equal? (poo-module-option-merge-receipt-rule layers)
                      'append)
        (check-equal? (poo-module-option-merge-receipt-value layers)
                      '("base" "child" "root"))
        (check-equal? (poo-module-option-merge-receipt-source-modules
                       layers)
                      '(user-child user-root))
        (check-equal? (poo-module-option-merge-receipt-code priority)
                      'overridden)
        (check-equal? (poo-module-option-merge-receipt-value priority)
                      "root")
        (check-equal? (poo-module-option-merge-receipt-valid? mode-lock)
                      #t)
        (check-equal? (poo-module-option-merge-receipt-value mode-lock)
                      "stable")
        (check-equal? (alist-value "layers" alist)
                      '("base" "child" "root"))
        (check-equal? (alist-value "priority" alist)
                      "root")))
    (test-case "reports conflicting option merges as receipts"
      (let* ((receipts
              (poo-module-option-merge-receipts merge-conflict-module))
             (mode-lock
              (poo-module-find-merge-receipt receipts "mode-lock")))
        (check-equal? (poo-module-option-merge-receipt-rule mode-lock)
                      'conflict)
        (check-equal? (poo-module-option-merge-receipt-valid? mode-lock)
                      #f)
        (check-equal? (poo-module-option-merge-receipt-code mode-lock)
                      'conflict)
        (check-equal? (poo-module-option-merge-receipt-messages mode-lock)
                      '("option values conflict"))))
    (test-case "loads source refs into catalogs before resolver activation"
      (let* ((sources (list loader-root-source loader-child-source))
             (backends (list user-static-loader))
             (receipts
              (poo-module-load-source-receipts backends sources))
             (catalog
              (poo-module-load-catalog 'loaded-user-catalog
                                       backends
                                       sources))
             (doctor
              (poo-module-resolve-doctor catalog sources))
             (activation
              (poo-module-resolve-and-activate catalog sources)))
        (check-equal? (map poo-module-load-receipt-code receipts)
                      '(loaded loaded))
        (check-equal? (map poo-module-load-receipt-backend-name receipts)
                      '(user-static-loader user-static-loader))
        (check-equal? (poo-module-catalog-name catalog)
                      'loaded-user-catalog)
        (check-equal? (map poo-module-name
                           (poo-module-catalog-modules catalog))
                      '(loaded-root loaded-child))
        (check-equal? (poo-module-doctor-report-status doctor)
                      'warning)
        (check-equal? (poo-module-names
                       (poo-module-activation-modules activation))
                      '(loaded-root loaded-child))))
    (test-case "presents doctor evidence without runtime execution"
      (let* ((doctor-presentation
              (pooModuleDoctorPresentation user-catalog 'user-root))
             (conflict-presentation
              (pooModuleDoctorPresentation
               (pooModuleCatalog merge-conflict-module)
               'merge-conflict))
             (source-presentation
              (pooModuleSourceDoctorPresentation
               (list user-static-loader)
               (list loader-root-source loader-child-source)))
             (source-doctor
              (.ref source-presentation 'module-doctor)))
        (check-equal? (.ref doctor-presentation 'kind)
                      poo-module-doctor-presentation-kind)
        (check-equal? (.ref doctor-presentation 'root-module-id)
                      'user-root)
        (check-equal? (.ref doctor-presentation 'runtime-executed)
                      #f)
        (check-equal? (.ref doctor-presentation 'merge-status)
                      'ok)
        (check-equal? (.ref conflict-presentation 'merge-status)
                      'error)
        (check-equal? (.ref source-presentation 'kind)
                      poo-module-source-doctor-presentation-kind)
        (check-equal? (.ref source-presentation 'loaded-count) 2)
        (check-equal? (.ref source-doctor 'root-module-id)
                      'loaded-root)))
    (test-case "builds module sets with pure macro sugar"
      (let* ((modules (.ref user-macro-catalog 'modules))
             (eval-result (pooEvalModules user-macro-catalog 'user-root)))
        (check-equal? (length modules) 2)
        (check-equal? (map poo-module-name modules)
                      '(user-root user-child))
        (check-equal? (pooModuleActive? user-macro-catalog
                                        'user-child
                                        '+helper)
                      #t)
        (check-equal? (pooModuleActive? user-macro-catalog 'invalid-user)
                      #f)
        (check-equal? (.ref eval-result 'module-count) 2))))
  )

(run-tests! module-system-user-interface-test)
