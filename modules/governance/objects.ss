;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO-native Governance values and default method slots.
;;; Invariant: the root Profile is abstract and an assessment is never authority.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :std/list/list filter)
        (only-in :poo-flow/modules/governance/types
                 poo-flow-governance-profile-kind
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
                 poo-flow-governance-assess-threats))

(export PooFlowGovernanceProfile.
        PooFlowGovernanceThreatModel.
        poo-flow-governance-source
        poo-flow-governance-precondition
        poo-flow-governance-threat
        poo-flow-governance-threat-model
        poo-flow-governance-threat-blocking?
        poo-flow-governance-assessment-value
        poo-flow-governance-assessment)

(def (poo-flow-governance-assessment-value
      profile model unresolved-threat-values context-value)
  (validate
   PooFlowGovernanceAssessment
   (.o kind: poo-flow-governance-assessment-kind
       profile-identity: (.ref profile 'identity)
       model-identity: (.ref model 'identity)
       assessed-threats: (.ref model 'threats)
       unresolved-threats: unresolved-threat-values
       handoff-ready?: (null? unresolved-threat-values)
       runtime-executed?: #f
       context: context-value)))

(def (poo-flow-governance-threat-blocking? threat)
  (and (memq (.ref threat 'severity) '(high critical))
       (memq (.ref threat 'phase) '(exposed realized))
       #t))

(def (poo-flow-governance-default-assessment model profile context-value)
  (let* ((threats (.ref model 'threats))
         (unresolved
          (map (lambda (threat) (.ref threat 'identity))
               (filter poo-flow-governance-threat-blocking? threats))))
    (poo-flow-governance-assessment-value
     profile model unresolved context-value)))

(def PooFlowGovernanceThreatModel.
  (.o (:: self)
      kind: poo-flow-governance-threat-model-kind
      identity: "poo-flow/governance/threat-model/empty"
      threats: '()
      .assess-threats:
      (lambda (profile context)
        (poo-flow-governance-default-assessment self profile context))))

(def PooFlowGovernanceProfile.
  (.o (:: self)
      kind: poo-flow-governance-profile-kind
      identity: #f
      revision: #f
      owner: #f
      ontology: (.o)
      policies: (.o)
      source-assets: '()
      threat-model: PooFlowGovernanceThreatModel.
      .assess-governance:
      (lambda (context)
        (poo-flow-governance-assess-threats threat-model self context))))

(def (poo-flow-governance-source identity-value path-value language-value)
  (validate
   PooFlowGovernanceSource
   (.o kind: poo-flow-governance-source-kind
       governance-kind: poo-flow-governance-source-kind
       identity: identity-value
       path: path-value
       language: language-value)))

(def (poo-flow-governance-precondition identity-value observed-value
                                       evidence-value)
  (validate
   PooFlowGovernancePrecondition
   (.o kind: poo-flow-governance-precondition-kind
       identity: identity-value
       observed?: (if observed-value #t #f)
       evidence: evidence-value)))

(def (poo-flow-governance-threat identity-value severity-value phase-value
                                 precondition-values
                                 mitigations: (mitigation-values '())
                                 acceptance-authority:
                                 (acceptance-authority-value #f))
  (validate
   PooFlowGovernanceThreat
   (.o kind: poo-flow-governance-threat-kind
       identity: identity-value
       severity: severity-value
       phase: phase-value
       preconditions: precondition-values
       mitigations: mitigation-values
       acceptance-authority: acceptance-authority-value)))

(def (poo-flow-governance-threat-model identity-value threat-values)
  (validate
   PooFlowGovernanceThreatModel
   (.o (:: @ PooFlowGovernanceThreatModel.)
       identity: identity-value
       threats: threat-values)))

(def (poo-flow-governance-assessment profile context)
  (poo-flow-governance-assess-threats
   (.ref profile 'threat-model) profile context))
