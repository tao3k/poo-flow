;;; -*- Gerbil -*-
;;; Boundary: declarative Building Framework extension for guarded gxi stages.

(export define-guarded-gxi-stage)

(import :gslph/src/building/facade
        :clan/poo/object
        :poo-flow/src/build-api/process-memory-guard)

(defrules define-guarded-gxi-stage ()
  ((_ binding
      label: label
      file: file
      max-rss-mib: max-rss-mib
      timeout-seconds: timeout-seconds)
   (def binding
     (make-build-stage
      label
      'guarded-gxi-test
      file
      (lambda (_stage _context) #f)
      (lambda (_stage _context)
        (poo-flow-process-memory-guard-run
         label (* max-rss-mib 1024 1024) timeout-seconds
         (list "gxi" file)))
      (lambda (_stage _context receipt)
        (unless (= 0 (.ref receipt 'exit-code))
          (error "guarded gxi build stage failed"
                 (poo-flow-process-memory-guard-receipt->alist receipt))))
      "Scheme-owned gxi RSS and elapsed-time guard"))))
