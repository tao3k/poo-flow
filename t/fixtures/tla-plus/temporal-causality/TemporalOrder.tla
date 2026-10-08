---- MODULE TemporalOrder ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

\* Partial clock order for the admitted finite literal observation profile.
\* Cross-domain comparison is unknown here; no conversion is inferred.
EXTENDS Naturals

CONSTANT Observations

ObservationIds == {o[1] : o \in Observations}
Observation(id) == CHOOSE o \in Observations : o[1] = id

Known(id) ==
  /\ id \in ObservationIds
  /\ Observation(id)[5] = "observed"

Comparable(left, right) ==
  /\ Known(left)
  /\ Known(right)
  /\ Observation(left)[2] = Observation(right)[2]

OrderStatus(left, right, relation) ==
  IF ~Comparable(left, right)
  THEN "unknown"
  ELSE IF (relation = "before" /\ Observation(left)[3] < Observation(right)[3])
          \/ (relation = "not-after" /\ Observation(left)[3] <= Observation(right)[3])
       THEN "admitted"
       ELSE "refuted"

====
