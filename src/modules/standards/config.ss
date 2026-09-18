;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Standard core owns the composable module prototype, but no ambient industry
;;; catalog or concrete validation Provider.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        "types.ss"
        "objects.ss"
        "funs.ss"
        "loader.ss")

(export poo-flow-standard-default-budget
        poo-flow-standard-empty-catalog
        PooFlowStandardGovernanceInterface.
        PooFlowStandardMigrationGovernanceInterface.
        PooFlowStandardFeatureModule.
        PooFlowStandardMigrationFeatureModule.
        PooFlowStandardsModule.
        poo-flow-standards-module)

(def poo-flow-standard-default-budget
  (poo-flow-standard-budget 64 4096 64 (* 64 1024 1024) 100000))

(def poo-flow-standard-empty-catalog
  (poo-flow-standard-catalog "poo-flow/standard/empty" '() '()))

;;; Feature modules are composable children of the Standards module.  Core
;;; declares stable extension points; vertical owners add fixtures and methods.
(def PooFlowStandardGovernanceInterface.
  (poo-flow-standard-governance-interface
   "poo-flow/modules/standards/governance/base"
   '() '(documentation presentation-metadata reference-implementation)
   (.o declaration: (.o))
   (.o)
   (lambda (_binding) #t)))

(def PooFlowStandardFeatureModule.
  (poo-flow-standard-feature-module
   "poo-flow/modules/standards/features/base" 'base '() (.o)
   PooFlowStandardGovernanceInterface. '()))

(def PooFlowStandardMigrationGovernanceInterface.
  (poo-flow-standard-governance-interface
   "poo-flow/modules/standards/features/migration/governance"
   '(authority-provider human-authorization formal-model refinement-proof
     impact-contract conformance audit-receipt)
   '(documentation presentation-metadata reference-implementation
     non-authoritative-analysis)
   (.o declaration: (.o)
       review:
       (.o formal-model: '(qualified admitted)
           refinement-proof: '(qualified admitted)
           impact-contract: '(qualified admitted)
           conformance: '(qualified admitted))
       admit:
       (.o authority-provider: '(qualified admitted)
           human-authorization: '(qualified admitted)
           formal-model: '(qualified admitted)
           refinement-proof: '(qualified admitted)
           impact-contract: '(qualified admitted)
           conformance: '(qualified admitted)
           audit-receipt: '(qualified admitted))
       cutover:
       (.o authority-provider: '(admitted)
           human-authorization: '(admitted)
           formal-model: '(admitted)
           refinement-proof: '(admitted)
           impact-contract: '(admitted)
           conformance: '(admitted)
           audit-receipt: '(admitted)))
   (.o)
   (lambda (_binding) #t)))

(def PooFlowStandardMigrationFeatureModule.
  (poo-flow-standard-feature-module
   "poo-flow/modules/standards/features/migration" 'migration
   '(source-adapter mapping-proposal human-review conformance admission
     governance fixture)
   (.o) PooFlowStandardMigrationGovernanceInterface.
   '((owner . poo-flow-standards))))

;;; This is the Lego stud exposed by POO Flow.  Vertical contributors derive a
;;; module object and replace only catalog, budget and Provider slots.
(def PooFlowStandardsModule.
  (.o (:: self)
      kind: +poo-flow-standards-module-kind+
      identity: "poo-flow/modules/standards"
      catalog: poo-flow-standard-empty-catalog
      budget: poo-flow-standard-default-budget
      providers: (.o)
      features: (.o migration: PooFlowStandardMigrationFeatureModule.)
      .resolve:
      (lambda (root-identities terminology-snapshot-digest)
        (poo-flow-standard-resolve
         catalog root-identities budget terminology-snapshot-digest))
      .materialization-context:
      (lambda (identity bundle)
        (poo-flow-standard-materialization-context
         identity (.ref bundle 'artifacts)))
      .make-validation-closure:
      (lambda (identity bundle provider-identity subject-kind
                        subject-snapshot-digest constraints)
        (poo-flow-standard-make-validation-closure
         identity bundle provider-identity subject-kind
         subject-snapshot-digest constraints))))

(def (poo-flow-standards-module identity-value catalog-value budget-value
                                provider-values
                                (feature-values
                                 (.o migration:
                                     PooFlowStandardMigrationFeatureModule.)))
  (validate
   PooFlowStandardsModule
   (.o (:: @ PooFlowStandardsModule.)
       identity: identity-value
       catalog: catalog-value
       budget: budget-value
       providers: provider-values
       features: feature-values)))
