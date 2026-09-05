from pathlib import Path
import re


def migration_contract_version() -> int:
    return 1


root = Path.cwd().resolve()
if not (root / "MODULE.bazel").is_file():
    raise SystemExit(f"run from the poo-flow repository root: {root}")
source_path = root / "docs/10-19-design/10.06-poo-module-system/45-07-user-composition-and-mix-module-interface.org"
source = source_path.read_text()
lines = source.splitlines(keepends=True)

heading_pattern = re.compile(r"^\*\* ([^\n]+)\n?$")
heading_starts = []
for index, line in enumerate(lines):
    match = heading_pattern.match(line)
    if match:
        heading_starts.append((index, match.group(1).strip()))

groups = [
    {
        "path": "45-07-10-cedar-capability-and-input-identity.org",
        "title": "Mix/Profile RFC — Cedar Capability And Input Identity",
        "depends": "45-07-user-composition-and-mix-module-interface.org",
        "scope": "Cedar capability, input content identity, generation transition, authority-issued transition, predecessor lineage, and publication-domain checkpoint binding.",
        "headings": [
            "Cedar capability grant closure",
            "Cedar input content-identity refinement",
            "Content-identity generation transition",
            "Authority-issued content-identity transition",
            "Published predecessor lineage",
            "Successor/checkpoint publication-domain binding",
        ],
    },
    {
        "path": "45-07-11-registry-trust-and-semantic-identity.org",
        "title": "Mix/Profile RFC — Registry Trust And Semantic Identity",
        "depends": "45-07-10-cedar-capability-and-input-identity.org",
        "scope": "Publication-domain semantic identity and canonical registry trust-claim authority binding.",
        "headings": [
            "Publication-domain semantic-identity binding",
            "Registry trust-claim authority binding",
        ],
    },
    {
        "path": "45-07-12-registry-transition-and-admission.org",
        "title": "Mix/Profile RFC — Registry Transition And Admission",
        "depends": "45-07-11-registry-trust-and-semantic-identity.org",
        "scope": "Registry content transition, authority-issued retirement, successor admission, and adjacent same-domain rotation.",
        "headings": [
            "Registry content-transition governance",
            "Successor descriptor admission and same-domain rotation",
        ],
    },
    {
        "path": "45-07-13-recovery-and-replica-provenance.org",
        "title": "Mix/Profile RFC — Recovery And Replica Provenance",
        "depends": "45-07-12-registry-transition-and-admission.org",
        "scope": "Content-aware recovery, N-way replica summaries, authority-issued origin provenance, interval admission, and recovered-head floors.",
        "headings": [
            "Registry recovery and replica content-evidence propagation",
            "N-way content-aware replica summary",
            "Authority-issued replica-summary provenance",
            "Recovered-only descriptor admission witness",
            "Authority-provenance recovered-head floor",
        ],
    },
    {
        "path": "45-07-14-recovery-authority-and-lifecycle-join.org",
        "title": "Mix/Profile RFC — Recovery Authority And Lifecycle Join",
        "depends": "45-07-13-recovery-and-replica-provenance.org",
        "scope": "Gap-separated domain rotation, recovery-authority claims, retirement issuance, full Cedar registry evidence, and lifecycle join closure.",
        "headings": [
            "Gap-separated same-domain rotation",
            "Recovery-authority registry-claim binding",
            "Authority-issued descriptor retirement",
            "Full Cedar lifecycle registry join",
            "Cedar lifecycle join closure",
        ],
    },
]

target_to_group = {}
ordered_targets = []
for group in groups:
    for heading in group["headings"]:
        if heading in target_to_group:
            raise SystemExit(f"duplicate target heading: {heading}")
        target_to_group[heading] = group["path"]
        ordered_targets.append(heading)

actual_headings = [heading for _, heading in heading_starts]
missing = [heading for heading in ordered_targets if heading not in actual_headings]
if missing:
    raise SystemExit(f"missing target headings: {missing}")

first_target_index = actual_headings.index(ordered_targets[0])
actual_target_tail = actual_headings[first_target_index:]
if actual_target_tail != ordered_targets:
    raise SystemExit(
        "proof tranche tail differs from parser-owned migration map:\n"
        f"expected={ordered_targets}\nactual={actual_target_tail}"
    )

block_by_heading = {}
for position, (start, heading) in enumerate(heading_starts):
    end = heading_starts[position + 1][0] if position + 1 < len(heading_starts) else len(lines)
    block_by_heading[heading] = "".join(lines[start:end])

first_target_line = heading_starts[first_target_index][0]
hub_prefix = "".join(lines[:first_target_line]).rstrip() + "\n\n"
navigation = """** Companion proof tranches

This file owns only the public =use-composition=, Profile, Mix, macro, identity,
and module-interface surface.  Formal enterprise proof tranches are maintained
as independent Org RFC modules:

- [[file:45-07-10-cedar-capability-and-input-identity.org][45-07-10 — Cedar capability and input identity]]
- [[file:45-07-11-registry-trust-and-semantic-identity.org][45-07-11 — Registry trust and semantic identity]]
- [[file:45-07-12-registry-transition-and-admission.org][45-07-12 — Registry transition and admission]]
- [[file:45-07-13-recovery-and-replica-provenance.org][45-07-13 — Recovery and replica provenance]]
- [[file:45-07-14-recovery-authority-and-lifecycle-join.org][45-07-14 — Recovery authority and lifecycle join]]

The companion sequence is normative.  Each module owns its Requirement,
counterexample, Typst model, Mermaid closure, Decision, Checklist, and execution
receipt; this hub does not duplicate those bodies.
"""
source_path.write_text(hub_prefix + navigation)

docs_dir = source_path.parent
for group in groups:
    body = "".join(block_by_heading[heading] for heading in group["headings"])
    header = (
        f"#+title: {group['title']}\n"
        "#+status: draft\n"
        "#+parent: 45-07-user-composition-and-mix-module-interface.org\n"
        f"#+depends_on: {group['depends']}\n\n"
        "* Scope\n\n"
        f"{group['scope']}\n\n"
        "The public composition contract remains in "
        "[[file:45-07-user-composition-and-mix-module-interface.org][45-07]].\n\n"
    )
    (docs_dir / group["path"]).write_text(header + body)

print(f"hub={source_path.name} companions={len(groups)} moved_headings={len(ordered_targets)}")
