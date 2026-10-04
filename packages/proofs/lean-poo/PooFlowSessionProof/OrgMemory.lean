import Std

/- POO Flow owns the pure source and Session policy gate. Orgize parser/query
   receipts, MRR semantic admission and runtime CAS are separate authorities. -/
namespace PooFlowSessionProof.OrgMemory

structure Load where
  project : Nat
  worktree : Nat
  sourceCut : Nat
  bytes : Nat
  orgizeRevision : Nat
  parser : Nat
  graph : Nat
  query : Nat
  queryRule : Nat
  candidates : List Nat
  deriving DecidableEq, Repr

structure Current where
  project : Nat
  worktree : Nat
  sourceCut : Nat
  bytes : Nat
  orgizeRevision : Nat
  parser : Nat
  graph : Nat
  allowedQuery : Nat
  queryRule : Nat
  expectedHead : Nat
  currentHead : Nat
  readGranted : Bool
  sessionActive : Bool
  memoryPolicyAllows : Bool
  deriving DecidableEq, Repr

structure SelectionIntent where
  project : Nat
  worktree : Nat
  sourceCut : Nat
  bytes : Nat
  query : Nat
  expectedHead : Nat
  candidates : List Nat
  semanticAdmitted : Bool
  runtimeExecuted : Bool
  deriving DecidableEq, Repr

/-- A proposal carries exact load identity only when all current POO Flow
scope and policy premises still match. It never claims MRR or CAS authority. -/
def propose (load : Load) (current : Current) : Option SelectionIntent :=
  if load.project = current.project ∧
      load.worktree = current.worktree ∧
      load.sourceCut = current.sourceCut ∧
      load.bytes = current.bytes ∧
      load.orgizeRevision = current.orgizeRevision ∧
      load.parser = current.parser ∧
      load.graph = current.graph ∧
      load.query = current.allowedQuery ∧
      load.queryRule = current.queryRule ∧
      current.expectedHead = current.currentHead ∧
      current.readGranted = true ∧
      current.sessionActive = true ∧
      current.memoryPolicyAllows = true ∧
      load.candidates ≠ [] then
    some {
      project := load.project
      worktree := load.worktree
      sourceCut := load.sourceCut
      bytes := load.bytes
      query := load.query
      expectedHead := current.expectedHead
      candidates := load.candidates
      semanticAdmitted := false
      runtimeExecuted := false
    }
  else none

theorem foreign_worktree_refused (load : Load) (current : Current)
    (foreign : load.worktree ≠ current.worktree) :
    propose load current = none := by
  simp [propose, foreign]

theorem stale_source_cut_refused (load : Load) (current : Current)
    (stale : load.sourceCut ≠ current.sourceCut) :
    propose load current = none := by
  simp [propose, stale]

theorem changed_bytes_refused (load : Load) (current : Current)
    (changed : load.bytes ≠ current.bytes) :
    propose load current = none := by
  simp [propose, changed]

theorem stale_parser_refused (load : Load) (current : Current)
    (stale : load.parser ≠ current.parser) :
    propose load current = none := by
  simp [propose, stale]

theorem stale_graph_refused (load : Load) (current : Current)
    (stale : load.graph ≠ current.graph) :
    propose load current = none := by
  simp [propose, stale]

theorem stale_query_rule_refused (load : Load) (current : Current)
    (stale : load.queryRule ≠ current.queryRule) :
    propose load current = none := by
  simp [propose, stale]

theorem revoked_read_refused (load : Load) (current : Current)
    (revoked : current.readGranted = false) :
    propose load current = none := by
  simp [propose, revoked]

theorem inactive_session_refused (load : Load) (current : Current)
    (inactive : current.sessionActive = false) :
    propose load current = none := by
  simp [propose, inactive]

theorem losing_head_refused (load : Load) (current : Current)
    (changed : current.expectedHead ≠ current.currentHead) :
    propose load current = none := by
  simp [propose, changed]

theorem accepted_selection_preserves_source_without_publication
    (load : Load) (current : Current) (intent : SelectionIntent)
    (accepted : propose load current = some intent) :
    intent.project = load.project ∧
      intent.worktree = load.worktree ∧
      intent.sourceCut = load.sourceCut ∧
      intent.bytes = load.bytes ∧
      intent.query = load.query ∧
      intent.candidates = load.candidates ∧
      intent.semanticAdmitted = false ∧
      intent.runtimeExecuted = false := by
  unfold propose at accepted
  split at accepted
  · cases accepted
    simp
  · contradiction

end PooFlowSessionProof.OrgMemory
