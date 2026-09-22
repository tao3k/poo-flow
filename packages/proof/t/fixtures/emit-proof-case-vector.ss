#!/usr/bin/env gxi
;;; Proof fixture owner: emit the canonical proof vector and its integrity
;;; digest for the cross-language differential gate.

(import (only-in :std/text/hex hex-encode)
        :poo-flow/src/proof/generated/proof-case-vector-v1
        :poo-flow/src/proof/proof-case-vector
        :poo-flow/t/scenarios/proof-case-vector-test)

(export main)

;;; Emission boundary: the canonical test case is projected once into a fresh
;;; byte vector, then both bytes and digest are written to standard output.
;; : (-> Unit Void)
(def (main)
  (let (vector (make-u8vector poo-flow-proof-case-vector-size 0))
    (poo-flow-proof-case-vector-write! canonical-proof-case vector)
    (display "vector=")
    (display (hex-encode vector))
    (newline)
    (display "digest=")
    (display (poo-flow-proof-case-vector-digest vector))
    (newline)))
