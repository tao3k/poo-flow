;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/walist walist)
        (only-in :std/text/json json-object->string)
        :poo-flow/src/qualification/runtime-symbol-manifest)

(def args (cddr (command-line)))
(unless (= (length args) 2)
  (displayln "usage: gxi tools/validate-runtime-v0-symbol-surface.ss MANIFEST.json ACTUAL.txt")
  (exit 64))

(def (read-lines path)
  (call-with-input-file
   path
   (lambda (port)
     (let loop ((lines '()))
       (let (line (read-line port))
         (if (eof-object? line) (reverse lines)
             (loop (cons line lines))))))))

(def manifest (poo-flow-runtime-symbol-manifest-read-file (car args)))
(def receipt
  (poo-flow-runtime-symbol-manifest-verify manifest (read-lines (cadr args))))

(display
 (json-object->string
  (walist
   (list
    (cons "schema" (.ref receipt 'schema))
    (cons "schemaVersion" (.ref receipt 'schema-version))
    (cons "accepted" (.ref receipt 'accepted?))
    (cons "abi" (.ref receipt 'abi))
    (cons "expectedSymbols" (.ref receipt 'expected-symbols))
    (cons "actualSymbols" (.ref receipt 'actual-symbols))
    (cons "forbiddenSymbols" (.ref receipt 'forbidden-symbols))
    (cons "diagnostics"
          (map symbol->string (.ref receipt 'diagnostics)))))))
(newline)
(exit (if (.ref receipt 'accepted?) 0 1))
