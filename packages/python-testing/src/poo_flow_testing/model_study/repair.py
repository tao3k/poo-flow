# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Preview and run one Scheme candidate, native receipt, and repair turn."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import select
import shutil
import subprocess
import time
from pathlib import Path

from ..ascent.candidate import candidate_text
from ..ascent.live import key_from_file
from .protocol import require_clean, require_pinned_ascent
from .reporting import report_json
from .runner import source_head
from .scheme import native as native_control, readable_answer

HERE = Path(__file__).resolve().parent / "scheme_source"
MODEL = "deepseek-flash"
TASK = "repair_task.ss"
CONTROLS = ("control_pure", "control_contract")


def repair_payload(task: str, candidate: str, receipt: str) -> str:
    return (task + "\n;;; Native tool feedback; one repair turn only.\n"
            + f"(def prior-candidate '{candidate})\n"
            + f"(def native-receipt '{receipt})\n"
            + ";;; Return one corrected (candidate ...) datum.\n")


def syntax_payload(task: str) -> str:
    return (task + "\n;;; Native reader rejected the first output's"
            " candidate syntax. Return one (candidate ...) datum.\n")


def scheme_env(ascent_root: Path, gerbil_path: Path) -> dict[str, str]:
    env = os.environ.copy()
    env.pop("DEEPSEEK_API_KEY", None)
    env["GERBIL_PATH"] = str(gerbil_path)
    env["GERBIL_LOADPATH"] = str(ascent_root)
    return env


def score(receipt_path: Path, poo_root: Path, ascent_root: Path,
          gerbil_path: Path) -> str:
    result = subprocess.run(
        ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi",
         str(HERE / "repair_score.ss"), str(receipt_path)],
        cwd=poo_root, env=scheme_env(ascent_root, gerbil_path),
        capture_output=True, text=True, timeout=90, check=True,
    )
    scores = [line for line in result.stdout.splitlines()
              if line.startswith("(score ")]
    if len(scores) != 1:
        raise RuntimeError("native scorer returned no unique score")
    return scores[0]


def control_score(expected: Path, answer: Path, poo_root: Path,
                  ascent_root: Path, gerbil_path: Path) -> str:
    result = subprocess.run(
        ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi",
         str(HERE / "score.ss"), str(expected), str(answer)],
        cwd=poo_root, env=scheme_env(ascent_root, gerbil_path),
        capture_output=True, text=True, timeout=90, check=True,
    )
    scores = [line for line in result.stdout.splitlines()
              if line.startswith("(score ")]
    if len(scores) != 1:
        raise RuntimeError("control scorer returned no unique score")
    return scores[0]


class NativeTool:
    def __init__(self, poo_root: Path, ascent_root: Path,
                 gerbil_path: Path) -> None:
        self.process = subprocess.Popen(
            ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi",
             str(HERE / "repair_attempt.ss")],
            cwd=poo_root, env=scheme_env(ascent_root, gerbil_path),
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        self.pending = b""
        self.last_native_ns: int | None = None

    def attempt(self, candidate: str) -> str:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("native tool pipes unavailable")
        self.process.stdin.write((candidate + "\n").encode("ascii"))
        self.process.stdin.flush()
        deadline = time.monotonic() + 90
        lines: list[str] = []
        while True:
            if b"\n" in self.pending:
                raw, self.pending = self.pending.split(b"\n", 1)
                line = raw.decode("utf-8")
                if line == "END":
                    break
                lines.append(line)
                continue
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                self.process.kill()
                raise TimeoutError("native tool exceeded 90 seconds")
            readable, _, _ = select.select([self.process.stdout], [], [], remaining)
            if not readable:
                continue
            chunk = os.read(self.process.stdout.fileno(), 4096)
            if not chunk:
                raise RuntimeError("native tool exited without a receipt")
            self.pending += chunk
        receipts = [line for line in lines if line.startswith("(receipt ")]
        timings = [line for line in lines if line.startswith("TIMING ")]
        if len(receipts) != 1 or len(timings) != 1:
            raise RuntimeError("native tool returned no unique receipt")
        self.last_native_ns = int(timings[0].split()[1])
        return receipts[0] + "\n"

    def close(self) -> None:
        if self.process.stdin is not None:
            self.process.stdin.close()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        if self.process.stdout is not None:
            self.process.stdout.close()


