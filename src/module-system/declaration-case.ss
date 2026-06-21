;;; -*- Gerbil -*-
;;; Boundary: upstream case contracts for downstream declaration practice files.
;;; Invariant: cases consume config declarations; root user-facing files remain declarations only.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/src/module-system/profile-config)

(export poo-flow-declaration-case-kind
        poo-flow-declaration-case-default-setting-keys
        poo-flow-declaration-case-default-module-keys
        poo-flow-declaration-case-default-trace-stages
        pooFlowDeclarationCase
        pooFlowRootDeveloperDeclarationCase
        poo-flow-declaration-case?
        poo-flow-declaration-case-name
        poo-flow-declaration-case-case-file
        poo-flow-declaration-case-init-file
        poo-flow-declaration-case-custom-module-file
        poo-flow-declaration-case-config
        poo-flow-declaration-case-presentation
        poo-flow-declaration-case-expected-setting-keys
        poo-flow-declaration-case-expected-module-keys
        poo-flow-declaration-case-expected-trace-stages
        poo-flow-declaration-case-alist-value
        poo-flow-declaration-case-trace-stages
        poo-flow-declaration-case-trace-field-all-equal?
        poo-flow-declaration-case-trace-safe?
        poo-flow-declaration-case-presentation-matches?)

;; : (-> Unit PooFlowDeclarationCaseKind)
(def poo-flow-declaration-case-kind
  "poo-flow.modules.declaration-case.v1")

;; : (-> Unit [Symbol])
(def (poo-flow-declaration-case-default-setting-keys)
  '(surface
    profile
    flow-mode
    loop-strategy
    sandbox-policy
    sandbox-backends
    mode-lock))

;; : (-> Unit [Pair])
(def (poo-flow-declaration-case-default-module-keys)
  '((flow . funflow)
    (loop . governor)
    (sandbox . nono-sandbox)
    (sandbox . cubeSandbox)
    (sandbox . docker-sandbox)
    (flow . loop-engine)
    (custom . my-module)))

;; : (-> Unit [Symbol])
(def (poo-flow-declaration-case-default-trace-stages)
  '(selected-modules
    feature-facts
    cicd-intents
    workflow-cicd-pipelines
    workflow-cicd-runtime-readiness
    workflow-cicd-runtime-command-manifest-maps
    workflow-cicd-runtime-command-manifest-summaries
    workflow-cicd-runtime-command-manifest-agreement
    workflow-cicd-marlin-runtime-handoff-abis
    workflow-cicd-receipts
    loop-engine-intents
    settings))

