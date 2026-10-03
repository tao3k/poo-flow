-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import Lean
/-! Integer duration-quanta conservation. No physical clock accuracy or SQLite
implementation theorem is asserted. Failed attempts retain their reserved cost. -/
namespace PooFlowTemporalPooProof.DurationBudget
structure Budget where
  capacity : Nat
  remaining : Nat
  reserved : Nat
  conserved : remaining + reserved = capacity

def reserve (b : Budget) (amount : Nat) (admitted : amount ≤ b.remaining) : Budget where
  capacity := b.capacity
  remaining := b.remaining - amount
  reserved := b.reserved + amount
  conserved := by have h := b.conserved; omega

theorem remaining_monotone (b : Budget) (amount : Nat) (h : amount ≤ b.remaining) :
    (reserve b amount h).remaining ≤ b.remaining := by simp [reserve] <;> omega

theorem failure_does_not_refund (b : Budget) (amount : Nat) (h : amount ≤ b.remaining) :
    (reserve b amount h).reserved = b.reserved + amount := rfl

theorem delegation_conserves (b : Budget) (amount : Nat) (h : amount ≤ b.remaining) :
    (reserve b amount h).remaining + amount = b.remaining := by simp [reserve] <;> omega
end PooFlowTemporalPooProof.DurationBudget
