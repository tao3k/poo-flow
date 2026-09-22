;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: engine-neutral Governance types and open dispatch protocols.
;;; Invariant: admission and threat assessment never imply action authority.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop .defgeneric define-type Type. element?)
        (only-in :std/list/list every))

(export poo-flow-governance-profile-kind
        poo-flow-governance-source-kind
        poo-flow-governance-precondition-kind
        poo-flow-governance-threat-kind
        poo-flow-governance-threat-model-kind
        poo-flow-governance-assessment-kind
        PooFlowGovernanceSource
        PooFlowGovernancePrecondition
        PooFlowGovernanceThreat
        PooFlowGovernanceThreatModel
        PooFlowGovernanceAssessment
        PooFlowGovernanceProfile
        poo-flow-governance-assess-threats
        poo-flow-governance-assess
        poo-flow-governance-source?
        poo-flow-governance-precondition?
        poo-flow-governance-threat?
        poo-flow-governance-threat-model?
        poo-flow-governance-assessment?
        poo-flow-governance-profile?)

(def poo-flow-governance-profile-kind 'poo-flow.governance-profile)
(def poo-flow-governance-source-kind 'poo-flow.governance-source)
(def poo-flow-governance-precondition-kind 'poo-flow.governance-precondition)
(def poo-flow-governance-threat-kind 'poo-flow.governance-threat)
(def poo-flow-governance-threat-model-kind 'poo-flow.governance-threat-model)
(def poo-flow-governance-assessment-kind 'poo-flow.governance-assessment)

;;; Threat-model and Profile specializations replace method slots through
;;; ordinary gerbil-poo inheritance; no central case statement owns extension.
(.defgeneric (poo-flow-governance-assess-threats model profile context)
  slot: .assess-threats)

(.defgeneric (poo-flow-governance-assess profile context)
  slot: .assess-governance)

(def (governance-text? value)
  (and (string? value) (> (string-length value) 0)))

(def (governance-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (governance-kind? value kind slots)
  (and (governance-has-slots? value (cons 'kind slots))
       (eq? (.ref value 'kind) kind)))

(def (poo-flow-governance-source-shape? value)
  (and (governance-has-slots?
        value '(kind governance-kind identity path language))
       (eq? (.ref value 'governance-kind) poo-flow-governance-source-kind)
       (governance-text? (.ref value 'identity))
       (governance-text? (.ref value 'path))
       (symbol? (.ref value 'language))))

(define-type (PooFlowGovernanceSource @ Type.)
  .element?: poo-flow-governance-source-shape?)

(def (poo-flow-governance-precondition-shape? value)
  (and (governance-kind?
        value poo-flow-governance-precondition-kind
        '(identity observed? evidence))
       (governance-text? (.ref value 'identity))
       (boolean? (.ref value 'observed?))
       (if (.ref value 'observed?)
         (governance-text? (.ref value 'evidence))
         (or (not (.ref value 'evidence))
             (governance-text? (.ref value 'evidence))))))

(define-type (PooFlowGovernancePrecondition @ Type.)
  .element?: poo-flow-governance-precondition-shape?)

(def (governance-severity? value)
  (and (memq value '(low moderate high critical)) #t))

(def (governance-threat-phase? value)
  (and (memq value '(latent exposed realized mitigated accepted)) #t))

(def (poo-flow-governance-threat-shape? value)
  (and
   (governance-kind?
    value poo-flow-governance-threat-kind
    '(identity severity phase preconditions mitigations acceptance-authority))
   (governance-text? (.ref value 'identity))
   (governance-severity? (.ref value 'severity))
   (governance-threat-phase? (.ref value 'phase))
   (list? (.ref value 'preconditions))
   (pair? (.ref value 'preconditions))
   (every (lambda (item) (element? PooFlowGovernancePrecondition item))
          (.ref value 'preconditions))
   (list? (.ref value 'mitigations))
   (every governance-text? (.ref value 'mitigations))
   (if (eq? (.ref value 'phase) 'mitigated)
     (pair? (.ref value 'mitigations))
     #t)
   (if (eq? (.ref value 'phase) 'accepted)
     (governance-text? (.ref value 'acceptance-authority))
     (or (not (.ref value 'acceptance-authority))
         (governance-text? (.ref value 'acceptance-authority))))))

(define-type (PooFlowGovernanceThreat @ Type.)
  .element?: poo-flow-governance-threat-shape?)

(def (poo-flow-governance-threat-model-shape? value)
  (and (governance-kind?
        value poo-flow-governance-threat-model-kind
        '(identity threats .assess-threats))
       (governance-text? (.ref value 'identity))
       (list? (.ref value 'threats))
       (every (lambda (item) (element? PooFlowGovernanceThreat item))
              (.ref value 'threats))
       (procedure? (.ref value '.assess-threats))))

(define-type (PooFlowGovernanceThreatModel @ Type.)
  .element?: poo-flow-governance-threat-model-shape?)

(def (poo-flow-governance-assessment-shape? value)
  (and
   (governance-kind?
    value poo-flow-governance-assessment-kind
    '(profile-identity model-identity assessed-threats unresolved-threats
      handoff-ready? runtime-executed? context))
   (governance-text? (.ref value 'profile-identity))
   (governance-text? (.ref value 'model-identity))
   (list? (.ref value 'assessed-threats))
   (every (lambda (item) (element? PooFlowGovernanceThreat item))
          (.ref value 'assessed-threats))
   (list? (.ref value 'unresolved-threats))
   (every governance-text? (.ref value 'unresolved-threats))
   (boolean? (.ref value 'handoff-ready?))
   (eq? (.ref value 'handoff-ready?)
        (null? (.ref value 'unresolved-threats)))
   (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowGovernanceAssessment @ Type.)
  .element?: poo-flow-governance-assessment-shape?)

(def (poo-flow-governance-profile-shape? value)
  (and
   (governance-kind?
    value poo-flow-governance-profile-kind
    '(identity revision owner ontology policies source-assets threat-model
      .assess-governance))
   (every (lambda (slot) (governance-text? (.ref value slot)))
          '(identity revision owner))
   (object? (.ref value 'ontology))
   (object? (.ref value 'policies))
   (list? (.ref value 'source-assets))
   (every (lambda (item) (element? PooFlowGovernanceSource item))
          (.ref value 'source-assets))
   (element? PooFlowGovernanceThreatModel (.ref value 'threat-model))
   (procedure? (.ref value '.assess-governance))))

(define-type (PooFlowGovernanceProfile @ Type.)
  .element?: poo-flow-governance-profile-shape?)

(def (poo-flow-governance-source? value)
  (element? PooFlowGovernanceSource value))

(def (poo-flow-governance-precondition? value)
  (element? PooFlowGovernancePrecondition value))

(def (poo-flow-governance-threat? value)
  (element? PooFlowGovernanceThreat value))

(def (poo-flow-governance-threat-model? value)
  (element? PooFlowGovernanceThreatModel value))

(def (poo-flow-governance-assessment? value)
  (element? PooFlowGovernanceAssessment value))

(def (poo-flow-governance-profile? value)
  (element? PooFlowGovernanceProfile value))
