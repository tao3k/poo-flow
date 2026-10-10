# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Pinned Quint finite proofs, with real-output watchdog and negative controls."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from collections.abc import Callable

from ..model import CaseContext, CaseEvidence


IDLE_LIMIT_SECONDS = 5
CASE_LIMIT_SECONDS = 45
STATE_COUNT = re.compile(rb"([\d,]+) states generated, ([\d,]+) distinct states.*?([\d,]+) states left on queue")

@dataclass(frozen=True)
class QuintCase:
    model: str
    invariant: str = "safety"
    negative: bool = False
    temporal: str | None = None

GROUPS = {
    "search-evidence-history": [QuintCase("SearchEvidenceHistory_none"),
        QuintCase("SearchEvidenceHistory_ignoreUsed", "UniqueEventAdmission", True),
        QuintCase("SearchEvidenceHistory_clearHistory", "HistoryRetention", True)],
    "search-evidence": [QuintCase("SearchEvidence_none"),
        QuintCase("SearchEvidence_ignoreParents", "ExactCausalParents", True),
        QuintCase("SearchEvidence_ignoreScope", "ObservationScope", True),
        QuintCase("SearchEvidence_ignoreTime", "TemporalOrder", True),
        QuintCase("SearchEvidence_ignoreCommitted", "CommittedEvidence", True)],
    "search-dag": [QuintCase("SearchDag_none"),
        QuintCase("SearchDag_ignoreParents", "DependencyOrder", True),
        QuintCase("SearchDag_ignoreFreshness", "FreshResults", True),
        QuintCase("SearchDag_clearAll", "BranchRetention", True)],
    "search-readiness": [QuintCase("SearchReadiness_none"),
        QuintCase("SearchReadiness_ignoreMissing", "AllPrerequisites", True),
        QuintCase("SearchReadiness_ignoreRevision", "CurrentPrerequisites", True),
        QuintCase("SearchReadiness_ignoreScope", "ScopeIsolation", True)],
    "search-attempt": [QuintCase("SearchAttempt_none"),
        QuintCase("SearchAttempt_ignoreRevision", "CurrentRevision", True),
        QuintCase("SearchAttempt_ignoreAttempt", "ExactAttempt", True),
        QuintCase("SearchAttempt_ignoreRetired", "NoRetiredAdmission", True),
        QuintCase("SearchAttempt_cancelAny", "NoStaleCancellation", True)],
    "governance": [QuintCase("GovernanceCore")],
    "query": [QuintCase("NativeSemanticQuery")],
    "healthcare": [QuintCase("HealthcarePrescriptionCausality")],
    "healthcare-ai": [QuintCase("HealthcareAIAssistedPrescriptionCausality")],
    "healthcare-migration": [QuintCase("HealthcareStandardMigration")],
    "family": [QuintCase(n, temporal="eventuallyTerminal") for n in
               ("TemporalFamilyCase", "TemporalFamilyBounded", "TemporalDiscriminatingCase")]
              + [QuintCase("TemporalFamilyMutation", "TerminalAgreement", True)],
    "revision": [QuintCase("TemporalRevision", temporal="eventuallyComplete")],
    "invalidation": [QuintCase(n, temporal="eventuallyComplete") for n in
                     ("TemporalInvalidationCase", "TemporalReprojectionCase")]
                    + [QuintCase("TemporalReprojectionMutation", "DirectScheduled", True)],
    "selection": [QuintCase("TemporalConclusionSelectionCase", temporal="eventuallyResolved"),
                  QuintCase("TemporalConclusionSelectionMutation", "AtMostOneCommit", True)],
    "evidence": [QuintCase("EvidenceLineageCase"), QuintCase("EvidenceAssessmentCase"),
                 QuintCase("CandidateExchangeCase"),
                 QuintCase("EvidenceLineageMutation", "ActiveSupportInvariant", True),
                 QuintCase("EvidenceAssessmentMutation", "ActiveAssessmentInvariant", True),
                 QuintCase("CandidateExchangeMutation", "ReviewabilityInvariant", True)],
    "publication": [QuintCase("TemporalPublicationDeliveryCase"),
                    QuintCase("TemporalPublicationDeliveryMutation", "AtomicTuple", True),
                    QuintCase("TemporalPublicationAuthorityCase"),
                    QuintCase("TemporalPublicationGenerationMutation", "NoUnauthorizedCommit", True),
                    QuintCase("TemporalPublicationRetirementMutation", "NoUnauthorizedCommit", True)],
    "session": [],
    "context-temporal-lifecycle": [QuintCase("ContextTemporalLifecycle_none")] + [
        QuintCase("ContextTemporalLifecycle_" + bug, invariant, True) for bug, invariant in [
            ("ignoreSource", "ExactSource"), ("ignoreTemporal", "ExactTemporal"),
            ("ignorePolicy", "ExactPolicy"), ("ignoreEvidence", "CurrentEvidence"),
            ("ignoreDomain", "ComparableClock"), ("ignoreUncertainty", "ConservativeWindow"),
            ("ignoreTerminalReceipt", "TerminalReceipt"), ("resurrect", "NoResurrection"),
            ("reviveObligation", "NoObligationResurrection")]],
    "context-session-claim": [QuintCase("ContextSessionClaim_none")] + [
        QuintCase("ContextSessionClaim_" + bug, invariant, True) for bug, invariant in [
            ("ignoreOwner", "ExactOwner"), ("ignoreSource", "ExactSource"),
            ("ignoreGrantGeneration", "CurrentGrant"), ("ignoreRevocation", "EnabledGrant"),
            ("ignoreClock", "EffectiveClock"), ("dropObligation", "PendingPreserved"),
            ("ignoreScope", "FixedScope")]],
    "session-attempt": [QuintCase("SessionAttempt_none"),
        QuintCase("SessionAttempt_ignoreGeneration", "ExactAttempt", True),
        QuintCase("SessionAttempt_dropObligation", "RecoveryPreservesObligation", True),
        QuintCase("SessionAttempt_resumeClosed", "ClosedIsTerminal", True)],
    "context-coverage": [QuintCase("ContextCoverage_none")] + [
        QuintCase("ContextCoverage_" + bug, "IncrementalEqualsFull", True)
        for bug in ("omitInsertion", "omitRemoval", "omitNegative")],
    "context-delta": [QuintCase("ContextDelta_none")] + [
        QuintCase("ContextDelta_" + bug, inv, True) for bug, inv in [
            ("ignoreCAS", "OnePublication"), ("ignoreCut", "ExactTargetCut"),
            ("ignoreDelete", "ExactReconstruction"), ("ignoreUseCut", "CurrentConsumption"),
            ("ignoreGrant", "AuthorizedConsumption")]],
}
SESSION_CASES = (
    ("ContextSession", "none", None),
    ("ContextSession", "ignoreCAS", "NoDoubleCommit"),
    ("ContextSession", "ignoreAuth", "NoUnauthorizedCommit"),
    ("ContextSession", "ignoreCut", "NoMixedCut"),
    ("ContextSession", "resurrect", "NoClosedResume"),
    ("WorktreeContext", "none", None),
    ("WorktreeContext", "ignoreScope", "NoForeignRead"),
    ("WorktreeContext", "ignoreReadAuth", "NoUnauthorizedRead"),
    ("WorktreeContext", "ignoreSourceCut", "NoStaleSourceImport"),
    ("WorktreeContext", "ignoreTargetCut", "NoStaleTargetImport"),
    ("WorktreeContext", "ignoreCAS", "NoDoubleImport"),
    ("WorktreeContext", "ignoreApplicable", "NoInapplicableImport"),
)
GROUPS["session"] = [QuintCase(f"{m}_{bug}", inv or "safety", inv is not None)
                     for m, bug, inv in SESSION_CASES]


