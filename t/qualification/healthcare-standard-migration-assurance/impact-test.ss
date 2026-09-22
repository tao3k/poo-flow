;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Exact change-impact qualification between the migration TLA+ model and its
;;; Lean refinement.  A changed upstream digest must invalidate the retained
;;; downstream Binding before an Agent can write it into the governance slot.
(import :std/test
        (only-in :clan/poo/object .all-slots .cc .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/src/modules/standards/interface
                 poo-flow-standard-digest)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/migration/interface
                 AUHealthcareMigrationFormalModelEvidence
                 AUHealthcareMigrationImpactContract
                 AUHealthcareMigrationRefinementProofEvidence
                 HealthcareStandardMigrationGovernanceInterface))

(export healthcare-standard-migration-proof-impact-test)

(def (file-digest path)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (string->utf8 (call-with-input-file path read-all-as-string))))))

(def healthcare-standard-migration-proof-impact-test
  (test-suite
   "Healthcare Standard migration TLA+ to Lean impact"
   (test-case "retained governance evidence matches exact source bytes"
     (let* ((tla-path
             (.ref AUHealthcareMigrationFormalModelEvidence 'source-path))
            (cfg-path
             (.ref AUHealthcareMigrationFormalModelEvidence 'config-path))
            (lean-path
             (.ref AUHealthcareMigrationRefinementProofEvidence 'source-path))
            (tla-digest (file-digest tla-path))
            (lean-source (call-with-input-file lean-path read-all-as-string)))
       (check-equal?
        tla-digest
        (.ref AUHealthcareMigrationFormalModelEvidence 'source-digest))
       (check-equal?
        (file-digest cfg-path)
        (.ref AUHealthcareMigrationFormalModelEvidence 'config-digest))
       (check-equal?
        (file-digest lean-path)
        (.ref AUHealthcareMigrationRefinementProofEvidence 'source-digest))
       (check-equal?
        (.ref AUHealthcareMigrationRefinementProofEvidence 'tla-source-digest)
        tla-digest)
       (check-equal? (and (string-contains lean-source tla-digest) #t) #t)
       (check-equal?
        (.ref AUHealthcareMigrationImpactContract 'upstream-source-digest)
        tla-digest)
       (check-equal?
        (.ref AUHealthcareMigrationImpactContract 'downstream-source-digest)
        (.ref AUHealthcareMigrationRefinementProofEvidence 'source-digest))
       (check-equal?
        (.all-slots (.ref AUHealthcareMigrationImpactContract 'impact-map))
        '(AINeverGrantsAuthority ReviewRequiresConformance
          CedarPermitRequiresHumanReview CutoverRequiresCedarPermit
          CutoverRequiresCompleteEvidence))))
   (test-case "an Agent cannot write a stale TLA impact Binding"
     (let* ((binding
             (.ref
              (.ref HealthcareStandardMigrationGovernanceInterface 'bindings)
              'impact-contract))
            (stale-payload
             (.cc (.ref binding 'payload) 'upstream-source-digest
                  (poo-flow-standard-digest 'changed-tla-source)))
            (stale-binding (.cc binding 'payload stale-payload)))
       (check-exception
        ((.ref HealthcareStandardMigrationGovernanceInterface
               '.write-governance)
         stale-binding)
        true)))))
