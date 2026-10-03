;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "authority-types.ss")
(export poo-flow-temporal-source-authority poo-flow-temporal-source-assertion-value
        poo-flow-temporal-clock-conversion-value)
(def (poo-flow-temporal-source-authority id issuer-value source-value key-id domain key)
  (validate PooFlowTemporalSourceAuthority
    (.o kind: 'temporal/source-authority identity: id issuer: issuer-value source: source-value
        key-identity: key-id admission-domain: domain verification-key: (u8vector-copy key))))
(def (poo-flow-temporal-source-assertion-value id issuer-value source-value key-id domain predicate-value body start end signature-value)
  (validate PooFlowTemporalSourceAssertion
    (.o kind: 'temporal/source-assertion identity: id issuer: issuer-value source: source-value
        key-identity: key-id admission-domain: domain predicate: predicate-value body-digest: body
        not-before: start expires: end signature: (u8vector-copy signature-value))))
(def (poo-flow-temporal-clock-conversion-value id source-value from to num den shift error-range first-value last-value digest)
  (validate PooFlowTemporalClockConversion
    (.o kind: 'temporal/clock-conversion identity: id source: source-value source-domain: from target-domain: to
        numerator: num denominator: den offset: shift radius: error-range first: first-value last: last-value semantic-digest: digest)))