def preview(directory: Path, poo_root: Path, ascent_root: Path,
            gerbil_path: Path, repair_only: bool = False) -> None:
    if directory.exists():
        raise FileExistsError(directory)
    if directory.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("preview must stay outside the repository")
    directory.mkdir(parents=True)
    source = HERE / TASK
    shutil.copyfile(source, directory / TASK)
    if not repair_only:
        expected_dir = directory / "expected"
        expected_dir.mkdir()
        control_digests = []
        for name in CONTROLS:
            control = HERE / f"{name}.ss"
            shutil.copyfile(control, directory / control.name)
            (expected_dir / f"{name}.sexp").write_text(
                native_control(control, poo_root, ascent_root, gerbil_path),
                encoding="utf-8",
            )
            control_digests.append(
                f"{name}\t{hashlib.sha256(control.read_bytes()).hexdigest()}\n"
            )
        (directory / "controls.tsv").write_text(
            "name\tpayload_sha256\n" + "".join(control_digests),
            encoding="utf-8",
        )
    task = source.read_text(encoding="utf-8")
    (directory / "repair-template.ss").write_text(
        repair_payload(task, "<candidate-from-first-call>",
                       "<native-receipt-from-tool>"), encoding="utf-8",
    )
    (directory / "syntax-template.ss").write_text(
        syntax_payload(task), encoding="utf-8",
    )
    (directory / "manifest.tsv").write_text(
        "payload_sha256\tascent_head\tpoo_head\tmodel\tmax_calls\n"
        f"{hashlib.sha256(source.read_bytes()).hexdigest()}\t"
        f"{source_head(ascent_root)}\t{source_head(poo_root)}\t{MODEL}\t"
        f"{2 if repair_only else 4}\n",
        encoding="utf-8",
    )


def live(directory: Path, output: Path, poo_root: Path, ascent_root: Path,
         gerbil_path: Path, api_key: str, repair_only: bool = False) -> None:
    from openai import OpenAI

    require_clean(poo_root)
    require_clean(ascent_root)
    require_pinned_ascent(ascent_root, poo_root)
    if output.exists():
        raise FileExistsError(output)
    if output.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("raw output must stay outside the repository")
    header, row = (directory / "manifest.tsv").read_text(
        encoding="utf-8").splitlines()
    if header != "payload_sha256\tascent_head\tpoo_head\tmodel\tmax_calls":
        raise RuntimeError("preview manifest changed")
    digest, ascent_head, poo_head, model, max_calls = row.split("\t")
    payload = (directory / TASK).read_text(encoding="utf-8")
    if (hashlib.sha256(payload.encode()).hexdigest() != digest
            or payload != (HERE / TASK).read_text(encoding="utf-8")
            or ascent_head != source_head(ascent_root)
            or poo_head != source_head(poo_root)
            or model != MODEL
            or max_calls != ("2" if repair_only else "4")):
        raise RuntimeError("preview no longer matches committed source and heads")
    if ((directory / "repair-template.ss").read_text(encoding="utf-8")
            != repair_payload(payload, "<candidate-from-first-call>",
                              "<native-receipt-from-tool>")
            or (directory / "syntax-template.ss").read_text(
                encoding="utf-8") != syntax_payload(payload)):
        raise RuntimeError("repair preview changed")
    if repair_only:
        if (directory / "controls.tsv").exists():
            raise RuntimeError("repair-only preview unexpectedly has controls")
    else:
        control_rows = (directory / "controls.tsv").read_text(
            encoding="utf-8").splitlines()
        if (len(control_rows) != len(CONTROLS) + 1
                or control_rows[0] != "name\tpayload_sha256"):
            raise RuntimeError("control manifest changed")
        for name, row in zip(CONTROLS, control_rows[1:], strict=True):
            actual_name, control_digest = row.split("\t")
            control = (directory / f"{name}.ss").read_bytes()
            if (actual_name != name
                    or hashlib.sha256(control).hexdigest() != control_digest
                    or control != (HERE / f"{name}.ss").read_bytes()
                    or (directory / "expected" / f"{name}.sexp").read_text(
                        encoding="utf-8") != native_control(
                            HERE / f"{name}.ss", poo_root,
                            ascent_root, gerbil_path)):
                raise RuntimeError("control preview changed")
    output.mkdir(parents=True)
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com",
                    max_retries=0, timeout=45.0)
    records: list[dict[str, object]] = []
    try:
        for name in (() if repair_only else CONTROLS):
            control_payload = (directory / f"{name}.ss").read_text(
                encoding="utf-8")
            started = time.perf_counter()
            response = client.responses.create(
                model=MODEL, input=[{"role": "user", "content": control_payload}],
                reasoning={"effort": "none"}, temperature=0,
                max_output_tokens=512,
            )
            raw = response.output_text
            answer = output / f"{name}.sexp"
            answer.write_text(raw, encoding="utf-8")
            verdict = "(score (valid #f) (correct #f))"
            if response.status == "completed" and readable_answer(raw):
                verdict = control_score(
                    directory / "expected" / f"{name}.sexp", answer,
                    poo_root, ascent_root, gerbil_path,
                )
            records.append({"case": name, "response_id": response.id,
                            "status": response.status, "native_score": verdict,
                            "seconds": round(time.perf_counter() - started, 3)})
        tool = NativeTool(poo_root, ascent_root, gerbil_path)
        try:
            run_repair(tool, client, directory, output, poo_root,
                       ascent_root, gerbil_path, records, payload)
        finally:
            tool.close()
    finally:
        (output / "manifest.json").write_text(
            json.dumps(records, indent=2) + "\n", encoding="utf-8",
        )


