;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Source keys are host-configured trust anchors. Authentication establishes
;;; an issuer's scoped assertion, not physical clock truth or action authority.
(import (only-in :clan/poo/object .ref)
        (only-in :std/list/list every)
        (only-in :std/crypto/digest sha256)
        (only-in :std/crypto/hmac hmac-sha256)
        (only-in :std/encoding/hex hex-encode)
        "types.ss" "funs.ss" "authority-types.ss" "authority-objects.ss"
        "watermark-funs.ss")
(export poo-flow-temporal-source-attest poo-flow-temporal-source-authenticate
        poo-flow-temporal-clock-conversion poo-flow-temporal-clock-conversion-replay
        poo-flow-temporal-compare/converted poo-flow-temporal-watermark-verified-cut-claim
        poo-flow-temporal-watermark-late-disposition poo-flow-temporal-event-source-digest)
(def (digest v) (string-append "sha256:" (hex-encode (sha256 (string->utf8 (object->string v))))))
(def (assertion-bytes id authority predicate body start end)
  (string->utf8 (object->string
                (list 'poo-flow.temporal.source-assertion.v1 id (.ref authority 'issuer)
                      (.ref authority 'source) (.ref authority 'key-identity) (.ref authority 'admission-domain)
                      predicate body start end))))
(def (poo-flow-temporal-source-attest authority id predicate body start end)
  (unless (poo-flow-temporal-source-authority? authority) (error "invalid configured source authority"))
  (poo-flow-temporal-source-assertion-value
   id (.ref authority 'issuer) (.ref authority 'source) (.ref authority 'key-identity)
   (.ref authority 'admission-domain) predicate body start end
   (hmac-sha256 (.ref authority 'verification-key) (assertion-bytes id authority predicate body start end))))
(def (same-signature? a b)
  (and (= (u8vector-length a) (u8vector-length b))
       (let loop ((i 0) (difference 0))
         (if (= i (u8vector-length a)) (= difference 0)
           (loop (+ i 1) (bitwise-ior difference (bitwise-xor (u8vector-ref a i) (u8vector-ref b i))))))))
(def (poo-flow-temporal-source-authenticate authority assertion predicate body as-of)
  (and (poo-flow-temporal-source-authority? authority) (poo-flow-temporal-source-assertion? assertion)
       (poo-flow-temporal-instant? as-of) (eq? (.ref as-of 'modality) 'observed)
       (every (lambda (slot) (equal? (.ref authority slot) (.ref assertion slot)))
              '(issuer source key-identity admission-domain))
       (equal? (.ref as-of 'domain-identity) (.ref authority 'admission-domain))
       (eq? predicate (.ref assertion 'predicate)) (equal? body (.ref assertion 'body-digest))
       (<= (.ref assertion 'not-before) (.ref as-of 'coordinate))
       (< (.ref as-of 'coordinate) (.ref assertion 'expires))
       (same-signature?
        (.ref assertion 'signature)
        (hmac-sha256 (.ref authority 'verification-key)
                     (assertion-bytes (.ref assertion 'identity) authority predicate body
                                      (.ref assertion 'not-before) (.ref assertion 'expires))))))
(def (poo-flow-temporal-clock-conversion id source from to numerator denominator offset radius first last)
  (unless (and (exact-integer? numerator) (> numerator 0) (exact-integer? denominator) (> denominator 0))
    (error "clock conversion slope must be positive and exact"))
  (let* ((divisor (gcd numerator denominator)) (num (quotient numerator divisor)) (den (quotient denominator divisor))
         (row (list 'poo-flow.temporal.clock-conversion.v1 id source from to num den offset radius first last)))
    (poo-flow-temporal-clock-conversion-value id source from to num den offset radius first last (digest row))))
(def (poo-flow-temporal-clock-conversion-replay conversion)
  (unless (poo-flow-temporal-clock-conversion? conversion) (error "invalid clock conversion"))
  (let (canonical (apply poo-flow-temporal-clock-conversion
                   (map (lambda (s) (.ref conversion s))
                        '(identity source source-domain target-domain numerator denominator offset radius first last))))
    (unless (equal? (.ref canonical 'semantic-digest) (.ref conversion 'semantic-digest))
      (error "clock conversion digest mismatch")) canonical))
(def (poo-flow-temporal-compare/converted left right conversion assertion authority as-of)
  (unless (and (poo-flow-temporal-instant? left) (poo-flow-temporal-instant? right)) (error "invalid converted comparison"))
  (if (equal? (.ref left 'domain-identity) (.ref right 'domain-identity))
    (poo-flow-temporal-compare left right)
    (let (conversion (poo-flow-temporal-clock-conversion-replay conversion))
      (cond
       ((not (and (equal? (.ref left 'domain-identity) (.ref conversion 'source-domain))
                  (equal? (.ref right 'domain-identity) (.ref conversion 'target-domain)))) 'incomparable)
       ((not (and (eq? (.ref left 'modality) 'observed) (eq? (.ref right 'modality) 'observed))) 'unknown)
       ((not (and (poo-flow-temporal-source-authority? authority)
                  (equal? (.ref authority 'source) (.ref conversion 'source))
                  (poo-flow-temporal-source-authenticate authority assertion 'clock-conversion
                   (.ref conversion 'semantic-digest) as-of))) 'rejected)
       ((not (<= (.ref conversion 'first) (.ref left 'coordinate) (.ref conversion 'last))) 'outside-scope)
       (else
        (let* ((mapped (+ (* (.ref left 'coordinate) (/ (.ref conversion 'numerator) (.ref conversion 'denominator)))
                          (.ref conversion 'offset)))
               (lower (- (floor mapped) (.ref conversion 'radius)))
               (upper (+ (ceiling mapped) (.ref conversion 'radius))) (boundary (.ref right 'coordinate)))
          (cond ((< lower 0) 'rejected) ((< upper boundary) 'before) ((> lower boundary) 'after)
                ((= lower upper boundary) 'equal) (else 'unknown))))))))
(def (poo-flow-temporal-watermark-verified-cut-claim watermark source partition sequence boundary assertion authority as-of)
  (poo-flow-temporal-watermark-replay watermark)
  (if (and (poo-flow-temporal-source-authority? authority)
           (equal? (.ref authority 'source) (.ref watermark 'source-identity))
           (equal? (.ref authority 'issuer) (.ref watermark 'issuer-identity))
           (poo-flow-temporal-source-assertion? assertion)
           (equal? (.ref assertion 'identity) (.ref watermark 'coverage-identity))
           (poo-flow-temporal-source-authenticate authority assertion 'watermark-completeness
            (.ref watermark 'semantic-digest) as-of))
    (let (status (poo-flow-temporal-watermark-cut-claim watermark source partition sequence boundary))
      (if (eq? status 'coverage-claimed) 'source-coverage-verified status)) 'rejected))
(def (poo-flow-temporal-event-source-digest source partition sequence instant)
  (unless (and (string? source) (string? partition) (exact-integer? sequence) (>= sequence 0)
               (poo-flow-temporal-instant? instant)) (error "invalid source event digest"))
  (digest (list 'poo-flow.temporal.source-event.v1 source partition sequence
                (map (lambda (s) (.ref instant s)) '(identity domain-identity coordinate provenance-identity modality)))))
(def (poo-flow-temporal-watermark-late-disposition watermark source partition sequence event
      coverage event-assertion authority as-of)
  (poo-flow-temporal-watermark-replay watermark)
  (cond
   ((not (and (poo-flow-temporal-source-authority? authority)
              (poo-flow-temporal-source-assertion? coverage)
              (equal? (.ref authority 'source) (.ref watermark 'source-identity))
              (equal? (.ref authority 'issuer) (.ref watermark 'issuer-identity))
              (equal? (.ref coverage 'identity) (.ref watermark 'coverage-identity))
              (poo-flow-temporal-source-authenticate authority coverage 'watermark-completeness
               (.ref watermark 'semantic-digest) as-of)
              (poo-flow-temporal-source-authenticate authority event-assertion 'event-observation
               (poo-flow-temporal-event-source-digest source partition sequence event) as-of))) 'rejected)
   ((not (and (equal? source (.ref watermark 'source-identity))
              (equal? source (.ref authority 'source))
              (equal? partition (.ref watermark 'partition-identity)))) 'outside-scope)
   ((not (eq? (.ref event 'modality) 'observed)) 'unknown)
   (else
    (let (bound (.ref (.ref watermark 'time-observation) 'earliest))
      (cond ((not (equal? (.ref bound 'domain-identity) (.ref event 'domain-identity))) 'incomparable)
            ((< (.ref event 'coordinate) (.ref bound 'coordinate)) 'reevaluate-cut)
            (else 'not-before-watermark))))))
