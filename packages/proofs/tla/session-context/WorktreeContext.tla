----------------------------- MODULE WorktreeContext -----------------------------
EXTENDS Naturals, Integers, FiniteSets, Sequences
CONSTANTS Worktrees, Sessions, Workers, SourceWorktree, TargetWorktree,
          SourceSession, TargetSession, Bug
ASSUME /\ IsFiniteSet(Worktrees) /\ Cardinality(Worktrees) = 2
       /\ SourceWorktree \in Worktrees /\ TargetWorktree \in Worktrees
       /\ SourceWorktree # TargetWorktree
       /\ IsFiniteSet(Sessions) /\ Cardinality(Sessions) = 2
       /\ SourceSession \in Sessions /\ TargetSession \in Sessions
       /\ SourceSession # TargetSession
       /\ IsFiniteSet(Workers) /\ Cardinality(Workers) = 2
       /\ Bug \in {"none", "ignoreScope", "ignoreReadAuth",
                  "ignoreSourceCut", "ignoreTargetCut", "ignoreCAS",
                  "ignoreApplicable"}

Owner == [s \in Sessions |-> IF s = SourceSession THEN SourceWorktree
                       ELSE TargetWorktree]
NoProposal == <<>>
VARIABLES cut, rev, artifactCut, importedCut, authorized, applicable,
          proposals, imports, readDone, reads
vars == <<cut, rev, artifactCut, importedCut, authorized, applicable,
          proposals, imports, readDone, reads>>

Init ==
  /\ cut = [w \in Worktrees |-> 0]
  /\ rev = [w \in Worktrees |-> 0]
  /\ artifactCut = -1
  /\ importedCut = -1
  /\ authorized = [s \in Sessions |-> TRUE]
  /\ applicable = TRUE
  /\ proposals = [w \in Workers |-> NoProposal]
  /\ imports = <<>>
  /\ readDone = [s \in Sessions |-> FALSE]
  /\ reads = <<>>

PublishSource ==
  /\ artifactCut = -1
  /\ rev[SourceWorktree] < 2
  /\ artifactCut' = cut[SourceWorktree]
  /\ rev' = [rev EXCEPT ![SourceWorktree] = @ + 1]
  /\ UNCHANGED <<cut, importedCut, authorized, applicable,
                 proposals, imports, readDone, reads>>

AdvanceCut(w) ==
  /\ w \in Worktrees /\ cut[w] = 0
  /\ cut' = [cut EXCEPT ![w] = 1]
  /\ UNCHANGED <<rev, artifactCut, importedCut, authorized, applicable,
                 proposals, imports, readDone, reads>>

Revoke(s) ==
  /\ s \in Sessions /\ authorized[s]
  /\ authorized' = [authorized EXCEPT ![s] = FALSE]
  /\ UNCHANGED <<cut, rev, artifactCut, importedCut, applicable,
                 proposals, imports, readDone, reads>>

InvalidateTarget ==
  /\ applicable /\ applicable' = FALSE
  /\ UNCHANGED <<cut, rev, artifactCut, importedCut, authorized,
                 proposals, imports, readDone, reads>>

ProposeTransfer(worker) ==
  /\ worker \in Workers /\ artifactCut # -1
  /\ proposals[worker] = NoProposal
  /\ (importedCut # cut[TargetWorktree] \/ Bug = "ignoreCAS")
  /\ rev[TargetWorktree] < 2
  /\ proposals' = [proposals EXCEPT ![worker] =
       <<artifactCut, rev[SourceWorktree],
         cut[TargetWorktree], rev[TargetWorktree]>>]
  /\ UNCHANGED <<cut, rev, artifactCut, importedCut, authorized,
                 applicable, imports, readDone, reads>>

CommitTransfer(worker) ==
  /\ worker \in Workers /\ proposals[worker] # NoProposal
  /\ LET p == proposals[worker]
     IN /\ artifactCut = p[1]
        /\ (cut[SourceWorktree] = p[1] \/ Bug = "ignoreSourceCut")
        /\ rev[SourceWorktree] = p[2]
        /\ (cut[TargetWorktree] = p[3] \/ Bug = "ignoreTargetCut")
        /\ (rev[TargetWorktree] = p[4] \/ Bug = "ignoreCAS")
        /\ (importedCut # cut[TargetWorktree] \/ Bug = "ignoreCAS")
        /\ rev[TargetWorktree] < 2
        /\ authorized[SourceSession] /\ authorized[TargetSession]
        /\ (applicable \/ Bug = "ignoreApplicable")
        /\ rev' = [rev EXCEPT ![TargetWorktree] = @ + 1]
        /\ importedCut' = cut[TargetWorktree]
        /\ proposals' = [proposals EXCEPT ![worker] = NoProposal]
        /\ imports' = Append(imports,
             <<p[1], cut[SourceWorktree], p[3], cut[TargetWorktree],
               p[4], authorized[SourceSession],
               authorized[TargetSession], applicable, worker>>)
  /\ UNCHANGED <<cut, artifactCut, authorized, applicable,
                 readDone, reads>>

Read(s, w) ==
  /\ s \in Sessions /\ w \in Worktrees /\ ~readDone[s]
  /\ (w = Owner[s] \/ Bug = "ignoreScope")
  /\ (authorized[s] \/ Bug = "ignoreReadAuth")
  /\ (IF w = SourceWorktree
      THEN artifactCut = cut[w]
      ELSE importedCut = cut[w])
  /\ readDone' = [readDone EXCEPT ![s] = TRUE]
  /\ reads' = Append(reads, <<s, w, Owner[s], authorized[s], cut[w]>>)
  /\ UNCHANGED <<cut, rev, artifactCut, importedCut, authorized,
                 applicable, proposals, imports>>

Next ==
  \/ PublishSource \/ InvalidateTarget
  \/ \E w \in Worktrees : AdvanceCut(w)
  \/ \E s \in Sessions : Revoke(s)
  \/ \E worker \in Workers : ProposeTransfer(worker) \/ CommitTransfer(worker)
  \/ \E s \in Sessions : \E w \in Worktrees : Read(s, w)

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ cut \in [Worktrees -> 0..1]
  /\ rev \in [Worktrees -> 0..2]
  /\ artifactCut \in {-1, 0, 1}
  /\ importedCut \in {-1, 0, 1}
  /\ authorized \in [Sessions -> BOOLEAN]
  /\ applicable \in BOOLEAN
  /\ readDone \in [Sessions -> BOOLEAN]

NoForeignRead ==
  \A i \in 1..Len(reads) : reads[i][2] = reads[i][3]

NoUnauthorizedRead ==
  \A i \in 1..Len(reads) : reads[i][4] = TRUE

NoStaleSourceImport ==
  \A i \in 1..Len(imports) : imports[i][1] = imports[i][2]

NoStaleTargetImport ==
  \A i \in 1..Len(imports) : imports[i][3] = imports[i][4]

NoDoubleImport ==
  \A i, j \in 1..Len(imports) : i # j => imports[i][5] # imports[j][5]

NoUnauthorizedImport ==
  \A i \in 1..Len(imports) :
    imports[i][6] = TRUE /\ imports[i][7] = TRUE

NoInapplicableImport ==
  \A i \in 1..Len(imports) : imports[i][8] = TRUE
=============================================================================
