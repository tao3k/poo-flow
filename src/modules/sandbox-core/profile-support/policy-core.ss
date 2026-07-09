;;; -*- Gerbil -*-
;;; Boundary: sandbox policy core owns shared policy facts that backend and
;;; profile modules inherit through POO object composition.
;;; Invariant: core policy defaults must remain backend-neutral and safe for
;;; module loader reuse.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref .slot? object?))

(export poo-flow-sandbox-backend-capability-kind
        poo-flow-sandbox-backend-capability-registry-kind
        poo-flow-sandbox-backend-capability-registry-diagnostic-kind
        poo-flow-sandbox-backend-capability-registry-validation-kind
        poo-flow-sandbox-profile-policy-kind
        poo-flow-sandbox-profile-policy-diagnostic-kind
        poo-flow-sandbox-profile-policy-validation-kind
        poo-flow-sandbox-profile-policy-projection-kind
        poo-flow-sandbox-profile-policy-option
        poo-flow-sandbox-profile-policy-option?
        poo-flow-sandbox-policy-value-index
        poo-flow-sandbox-policy-object-kind?
        poo-flow-sandbox-profile-policy-object-slot/default)

;; poo-flow-sandbox-backend-capability-kind
;;   : PooFlowSandboxBackendCapabilityKindId
;;   | type PooFlowSandboxBackendCapabilityKindId = String
;;   | doc m%
;;       Stable schema kind for backend capability POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-kind
;;       ;; => "poo-flow.sandbox.backend-capability.v1"
;;       ```
(defconst poo-flow-sandbox-backend-capability-kind
  "poo-flow.sandbox.backend-capability.v1")

;; poo-flow-sandbox-backend-capability-registry-kind
;;   : PooFlowSandboxBackendCapabilityRegistryKindId
;;   | type PooFlowSandboxBackendCapabilityRegistryKindId = String
;;   | doc m%
;;       Stable schema kind for backend capability registry POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-registry-kind
;;       ;; => "poo-flow.sandbox.backend-capability-registry.v1"
;;       ```
(defconst poo-flow-sandbox-backend-capability-registry-kind
  "poo-flow.sandbox.backend-capability-registry.v1")

;; poo-flow-sandbox-backend-capability-registry-diagnostic-kind
;;   : String
;;   | contract: stable schema id for backend capability registry diagnostics
;;   | result: literal kind string emitted in projected diagnostic alists
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-registry-diagnostic-kind
;;       ;; => "poo-flow.sandbox.backend-capability-registry.diagnostic.v1"
;;       ```
;;     %
(defconst poo-flow-sandbox-backend-capability-registry-diagnostic-kind
  "poo-flow.sandbox.backend-capability-registry.diagnostic.v1")

;; poo-flow-sandbox-backend-capability-registry-validation-kind
;;   : String
;;   | contract: stable schema id for backend capability registry validations
;;   | result: literal kind string emitted in registry validation receipts
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-registry-validation-kind
;;       ;; => "poo-flow.sandbox.backend-capability-registry.validation.v1"
;;       ```
;;     %
(defconst poo-flow-sandbox-backend-capability-registry-validation-kind
  "poo-flow.sandbox.backend-capability-registry.validation.v1")

;; poo-flow-sandbox-profile-policy-kind
;;   : PooFlowSandboxProfilePolicyKindId
;;   | type PooFlowSandboxProfilePolicyKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-kind
;;       ;; => "poo-flow.sandbox.profile-policy.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-kind
  "poo-flow.sandbox.profile-policy.v1")

;; poo-flow-sandbox-profile-policy-diagnostic-kind
;;   : PooFlowSandboxProfilePolicyDiagnosticKindId
;;   | type PooFlowSandboxProfilePolicyDiagnosticKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy diagnostic POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-diagnostic-kind
;;       ;; => "poo-flow.sandbox.profile-policy.diagnostic.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-diagnostic-kind
  "poo-flow.sandbox.profile-policy.diagnostic.v1")

;; poo-flow-sandbox-profile-policy-validation-kind
;;   : PooFlowSandboxProfilePolicyValidationKindId
;;   | type PooFlowSandboxProfilePolicyValidationKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy validation receipts.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-validation-kind
;;       ;; => "poo-flow.sandbox.profile-policy.validation.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-validation-kind
  "poo-flow.sandbox.profile-policy.validation.v1")

;; poo-flow-sandbox-profile-policy-projection-kind
;;   : PooFlowSandboxProfilePolicyProjectionKindId
;;   | type PooFlowSandboxProfilePolicyProjectionKindId = String
;;   | doc m%
;;       Stable schema kind for non-executing profile policy projections.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-projection-kind
;;       ;; => "poo-flow.sandbox.profile-policy.projection.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-projection-kind
  "poo-flow.sandbox.profile-policy.projection.v1")

;; poo-flow-sandbox-profile-policy-option
;;   : (-> Alist Symbol Value Value)
;;   | contract: read one optional profile policy setting with a default
;;   | result: option value when present, otherwise the caller-supplied default
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-option
;;        '((network . deny)) 'network 'allow)
;;       ;; => deny
;;       ```
;;     %
;;; Profile policy options share the same row shape across sandbox backends.
;;; - Keep kind/value/default metadata construction centralized for backend and profile helpers.
;; : (-> Alist Symbol Any Any)
(def (poo-flow-sandbox-profile-policy-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;; poo-flow-sandbox-profile-policy-option?
;;   : (-> Alist Symbol Boolean)
;;   | contract: test whether a profile policy option key is present
;;   | result: #t when the key has an entry, otherwise #f
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-option?
;;        '((network . deny)) 'network)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-option? options key)
  (and (assoc key options) #t))

;; poo-flow-sandbox-policy-value-index
;;   : (-> [Value] HashTable)
;;   | contract: build a membership index for policy validation values
;;   | result: hash table mapping every input value to #t
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (hash-get (poo-flow-sandbox-policy-value-index '(read write)) 'read)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-sandbox-policy-value-index values)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! index value #t))
     values)
    index))

;; poo-flow-sandbox-policy-object-kind?
;;   : (-> SandboxPolicyCandidate SandboxPolicyKindId Boolean)
;;   | contract: recognize POO policy objects carrying the expected kind slot
;;   | result: #t when value is a POO object whose kind equals the expected id
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-policy-object-kind? '() "kind")
;;       ;; => #f
;;       ```
;;     %
;; : (-> SandboxPolicyCandidate SandboxPolicyKindId Boolean)
(def (poo-flow-sandbox-policy-object-kind? value kind)
  (and (object? value)
       (.slot? value 'kind)
       (equal? (.ref value 'kind) kind)))

;; poo-flow-sandbox-profile-policy-object-slot/default
;;   : (-> PooFlowProfileObject Symbol Value Value)
;;   | contract: read one optional policy object slot with a default value
;;   | result: slot value when available, otherwise default
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-object-slot/default '() 'network-policy 'deny)
;;       ;; => deny
;;       ```
(def (poo-flow-sandbox-profile-policy-object-slot/default object
                                                           key
                                                           default-value)
  (if (and (object? object) (.slot? object key))
    (.ref object key)
    default-value))
