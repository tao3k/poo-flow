;;; -*- Gerbil -*-
;;; Boundary: sandbox profile core owns reusable profile objects before
;;; backend-specific modules specialize filesystem, network, and resource policy.
;;; Invariant: profile objects must remain composable through POO inheritance.

(import :gerbil/gambit
        (only-in :clan/poo/object object<-alist .ref .slot?)
        :poo-flow/src/modules/sandbox-core/profile-support/policy-core
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-capability
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax
        (only-in :poo-flow/src/module-system/durable-policy
                 poo-flow-durable-policy/default
                 poo-flow-durable-policy?
                 poo-flow-durable-policy-name))

(export poo-flow-sandbox-profile-policy
        poo-flow-sandbox-profile-policy?
        poo-flow-sandbox-profile-policy-required-capabilities
        poo-flow-sandbox-profile-policy-resource-policy
        poo-flow-sandbox-profile-policy-durable-policy
        poo-flow-sandbox-profile-policy-durable-policy-ref
        poo-flow-sandbox-profile-policy-sandbox-handle-class
        poo-flow-sandbox-profile-policy/default
        poo-flow-sandbox-profile-policy-append-distinct
        poo-flow-sandbox-profile-policy-append-distinct/indexed
        poo-flow-sandbox-profile-policy-effective-required)

;; poo-flow-sandbox-profile-policy
;;   : (-> [Symbol] [Alist] POOObject)
;;   | contract: build a POO sandbox profile policy object from required capabilities
;;   | result: immutable policy object carrying normalized option slots
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy
;;        '(filesystem-read) '((network-policy . deny)))
;;       ;; => sandbox profile policy object
;;       ```
;;     %
;;; Sandbox profile policy objects carry required capabilities and runtime policy knobs.
;;; - Keep durable, resource, and sandbox handle policy fields on one POO object boundary.
;; : (-> List List Object)
(def (poo-flow-sandbox-profile-policy required-capabilities . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-profile-policy-kind)
      (cons 'required-capabilities required-capabilities)
      (cons 'backend-intent
            (poo-flow-sandbox-profile-policy-option options 'backend-intent '()))
      (cons 'resource-policy
            (poo-flow-sandbox-profile-policy-option options 'resource-policy '()))
      (cons 'durable-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'durable-policy
             poo-flow-durable-policy/default))
      (cons 'sandbox-handle-class
            (poo-flow-sandbox-profile-policy-option
             options
             'sandbox-handle-class
             'sandbox/profile-handle))
      (cons 'safety-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'safety-policy
             '((deny . ()) (human-gates . ()))))
      (cons 'failure-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'failure-policy
             '((structured . #t) (recoverable . #t))))
      (cons 'projection-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'projection-policy
             '((runtime-executed . #f) (target . marlin-agent-core))))
      (cons 'metadata
            (poo-flow-sandbox-profile-policy-option options 'metadata '()))))))

;; poo-flow-sandbox-profile-policy?
;;   : (-> SandboxPolicyCandidate Boolean)
;;   | contract: recognize POO sandbox profile policy objects
;;   | result: #t only for values carrying the sandbox profile policy kind id
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy? '())
;;       ;; => #f
;;       ```
;;     %
;; : (-> SandboxPolicyCandidate Boolean)
(def (poo-flow-sandbox-profile-policy? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-profile-policy-kind))

