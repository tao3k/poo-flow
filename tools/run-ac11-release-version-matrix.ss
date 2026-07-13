;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        :poo-flow/src/qualification/release-version-matrix)

(def matrix (poo-flow-ac11-current-release-version-matrix))
(def receipt (poo-flow-ac11-release-version-matrix-verify matrix))
(def runtime-abi (poo-flow-release-version-matrix-runtime-abi matrix))
(def proof-vector (poo-flow-release-version-matrix-proof-vector matrix))

(write
 (list
  (cons 'schema 'poo-flow.release-version-matrix-receipt.v1)
  (cons 'accepted? (.ref receipt 'accepted?))
  (cons 'bundle-schema
        (poo-flow-release-version-matrix-bundle-schema matrix))
  (cons 'runtime-abi
        (cons (.ref runtime-abi 'major) (.ref runtime-abi 'minor)))
  (cons 'proof-vector-version (.ref proof-vector 'version))
  (cons 'proof-schema-fingerprint (.ref proof-vector 'schema-fingerprint))
  (cons 'assurance-schema
        (poo-flow-release-version-matrix-assurance-schema matrix))
  (cons 'abi-v1-frozen? (.ref receipt 'abi-v1-frozen?))
  (cons 'decision-required? (.ref receipt 'decision-required?))))
(newline)
(exit (if (.ref receipt 'accepted?) 0 1))