;; : (-> MaybeValue String Boolean)
(def (poo-flow-declaration-case-object-kind? value expected-kind)
  (and (object? value)
       (equal? (.ref value 'kind) expected-kind)))

;;; The constructor computes presentation data before constructing the POO
;;; object. This keeps case metadata strict and prevents lazy-slot recursion
;;; between the `config` and `presentation` slots during debugging.
;; pooFlowDeclarationCase
;;   : (-> Symbol String String String PooUserConfig [Symbol] [Pair] [Symbol] POOObject)
;;   | contract: wraps a downstream user config in an upstream-owned case object
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (pooFlowDeclarationCase
;;        'developer
;;        "src/module-system/declaration-case.ss"
;;        "user-interface/init.ss"
;;        "user-interface/custom/my-module/config.ss"
;;        config
;;        setting-keys
;;        module-keys
;;        trace-stages)
;;       ;; => case object
;;       ```
;;     %
;; : (-> Symbol String String String PooUserConfig [Symbol] [Pair] [Symbol] POOObject)
(def (pooFlowDeclarationCase
      name-value
      case-file-path
      init-file-path
      custom-module-file-path
      config-value
      setting-key-list
      expected-module-key-list
      expected-trace-stage-list)
  (let ((presentation-value
         (pooFlowUserConfigPresentation config-value setting-key-list)))
    (.o kind: poo-flow-declaration-case-kind
        name: name-value
        case-file: case-file-path
        init-file: init-file-path
        custom-module-file: custom-module-file-path
        config: config-value
        presentation: presentation-value
        expected-setting-keys: setting-key-list
        expected-module-keys: expected-module-key-list
        expected-trace-stages: expected-trace-stage-list
        declaration-owned?: #t
        declarative-only?: #t
        runtime-owner: "marlin-agent-core"
        descriptor-realized?: #f
        runtime-executed: #f)))

;;; This is a maintained template for the root practice interface. The concrete
;;; downstream declarations still live in user-interface/init.ss and custom modules.
;; pooFlowRootDeveloperDeclarationCase
;;   : (-> PooUserConfig POOObject)
;;   | contract: builds the developer case from the supplied root config facade
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (pooFlowRootDeveloperDeclarationCase poo-flow-user-config)
;;       ;; => root developer case object
;;       ```
;;     %
;; : (-> PooUserConfig POOObject)
(def (pooFlowRootDeveloperDeclarationCase config)
  (pooFlowDeclarationCase
   'developer
   "src/module-system/declaration-case.ss"
   "user-interface/init.ss"
   "user-interface/custom/my-module/config.ss"
   config
   (poo-flow-declaration-case-default-setting-keys)
   (poo-flow-declaration-case-default-module-keys)
   (poo-flow-declaration-case-default-trace-stages)))

;; : (-> MaybeValue Boolean)
(def (poo-flow-declaration-case? value)
  (poo-flow-declaration-case-object-kind?
   value
   poo-flow-declaration-case-kind))

;; : (-> POOObject Symbol)
(def (poo-flow-declaration-case-name case-object)
  (.ref case-object 'name))

;; : (-> POOObject String)
(def (poo-flow-declaration-case-case-file case-object)
  (.ref case-object 'case-file))

;; : (-> POOObject String)
(def (poo-flow-declaration-case-init-file case-object)
  (.ref case-object 'init-file))

;; : (-> POOObject String)
(def (poo-flow-declaration-case-custom-module-file case-object)
  (.ref case-object 'custom-module-file))

;; : (-> POOObject PooUserConfig)
(def (poo-flow-declaration-case-config case-object)
  (.ref case-object 'config))

;; : (-> POOObject POOObject)
(def (poo-flow-declaration-case-presentation case-object)
  (.ref case-object 'presentation))

;; : (-> POOObject [Symbol])
(def (poo-flow-declaration-case-expected-setting-keys case-object)
  (.ref case-object 'expected-setting-keys))

;; : (-> POOObject [Pair])
(def (poo-flow-declaration-case-expected-module-keys case-object)
  (.ref case-object 'expected-module-keys))

;; : (-> POOObject [Symbol])
(def (poo-flow-declaration-case-expected-trace-stages case-object)
  (.ref case-object 'expected-trace-stages))

;; : (-> Symbol Alist MaybeValue)
(def (poo-flow-declaration-case-alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (poo-flow-declaration-case-alist-value key (cdr entries)))))

;;; The map projection keeps trace rows in presentation order, preserving the
;;; stage sequence users need when a lazy POO projection starts to recurse.
;; : (-> [Alist] [Symbol])
(def (poo-flow-declaration-case-trace-stages trace)
  (map (lambda (step)
         (poo-flow-declaration-case-alist-value 'stage step))
       trace))

;; : (-> Symbol MaybeValue [Alist] Boolean)
(def (poo-flow-declaration-case-trace-field-all-equal?
      key
      expected
      trace)
  (cond
   ((null? trace) #t)
   ((equal? expected
            (poo-flow-declaration-case-alist-value key (car trace)))
    (poo-flow-declaration-case-trace-field-all-equal?
     key
     expected
     (cdr trace)))
   (else #f)))

;;; Trace checks are the observability contract for declaration cases: a
;;; failing case should show the projection stage instead of hanging on a slot.
;; : (-> POOObject Boolean)
(def (poo-flow-declaration-case-trace-safe? case-object)
  (let* ((presentation
          (poo-flow-declaration-case-presentation case-object))
         (trace (.ref presentation 'presentation-trace)))
    (and (equal? (poo-flow-declaration-case-trace-stages trace)
                 (poo-flow-declaration-case-expected-trace-stages
                  case-object))
         (poo-flow-declaration-case-trace-field-all-equal?
          'status
          'ok
          trace)
         (poo-flow-declaration-case-trace-field-all-equal?
          'descriptor-realized?
          #f
          trace)
         (poo-flow-declaration-case-trace-field-all-equal?
          'runtime-executed
          #f
          trace))))

;;; Presentation matching is the test-facing predicate; it proves the root
;;; declaration stayed declarative while still exposing module intent.
;; : (-> POOObject Boolean)
(def (poo-flow-declaration-case-presentation-matches? case-object)
  (let ((presentation
         (poo-flow-declaration-case-presentation case-object)))
    (and (equal? (.ref presentation 'module-keys)
                 (poo-flow-declaration-case-expected-module-keys
                  case-object))
         (equal? (.ref presentation 'setting-keys)
                 (poo-flow-declaration-case-expected-setting-keys
                  case-object))
         (equal? (.ref presentation 'descriptor-realized?) #f)
         (equal? (.ref presentation 'runtime-executed) #f)
         (poo-flow-declaration-case-trace-safe? case-object))))
