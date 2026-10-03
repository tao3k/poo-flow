# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Internal runtime handoff for a privately frozen TLA source/toolchain bundle.

The POO control plane owns semantic projection. This backend only checks the
exact supplied source bundle with an owner-pinned Java toolchain. It does not
admit a caller's semantic-refinement or action-authorization assertion.
"""
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import tempfile
import time
from typing import Callable, Mapping


def digest(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def framed_digest(values) -> str:
    return digest(b"".join(str(len(value.encode("utf-8"))).encode() + b":" + value.encode("utf-8") + b"," for value in values))


def file_digest(path: Path) -> str:
    hashed = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1 << 20), b""):
            hashed.update(block)
    return "sha256:" + hashed.hexdigest()


@dataclass(frozen=True)
class TlcToolchain:
    java: Path
    jar: Path
    # Configured by the trusted host: the entire Java home file inventory,
    # TLC JAR and additional runtime dependencies. Host OS/filesystem are the
    # declared trust base, rather than a claimed transitive system proof.
    artifacts: tuple[tuple[Path, str], ...]

    def verify(self) -> str:
        paths = [str(path.resolve()) for path, _ in self.artifacts]
        java_home = self.java.resolve().parent.parent
        required = {str(path.resolve()) for path in java_home.rglob("*") if path.is_file()}
        required.update((str(self.java.resolve()), str(self.jar.resolve())))
        if len(paths) != len(set(paths)) or not required.issubset(paths) or not all(Path(p).is_absolute() for p in paths):
            raise ValueError("toolchain must uniquely pin the entire Java home, TLC JAR and runtime artifacts")
        rows = []
        for path, expected in self.artifacts:
            actual = file_digest(path)
            if actual != expected:
                raise ValueError(f"toolchain artifact differs from owner pin: {path.name}")
            rows.append((str(path.resolve()), actual))
        return framed_digest(["poo-flow.tlc.toolchain.v1", str(self.java), str(self.jar), *(item for row in sorted(rows) for item in row)])


@dataclass(frozen=True)
class FrozenTlcReceipt:
    bundle_digest: str
    source_digests: tuple[tuple[str, str], ...]
    toolchain_digest: str
    output_digest: str
    output: bytes
    exit_code: int
    checked: bool
    semantic_refinement: bool = False
    action_authorized: bool = False


def check_frozen_bundle(sources: Mapping[str, bytes], *, root: str, toolchain: TlcToolchain,
                        workers: int = 1, timeout: float = 90,
                        output: Callable[[bytes], None] | None = None) -> FrozenTlcReceipt:
    """TLC sees only private snapshots and the pinned classpath.

    Root + every custom imported module + config belong in sources. No ambient
    TLA_LIBRARY, Java option injection, caller cwd or caller classpath is used.
    The trusted host selects pins; hashes alone are not source authority.
    """
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", root) or type(workers) is not int or workers < 1 or timeout <= 0:
        raise ValueError("invalid frozen TLC request")
    snapshot = dict(sources)
    if root + ".tla" not in snapshot or root + ".cfg" not in snapshot:
        raise ValueError("root and config are required")
    for name, data in snapshot.items():
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*\.(tla|cfg)", name) or not isinstance(data, bytes):
            raise ValueError("source bundle permits flat module/config byte snapshots only")
    tool_digest = toolchain.verify()
    rows = tuple(sorted((name, digest(data)) for name, data in snapshot.items()))
    bundle_digest = framed_digest(["poo-flow.tlc.private-bundle.v1", root, str(workers), tool_digest, *(item for row in rows for item in row)])
    with tempfile.TemporaryDirectory(prefix="poo-flow-tlc-") as directory:
        base = Path(directory)
        for name, data in snapshot.items():
            (base / name).write_bytes(data)
            (base / name).chmod(0o400)
        env = {"PATH": "/usr/bin:/bin", "LANG": "C", "HOME": directory, "TMPDIR": directory}
        command = [str(toolchain.java.resolve()), "-Xmx1g", "-Duser.home=" + directory,
                   "-Djava.io.tmpdir=" + directory, "-Dfile.encoding=UTF-8", "-DTLA-Library=" + directory,
                   "-cp", str(toolchain.jar.resolve()), "tlc2.TLC", "-workers", str(workers),
                   "-metadir", str(base / "states"), "-config", root + ".cfg", root]
        child = subprocess.Popen(command, cwd=base, env=env, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        selector = selectors.DefaultSelector()
        selector.register(child.stdout, selectors.EVENT_READ)
        started = last = time.monotonic()
        chunks = []
        try:
            while selector.get_map():
                now = time.monotonic()
                if now - started >= timeout or now - last >= 5:
                    raise TimeoutError("frozen TLC gate exceeded total or five-second output deadline")
                for key, _ in selector.select(min(timeout - (now - started), 5 - (now - last))):
                    data = os.read(key.fd, 65536)
                    if not data:
                        selector.unregister(key.fileobj)
                    else:
                        last = time.monotonic()
                        chunks.append(data)
                        if output:
                            output(data)
            status = child.wait(timeout=max(.01, min(5, timeout - (time.monotonic() - started))))
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
            selector.close()
            child.stdout.close()
        # Owner pins and snapshot contents must still agree at completion.
        if toolchain.verify() != tool_digest or any(file_digest(base / name) != sha for name, sha in rows):
            raise ValueError("frozen TLC inputs changed during execution")
        transcript = b"".join(chunks)
        checked = status == 0 and b"Model checking completed. No error has been found." in transcript
        return FrozenTlcReceipt(bundle_digest, rows, tool_digest, digest(transcript), transcript, status, checked)


def _cli():
    """Owned JSON transport for the POO runtime handoff, not a user model DSL."""
    import sys
    request = json.loads(Path(sys.argv[1]).read_text())
    config = request["toolchain"]
    toolchain = TlcToolchain(Path(config["java"]), Path(config["jar"]),
                            tuple((Path(path), sha) for path, sha in config["artifacts"]))
    def emit(data):
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
    receipt = check_frozen_bundle({name: text.encode("utf-8") for name, text in request["sources"].items()},
                                  root=request["root"], workers=request["workers"], toolchain=toolchain, output=emit)
    row = {"schema": "poo-flow.tlc.private-bundle.v1", "bundle": receipt.bundle_digest,
           "sources": receipt.source_digests, "toolchain": receipt.toolchain_digest,
           "output": receipt.output.decode("utf-8"), "output_digest": receipt.output_digest,
           "exit_code": receipt.exit_code, "checked": receipt.checked,
           "semantic_refinement": False, "action_authorized": False}
    print("POO-FROZEN-RECEIPT " + json.dumps(row, ensure_ascii=False, separators=(",", ":")), flush=True)


if __name__ == "__main__":
    _cli()
