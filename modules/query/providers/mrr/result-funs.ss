;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Structural projection only: the native Rust receipt is not verified here.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/query/types poo-flow-query?)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-source-content-identity)
        (only-in "result-types.ss"
                 poo-flow-mrr-result-admission-projection?)
        (only-in "result-objects.ss"
                 poo-flow-mrr-result-admission-projection-value))
(export poo-flow-mrr-result-admission-projection
        poo-flow-mrr-result-admission-projection-replay)

(def +mrr-result-schema+ "mrr.query-result-admission.v1")
(def +mrr-result-prefix+ "mrr.query-result-admission.v1:")
(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (hex-char? character)
  (or (char<=? #\0 character #\9)
      (char<=? #\a character #\f)))
(def (sha256-text? value)
  (and (string? value) (= (string-length value) 71)
       (string=? (substring value 0 7) "sha256:")
       (every hex-char? (string->list (substring value 7 71)))))
(def (digest datum)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (string->utf8
             (call-with-output-string
              (lambda (port) (write datum port))))))))

(def (poo-flow-mrr-result-admission-projection
      id query binding generation relation entity snapshot native-result count)
  (unless (and (text? id) (poo-flow-query? query)
               (every sha256-text?
                      (list binding relation entity snapshot native-result))
               (exact-integer? generation) (>= generation 0)
               (exact-integer? count) (>= count 0))
    (error "invalid native MRR result admission projection"))
  (let* ((source (poo-flow-query-source-content-identity query))
         (result (string-append +mrr-result-prefix+ native-result))
         (semantic
          (digest (list 'poo-flow.mrr-result-projection.v1 id
                        +mrr-result-schema+ source binding generation
                        relation entity snapshot result count))))
    (poo-flow-mrr-result-admission-projection-value
     id semantic +mrr-result-schema+ source binding generation
     relation entity snapshot result count)))

(def (poo-flow-mrr-result-admission-projection-replay projection query)
  (unless (and (poo-flow-mrr-result-admission-projection? projection)
               (poo-flow-query? query)
               (equal? (.ref projection 'native-schema)
                       +mrr-result-schema+)
               (string? (.ref projection 'result-digest))
               (> (string-length (.ref projection 'result-digest))
                  (string-length +mrr-result-prefix+))
               (string=?
                (substring (.ref projection 'result-digest)
                           0 (string-length +mrr-result-prefix+))
                +mrr-result-prefix+))
    (error "invalid native MRR projection replay"))
  (let (replayed
        (poo-flow-mrr-result-admission-projection
         (.ref projection 'identity) query
         (.ref projection 'query-binding-digest)
         (.ref projection 'generation)
         (.ref projection 'relation-catalog-digest)
         (.ref projection 'entity-catalog-digest)
         (.ref projection 'snapshot-digest)
         (substring (.ref projection 'result-digest)
                    (string-length +mrr-result-prefix+)
                    (string-length (.ref projection 'result-digest)))
         (.ref projection 'result-count)))
    (unless (equal? (.ref projection 'semantic-digest)
                    (.ref replayed 'semantic-digest))
      (error "native MRR projection digest mismatch"))
    replayed))
