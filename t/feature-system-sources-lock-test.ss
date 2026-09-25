;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         (only-in :clan/poo/object .o .ref)
        (only-in :std/error Error?)
        (only-in :std/test check-equal? check-exception test-suite)
        :poo-flow/src/feature-system/interface)

(export feature-system-sources-lock-test)

(def locked-payload "locked source payload")

(def locked-source-reference
  (.o (:: @ SourceReference.)
      identity: "example/source"
      path: "sources/example.txt"
      canonical-uri: "https://example.test/source"
      exact-version: "2026-09-17"
      representation: 'text))

(def example-sources-lock
  (sources-lock-freeze
   "example/sources" "2026-09-17" (list locked-source-reference)
   (lambda (_path) locked-payload)))

(def feature-system-sources-lock-test
  (test-suite
   "POO-native Sources Lock Feature"
   (poo-flow-test-case
    "publishes one reusable Feature and an indexed immutable lock"
    (check-equal? (.ref sources-lock-feature 'feature-id) 'sources-lock)
    (check-equal? (sources-lock? example-sources-lock) #t)
    (check-equal? (.ref example-sources-lock 'entry-count) 1)
    (check-equal? (.ref example-sources-lock 'byte-count)
                  (u8vector-length (string->utf8 locked-payload)))
    (check-equal? (.ref (sources-lock-ref
                         example-sources-lock "example/source")
                        'path)
                  "sources/example.txt"))
   (poo-flow-test-case
    "verifies bytes against both digest and byte count"
    (let (receipt
          (source-lock-verify-payload
           example-sources-lock "example/source" locked-payload))
      (check-equal? (.ref receipt 'valid?) #t)
      (check-equal? (.ref receipt 'lock-digest)
                    (.ref example-sources-lock 'digest)))
    (check-equal?
     (.ref (source-lock-verify-payload
            example-sources-lock "example/source" "changed")
           'valid?)
     #f)
    (check-exception
     (require-source-lock-payload
      example-sources-lock "example/source" "changed")
     Error?))
   (poo-flow-test-case
    "rejects duplicate identities while constructing its private index"
    (check-exception
     (let (_duplicate-lock
          (sources-lock-freeze
           "duplicate/id" "1"
           (list locked-source-reference locked-source-reference)
           (lambda (_path) locked-payload)))
       #f)
     Error?))
   (poo-flow-test-case
    "canonicalizes discovery order into one digest and generated module"
    (let* ((second
            (.o (:: @ SourceReference.)
                identity: "another/source"
                path: "sources/another.txt"
                canonical-uri: "https://example.test/another"
                exact-version: "1"
                representation: 'text))
           (read-source (lambda (path) (string-append "payload:" path)))
           (left
            (sources-lock-freeze
             "example/ordered" "1"
             (list locked-source-reference second) read-source))
           (right
            (sources-lock-freeze
             "example/ordered" "1"
             (list second locked-source-reference) read-source))
           (left-source
            (call-with-output-string
             (lambda (port)
               (write-sources-lock-module port 'example-sources left))))
           (right-source
            (call-with-output-string
             (lambda (port)
               (write-sources-lock-module port 'example-sources right)))))
      (check-equal? (.ref left 'digest) (.ref right 'digest))
      (check-equal?
       (map (lambda (entry) (.ref entry 'identity)) (.ref left 'entries))
       '("another/source" "example/source"))
      (check-equal? left-source right-source)))
   (poo-flow-test-case
    "locks native bytevector sources without a text conversion boundary"
    (let* ((payload #u8(0 1 2 127 128 255))
           (source
            (.o (:: @ SourceReference.)
                identity: "example/binary"
                path: "sources/example.bin"
                canonical-uri: "https://example.test/example.bin"
                exact-version: "1"
                representation: 'binary))
           (lock
            (sources-lock-freeze
             "example/binary-sources" "1" (list source)
             (lambda (_path) payload))))
      (check-equal? (.ref lock 'byte-count) 6)
      (check-equal?
       (.ref (source-lock-verify-payload lock "example/binary" payload)
             'valid?)
       #t)))))
