;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Explicit verification boundary. The configured operation is host-trusted;
;;; submitted POO facts and their claimed verification flags are not.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/hash/misc hash-remove!))
(export poo-flow-verification-adapter poo-flow-verify poo-flow-verification-valid?
        poo-flow-revoke-verification! poo-flow-verification-admission
        poo-flow-verification-admission-valid?)
(def (instant? value) (and (exact-integer? value) (>= value 0)))
(def (text? value) (and (string? value) (> (string-length value) 0)))
;;; Public POO objects are presentations, not authority. Keep the exact
;;; constructed adapter and indexed admission identities in private storage.
(def issued-adapters (make-hash-table-eq weak-keys: #t))
(def issued-admissions (make-hash-table-eq weak-keys: #t))
(def (adapter-entry adapter)
  (let (entry (hash-get issued-adapters adapter))
    (and entry (object? adapter)
         (.slot? adapter 'identity) (.slot? adapter 'verify)
         (.slot? adapter 'admits?) (.slot? adapter 'admission)
         (.slot? adapter 'revoke!)
         (equal? (.ref adapter 'identity) (vector-ref entry 0))
         (eq? (.ref adapter 'verify) (vector-ref entry 1))
         (eq? (.ref adapter 'admits?) (vector-ref entry 2))
         (eq? (.ref adapter 'admission) (vector-ref entry 3))
         (eq? (.ref adapter 'revoke!) (vector-ref entry 4))
         entry)))
(def (required-adapter-entry adapter)
  (or (adapter-entry adapter)
      (error "unissued or modified verification adapter")))
(def (admission-entry admission)
  (let (entry (hash-get issued-admissions admission))
    (and entry (object? admission)
         (.slot? admission 'identity) (.slot? admission 'instant)
         (.slot? admission 'admits?)
         (equal? (.ref admission 'identity) (vector-ref entry 0))
         (equal? (.ref admission 'instant) (vector-ref entry 1))
         (eq? (.ref admission 'admits?) (vector-ref entry 2))
         entry)))
(def (poo-flow-verification-adapter identity-value operation snapshot)
  (unless (and (text? identity-value) (procedure? operation) (procedure? snapshot))
    (error "verification adapter requires an identity, operation and snapshot function"))
  ;; Private issuance and revocation state is confined to this explicit boundary.
  ;; A snapshot string is copied: mutable input strings must not mutate seals.
  (let ((issued (make-hash-table-eq)) (sequence 0))
    (def (freeze value)
      (let (result (snapshot value))
        (unless (string? result) (error "verification snapshot must be a string"))
        (string-copy result)))
    (def (verify-value value now until)
      (unless (and (instant? now) (instant? until) (< now until))
        (error "invalid verification validity interval"))
      (let (before (freeze value))
        (if (eq? (operation value now until) #t)
          (begin
            (unless (equal? before (freeze value))
              (error "verification input changed during verification"))
            (set! sequence (+ sequence 1))
            (let* ((id (string-append identity-value "/" (number->string sequence)))
                   (receipt (.o identity: id issuer: identity-value issued-at: now expires-at: until)))
              ;; Receipt identity and validity are read from private storage,
              ;; never from an editable presentation slot on the returned object.
              (hash-put! issued receipt
                         (vector before now until (string-copy id) (string-copy identity-value)))
              receipt))
          #f)))
    (def (entry-valid? receipt entry now)
      (and entry (<= (vector-ref entry 1) now) (< now (vector-ref entry 2))
           (object? receipt)
           (.slot? receipt 'identity) (.slot? receipt 'issuer)
           (.slot? receipt 'issued-at) (.slot? receipt 'expires-at)
           (equal? (.ref receipt 'identity) (vector-ref entry 3))
           (equal? (.ref receipt 'issuer) (vector-ref entry 4))
           (equal? (.ref receipt 'issued-at) (vector-ref entry 1))
           (equal? (.ref receipt 'expires-at) (vector-ref entry 2))))
    (def (valid? receipt value now)
      (and (instant? now)
           (let (entry (hash-get issued receipt))
             (and (entry-valid? receipt entry now)
                  (equal? (freeze value) (vector-ref entry 0)) #t))))
    (def (admission-value receipts now)
      (unless (and (list? receipts) (instant? now))
        (error "verification admission requires receipts and a current instant"))
      (let (snapshot-index (make-hash-table))
        (for-each
         (lambda (receipt)
           (let (entry (hash-get issued receipt))
             (when (entry-valid? receipt entry now)
               (let* ((snapshot (vector-ref entry 0))
                      (matching (hash-get snapshot-index snapshot)))
                 (hash-put! snapshot-index snapshot (cons receipt matching))))))
         receipts)
        (let* ((admits-value?
                (lambda (value)
                  (let (matching (hash-get snapshot-index (freeze value)))
                    (and matching
                         (ormap (lambda (receipt)
                                  (entry-valid? receipt (hash-get issued receipt) now))
                                matching)
                         #t))))
               (admission
                (.o identity: identity-value instant: now
                    admits?: admits-value?)))
          (hash-put! issued-admissions admission
                     (vector (string-copy identity-value) now admits-value?))
          admission)))
    (def (revoke-value! receipt)
      (hash-remove! issued receipt))
    (let (adapter
          (.o identity: identity-value verify: verify-value admits?: valid?
              admission: admission-value revoke!: revoke-value!))
      (hash-put! issued-adapters adapter
                 (vector (string-copy identity-value) verify-value valid?
                         admission-value revoke-value!))
      adapter)))
(def (poo-flow-verify adapter value now until)
  ((vector-ref (required-adapter-entry adapter) 1) value now until))
(def (poo-flow-verification-valid? adapter receipt value now)
  (let (entry (adapter-entry adapter))
    (and entry ((vector-ref entry 2) receipt value now))))
(def (poo-flow-revoke-verification! adapter receipt)
  ((vector-ref (required-adapter-entry adapter) 4) receipt))
(def (poo-flow-verification-admission adapter receipts now)
  ((vector-ref (required-adapter-entry adapter) 3) receipts now))
(def (poo-flow-verification-admission-valid? admission value)
  (let (entry (admission-entry admission))
    (and entry ((vector-ref entry 2) value))))
