;;; -*- Gerbil -*-
;;; Boundary: public Loader diagnostics feature interface.
;;; Invariant: diagnostic records and doctor projection never activate modules.

(import "records.ss"
        "doctor.ss")

(export (import: "records.ss")
        (import: "doctor.ss"))
