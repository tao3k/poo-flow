;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        :poo-flow/modules/temporal-causality/time/interface)
(export temporal-source-authority-test)
(def authority (poo-flow-temporal-source-authority "clock-authority" "clock-owner" "time-source" "key-1" "knowledge" (make-u8vector 32 7)))
(def (instant id domain coordinate)
  (poo-flow-temporal-instant id domain coordinate "observer" 'observed))
(def as-of (instant "admission" "knowledge" 5))
(def temporal-source-authority-test
  (test-suite "authenticated scoped temporal source evidence"
    (poo-flow-test-case "a configured issuer signature binds identity scope expiry and predicate"
      (let ((assertion (poo-flow-temporal-source-attest authority "receipt" 'clock-conversion "body" 2 10)))
        (check (poo-flow-temporal-source-authenticate authority assertion 'clock-conversion "body" as-of) => #t)
        (check (poo-flow-temporal-source-authenticate authority assertion 'watermark-completeness "body" as-of) => #f)
        (check (poo-flow-temporal-source-authenticate authority assertion 'clock-conversion "changed-body" as-of) => #f)
        (check (poo-flow-temporal-source-authenticate authority assertion 'clock-conversion "body" (instant "expired" "knowledge" 10)) => #f)
        (check (poo-flow-temporal-source-authenticate authority assertion 'clock-conversion "body" (instant "other-domain" "wall" 5)) => #f)
        (check (poo-flow-temporal-source-authenticate authority (.o (:: @ assertion) signature: (make-u8vector 32 0)) 'clock-conversion "body" as-of) => #f)
        (check (poo-flow-temporal-source-authenticate
                (poo-flow-temporal-source-authority "spoof" "clock-owner" "time-source" "key-1" "knowledge" (make-u8vector 32 8))
                assertion 'clock-conversion "body" as-of) => #f)))
    (poo-flow-test-case "verified positive affine conversion preserves uncertainty and finite scope"
      (let* ((conversion (poo-flow-temporal-clock-conversion "calibration" "time-source" "sensor" "wall" 2 1 10 1 0 100))
             (assertion (poo-flow-temporal-source-attest authority "calibration-receipt" 'clock-conversion (.ref conversion 'semantic-digest) 0 10))
             (left (instant "measurement" "sensor" 10)))
        (check (poo-flow-temporal-compare left (instant "boundary" "wall" 32)) => 'incomparable)
        (check (poo-flow-temporal-compare/converted left (instant "boundary" "wall" 32) conversion assertion authority as-of) => 'before)
        (check (poo-flow-temporal-compare/converted left (instant "boundary" "wall" 28) conversion assertion authority as-of) => 'after)
        (check (poo-flow-temporal-compare/converted left (instant "boundary" "wall" 30) conversion assertion authority as-of) => 'unknown)
        (check (poo-flow-temporal-compare/converted (instant "outside" "sensor" 101) (instant "boundary" "wall" 300) conversion assertion authority as-of) => 'outside-scope)
        (check (poo-flow-temporal-compare/converted left (instant "boundary" "wall" 32) conversion assertion authority (instant "expired" "knowledge" 10)) => 'rejected)
        (check-exception (poo-flow-temporal-clock-conversion-replay (.o (:: @ conversion) offset: 12)) true)))
    (poo-flow-test-case "authenticated coverage and late evidence demand reevaluation without relabeling old cuts"
      (let* ((bound (poo-flow-temporal-bounded-observation "watermark-time" 'event "time-source"
                      (instant "lower" "events" 10) (instant "upper" "events" 12)
                      2 as-of "time-receipt" #f "attempt" "schema"))
             (watermark (poo-flow-temporal-watermark "wm" "time-source" "partition" 0 20 bound "clock-owner" "coverage" "late-revision" "wm-receipt"))
             (coverage (poo-flow-temporal-source-attest authority "coverage" 'watermark-completeness (.ref watermark 'semantic-digest) 0 10))
             (event (instant "late" "events" 4))
             (event-assertion (poo-flow-temporal-source-attest authority "late-evidence" 'event-observation
                               (poo-flow-temporal-event-source-digest "time-source" "partition" 21 event) 0 10)))
        (check (poo-flow-temporal-watermark-verified-cut-claim watermark "time-source" "partition" 20
                (instant "cut" "events" 8) coverage authority as-of) => 'source-coverage-verified)
        (check (poo-flow-temporal-watermark-late-disposition watermark "time-source" "partition" 21 event coverage event-assertion authority as-of) => 'reevaluate-cut)
        (check (poo-flow-temporal-watermark-late-disposition watermark "time-source" "partition" 22 event coverage event-assertion authority as-of) => 'rejected)
        (check (.ref (poo-flow-temporal-watermark-replay watermark) 'semantic-digest) => (.ref watermark 'semantic-digest))))))
