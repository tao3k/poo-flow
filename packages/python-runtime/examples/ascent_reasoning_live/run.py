"""Interactive DeepSeek access to the Scheme-native reasoning candidate check."""

from __future__ import annotations

import argparse
import json
import os
import re
import select
import subprocess
import sys
import time
from pathlib import Path

from openai import OpenAI
from poo_flow_runtime import RuntimeGraphExecutor, linear_plan

HERE = Path(__file__).resolve().parent
ALLOWED = re.compile(r"[A-Za-z0-9_?+*<>=!()\s-]+\Z", re.ASCII)


def key_from_file(path: Path) -> str:
    """Load one credential without evaluating the env file or printing it."""
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"(?:export\s+)?DEEPSEEK_API_KEY\s*=\s*(.+)", line)
        if match:
            value = match.group(1).strip().strip("\"'")
            if value:
                return value
    raise ValueError("DEEPSEEK_API_KEY is absent from the selected env file")


def candidate_text(output: str) -> str | None:
    text = output.strip()
    if text.startswith("```") and text.endswith("```"):
        lines = text.splitlines()
        if len(lines) >= 3 and lines[0] in ("```", "```scheme", "```gerbil"):
            text = "\n".join(lines[1:-1]).strip()
    if not text.startswith("(candidate "):
        if not text.startswith("(candidate\n"):
            return None
    if len(text) > 16384 or not ALLOWED.fullmatch(text):
        return None
    depth = 0
    for index, char in enumerate(text):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if depth < 0 or depth > 128:
            return None
        if depth == 0 and text[index + 1:].strip():
            return None
    return text if depth == 0 else None


class SchemeChecker:
    """One temporary Gerbil worker per experiment conversation."""

    def __init__(self, ascent_root: Path | None = None) -> None:
        env = os.environ.copy()
        if ascent_root is not None:
            env["GERBIL_LOADPATH"] = str(ascent_root) + (
                ":" + env["GERBIL_LOADPATH"] if env.get("GERBIL_LOADPATH") else ""
            )
        self.process = subprocess.Popen(
            ["gerbil", "-:max-heap=1G,debug=q", "env", "gxi",
             str(HERE / "attempt.ss")],
            cwd=ascent_root or HERE, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, env=env,
        )
        self.pending = b""

    def attempt(self, candidate: str) -> dict[str, str]:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("Scheme worker pipes are unavailable")
        self.process.stdin.write((candidate + "\n").encode("ascii"))
        self.process.stdin.flush()
        deadline = time.monotonic() + 45
        lines = []
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
                raise RuntimeError("Scheme worker exceeded 45 seconds")
            ready, _, _ = select.select([self.process.stdout], [], [], remaining)
            if not ready:
                continue
            chunk = os.read(self.process.stdout.fileno(), 4096)
            if not chunk:
                raise RuntimeError("Scheme worker exited before its receipt")
            self.pending += chunk
        fields = dict(line.split("\t", 1) for line in lines)
        required = {"status", "rows", "bound", "snapshot-digest",
                    "candidate-digest", "diagnostics", "after-status",
                    "after-rows", "after-bound", "after-snapshot-digest"}
        if set(fields) != required:
            raise RuntimeError("Scheme worker returned an incomplete receipt")
        return fields

    def close(self) -> None:
        if self.process.stdin:
            try:
                self.process.stdin.close()
            except BrokenPipeError:
                pass
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        if self.process.stdout:
            self.process.stdout.close()


def scheme_attempt(candidate: str, ascent_root: Path | None = None) -> dict[str, str]:
    checker = SchemeChecker(ascent_root)
    try:
        return checker.attempt(candidate)
    finally:
        checker.close()


