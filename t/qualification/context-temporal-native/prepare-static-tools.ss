;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Materialize the installed SDK's two test-tool objects in the user artifact
;;; root. The SDK stays read-only; source and compiler come from the same SDK.
(import (only-in :std/misc/process run-process))
(let* ((sdk-static (path-expand "lib/static" (gerbil-home)))
       (user-static (path-expand "lib/static" (gerbil-path)))
       (compiler (getenv "GERBIL_GSC" (path-expand "bin/gsc" (gerbil-home)))))
  (when (equal? sdk-static user-static) (error "Static test artifacts must have a separate user root"))
  (create-directory* user-static)
  (for-each (lambda (module)
    (let* ((filename (string-append "gerbil__tools__" module ".scm"))
           (source (path-expand filename sdk-static))
           (target (path-expand filename user-static)))
      (unless (file-exists? source) (error "Installed SDK lacks static test tool source" source))
      (when (file-exists? target) (delete-file target))
      (copy-file source target)
      ;; The official executable linker reads the C metadata as well as the
      ;; object. Compile C explicitly so -obj does not discard that metadata.
      (run-process [compiler "-c" target])
      (run-process [compiler "-obj" "-cc-options"
        (string-append "-I " sdk-static " -I " user-static)
        (string-append (path-strip-extension target) ".c")])
      (displayln "STATIC-TOOL-OK " module) (force-output))) '("env" "gxtest")))
