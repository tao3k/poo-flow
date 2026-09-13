;;; -*- Gerbil -*-
;;; Boundary: loop-engine module configuration entrypoint.
;;; Invariant: the public contract is owned by interface.ss; loading this file
;;; does not move loop behavior back into module-system mechanisms.

(import "interface.ss")

(export (import: "interface.ss"))