def run_repair(tool: NativeTool, client: object, directory: Path, output: Path,
               poo_root: Path, ascent_root: Path, gerbil_path: Path,
               records: list[dict[str, object]], payload: str) -> None:
    for turn in (1, 2):
        started = time.perf_counter()
        response = client.responses.create(
            model=MODEL, input=[{"role": "user", "content": payload}],
            reasoning={"effort": "none"}, temperature=0,
            max_output_tokens=1024,
        )
        raw = response.output_text
        (output / f"candidate-{turn}.sexp").write_text(raw, encoding="utf-8")
        candidate = candidate_text(raw) if response.status == "completed" else None
        if candidate is None:
            records.append({"case": "repair", "turn": turn,
                            "response_id": response.id,
                            "status": response.status, "syntax": False,
                            "seconds": round(time.perf_counter() - started, 3)})
            if turn == 1:
                payload = syntax_payload(
                    (directory / TASK).read_text(encoding="utf-8"))
            continue
        receipt = tool.attempt(candidate)
        native_ns = tool.last_native_ns
        receipt_path = output / f"receipt-{turn}.sexp"
        receipt_path.write_text(receipt, encoding="utf-8")
        verdict = score(receipt_path, poo_root, ascent_root, gerbil_path)
        records.append({"case": "repair", "turn": turn,
                        "response_id": response.id,
                        "status": response.status, "syntax": True,
                        "native_score": verdict,
                        "native_seconds": round(native_ns / 1e9, 3)
                        if native_ns is not None else None,
                        "seconds": round(time.perf_counter() - started, 3)})
        if verdict == "(score (exact #t))":
            break
        payload = repair_payload(
            (directory / TASK).read_text(encoding="utf-8"),
            candidate, receipt.strip(),
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--poo-root", type=Path, required=True)
    parser.add_argument("--ascent-root", type=Path, required=True)
    parser.add_argument("--gerbil-path", type=Path, required=True)
    parser.add_argument("--preview-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--env-file", type=Path)
    parser.add_argument("--repair-only", action="store_true",
                        help="reuse the already scored control calls")
    args = parser.parse_args()
    if args.output_dir is None:
        preview(args.preview_dir, args.poo_root, args.ascent_root,
                args.gerbil_path, args.repair_only)
        report_json({"preview": str(args.preview_dir),
                     "max_calls": 2 if args.repair_only else 4})
        return 0
    api_key = os.environ.get("DEEPSEEK_API_KEY") or (
        key_from_file(args.env_file) if args.env_file else ""
    )
    if not api_key:
        parser.error("DEEPSEEK_API_KEY or --env-file is required")
    live(args.preview_dir, args.output_dir, args.poo_root,
         args.ascent_root, args.gerbil_path, api_key, args.repair_only)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
