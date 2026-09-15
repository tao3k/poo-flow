;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Explicit verification boundary. The configured operation is host-trusted;
;;; submitted POO facts and their claimed verification flags are not.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/misc/hash hash-remove!))
(export poo-flow-verification-adapter poo-flow-verify poo-flow-verification-valid?
        poo-flow-revoke-verification! poo-flow-verification-admission
        poo-flow-verification-admission-valid?)
(def (instant? value) (and (exact-integer? value) (>= value 0)))
(def (text? value) (and (string? value) (> (string-length value) 0)))
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
        (.o identity: identity-value instant: now
            admits?:
            (lambda (value)
              (let (matching (hash-get snapshot-index (freeze value)))
                (and matching
                     (ormap (lambda (receipt)
                              (entry-valid? receipt (hash-get issued receipt) now))
                            matching)
                     #t))))))
    (def (revoke-value! receipt)
      (hash-remove! issued receipt))
    (.o identity: identity-value verify: verify-value admits?: valid?
        admission: admission-value revoke!: revoke-value!)))
(def (poo-flow-verify adapter value now until)
  ((.ref adapter 'verify) value now until))
(def (poo-flow-verification-valid? adapter receipt value now)
  ((.ref adapter 'admits?) receipt value now))
(def (poo-flow-revoke-verification! adapter receipt)
  ((.ref adapter 'revoke!) receipt))
(def (poo-flow-verification-admission adapter receipts now)
  ((.ref adapter 'admission) receipts now))
(def (poo-flow-verification-admission-valid? admission value)
  ((.ref admission 'admits?) value))
