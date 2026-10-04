----------------------------- MODULE ContextSession -----------------------------
EXTENDS Naturals, Integers, FiniteSets, Sequences
CONSTANTS Sessions, Workers, Bug
ASSUME /\ IsFiniteSet(Sessions) /\ Sessions # {}
       /\ IsFiniteSet(Workers) /\ Cardinality(Workers) = 2
       /\ Bug \in {"none", "ignoreCAS", "ignoreAuth", "ignoreCut", "resurrect"}

None == -1
NoProposal == <<>>
VARIABLES status, rev, nextTurn, pending, sourceCut, authorized,
          validatedCut, proposals, receipts, closedEver
vars == <<status, rev, nextTurn, pending, sourceCut, authorized,
          validatedCut, proposals, receipts, closedEver>>

Init ==
  /\ status = [s \in Sessions |-> "absent"]
  /\ rev = [s \in Sessions |-> 0]
  /\ nextTurn = [s \in Sessions |-> 0]
  /\ pending = [s \in Sessions |-> None]
  /\ sourceCut = 0
  /\ authorized = [s \in Sessions |-> TRUE]
  /\ validatedCut = [s \in Sessions |-> -1]
  /\ proposals = [w \in Workers |-> NoProposal]
  /\ receipts = <<>>
  /\ closedEver = {}

Create(s) ==
  /\ s \in Sessions /\ status[s] = "absent"
  /\ status' = [status EXCEPT ![s] = "active"]
  /\ rev' = [rev EXCEPT ![s] = @ + 1]
  /\ UNCHANGED <<nextTurn, pending, sourceCut, authorized,
                 validatedCut, proposals, receipts, closedEver>>

Begin(s) ==
  /\ s \in Sessions /\ status[s] = "active" /\ pending[s] = None
  /\ nextTurn[s] < 1 /\ rev[s] < 4
  /\ pending' = [pending EXCEPT ![s] = nextTurn[s]]
  /\ nextTurn' = [nextTurn EXCEPT ![s] = @ + 1]
  /\ rev' = [rev EXCEPT ![s] = @ + 1]
  /\ UNCHANGED <<status, sourceCut, authorized, validatedCut,
                 proposals, receipts, closedEver>>

Validate(s) ==
  /\ s \in Sessions /\ status[s] = "suspended" /\ authorized[s]
  /\ validatedCut[s] # sourceCut
  /\ validatedCut' = [validatedCut EXCEPT ![s] = sourceCut]
  /\ UNCHANGED <<status, rev, nextTurn, pending, sourceCut,
                 authorized, proposals, receipts, closedEver>>

Propose(w, s) ==
  /\ w \in Workers /\ s \in Sessions
  /\ status[s] = "active" /\ pending[s] # None
  /\ proposals[w] = NoProposal
  /\ proposals' = [proposals EXCEPT ![w] = <<s, rev[s], pending[s], sourceCut>>]
  /\ UNCHANGED <<status, rev, nextTurn, pending, sourceCut,
                 authorized, validatedCut, receipts, closedEver>>

Commit(w) ==
  /\ w \in Workers /\ proposals[w] # NoProposal
  /\ LET p == proposals[w]
         s == p[1]
     IN /\ status[s] = "active"
        /\ (pending[s] = p[3] \/ Bug = "ignoreCAS")
        /\ (rev[s] = p[2] \/ Bug = "ignoreCAS")
        /\ (authorized[s] \/ Bug = "ignoreAuth")
        /\ (sourceCut = p[4] \/ Bug = "ignoreCut")
        /\ rev[s] < 4
        /\ rev' = [rev EXCEPT ![s] = @ + 1]
        /\ pending' = [pending EXCEPT ![s] = None]
        /\ proposals' = [proposals EXCEPT ![w] = NoProposal]
        /\ receipts' = Append(receipts,
             <<s, p[2], p[3], p[4], sourceCut, authorized[s], w>>)
  /\ UNCHANGED <<status, nextTurn, sourceCut, authorized,
                 validatedCut, closedEver>>

AdvanceCut ==
  /\ sourceCut = 0 /\ sourceCut' = 1
  /\ UNCHANGED <<status, rev, nextTurn, pending, authorized,
                 validatedCut, proposals, receipts, closedEver>>

Revoke(s) ==
  /\ s \in Sessions /\ status[s] \in {"active", "suspended"}
  /\ authorized[s]
  /\ authorized' = [authorized EXCEPT ![s] = FALSE]
  /\ UNCHANGED <<status, rev, nextTurn, pending, sourceCut,
                 validatedCut, proposals, receipts, closedEver>>

Suspend(s) ==
  /\ s \in Sessions /\ status[s] = "active" /\ pending[s] = None
  /\ rev[s] < 4
  /\ status' = [status EXCEPT ![s] = "suspended"]
  /\ rev' = [rev EXCEPT ![s] = @ + 1]
  /\ UNCHANGED <<nextTurn, pending, sourceCut, authorized,
                 validatedCut, proposals, receipts, closedEver>>

Resume(s) ==
  /\ s \in Sessions
  /\ (status[s] = "suspended" \/
      (Bug = "resurrect" /\ status[s] = "closed"))
  /\ authorized[s] /\ validatedCut[s] = sourceCut /\ rev[s] < 4
  /\ status' = [status EXCEPT ![s] = "active"]
  /\ rev' = [rev EXCEPT ![s] = @ + 1]
  /\ UNCHANGED <<nextTurn, pending, sourceCut, authorized,
                 validatedCut, proposals, receipts, closedEver>>

Close(s) ==
  /\ s \in Sessions /\ status[s] \in {"active", "suspended"}
  /\ pending[s] = None /\ rev[s] < 4
  /\ status' = [status EXCEPT ![s] = "closed"]
  /\ rev' = [rev EXCEPT ![s] = @ + 1]
  /\ closedEver' = closedEver \cup {s}
  /\ UNCHANGED <<nextTurn, pending, sourceCut, authorized,
                 validatedCut, proposals, receipts>>

Next ==
  \/ \E s \in Sessions : Create(s) \/ Begin(s) \/ Validate(s)
                        \/ Revoke(s) \/ Suspend(s) \/ Resume(s) \/ Close(s)
  \/ \E w \in Workers : \E s \in Sessions : Propose(w, s)
  \/ \E w \in Workers : Commit(w)
  \/ AdvanceCut

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ status \in [Sessions -> {"absent", "active", "suspended", "closed"}]
  /\ rev \in [Sessions -> 0..4]
  /\ nextTurn \in [Sessions -> 0..1]
  /\ pending \in [Sessions -> {None, 0}]
  /\ sourceCut \in {0, 1}
  /\ authorized \in [Sessions -> BOOLEAN]
  /\ validatedCut \in [Sessions -> {-1, 0, 1}]
  /\ closedEver \subseteq Sessions

NoDoubleCommit ==
  \A i, j \in 1..Len(receipts) :
    i # j =>
      ~(receipts[i][1] = receipts[j][1] /\ receipts[i][2] = receipts[j][2])

NoUnauthorizedCommit ==
  \A i \in 1..Len(receipts) : receipts[i][6] = TRUE

NoMixedCut ==
  \A i \in 1..Len(receipts) : receipts[i][4] = receipts[i][5]

NoClosedResume ==
  \A s \in closedEver : status[s] = "closed"

ExactTurn ==
  \A i \in 1..Len(receipts) :
    receipts[i][1] \in Sessions /\ receipts[i][3] < nextTurn[receipts[i][1]]
=============================================================================
