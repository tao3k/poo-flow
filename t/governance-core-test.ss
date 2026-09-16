;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop element?)
        (only-in :poo-flow/src/module-system/contribution/interface
                 admit-contributions)
        (only-in :poo-flow/src/module-system/poo-clos/interface
                 poo-clos-generic-methods
                 poo-clos-make-instance)
        :poo-flow/src/modules/governance/interface
        :poo-flow/src/modules/authorization/interface
        :poo-flow/src/modules/authorization/providers/cedar/interface)

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

(def (test-proof composition profiles assessments)
  (poo-flow-cedar-proof-binding
   composition (map (lambda (profile) (.ref profile 'identity)) profiles)
   test-digest test-digest test-digest test-digest
   (poo-flow-governance-assessments-digest assessments)
   test-digest
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

(def test-elevated-capability
  (poo-flow-authorization-capability
   "test/capability/release" "test::Action" 1 'elevated))

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
    (test-case "Authorization contracts keep elevated capability strict"
      (check-equal?
       (.ref CedarAuthorizationProvider 'identity)
       "poo-flow/authorization/cedar")
      (let (receipt
            (poo-flow-authorization-capability-contract
             CedarAuthorizationProvider
             (list test-elevated-capability)))
        (check-equal? (.ref receipt 'admitted?) #t)
        (check-equal? (.ref receipt 'runtime-executed?) #f)
        ;; Force the lazy slot: lexical names matching POO slot names can
        ;; otherwise hide a recursive capture until a downstream handoff.
        (check-equal?
         (.ref receipt 'contract-digest)
         (poo-flow-authorization-capabilities-digest
          CedarAuthorizationProvider
          (list test-elevated-capability)))
        (check-equal?
         (poo-flow-authorization-provider-engines
          CedarAuthorizationProvider)
         '("cedar-rust" "cedar-lean"))))
    (test-case "Authorization Provider publishes its CLOS method bundle"
      (check-equal?
       (length
        (poo-clos-generic-methods AuthorizationCapabilityContractGeneric))
       2)
      (let (unsupported-provider
            (poo-flow-authorization-provider
             "test/authorization/unsupported"
             '("unsupported")
             'strict-lockstep
             (poo-clos-make-instance
              AuthorizationCapabilityContractExecutor)
             'test.runtime))
        (check-exception
         (poo-flow-authorization-capability-contract
          unsupported-provider
          (list test-elevated-capability))
         true)))
    (test-case "Cedar adapter binds the exact Governance Profile identity"
      (let* ((profiles (list TestGovernanceProfile))
             (assessments
              (list (poo-flow-governance-evaluate TestGovernanceProfile (.o))))
             (snapshot
            (poo-flow-cedar-governance-snapshot
             "test/governance" profiles assessments test-context
             (test-proof "test/governance" profiles assessments)
             (list test-policy) test-schema test-entities
             (list test-capability))))
        (check-equal? (.ref snapshot 'runtime-executed?) #f)
        (check-equal?
         (.ref (car (.ref snapshot 'governance-assessments)) 'handoff-ready?) #t)
        (check-equal?
         (.ref (.ref snapshot 'proof-binding) 'composition)
         "test/governance")))
    (test-case "Cedar adapter rejects another composition"
      (check-exception
       (let* ((profiles (list TestGovernanceProfile))
              (assessments
               (list (poo-flow-governance-evaluate TestGovernanceProfile (.o)))))
         (poo-flow-cedar-governance-snapshot
          "test/governance" profiles assessments test-context
          (test-proof "other/governance" profiles assessments)
          (list test-policy) test-schema test-entities (list test-capability)))
       true))
    (test-case "Cedar adapter cannot bypass unresolved Governance threats"
      (check-exception
       (let* ((profiles (list UnsafeGovernanceProfile))
              (assessments
               (list (poo-flow-governance-evaluate UnsafeGovernanceProfile (.o)))))
         (poo-flow-cedar-governance-snapshot
          "test/governance/unsafe" profiles assessments test-context
          (test-proof "test/governance/unsafe" profiles assessments)
          (list test-policy) test-schema test-entities (list test-capability)))
       true))))
