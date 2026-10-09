;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Explicit in-process runtime control capability. No semantic wire dispatch.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :poo-flow/modules/temporal-causality/time/objects poo-flow-temporal-instant)
        "policy.ss")
(export poo-flow-temporal-support-policy-host
        poo-flow-temporal-support-policy-host-refresh!
        poo-flow-temporal-support-policy-host-guard
        poo-flow-temporal-support-policy-host-guard-current
        poo-flow-temporal-support-policy-host-current)
;;; Opaque runtime state, never transported; the host serializes control/use.
(defstruct policy-host-state (current revisions))
(def (poo-flow-temporal-support-policy-host)
  (.o kind: 'poo-flow.temporal-causality.policy-host.v1
      private-runtime-state: (make-policy-host-state (make-hash-table) (make-hash-table))))
(def (state host)
  (unless (and (object? host) (.slot? host 'kind)
               (eq? (.ref host 'kind) 'poo-flow.temporal-causality.policy-host.v1)
               (.slot? host 'private-runtime-state)
               (policy-host-state? (.ref host 'private-runtime-state)))
    (error "invalid policy host capability"))
  (.ref host 'private-runtime-state))
(def (instant-row x)
  (map (lambda (s) (.ref x s)) '(identity domain-identity coordinate provenance-identity modality)))
(def (canonical-policy p)
  (let (canonical (poo-flow-temporal-support-policy (.ref p 'identity) (.ref p 'revision-identity)
                    (.ref p 'start) (.ref p 'end)))
    (unless (equal? (.ref p 'semantic-digest) (.ref canonical 'semantic-digest))
      (error "forged host policy")) canonical))
(def (poo-flow-temporal-support-policy-host-refresh! host policy generation-value effective-value)
  (unless (and (exact-integer? generation-value) (<= 0 generation-value))
    (error "invalid host policy generation"))
  (let* ((s (state host)) (owned (canonical-policy policy))
         (time-value (poo-flow-temporal-instant (.ref effective-value 'identity)
           (.ref effective-value 'domain-identity) (.ref effective-value 'coordinate)
           (.ref effective-value 'provenance-identity) (.ref effective-value 'modality)))
         (id (.ref owned 'identity)) (current (policy-host-state-current s))
         (history (policy-host-state-revisions s)) (old (hash-get current id))
         (revision-key (list id (.ref owned 'revision-identity)))
         (original (hash-get history revision-key)))
    (unless (and (eq? (.ref time-value 'modality) 'observed)
                 (equal? (.ref time-value 'domain-identity) (.ref (.ref owned 'start) 'domain-identity)))
      (error "host policy clock domain or modality mismatch"))
    (when original
      (unless (equal? (.ref original 'semantic-digest) (.ref owned 'semantic-digest))
        (error "host policy revision identity is immutable")))
    (when old
      (unless (and (equal? (.ref time-value 'domain-identity)
                          (.ref (.ref old 'effective-at) 'domain-identity))
                   (>= (.ref time-value 'coordinate) (.ref (.ref old 'effective-at) 'coordinate)))
        (error "host policy clock rollback"))
      (unless (or (> generation-value (.ref old 'generation))
                  (and (= generation-value (.ref old 'generation))
                       (equal? (.ref owned 'semantic-digest) (.ref (.ref old 'policy) 'semantic-digest))
                       (equal? (instant-row time-value) (instant-row (.ref old 'effective-at)))))
        (error "host policy generation rollback or conflict")))
    (unless (and (or old (< (hash-length current) 128))
                 (or original (< (hash-length history) 128)))
      (error "host policy registry capacity exceeded"))
    (let (snapshot (.o kind: 'poo-flow.temporal-causality.policy-host-snapshot.v1
                       policy: owned generation: generation-value effective-at: time-value
                       trust-basis: 'host-registered-policy-snapshot
                       source-authenticated?: #f action-authorized?: #f durable?: #f))
      (hash-put! history revision-key owned)
      (hash-put! current id snapshot)
      snapshot)))
(def (poo-flow-temporal-support-policy-host-guard host expected-generation expected-policy-digest
                                                program journal as-of valid-at budget)
  (let* ((s (state host))
         (snapshot (hash-get (policy-host-state-current s) (.ref program 'policy-identity))))
    (unless (and snapshot (exact-integer? expected-generation)
                 (= expected-generation (.ref snapshot 'generation)))
      (error "unregistered or stale host policy generation"))
    ;; The query supplies neither a replacement policy nor an effective clock.
    (poo-flow-temporal-support-guard program journal as-of valid-at budget
      (.ref snapshot 'policy) expected-policy-digest (.ref snapshot 'effective-at))))

;;; Current proof applicability cannot choose a historical evidence cut or clock.
(def (poo-flow-temporal-support-policy-host-guard-current host expected-generation expected-policy-digest
                                                        program journal budget)
  (let* ((s (state host))
         (snapshot (hash-get (policy-host-state-current s) (.ref program 'policy-identity))))
    (unless (and snapshot (exact-integer? expected-generation)
                 (= expected-generation (.ref snapshot 'generation)))
      (error "unregistered or stale host policy generation"))
    (poo-flow-temporal-support-guard program journal (.ref snapshot 'effective-at) (.ref snapshot 'effective-at) budget
      (.ref snapshot 'policy) expected-policy-digest (.ref snapshot 'effective-at))))

;;; Read only the registered current snapshot; callers cannot choose its clock.
(def (poo-flow-temporal-support-policy-host-current host policy-identity)
  (or (hash-get (policy-host-state-current (state host)) policy-identity)
      (error "unregistered current policy")))
