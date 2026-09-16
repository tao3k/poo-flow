;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop element?)
        (only-in :poo-flow/src/module-system/contribution/interface
                 admit-contributions)
        :poo-flow/src/modules/governance/interface
        :poo-flow/src/policy/cedar-authority
        :poo-flow/src/policy/cedar-governance)

(export governance-core-test)

(def test-digest
  (string-append "sha256:" (make-string 64 #\0)))

(def TestGovernanceProfile
  (.o (:: @ PooFlowGovernanceProfile.)
      identity: "test/governance"
      revision: "1"
      owner: "test-owner"
      policies: (.o release: 'review-required)))

(def ExposedPrecondition
  (poo-flow-governance-precondition
   "test/precondition/external-input" #t "evidence:external-input"))

(def DerivedGovernanceSource
  (.o (:: @ (poo-flow-governance-source
              "test/source/derived" "sources/derived.json" 'json))
      kind: 'test.derived-governance-source))

(def BlockingThreat
  (poo-flow-governance-threat
   "test/threat/unreviewed-external-input"
   'critical
   'exposed
   (list ExposedPrecondition)))

(def BlockingThreatModel
  (poo-flow-governance-threat-model
   "test/threat-model/blocking" (list BlockingThreat)))

(def UnsafeGovernanceProfile
  (.o (:: @ TestGovernanceProfile)
      identity: "test/governance/unsafe"
      threat-model: BlockingThreatModel))

(def (test-proof composition)
  (poo-flow-cedar-proof-binding
   composition test-digest test-digest test-digest test-digest
   '("test-governance-qualification")))

(def test-context
  (poo-flow-cedar-authority-context
   "test-authority" "test-runtime" 1 test-digest 0 1 0))

(def test-policy
  (poo-flow-cedar-policy
   "test-policy"
   "permit(principal, action, resource);"))

(def test-schema
  (poo-flow-cedar-schema "{}"))

(def test-entities
  (poo-flow-cedar-entities "[]"))

(def test-capability
  (poo-flow-cedar-runtime-capability "test::Action" 1))

(def governance-core-test
  (test-suite "POO Flow Governance core and Cedar Provider boundary"
    (test-case "core prototype requires explicit contributor identity"
      (check-equal?
       (poo-flow-governance-profile? PooFlowGovernanceProfile.) #f)
      (check-equal?
       (poo-flow-governance-profile? TestGovernanceProfile) #t)
      (check-equal? (element? PooFlowGovernanceProfile TestGovernanceProfile)
                    #t)
      (check-equal? (element? PooFlowGovernanceThreat BlockingThreat) #t)
      (check-equal? (poo-flow-governance-source? DerivedGovernanceSource) #t))
    (test-case "Profile generic dispatch produces a typed inert assessment"
      (let (assessment
            (poo-flow-governance-evaluate
             TestGovernanceProfile (.o request: 'release)))
        (check-equal? (poo-flow-governance-assessment? assessment) #t)
        (check-equal? (.ref assessment 'handoff-ready?) #t)
        (check-equal? (.ref assessment 'runtime-executed?) #f)))
    (test-case "pre-threat exposure blocks Provider handoff"
      (let (assessment
            (poo-flow-governance-evaluate
             UnsafeGovernanceProfile (.o request: 'release)))
        (check-equal? (.ref assessment 'handoff-ready?) #f)
        (check-equal?
         (.ref assessment 'unresolved-threats)
         '("test/threat/unreviewed-external-input"))))
    (test-case "observed preconditions require evidence identity"
      (check-exception
       (poo-flow-governance-precondition "test/precondition/forged" #t #f)
       true))
    (test-case "governance contribution is semantic and inert"
      (let* ((contribution
              (poo-flow-governance-contribution
               TestGovernanceProfile '(knowledge-governance) '()))
             (receipt (admit-contributions (list contribution) '())))
        (check-equal? (.ref receipt 'accepted?) #t)
        (check-equal? (.ref receipt 'runtime-executed?) #f)))
    (test-case "Cedar adapter binds the exact Governance Profile identity"
      (let* ((assessment
              (poo-flow-governance-evaluate TestGovernanceProfile (.o)))
             (snapshot
            (poo-flow-cedar-governance-snapshot
             TestGovernanceProfile assessment test-context
             (test-proof "test/governance")
             (list test-policy) test-schema test-entities
             (list test-capability))))
        (check-equal? (.ref snapshot 'runtime-executed?) #f)
        (check-equal?
         (.ref (.ref snapshot 'governance-assessment) 'handoff-ready?) #t)
        (check-equal?
         (.ref (.ref snapshot 'proof-binding) 'composition)
         "test/governance")))
    (test-case "Cedar adapter rejects another composition"
      (check-exception
       (poo-flow-cedar-governance-snapshot
        TestGovernanceProfile
        (poo-flow-governance-evaluate TestGovernanceProfile (.o))
        test-context (test-proof "other/governance")
        (list test-policy) test-schema test-entities (list test-capability))
       true))
    (test-case "Cedar adapter cannot bypass unresolved Governance threats"
      (check-exception
       (poo-flow-cedar-governance-snapshot
        UnsafeGovernanceProfile
        (poo-flow-governance-evaluate UnsafeGovernanceProfile (.o))
        test-context (test-proof "test/governance/unsafe")
        (list test-policy) test-schema test-entities (list test-capability))
       true))))
