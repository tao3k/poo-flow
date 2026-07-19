;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/walist walist)
        (only-in :std/text/json json-object->string)
        :poo-flow/src/qualification/release-version-matrix)

(def args (cddr (command-line)))
(unless (= (length args) 1)
  (displayln "usage: gxi tools/run-ac11-release-version-matrix.ss SOURCE_REVISION")
  (exit 64))

(def matrix (poo-flow-ac11-current-release-version-matrix))
(def receipt (poo-flow-ac11-release-version-matrix-verify matrix))
(def runtime-abi (poo-flow-release-version-matrix-runtime-abi matrix))
(def proof-vector (poo-flow-release-version-matrix-proof-vector matrix))

(display
 (json-object->string
  (walist
   (list
    (cons "schema" "poo-flow.release-version-matrix.v1")
    (cons "schemaVersion" 1)
    (cons "sourceRevision" (car args))
    (cons "bundleSchema"
          (symbol->string
           (poo-flow-release-version-matrix-bundle-schema matrix)))
    (cons "runtimeAbi"
          (walist
           (list (cons "major" (.ref runtime-abi 'major))
                 (cons "minor" (.ref runtime-abi 'minor)))))
    (cons "proofVector"
          (walist
           (list
            (cons "version" (.ref proof-vector 'version))
            (cons "schemaFingerprint"
                  (.ref proof-vector 'schema-fingerprint))
            (cons "vectorDomain" (.ref proof-vector 'vector-domain))
            (cons "theoremSetDomain"
                  (.ref proof-vector 'theorem-set-domain)))))
    (cons "evidenceAssurance"
          (symbol->string
           (poo-flow-release-version-matrix-assurance-schema matrix)))
    (cons "ownerArtifacts"
          (map symbol->string
               (poo-flow-release-version-matrix-owner-artifacts matrix)))
    (cons "abiV1Frozen" (.ref receipt 'abi-v1-frozen?))
    (cons "decisionRequired" (.ref receipt 'decision-required?))
    (cons "accepted" (.ref receipt 'accepted?))))))
(newline)
(exit (if (.ref receipt 'accepted?) 0 1))
