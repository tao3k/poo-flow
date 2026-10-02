# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Run a bounded study in which the model reads Gerbil Scheme source."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

from ..ascent.live import key_from_file
from .protocol import require_clean, require_pinned_ascent
from .runner import source_head

HERE = Path(__file__).resolve().parent / "scheme_source"
CASES = ("withdrawal", "wrong_join", "negation_count")
ANSWER_ALPHABET = re.compile(r"[()\s0-9A-Za-z-]+\Z")
MODEL = "deepseek-flash"


def native(script: Path, root: Path, ascent_root: Path, gerbil_path: Path,
           *arguments: Path) -> str:
    env = os.environ.copy()
    env.pop("DEEPSEEK_API_KEY", None)
    env["GERBIL_PATH"] = str(gerbil_path)
    env["GERBIL_LOADPATH"] = str(ascent_root)
    result = subprocess.run(
        ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi", str(script),
         *(str(argument) for argument in arguments)],
        cwd=root, env=env, text=True, capture_output=True,
        timeout=90, check=True,
    )
    lines = [line for line in result.stdout.splitlines() if line.startswith("(")]
    if len(lines) != 1:
        raise RuntimeError(f"native Scheme script emitted {len(lines)} data lines")
    return lines[0] + "\n"


def preview(preview_dir: Path, ascent_root: Path, poo_root: Path,
            gerbil_path: Path) -> dict[str, str]:
    if preview_dir.exists():
        raise FileExistsError(preview_dir)
    if preview_dir.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("study preview must stay outside the repository")
    preview_dir.mkdir(parents=True)
    expected_dir = preview_dir / "expected"
    expected_dir.mkdir()
    digests = {}
    for case in CASES:
        source = HERE / f"{case}.ss"
        payload = source.read_bytes()
        shutil.copyfile(source, preview_dir / f"{case}.ss")
        expected = native(source, poo_root, ascent_root, gerbil_path)
        (expected_dir / f"{case}.sexp").write_text(expected, encoding="utf-8")
        digests[case] = hashlib.sha256(payload).hexdigest()
    (preview_dir / "manifest.tsv").write_text(
        "case\tpayload_sha256\tascent_head\tpoo_head\tmodel\trepeats\n"
        + "".join(
            f"{case}\t{digests[case]}\t{source_head(ascent_root)}\t"
            f"{source_head(poo_root)}\t{MODEL}\t3\n" for case in CASES
        ), encoding="utf-8",
    )
    return digests


def readable_answer(raw: str) -> bool:
    if len(raw) > 2048 or not ANSWER_ALPHABET.fullmatch(raw):
        return False
    depth = 0
    for character in raw:
        if character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def live(preview_dir: Path, output_dir: Path, ascent_root: Path, poo_root: Path,
         gerbil_path: Path, api_key: str) -> None:
    from openai import OpenAI

    require_clean(ascent_root)
    require_clean(poo_root)
    require_pinned_ascent(ascent_root, poo_root)
    if output_dir.exists():
        raise FileExistsError(output_dir)
    if output_dir.resolve().is_relative_to(poo_root.resolve()):
        raise ValueError("raw model responses must stay outside the repository")
    preview_rows = (preview_dir / "manifest.tsv").read_text(encoding="utf-8").splitlines()
    if len(preview_rows) != len(CASES) + 1:
        raise RuntimeError("preview manifest has unexpected case count")
    for case, row in zip(CASES, preview_rows[1:], strict=True):
        name, digest, ascent_head, poo_head, model, repeats = row.split("\t")
        payload = (preview_dir / f"{case}.ss").read_bytes()
        if (name != case or hashlib.sha256(payload).hexdigest() != digest
                or ascent_head != source_head(ascent_root)
                or poo_head != source_head(poo_root)
                or model != MODEL or repeats != "3"
                or payload != (HERE / f"{case}.ss").read_bytes()):
            raise RuntimeError("preview no longer matches committed source and heads")
        expected = native(HERE / f"{case}.ss", poo_root,
                          ascent_root, gerbil_path)
        if expected != (preview_dir / "expected" / f"{case}.sexp").read_text(
                encoding="utf-8"):
            raise RuntimeError("native answer changed since preview")
    output_dir.mkdir(parents=True)
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com",
                    max_retries=0, timeout=45.0)
    manifest = output_dir / "manifest.tsv"
    manifest.write_text("case\trepeat\tstatus\tvalid\tcorrect\tseconds\tresponse_id\n",
                        encoding="utf-8")
    scorer_env = os.environ.copy()
    scorer_env.pop("DEEPSEEK_API_KEY", None)
    scorer_env["GERBIL_PATH"] = str(gerbil_path)
    scorer_env["GERBIL_LOADPATH"] = str(ascent_root)
    with subprocess.Popen(
        ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi", str(HERE / "score.ss")],
        cwd=poo_root, env=scorer_env, text=True, bufsize=1,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    ) as scorer:
        assert scorer.stdin is not None and scorer.stdout is not None
        for case in CASES:
            payload = (preview_dir / f"{case}.ss").read_text(encoding="utf-8")
            expected = preview_dir / "expected" / f"{case}.sexp"
            for repeat in range(1, 4):
                started = time.perf_counter()
                response = client.responses.create(
                    model=MODEL, input=[{"role": "user", "content": payload}],
                    reasoning={"effort": "none"}, temperature=0,
                    max_output_tokens=512,
                )
                seconds = round(time.perf_counter() - started, 3)
                raw = response.output_text
                answer = output_dir / f"{case}-{repeat}.sexp"
                answer.write_text(raw, encoding="utf-8")
                valid = correct = False
                if response.status == "completed" and readable_answer(raw):
                    scorer.stdin.write(
                        f"{json.dumps(str(expected))} {json.dumps(str(answer))}\n"
                    )
                    scorer.stdin.flush()
                    score = scorer.stdout.readline()
                    if not score.startswith("(score "):
                        raise RuntimeError("native Scheme scorer did not return a score")
                    valid = "(valid #t)" in score
                    correct = "(correct #t)" in score
                with manifest.open("a", encoding="utf-8") as file:
                    file.write(f"{case}\t{repeat}\t{response.status}\t"
                               f"{str(valid).lower()}\t{str(correct).lower()}\t"
                               f"{seconds}\t{response.id}\n")
        scorer.stdin.write("quit\n")
        scorer.stdin.flush()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ascent-root", type=Path, required=True)
    parser.add_argument("--poo-root", type=Path, required=True)
    parser.add_argument("--gerbil-path", type=Path, required=True)
    parser.add_argument("--preview-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--env-file", type=Path)
    args = parser.parse_args()
    if args.output_dir is None:
        print(preview(args.preview_dir, args.ascent_root, args.poo_root,
                      args.gerbil_path))
        return 0
    api_key = os.environ.get("DEEPSEEK_API_KEY") or (
        key_from_file(args.env_file) if args.env_file else ""
    )
    if not api_key:
        parser.error("DEEPSEEK_API_KEY or --env-file is required for a live run")
    live(args.preview_dir, args.output_dir, args.ascent_root, args.poo_root,
         args.gerbil_path, api_key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
