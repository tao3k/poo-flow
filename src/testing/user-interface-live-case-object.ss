;;; -*- Gerbil -*-
;;; Boundary: inert test fixtures for downstream user-interface live cases.
;;; Invariant: no sandbox execution or process work here.
;;; Note: this is not the module-system POO object model. That model is owned by
;;; src/modules/object-core.ss, src/modules/*/objects.ss, and object-validation.ss.

(import (only-in :clan/poo/object
                 .ref
                 object?
                 make-object
                 $constant-slot-spec)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile-by-name)
        (only-in :poo-flow/src/modules/modules-system-base
                 poo-flow-user-module-selection-flag-entry))

(export pooFlowUserInterfaceLiveCase
        pooFlowUserInterfaceLiveCaseFromModuleSelection
        poo-flow-user-interface-live-case?
        poo-flow-user-interface-live-case-name
        poo-flow-user-interface-live-case-module-bundle
        poo-flow-user-interface-live-case-supers
        poo-flow-user-interface-live-case-super-names
        poo-flow-user-interface-live-case-config
        poo-flow-user-interface-live-case-alist-ref
        poo-flow-user-interface-live-case-config-ref
        poo-flow-user-interface-live-case-section-ref)

;;; Slot specs keep live-case objects inert; no accessor or runtime bridge is
;;; installed while user-interface declarations are being loaded.
;; : (-> Symbol Value PooLiveCaseSlotSpec)
(def (poo-flow-user-interface-live-case-slot key value)
  (cons key ($constant-slot-spec value)))

;; : (-> [PooUserModuleSelection] [PooSandboxProfile])
(def (poo-flow-user-interface-live-case-module-profiles module-bundle)
  (let* ((module-selection
          (if (and (pair? module-bundle) (car module-bundle))
            (car module-bundle)
            (error "live case requires a module bundle")))
         (config-entry
          (poo-flow-user-module-selection-flag-entry module-selection
                                                     ':config)))
    (if (and config-entry (pair? config-entry))
      (cdr config-entry)
      (error "live case module bundle has no :config profiles"))))

;; : (-> [PooSandboxProfile] Symbol PooSandboxProfile)
(def (poo-flow-user-interface-live-case-profile-super profiles name)
  (let (profile (poo-flow-sandbox-profile-by-name profiles name))
    (if profile
      profile
      (error "live case inherited profile not found" name))))

;; : (-> [PooSandboxProfile] [Symbol] [PooSandboxProfile])
(def (poo-flow-user-interface-live-case-profile-supers profiles names)
  (if (null? names)
    '()
    (cons (poo-flow-user-interface-live-case-profile-super profiles
                                                          (car names))
          (poo-flow-user-interface-live-case-profile-supers profiles
                                                           (cdr names)))))

;;; Live-case objects bind user selections, profile inheritance, and config
;;; rows into one POO object so tests exercise the same path as user config.
;; pooFlowUserInterfaceLiveCase
;;   : (-> Symbol [PooUserModuleSelection] [Symbol] LiveCaseConfig POOObject)
;;   | contract: constructs inert live-case POO objects for the testing runner
;;   | result: runtime-executed remains #f until src/testing/user-interface-live-case.ss starts it
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (pooFlowUserInterfaceLiveCase
;;        'current-system-build
;;        module-bundle
;;        '(ci/build)
;;        '((isolation (mode . project-copy))))
;;       ;; => live-case object
;;       ```
;;     %
(def (pooFlowUserInterfaceLiveCase name-value
                                   module-bundle-value
                                   super-name-values
                                   config-value)
  (let (super-values
        (poo-flow-user-interface-live-case-profile-supers
         (poo-flow-user-interface-live-case-module-profiles module-bundle-value)
         super-name-values))
    (make-object
     supers: super-values
     slots: (list
             (poo-flow-user-interface-live-case-slot
              'kind
              "poo-flow.testing.user-interface-live-case.v1")
             (poo-flow-user-interface-live-case-slot 'name name-value)
             (poo-flow-user-interface-live-case-slot
              'module-bundle
              module-bundle-value)
             (poo-flow-user-interface-live-case-slot 'supers super-values)
             (poo-flow-user-interface-live-case-slot
              'super-names
              super-name-values)
             (poo-flow-user-interface-live-case-slot 'config config-value)
             (poo-flow-user-interface-live-case-slot
              'case-owner
              "src/testing")
             (poo-flow-user-interface-live-case-slot
              'framework-owner
              "src/testing/user-interface-live-case.ss")
             (poo-flow-user-interface-live-case-slot 'runtime-executed #f)))))

;; : (-> PooUserModuleSelection Symbol Value)
(def (poo-flow-user-interface-live-case-flag-value selection flag)
  (let (entry (poo-flow-user-module-selection-flag-entry selection flag))
    (if (and entry (pair? entry))
      (cdr entry)
      (error "live case module selection missing required flag" flag))))

;; : (-> Value [Symbol])
(def (poo-flow-user-interface-live-case-inherits-list value)
  (cond
   ((symbol? value) (list value))
   ((list? value) value)
   (else
    (error "live case :inherits must be a symbol or list of symbols" value))))

;; : (-> PooUserModuleSelection Symbol Symbol Pair)
(def (poo-flow-user-interface-live-case-config-section selection flag section)
  (cons section
        (poo-flow-user-interface-live-case-flag-value selection flag)))

;;; Module-selection live cases reuse the same inert object constructor after
;;; decoding :inherits and config flags from user-facing selection bundles.
;; : (-> Symbol [PooUserModuleSelection] [PooUserModuleSelection] POOObject)
(def (pooFlowUserInterfaceLiveCaseFromModuleSelection name-value
                                                      module-bundle-value
                                                      case-bundle-value)
  (let* ((case-selection
          (if (and (pair? case-bundle-value) (car case-bundle-value))
            (car case-bundle-value)
            (error "live case requires a module selection bundle")))
         (super-name-values
          (poo-flow-user-interface-live-case-inherits-list
           (poo-flow-user-interface-live-case-flag-value case-selection
                                                         ':inherits)))
         (config-value
          (list
           (poo-flow-user-interface-live-case-config-section
            case-selection ':isolation 'isolation)
           (poo-flow-user-interface-live-case-config-section
            case-selection ':environment 'environment)
           (poo-flow-user-interface-live-case-config-section
            case-selection ':command 'command)
           (poo-flow-user-interface-live-case-config-section
            case-selection ':nono 'nono))))
    (pooFlowUserInterfaceLiveCase name-value
                                  module-bundle-value
                                  super-name-values
                                  config-value)))

;; | PooFlowUserInterfaceLiveCaseCandidate = Object
;; : (-> PooFlowUserInterfaceLiveCaseCandidate Boolean)
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

;; : (-> POOObject [PooSandboxProfile])
(def (poo-flow-user-interface-live-case-supers live-case)
  (.ref live-case 'supers))

;; : (-> POOObject [Symbol])
(def (poo-flow-user-interface-live-case-super-names live-case)
  (.ref live-case 'super-names))

;; : (-> POOObject LiveCaseConfig)
(def (poo-flow-user-interface-live-case-config live-case)
  (.ref live-case 'config))

;;; Alist lookup is local to live-case config so test objects can inspect
;;; nested declarative clauses without depending on runtime config readers.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-interface-live-case-alist-ref entries key default)
  (cond
   ((not (list? entries)) default)
   ((null? entries) default)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-interface-live-case-alist-ref (cdr entries) key default))))

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-user-interface-live-case-config-ref live-case key default)
  (poo-flow-user-interface-live-case-alist-ref
   (poo-flow-user-interface-live-case-config live-case)
   key
   default))

;; : (-> POOObject Symbol Symbol Value Value)
(def (poo-flow-user-interface-live-case-section-ref live-case
                                                    section
                                                    key
                                                    default)
  (poo-flow-user-interface-live-case-alist-ref
   (poo-flow-user-interface-live-case-config-ref live-case section '())
   key
   default))
