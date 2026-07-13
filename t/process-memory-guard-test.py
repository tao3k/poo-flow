from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / "tools" / "process_memory_guard.py"


class ProcessMemoryGuardTest(unittest.TestCase):
    def run_guard(self, code: str, max_rss: int, timeout: float) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / "receipt.json"
            completed = subprocess.run(
                [sys.executable, str(GUARD), "--label", "test", "--max-rss-mib", str(max_rss),
                 "--timeout-seconds", str(timeout), "--sample-ms", "10", "--receipt", str(receipt),
                 "--", sys.executable, "-c", code],
                capture_output=True, text=True, timeout=10,
            )
            return completed, json.loads(receipt.read_text(encoding="utf-8"))

    def test_completed_receipt(self) -> None:
        completed, receipt = self.run_guard("print('ok')", 128, 2)
        self.assertEqual(completed.returncode, 0)
        self.assertEqual(receipt["outcome"], "completed")
        self.assertGreater(receipt["peakRssBytes"], 0)

    def test_rss_limit_terminates_process_group(self) -> None:
        completed, receipt = self.run_guard(
            "import time; payload=bytearray(96*1024*1024); payload[::4096]=b'x'*len(payload[::4096]); time.sleep(5)",
            48, 4,
        )
        self.assertEqual(completed.returncode, 70)
        self.assertEqual(receipt["outcome"], "rss-limit-exceeded")
        self.assertGreater(receipt["peakRssBytes"], receipt["maxRssBytes"])

    def test_timeout_terminates_process_group(self) -> None:
        completed, receipt = self.run_guard("import time; time.sleep(5)", 128, 0.1)
        self.assertEqual(completed.returncode, 71)
        self.assertEqual(receipt["outcome"], "timeout")


if __name__ == "__main__":
    unittest.main()
