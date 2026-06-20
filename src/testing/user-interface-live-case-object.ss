;;; -*- Gerbil -*-
;;; Boundary: inert user-interface live case objects and declaration syntax.
;;; Invariant: no sandbox execution, module resolution, or process work here.

(import (only-in :clan/poo/object .o .ref object?))

(export pooFlowUserInterfaceLiveCase
        use-live-case
        poo-flow-user-interface-live-case?
        poo-flow-user-interface-live-case-name
        poo-flow-user-interface-live-case-module-bundle
        poo-flow-user-interface-live-case-profile-name
        poo-flow-user-interface-live-case-config
        poo-flow-user-interface-live-case-alist-ref
        poo-flow-user-interface-live-case-config-ref
        poo-flow-user-interface-live-case-section-ref)

;; pooFlowUserInterfaceLiveCase
;;   : (-> Symbol [PooUserModuleSelection] Symbol LiveCaseConfig POOObject)
;;   | contract: wraps a downstream live case declaration in an inert POO object
;;   | result: no runtime work; src/testing/user-interface-live-case.ss starts it later
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (pooFlowUserInterfaceLiveCase
;;        'current-system-build
;;        poo-flow-custom-my-module-cicd-module
;;        'ci/build
;;        '((isolation (mode . project-copy))))
;;       ;; => user-interface live case object
;;       ```
;;     %
;; : (-> Symbol [PooUserModuleSelection] Symbol LiveCaseConfig POOObject)
(def (pooFlowUserInterfaceLiveCase name-value
                                   module-bundle-value
                                   profile-name-value
                                   config-value)
  (.o kind: "poo-flow.testing.user-interface-live-case.v1"
      name: name-value
      module-bundle: module-bundle-value
      profile-name: profile-name-value
      config: config-value
      case-owner: "user-interface"
      framework-owner: "src/testing/user-interface-live-case.ss"
      runtime-executed: #f))

;;; User case files should stay as pure declarations. `use-live-case` is the
;;; case analogue of `use-module`: it records a live test case object without
;;; executing the sandbox or importing the upstream runner.
;; use-live-case
;;   : (-> Symbol :module PooUserModuleSelection :profile Symbol LiveCaseSection... POOObject)
;;   | contract: expands a downstream user-interface live case declaration into an inert case object
;;   | result: POOObject consumed by src/testing only when a test suite runs
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (use-live-case current-system-build
;;         :module poo-flow-custom-my-module-cicd-module
;;         :profile ci/build
;;         :isolation ((mode . project-copy))
;;         :environment ((policy . whitelist))
;;         :command ((program . "gxpkg") (args . ("build"))))
;;       ;; => live case object
;;       ```
;;     %
;; : (-> Syntax Syntax)
(defrules use-live-case (:module :profile :isolation :environment :command :nono)
  ((_ case-name
      :module module-bundle
      :profile profile-name
      :isolation (isolation-clause ...)
      :environment (environment-clause ...)
      :command (command-clause ...)
      :nono (nono-clause ...))
   (pooFlowUserInterfaceLiveCase
    'case-name
    module-bundle
    'profile-name
    '((isolation isolation-clause ...)
      (environment environment-clause ...)
      (command command-clause ...)
      (nono nono-clause ...)))))

;; : (-> MaybePOOObject Boolean)
(def (poo-flow-user-interface-live-case? value)
  (and (object? value)
       (equal? (.ref value 'kind)
               "poo-flow.testing.user-interface-live-case.v1")))

;; : (-> POOObject Symbol)
(def (poo-flow-user-interface-live-case-name live-case)
  (.ref live-case 'name))

;; : (-> POOObject [PooUserModuleSelection])
(def (poo-flow-user-interface-live-case-module-bundle live-case)
  (.ref live-case 'module-bundle))

;; : (-> POOObject Symbol)
(def (poo-flow-user-interface-live-case-profile-name live-case)
  (.ref live-case 'profile-name))

;; : (-> POOObject LiveCaseConfig)
(def (poo-flow-user-interface-live-case-config live-case)
  (.ref live-case 'config))

;; : (-> LiveCaseConfigEntries LiveCaseConfigKey FallbackValue LiveCaseConfigValue)
(def (poo-flow-user-interface-live-case-alist-ref entries key default)
  (cond
   ((not (list? entries)) default)
   ((null? entries) default)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-interface-live-case-alist-ref (cdr entries) key default))))

;; : (-> POOObject LiveCaseConfigKey FallbackValue LiveCaseConfigValue)
(def (poo-flow-user-interface-live-case-config-ref live-case key default)
  (poo-flow-user-interface-live-case-alist-ref
   (poo-flow-user-interface-live-case-config live-case)
   key
   default))

;; : (-> POOObject LiveCaseSection LiveCaseConfigKey FallbackValue LiveCaseConfigValue)
(def (poo-flow-user-interface-live-case-section-ref live-case
                                                    section
                                                    key
                                                    default)
  (poo-flow-user-interface-live-case-alist-ref
   (poo-flow-user-interface-live-case-config-ref live-case section '())
   key
   default))