;; poo-flow-sandbox-profile-policy-required-capabilities
;;   : (-> PooSandboxProfilePolicy [CapabilitySymbol])
;;   | contract: read required capability symbols from a profile policy object
;;   | result: required capability list, or empty list for invalid policies
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-required-capabilities '())
;;       ;; => ()
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy [CapabilitySymbol])
(def (poo-flow-sandbox-profile-policy-required-capabilities policy)
  (if (poo-flow-sandbox-profile-policy? policy)
    (.ref policy 'required-capabilities)
    '()))

;; poo-flow-sandbox-profile-policy-resource-policy
;;   : (-> PooSandboxProfilePolicy ResourcePolicy)
;;   | contract: read resource policy rows from a profile policy object
;;   | result: resource policy rows, or empty list for invalid policies
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-resource-policy '())
;;       ;; => ()
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy ResourcePolicy)
(def (poo-flow-sandbox-profile-policy-resource-policy policy)
  (if (poo-flow-sandbox-profile-policy? policy)
    (.ref policy 'resource-policy)
    '()))

;; poo-flow-sandbox-profile-policy-durable-policy
;;   : (-> PooSandboxProfilePolicy PooDurablePolicy)
;;   | contract: read durable policy slot or fall back to the default policy
;;   | result: durable policy object used by sandbox profile validation
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-durable-policy '())
;;       ;; => default durable policy object
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy PooDurablePolicy)
(def (poo-flow-sandbox-profile-policy-durable-policy policy)
  (if (and (poo-flow-sandbox-profile-policy? policy)
           (.slot? policy 'durable-policy))
    (.ref policy 'durable-policy)
    poo-flow-durable-policy/default))

;; poo-flow-sandbox-profile-policy-durable-policy-ref
;;   : (-> PooSandboxProfilePolicy MaybeSymbol)
;;   | contract: project the durable policy name from a profile policy object
;;   | result: durable policy symbol when available, otherwise #f
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-durable-policy-ref '())
;;       ;; => durable/default
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy MaybeSymbol)
(def (poo-flow-sandbox-profile-policy-durable-policy-ref policy)
  (let (durable-policy
        (poo-flow-sandbox-profile-policy-durable-policy policy))
    (if (poo-flow-durable-policy? durable-policy)
      (poo-flow-durable-policy-name durable-policy)
      #f)))

;; poo-flow-sandbox-profile-policy-sandbox-handle-class
;;   : (-> PooSandboxProfilePolicy Symbol)
;;   | contract: read sandbox handle class with the profile-handle default
;;   | result: sandbox handle class symbol
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-sandbox-handle-class '())
;;       ;; => sandbox/profile-handle
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy Symbol)
(def (poo-flow-sandbox-profile-policy-sandbox-handle-class policy)
  (if (and (poo-flow-sandbox-profile-policy? policy)
           (.slot? policy 'sandbox-handle-class))
    (.ref policy 'sandbox-handle-class)
    'sandbox/profile-handle))

;; poo-flow-sandbox-profile-policy/default
;;   : PooSandboxProfilePolicy
;;   | contract: default sandbox profile policy with no required capabilities
;;   | result: reusable POO policy object for callers without explicit policy rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy? poo-flow-sandbox-profile-policy/default)
;;       ;; => #t
;;       ```
;;     %
(def poo-flow-sandbox-profile-policy/default
  (poo-flow-sandbox-profile-policy '()))

;; poo-flow-sandbox-profile-policy-append-distinct
;;   : (-> [CapabilitySymbol] [CapabilitySymbol] [CapabilitySymbol])
;;   | contract: append missing capability symbols without duplicates
;;   | result: base capabilities plus distinct extra capabilities in stable order
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-append-distinct '(read) '(read write))
;;       ;; => (read write)
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-append-distinct base extra)
  (if (null? extra)
    base
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     extra
     (poo-flow-sandbox-policy-value-index base)
     '())))

;; : (-> CapabilityList CapabilityList HashTable CapabilityList CapabilityList)
(def (poo-flow-sandbox-profile-policy-append-distinct/indexed base
                                                              extra
                                                              seen
                                                              added)
  (cond
   ((null? extra)
    (if (null? added)
      base
      (append base (reverse added))))
   ((hash-get seen (car extra))
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     (cdr extra)
     seen
     added))
   (else
    (hash-put! seen (car extra) #t)
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     (cdr extra)
     seen
     (cons (car extra) added)))))

;; poo-flow-sandbox-profile-policy-effective-required
;;   : (-> PooSandboxProfilePolicy [CapabilitySymbol] [CapabilitySymbol])
;;   | contract: combine policy-required and profile-provided capabilities
;;   | result: distinct effective required capability symbols
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-effective-required policy '(read))
;;       ;; => effective capability symbols
;;       ```
;;     %
;; : (-> PooSandboxProfilePolicy [CapabilitySymbol] [CapabilitySymbol])
(def (poo-flow-sandbox-profile-policy-effective-required policy
                                                         profile-capabilities)
  (poo-flow-sandbox-profile-policy-append-distinct
   (poo-flow-sandbox-profile-policy-required-capabilities policy)
   profile-capabilities))
