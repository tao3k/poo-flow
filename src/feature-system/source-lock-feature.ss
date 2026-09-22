;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: the reusable Sources Lock Feature.  Module-owned source.lock.ss
;;; files are generated values; this implementation never owns their content.

(import (only-in :clan/poo/object .def .def! .o .ref object?)
        (only-in :std/crypto/digest sha256)
        (only-in :std/hash/misc hash-key? hash-put! hash-ref)
        (only-in :std/encoding/hex hex-encode)
        :poo-flow/src/feature-system/model)

(export +sources-lock-feature-id+
        sources-lock-feature
        SourceReference.
        SourceLockEntry.
        SourcesLock.
        source-lock-payload-digest
        source-lock-freeze
        sources-lock-value
        sources-lock-freeze
        sources-lock?
        sources-lock-ref
        source-lock-verify-payload
        require-source-lock-payload
        write-sources-lock-module)

(def +sources-lock-feature-id+ 'sources-lock)

(def sources-lock-feature
  (feature-descriptor
   (feature-spec-compose
    (feature-descriptor-base +sources-lock-feature-id+ 'poo-flow)
    (feature-schema-version 1)
    (feature-category 'source-integrity))))

;;; Public declaration and generated lock prototypes intentionally read like
;;; data.  Their methods are inherited from SourcesLock. below.
(.def SourceReference.
  (kind 'poo-flow.source-reference.v1)
  (identity #f) (path #f) (canonical-uri #f) (exact-version #f)
  (representation #f) (metadata '()))

(.def SourceLockEntry.
  (kind 'poo-flow.source-lock-entry.v1)
  (identity #f) (path #f) (canonical-uri #f) (exact-version #f)
  (representation #f) (digest #f) (size-bytes #f) (metadata '()))

(.def SourcesLock.
  (kind 'poo-flow.sources-lock.v1)
  (schema-version 1)
  (feature-id +sources-lock-feature-id+)
  (lock-id #f) (revision #f) (digest #f) (entries '()) (metadata '())
  (index #f) (entry-count 0) (byte-count 0) (computed-digest #f))

(def (source-lock-payload-bytes payload)
  (cond
   ((string? payload) (string->utf8 payload))
   ((u8vector? payload) payload)
   (else (error "source lock payload must be text or a bytevector" payload))))

(def (source-lock-payload-digest payload)
  (string-append
   "sha256:"
   (hex-encode (sha256 (source-lock-payload-bytes payload)))))

(def (source-lock-entry-row entry)
  (list (.ref entry 'identity) (.ref entry 'path)
        (.ref entry 'canonical-uri) (.ref entry 'exact-version)
        (.ref entry 'representation) (.ref entry 'digest)
        (.ref entry 'size-bytes)))

(def (source-lock-content-digest lock-id-value revision-value entry-values)
  (source-lock-payload-digest
   (call-with-output-string
    (lambda (port)
      (write (list 'poo-flow.sources-lock.v1 lock-id-value revision-value
                   (map source-lock-entry-row entry-values))
             port)))))

(def (source-lock-index entries)
  ;; Gerbil's native hash table owns string value hashing for serialized
  ;; identities; keep the std hash accessors and table implementation paired.
  (let (index (make-hash-table))
    (for-each
     (lambda (entry)
       (let (identity (.ref entry 'identity))
         (when (hash-key? index identity)
           (error "duplicate source lock identity" identity))
         (hash-put! index identity entry)))
     entries)
    index))

(.def! SourcesLock. .valid? (digest computed-digest)
  (and (string? digest) (string=? digest computed-digest)))
(.def! SourcesLock. .find (index)
  (lambda (identity) (hash-ref index identity #f)))
(.def! SourcesLock. .verify (.valid? .find lock-id digest)
  (lambda (identity payload)
    (unless .valid?
      (error "sources lock digest mismatch" lock-id digest))
    (let (entry (.find identity))
      (unless entry
        (error "source identity is absent from sources lock" lock-id identity))
      (let* ((lock-id-value lock-id)
             (lock-digest-value digest)
             (source-identity-value identity)
             (source-path-value (.ref entry 'path))
             (expected-digest-value (.ref entry 'digest))
             (actual-digest-value (source-lock-payload-digest payload))
             (expected-size-value (.ref entry 'size-bytes))
             (actual-size-value
              (u8vector-length (source-lock-payload-bytes payload)))
             (verified-value
              (and (string=? actual-digest-value expected-digest-value)
                   (= actual-size-value expected-size-value))))
        (.o kind: 'poo-flow.source-lock-verification-receipt.v1
            lock-id: lock-id-value lock-digest: lock-digest-value
            source-identity: source-identity-value
            source-path: source-path-value
            expected-digest: expected-digest-value
            actual-digest: actual-digest-value
            expected-size-bytes: expected-size-value
            actual-size-bytes: actual-size-value
            valid?: verified-value)))))
(.def! SourcesLock. .require (.verify)
  (lambda (identity payload)
    (let (receipt (.verify identity payload))
      (unless (.ref receipt 'valid?)
        (error "source lock content identity mismatch" receipt))
      receipt)))

(def (source-lock-freeze source-value read-source-value)
  (let* ((path-value (.ref source-value 'path))
         (payload-value (read-source-value path-value)))
    (.o (:: @ SourceLockEntry.)
        identity: (.ref source-value 'identity) path: path-value
        canonical-uri: (.ref source-value 'canonical-uri)
        exact-version: (.ref source-value 'exact-version)
        representation: (.ref source-value 'representation)
        digest: (source-lock-payload-digest payload-value)
        size-bytes: (u8vector-length (source-lock-payload-bytes payload-value))
        metadata: (.ref source-value 'metadata))))

;;; Discovery order belongs to the caller and may vary by filesystem.  Lock
;;; identity and generated source instead use one canonical identity order.
(def (source-lock-entry<? left right)
  (string<? (.ref left 'identity) (.ref right 'identity)))

(def (sources-lock-value lock-id-value revision-value digest-value entry-values
                         (metadata-value '()))
  (let* ((canonical-entries
          (list-sort source-lock-entry<? (append entry-values '())))
         (index-value (source-lock-index canonical-entries))
         (entry-count-value (length canonical-entries))
         (byte-count-value
          (foldl
           (lambda (entry total) (+ total (.ref entry 'size-bytes)))
           0
           canonical-entries))
         (computed-digest-value
          (source-lock-content-digest
           lock-id-value revision-value canonical-entries))
         (effective-digest-value
          (or digest-value computed-digest-value)))
    (.o (:: @ SourcesLock.)
        lock-id: lock-id-value
        revision: revision-value
        digest: effective-digest-value
        entries: canonical-entries
        metadata: metadata-value
        index: index-value
        entry-count: entry-count-value
        byte-count: byte-count-value
        computed-digest: computed-digest-value)))

(def (sources-lock-freeze lock-id-value revision-value source-values
                          read-source-value (metadata-value '()))
  (sources-lock-value
   lock-id-value revision-value #f
   (map (lambda (source-value)
          (source-lock-freeze source-value read-source-value))
        source-values)
   metadata-value))

(def (sources-lock? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (and (eq? (.ref value 'kind) 'poo-flow.sources-lock.v1)
               (.ref value '.valid?))))))

(def (sources-lock-ref lock identity)
  ((.ref lock '.find) identity))

(def (source-lock-verify-payload lock identity payload)
  ((.ref lock '.verify) identity payload))

(def (require-source-lock-payload lock identity payload)
  ((.ref lock '.require) identity payload))

(def (write-lock-value port value)
  (write value port))

(def (write-source-lock-entry port entry prefix)
  (display prefix port)
  (display "(.o (:: @ SourceLockEntry.)\n" port)
  (for-each
   (lambda (field)
     (display "           " port)
     (display (symbol->string (car field)) port)
     (display ": " port)
     (when (memq (car field) '(representation metadata))
       (display "'" port))
     (write-lock-value port (.ref entry (cdr field)))
     (newline port))
   '((identity . identity) (path . path) (canonical-uri . canonical-uri)
     (exact-version . exact-version) (representation . representation)
     (digest . digest) (size-bytes . size-bytes) (metadata . metadata)))
  (display "           )" port))

(def (write-sources-lock-module port binding lock)
  (display ";;; -*- Gerbil -*-\n" port)
  (display ";;; @generated by POO Flow Sources Lock Feature; DO NOT EDIT.\n" port)
  (display ";;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors\n;;;\n" port)
  (display ";;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later\n\n" port)
  (display ";;; Included by sources.ss after the public Feature prototypes.\n\n" port)
  (display "(def " port)
  (write-lock-value port binding)
  (display "\n  (sources-lock-value\n      " port)
  (write-lock-value port (.ref lock 'lock-id))
  (display "\n      " port)
  (write-lock-value port (.ref lock 'revision))
  (display "\n      " port)
  (write-lock-value port (.ref lock 'digest))
  (display "\n      (list\n" port)
  (let loop ((entries (.ref lock 'entries)) (first? #t))
    (unless (null? entries)
      (write-source-lock-entry port (car entries)
                               (if first? "       " "\n       "))
      (loop (cdr entries) #f)))
  (display ")\n      '" port)
  (write-lock-value port (.ref lock 'metadata))
  (display "))\n" port))