def build_graph(client: OpenAI, model: str, checker=scheme_attempt) -> RuntimeGraphExecutor:
    """The downstream adapter owns model and Scheme nodes, not graph semantics."""

    def model_turn(state: dict) -> dict:
        started = time.perf_counter()
        events = client.responses.create(
            model=model, input=state["messages"], max_output_tokens=4096,
            reasoning={"effort": "none"}, stream=True,
        )
        print("model> ", end="", flush=True)
        chunks: list[str] = []
        response = None
        first_token_seconds = None
        for event in events:
            if event.type == "response.output_text.delta":
                if first_token_seconds is None:
                    first_token_seconds = round(time.perf_counter() - started, 3)
                chunks.append(event.delta)
                print(event.delta, end="", flush=True)
            elif event.type in ("response.completed", "response.incomplete",
                                "response.failed"):
                response = event.response
        print(flush=True)
        if response is None:
            raise RuntimeError("DeepSeek stream ended without a final response")
        if response.status != "completed":
            reason = getattr(response.incomplete_details, "reason", None)
            raise RuntimeError(f"DeepSeek response status: {response.status} ({reason})")
        return {"output": "".join(chunks), "response_id": response.id,
                "usage": response.usage.model_dump() if response.usage else None,
                "model_seconds": round(time.perf_counter() - started, 3),
                "first_token_seconds": first_token_seconds}

    def check_candidate(state: dict) -> dict:
        started = time.perf_counter()
        candidate = candidate_text(state["output"])
        if candidate is None:
            return {"receipt": None, "scheme_seconds": 0.0}
        return {"receipt": checker(candidate),
                "scheme_seconds": round(time.perf_counter() - started, 3)}

    return RuntimeGraphExecutor(
        linear_plan("model", "candidate"),
        {"model": model_turn, "candidate": check_candidate},
    )


def converse(api_key: str, model: str, transcript: Path | None,
             ascent_root: Path | None) -> None:
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com",
                    max_retries=0, timeout=90.0)
    checker = SchemeChecker(ascent_root)
    graph = build_graph(client, model, checker.attempt)
    messages: list[dict[str, str]] = []
    print("DeepSeek interactive session. No initial prompt or instructions are sent.")
    print("Type /quit to end. Scheme sample source: edge/2 = {(0,1), (1,2)};")
    print("a second snapshot withdraws (1,2). Exact candidate data is checked locally.")
    while True:
        try:
            user = input("you> ")
        except EOFError:
            break
        if user == "/quit":
            break
        if not user.strip():
            continue
        messages.append({"role": "user", "content": user})
        try:
            result, trace = graph.invoke_with_trace({"messages": list(messages)})
        except Exception as error:
            messages.pop()
            print("turn failed> " + type(error).__name__)
            continue
        raw = result["output"]
        event: dict = {"user": user, "model": raw,
                       "response_id": result["response_id"],
                       "usage": result["usage"], "runtime_trace": trace,
                       "model_seconds": result["model_seconds"],
                       "first_token_seconds": result["first_token_seconds"],
                       "scheme_seconds": result["scheme_seconds"]}
        messages.append({"role": "assistant", "content": raw})
        print("timing> first token", result["first_token_seconds"],
              "s; model", result["model_seconds"], "s; Scheme",
              result["scheme_seconds"], "s")
        if result["receipt"] is not None:
            print("Scheme receipt> " + json.dumps(result["receipt"], ensure_ascii=False))
            event["receipt"] = result["receipt"]
        if transcript is not None:
            with transcript.open("a", encoding="utf-8") as file:
                file.write(json.dumps(event, ensure_ascii=False) + "\n")
    checker.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default="deepseek-flash")
    parser.add_argument("--env-file", type=Path)
    parser.add_argument("--transcript", type=Path,
                        help="optional local JSONL transcript path")
    parser.add_argument("--ascent-root", type=Path,
                        help="local Gerbil package checkout if not installed by gxpkg")
    args = parser.parse_args()
    api_key = os.environ.get("DEEPSEEK_API_KEY") or (
        key_from_file(args.env_file) if args.env_file else ""
    )
    if not api_key:
        parser.error("DEEPSEEK_API_KEY or --env-file is required")
    converse(api_key, args.model, args.transcript, args.ascent_root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