def _terminate(child: subprocess.Popen[bytes]) -> None:
    if child.poll() is not None:
        return
    try:
        os.killpg(child.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        child.wait(timeout=1)
    except subprocess.TimeoutExpired:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait()


def _run_quint(command: list[str], cwd: Path,
               progress: Callable[[bytes], None] | None = None) -> tuple[int, bytes, int]:
    """Collect actual Quint/backend bytes, with a strict idle and per-case deadline."""
    child = subprocess.Popen(
        command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        start_new_session=True, bufsize=0,
    )
    assert child.stdout is not None
    started = last_output = time.monotonic()
    output = bytearray()
    pending = bytearray()
    visible = (b"Parsing file", b"Starting...",
               b"Finished computing initial states", b"Model checking completed",
               b"Error: Invariant", b"Finished in")
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(child.stdout, selectors.EVENT_READ)
            while selector.get_map() or child.poll() is None:
                for key, _ in selector.select(timeout=0.1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    last_output = time.monotonic()
                    output.extend(chunk)
                    pending.extend(chunk)
                    while b"\n" in pending:
                        line, _, remainder = pending.partition(b"\n")
                        pending = bytearray(remainder)
                        visible_line = (any(token in line for token in visible)
                                        or b" states generated, " in line)
                        if progress is not None and (visible_line or line.startswith((b"[", b"PASS", b"# APALACHE"))):
                            progress(line + b"\n")
                now = time.monotonic()
                if now - last_output > IDLE_LIMIT_SECONDS:
                    raise TimeoutError("process produced no bytes for five seconds")
                if now - started > CASE_LIMIT_SECONDS:
                    raise TimeoutError("Quint exceeded the 45-second case limit")
        return child.wait(), bytes(output), round((time.monotonic() - started) * 1000)
    finally:
        _terminate(child)
        child.stdout.close()


def check_quint(context: CaseContext, case: QuintCase,
                progress: Callable[[bytes], None] | None = None) -> CaseEvidence:
    models = context.repository_root / "packages/proofs/quint"
    quint = models / "node_modules/.bin/quint"
    version = subprocess.run([str(quint), "--version"], capture_output=True,
                             text=True, check=True, timeout=5).stdout.strip()
    if version != "0.33.0":
        raise AssertionError(f"expected Quint 0.33.0, got {version!r}")
    source = models / f"{case.model}.qnt"
    # Include imported modules: an instance hash alone does not bind its semantics.
    sources = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
               for p in sorted(models.glob("*.qnt"))}
    with tempfile.TemporaryDirectory(prefix="poo-quint-") as directory:
        work = Path(directory)
        for p in models.glob("*.qnt"):
            (work / p.name).write_bytes(p.read_bytes())
        config = work / "backend.json"
        config.write_text('{"workers":"1","maxHeap":"-Xmx1G"}\n')
        command = [str(quint), "verify", str(work / source.name), "--main", case.model,
                   "--backend", "tlc", "--apalache-version", "0.62.1",
                   "--invariant", case.invariant, "--tlc-config", str(config),
                   "--verbosity", "3"]
        if case.temporal:
            command += ["--temporal", case.temporal]
        if progress is not None:
            progress(f"QUINT-CHECK {case.model} {case.invariant}\n".encode())
        status, output, duration_ms = _run_quint(command, work, progress)
    if sources != {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in sorted(models.glob("*.qnt"))}:
        raise AssertionError("Quint sources changed during verification")
    counts = STATE_COUNT.search(output)
    if case.negative:
        accepted = (status == 1 and b"Error: Invariant q_inv is violated." in output
                    and b"[violation] Found an issue" in output
                    and b"error: found a counterexample" in output)
    else:
        accepted = (status == 0 and b"[ok] No violation found" in output
                    and counts is not None and counts[3].replace(b",", b"") == b"0"
                    and (not case.temporal or b"Finished checking temporal properties" in output))
    if not accepted or counts is None:
        raise AssertionError(f"{case.model}/{case.invariant}: unexpected Quint result {status}; "
                             + output.decode(errors="replace")[-2400:])
    if progress is not None:
        progress(f"QUINT-OK {case.model} states={counts[2].decode()} negative={case.negative}\n".encode())
    return CaseEvidence({"model": case.model, "invariant": case.invariant,
                         "negative": case.negative, "temporal": case.temporal,
                         "quint_version": version, "backend": "tlc", "apalache_version": "0.62.1",
                         "sources_sha256": sources, "exit": status,
                         "generated_states": int(counts[1].replace(b",", b"")),
                         "distinct_states": int(counts[2].replace(b",", b"")),
                         "duration_ms": duration_ms, "idle_limit_seconds": 5,
                         "case_limit_seconds": 45,
                         "stdout_sha256": hashlib.sha256(output).hexdigest()})


def _scheme(value: object) -> str:
    if value is None: return "#f"
    if isinstance(value, bool): return "#t" if value else "#f"
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
    if isinstance(value, dict):
        return "(" + " ".join("(" + str(k).replace("_", "-") + " . " + _scheme(v) + ")"
                              for k, v in value.items()) + ")"
    if isinstance(value, list): return "(" + " ".join(map(_scheme, value)) + ")"
    return str(value)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--group", choices=["all", *GROUPS], default="all")
    parser.add_argument("--receipt", type=Path)
    args = parser.parse_args()
    if args.receipt:
        args.receipt.unlink(missing_ok=True)
    root = Path(__file__).resolve().parents[5]
    # The proof runner only uses repository_root from the harness context.
    from types import SimpleNamespace
    context = SimpleNamespace(repository_root=root)
    cases = [c for g, items in GROUPS.items() if args.group in ("all", g) for c in items]
    def progress(data: bytes) -> None:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()

    results = [dict(check_quint(context, c, progress).details) for c in cases]
    if args.receipt:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(_scheme({"schema": "poo-flow.quint-proof.v1", "cases": results}) + "\n")
    progress(f"QUINT-QUALIFICATION-OK {len(results)} cases\n".encode())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
