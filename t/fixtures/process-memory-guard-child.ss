;;; -*- Gerbil -*-
(import :gerbil/gambit)

(def args (cddr (command-line)))
(case (and (pair? args) (string->symbol (car args)))
  ((complete) (thread-sleep! 0.05) (exit 0))
  ((allocate)
   (let (payload (make-u8vector (* 256 1024 1024) 1))
     (u8vector-set! payload 0 2)
     (thread-sleep! 5)
     (exit (u8vector-ref payload 0))))
  ((sleep) (thread-sleep! 5) (exit 0))
  (else (exit 64)))
