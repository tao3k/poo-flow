;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/walist walist)
        (only-in :std/text/json json-object->string)
        (only-in :poo-flow/src/build-api/process-memory-guard
                 poo-flow-process-memory-guard-run)
        (only-in :poo-flow/src/qualification/runtime-symbol-manifest
                 poo-flow-runtime-symbol-manifest-read-file
                 poo-flow-runtime-symbol-manifest-verify)
        (only-in :poo-flow/src/qualification/release-version-matrix
                 poo-flow-ac11-current-release-version-matrix
                 poo-flow-ac11-release-version-matrix-verify)
        (only-in :poo-flow/src/qualification/cutover-readiness
                 poo-flow-cutover-legacy-guard
                 poo-flow-cutover-external-blocker
                 poo-flow-cutover-readiness-input
                 poo-flow-cutover-readiness-verify))

(def args (cddr (command-line)))
(unless (= (length args) 6)
  (displayln
   "usage: gxi tools/run-ac11-cutover-readiness.ss SOURCE_REVISION AC10_SOURCE_REVISION AC10_MANIFEST_DIGEST SYMBOL_MANIFEST.json ACTUAL_SYMBOLS.txt AUTHORING_AUDIT_ARTIFACT")
  (exit 64))

(def source-revision (list-ref args 0))
(def ac10-source-revision (list-ref args 1))
(def ac10-manifest-digest (list-ref args 2))
(def symbol-manifest-path (list-ref args 3))
(def actual-symbols-path (list-ref args 4))
(def authoring-audit-artifact (list-ref args 5))

(def (read-lines path)
  (call-with-input-file
   path
   (lambda (port)
     (let loop ((lines '()))
       (let (line (read-line port))
         (if (eof-object? line) (reverse lines)
             (loop (cons line lines))))))))

(def symbol-receipt
  (poo-flow-runtime-symbol-manifest-verify
   (poo-flow-runtime-symbol-manifest-read-file symbol-manifest-path)
   (read-lines actual-symbols-path)))
(def version-receipt
  (poo-flow-ac11-release-version-matrix-verify
   (poo-flow-ac11-current-release-version-matrix)))
(def python-process
  (poo-flow-process-memory-guard-run
   'python-no-ctypes (* 2048 1024 1024) 60
   '("uv" "run" "--project" "packages/python-runtime" "pytest"
     "-p" "no:terminal"
     "packages/python-runtime/tests/unit/test_runtime_public_surface.py")))
(def guards
  (list
   (poo-flow-cutover-legacy-guard
    'python-no-ctypes (= (.ref python-process 'exit-code) 0)
    "packages/python-runtime/tests/unit/test_runtime_public_surface.py")
   (poo-flow-cutover-legacy-guard
    'agent-sandbox-zero-consumer #t authoring-audit-artifact)))
(def blocker
  (poo-flow-cutover-external-blocker
   'asp-provider 'missing-asp-source-index-token-owner-v1 #f))
(def readiness
  (poo-flow-cutover-readiness-verify
   (poo-flow-cutover-readiness-input
    source-revision ac10-source-revision ac10-manifest-digest
    source-revision symbol-receipt source-revision version-receipt
    guards blocker #t #f #f)))

(display
 (json-object->string
  (walist
   (list
    (cons "schema" (.ref readiness 'schema))
    (cons "schemaVersion" (.ref readiness 'schema-version))
    (cons "sourceRevision" (.ref readiness 'source-revision))
    (cons "ac10SourceRevision" (.ref readiness 'ac10-source-revision))
    (cons "ac10ManifestDigest" (.ref readiness 'ac10-manifest-digest))
    (cons "ready" (.ref readiness 'ready?))
    (cons "decisionRequired" (.ref readiness 'decision-required?))
    (cons "abiV1Frozen" (.ref readiness 'abi-v1-frozen?))
    (cons "deletionAuthorized" (.ref readiness 'deletion-authorized?))
    (cons "symbolManifestAccepted" (.ref symbol-receipt 'accepted?))
    (cons "versionMatrixAccepted" (.ref version-receipt 'accepted?))
    (cons "pythonNoCtypesAccepted" (= (.ref python-process 'exit-code) 0))
    (cons "externalBlocker"
          "asp-provider:missing-asp-source-index-token-owner-v1")
    (cons "diagnostics"
          (map symbol->string (.ref readiness 'diagnostics)))))))
(newline)
(exit (if (.ref readiness 'ready?) 0 1))
