;;; -*- Gerbil -*-
;;; Contract: public receipt for JSON Schema to POO Flow contract generation.

(import (only-in "../utilities/contracts.ss"
                 poo-flow-object-type-contract->alist)
        (only-in "../type-facts/objects.ss"
                 poo-flow-type-fact-contract->alist
                 poo-flow-lean-fact-contract->alist
                 poo-flow-object-type-contract->type-facts
                 poo-flow-object-type-contract->lean-fact-contracts)
        (only-in "../observability/objects.ss"
                 poo-flow-observability-diagnostic-record
                 poo-flow-observability-diagnostic-severity
                 poo-flow-observability-diagnostic->alist)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-diagnostic-severity
                 poo-flow-json-schema-diagnostic-reason
                 poo-flow-json-schema-diagnostic-message
                 poo-flow-json-schema-diagnostic-value
                 poo-flow-json-schema-diagnostic->alist
                 poo-flow-json-schema-normalization-schema
                 poo-flow-json-schema-normalization-diagnostics
                 poo-flow-json-schema-normalization->alist)
        (only-in "./functional.ss"
                 poo-flow-contract-any?
                 poo-flow-contract-option
                 poo-flow-contract-project-list)
        (only-in "./json-schema-normalize.ss"
                 poo-flow-json-schema-normalize)
        (only-in "./json-schema-emit.ss"
                 poo-flow-json-schema-node->object-type-contract))

(export make-poo-flow-json-schema-contract-artifact
        poo-flow-json-schema-contract-artifact?
        poo-flow-json-schema-contract-artifact-kind
        poo-flow-json-schema-contract-artifact-schema
        poo-flow-json-schema-contract-artifact-source-ref
        poo-flow-json-schema-contract-artifact-normalization
        poo-flow-json-schema-contract-artifact-object-contract
        poo-flow-json-schema-contract-artifact-diagnostics
        poo-flow-json-schema-contract-artifact-type-facts
        poo-flow-json-schema-contract-artifact-lean-fact-contracts
        poo-flow-json-schema-contract-artifact-runtime-executed
        poo-flow-json-schema-contract-artifact-valid?
        poo-flow-json-schema-contract-artifact->alist
        poo-flow-json-schema-diagnostic->observability
        poo-flow-json-schema->contract-artifact)

;; poo-flow-json-schema-contract-artifact
;;   : (-> Symbol String SourceRef PooFlowJsonSchemaNormalization PooFlowObjectTypeContract [Diagnostic] [TypeFact] [LeanFact] Boolean Artifact)
;;   | doc m%
;;       Fixed public receipt for JSON Schema contract generation. The generated
;;       object contract is still Scheme data; external payloads use ->alist.
;;     %
(defstruct poo-flow-json-schema-contract-artifact
  (kind
   schema
   source-ref
   normalization
   object-contract
   diagnostics
   type-facts
   lean-fact-contracts
   runtime-executed)
  transparent: #t)

;; : (-> Alist Symbol Value)
(def (poo-flow-json-schema-option options key default-value)
  (poo-flow-contract-option options key default-value))

;; : (-> PooFlowJsonSchemaDiagnostic PooFlowObservabilityDiagnostic)
(def (poo-flow-json-schema-diagnostic->observability diagnostic)
  (poo-flow-observability-diagnostic-record
   (poo-flow-json-schema-diagnostic-severity diagnostic)
   'contract
   'json-schema-contract
   #f
   #f
   (poo-flow-json-schema-diagnostic-reason diagnostic)
   (poo-flow-json-schema-diagnostic-message diagnostic)
   'contract
   (list
    (cons 'value (poo-flow-json-schema-diagnostic-value diagnostic))
    (cons 'diagnostic
          (poo-flow-json-schema-diagnostic->alist diagnostic)))))

;; : (-> PooFlowObservabilityDiagnostic Boolean)
(def (poo-flow-json-schema-diagnostic-fatal? diagnostic)
  (let (severity (poo-flow-observability-diagnostic-severity diagnostic))
    (or (eq? severity 'error)
        (eq? severity 'fatal))))

;; : (-> PooFlowJsonSchemaContractArtifact Boolean)
(def (poo-flow-json-schema-contract-artifact-valid? artifact)
  (and (poo-flow-json-schema-contract-artifact? artifact)
       (not
        (poo-flow-contract-any?
         poo-flow-json-schema-diagnostic-fatal?
         (poo-flow-json-schema-contract-artifact-diagnostics artifact)))))

;; : (-> PooFlowJsonSchemaContractArtifact Alist)
(def (poo-flow-json-schema-contract-artifact->alist artifact)
  (list
   (cons 'kind
         (poo-flow-json-schema-contract-artifact-kind artifact))
   (cons 'schema
         (poo-flow-json-schema-contract-artifact-schema artifact))
   (cons 'source-ref
         (poo-flow-json-schema-contract-artifact-source-ref artifact))
   (cons 'valid?
         (poo-flow-json-schema-contract-artifact-valid? artifact))
   (cons 'normalization
         (poo-flow-json-schema-normalization->alist
          (poo-flow-json-schema-contract-artifact-normalization artifact)))
   (cons 'object-contract
         (poo-flow-object-type-contract->alist
          (poo-flow-json-schema-contract-artifact-object-contract artifact)))
   (cons 'diagnostics
         (poo-flow-contract-project-list
          poo-flow-observability-diagnostic->alist
          (poo-flow-json-schema-contract-artifact-diagnostics artifact)))
   (cons 'diagnostic-count
         (length
          (poo-flow-json-schema-contract-artifact-diagnostics artifact)))
   (cons 'type-facts
         (poo-flow-contract-project-list
          poo-flow-type-fact-contract->alist
          (poo-flow-json-schema-contract-artifact-type-facts artifact)))
   (cons 'lean-fact-contracts
         (poo-flow-contract-project-list
          poo-flow-lean-fact-contract->alist
          (poo-flow-json-schema-contract-artifact-lean-fact-contracts artifact)))
   (cons 'runtime-executed
         (poo-flow-json-schema-contract-artifact-runtime-executed artifact))))

;; : (-> JsonLikeSchema [Alist] PooFlowJsonSchemaContractArtifact)
(def (poo-flow-json-schema->contract-artifact schema . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (source-ref
          (poo-flow-json-schema-option options 'source-ref 'json-schema))
         (owner
          (poo-flow-json-schema-option options 'owner 'contract))
         (object-kind
          (poo-flow-json-schema-option
           options
           'object-kind
           'PooFlowJsonSchemaObject))
         (object-key
          (poo-flow-json-schema-option
           options
           'object-key
           'json-schema/root))
         (normalization
          (poo-flow-json-schema-normalize schema))
         (object-contract
          (poo-flow-json-schema-node->object-type-contract
           (poo-flow-json-schema-normalization-schema normalization)
           owner
           object-kind
           object-key))
         (diagnostics
          (poo-flow-contract-project-list
           poo-flow-json-schema-diagnostic->observability
           (poo-flow-json-schema-normalization-diagnostics normalization)))
         (type-facts
          (poo-flow-object-type-contract->type-facts object-contract))
         (lean-fact-contracts
          (poo-flow-object-type-contract->lean-fact-contracts object-contract)))
    (make-poo-flow-json-schema-contract-artifact
     'json-schema-contract-artifact
     "poo-flow-json-schema-contract-artifact/v1"
     source-ref
     normalization
     object-contract
     diagnostics
     type-facts
     lean-fact-contracts
     #f)))
