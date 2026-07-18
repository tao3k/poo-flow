from __future__ import annotations

import hashlib
import tempfile
import unittest
from pathlib import Path

from _scheme_datum import parse_scheme_datum, write_scheme_datum
from tools.bazel import scheme_projection_artifact_tool as projection_tool


class SchemeProjectionArtifactToolTest(unittest.TestCase):
    def test_main_writes_packaged_digest_envelope(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "flow.ss"
            projection = root / "runtime-load-projection.ss"
            compiled_root = root / "compiled"
            dependency_marker = root / "dependencies" / ".root"
            output = root / "flow.ss.poo-flow-projection.sexp"
            fake_gxi = root / "gxi"

            source.write_text("(use-composition smoke)\n", encoding="utf-8")
            projection.write_text(";; projection\n", encoding="utf-8")
            (compiled_root / "lib" / "poo-flow").mkdir(parents=True)
            dependency_marker.parent.mkdir(parents=True)
            dependency_marker.write_text("dependencies\n", encoding="utf-8")
            fake_gxi.write_text(
                "#!/bin/sh\n"
                "printf '%s\\n' '((\"schema\" \"projection.v1\") "
                "(\"name\" \"smoke\"))'\n",
                encoding="utf-8",
            )
            fake_gxi.chmod(0o755)

            status = projection_tool.main(
                [
                    "--gxi",
                    str(fake_gxi),
                    "--compiled-root",
                    str(compiled_root),
                    "--dependency-root-marker",
                    str(dependency_marker),
                    "--projection-source",
                    str(projection),
                    "--source",
                    str(source),
                    "--output",
                    str(output),
                ]
            )

            artifact = dict(parse_scheme_datum(output.read_text(encoding="utf-8")))
            expected = (
                ("schema", projection_tool.SCHEMA),
                ("source-digest", _digest(source)),
                ("projection-digest", _digest(projection)),
                (
                    "rows",
                    (("schema", "projection.v1"), ("name", "smoke")),
                ),
            )
            self.assertEqual(status, 0)
            self.assertEqual(
                output.read_text(encoding="utf-8"),
                write_scheme_datum(expected) + "\n",
            )
            self.assertEqual(artifact["schema"], projection_tool.SCHEMA)
            self.assertEqual(artifact["source-digest"], _digest(source))
            self.assertEqual(artifact["projection-digest"], _digest(projection))
            self.assertEqual(
                artifact["rows"],
                (("schema", "projection.v1"), ("name", "smoke")),
            )


def _digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


if __name__ == "__main__":
    unittest.main()
