;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :std/misc/uuid random-uuid uuid->string)
        (only-in :clan/poo/object .o .ref)
        (only-in "qualify.ss" fingerprint unchanged! successful-check-count
                 stream-process-log write-module-manifest!))
(export combination-qualification-io-test)
(def (with-owned-file inspect)
  (let* ((directory ".data/qualification/poo-method-combination/io-fixtures")
         (path (path-expand (uuid->string (random-uuid)) directory)))
    (create-directory* directory)
    (when (file-exists? path) (error "Fixture path already exists" path))
    (unwind-protect (inspect path) (when (file-exists? path) (delete-file path)))))
(def (write-fixture path text)
  (call-with-output-file path (lambda (port) (display text port))))
(def combination-qualification-io-test
  (test-suite "module: native qualification I/O boundaries"
    (test-case "test log bytes go to both explicit log and console, never printed port objects"
      (let* ((input (open-input-string "... 7 checks OK\n... 3 checks OK\nOK\n"))
             (log (open-output-string)) (console (open-output-string))
             (count (parameterize ((current-output-port console)) (stream-process-log input log)))
             ;; get-output-string drains these native ports; capture each once.
             (log-text (get-output-string log)) (console-text (get-output-string console)))
        (check-equal? count 10)
        (check-equal? log-text "... 7 checks OK\n... 3 checks OK\nOK\n")
        (check-equal? console-text log-text)
        (check-equal? (successful-check-count "... 0 checks OK") 0)
        (check-equal? (successful-check-count "... All tests OK") 0)))
    (test-case "module manifest is nonempty and file-local, with exact main and implementation identities"
      (with-owned-file
        (lambda (path)
          (let (console (open-output-string))
            (parameterize ((current-output-port console))
              (write-module-manifest! path "/library"
                (list (.o path: "/library/poo-flow/example.o1")
                      (.o path: "/library/poo-flow/example~0.o1"))))
            (check-equal? (get-output-string console) "")
            (call-with-input-file path
              (lambda (port)
                (check-equal? (read-line port) "poo-flow/example")
                (check-equal? (read-line port) "poo-flow/example~0")
                (check-equal? (eof-object? (read-line port)) #t)))))))
    (test-case "SHA-256 snapshots are eager, algorithm-tagged and reject subsequent content drift"
      (with-owned-file
        (lambda (path)
          (write-fixture path "abc")
          (let (value (fingerprint path))
            ;; Change the file BEFORE demanding any fingerprint slots.
            (write-fixture path "def")
            (check-equal? (.ref value 'path) path)
            (check-equal? (.ref value 'algorithm) 'sha256)
            (check-equal? (.ref value 'purpose) 'content-integrity)
            (check-equal? (.ref value 'sha256) "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
            (check-exception (unchanged! (list value)) (lambda (_) #t))))))))
