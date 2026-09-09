;;; -*- Gerbil -*-
;;; Boundary: public composition-analysis feature interface.
;;; Invariant: lineage and proof projection remain pure module-system data.

(import "lineage.ss"
        "proof-facts.ss")

(export (import: "lineage.ss")
        (import: "proof-facts.ss"))
