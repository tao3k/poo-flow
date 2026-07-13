#!/usr/bin/env gxi
(import :std/text/hex
        :poo-flow/src/proof/generated/proof-case-vector-v1
        :poo-flow/src/proof/proof-case-vector
        :poo-flow/t/scenarios/proof-case-vector-test)

(let (vector (make-u8vector poo-flow-proof-case-vector-size 0))
  (poo-flow-proof-case-vector-write! canonical-proof-case vector)
  (display "vector=")
  (display (hex-encode vector))
  (newline)
  (display "digest=")
  (display (poo-flow-proof-case-vector-digest vector))
  (newline))
