#!/usr/bin/env python3
"""
Tests for framework/hooks/pre_tool_use/spike_gate.py

Scenarios:
  1. blocked   — gate armed, current branch is main (not spike/)
  2. allowed   — gate armed, current branch is spike/valid-name
  3. allowed   — gate not armed, normal session on main
  4. blocked   — gate armed, branch is spike/fix (trivial name)
  5. allowed   — gate armed, branch is spike/add-reports-menu-item (valid)
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# Add the pre_tool_use directory to sys.path so we can import spike_gate
_HOOK_DIR = Path(__file__).parent.parent / "pre_tool_use"
sys.path.insert(0, str(_HOOK_DIR))

import spike_gate  # noqa: E402


def _make_payload(tool_name: str = "Write", file_path: str = "src/foo.py") -> str:
    return json.dumps({
        "tool_name": tool_name,
        "tool_input": {"file_path": file_path},
        "cwd": "/fake/project",
    })


class TestSpikeGate(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self._root = Path(self._tmpdir)
        (self._root / "AGENTS.md").touch()
        self._harnessable = self._root / ".harnessable"
        self._harnessable.mkdir()

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _arm_gate(self):
        (self._harnessable / "spike_gate").write_text("2026-01-01T00:00:00Z")

    def _run_hook(self, branch: str, tool: str = "Write") -> int:
        payload = json.dumps({
            "tool_name": tool,
            "tool_input": {"file_path": "src/foo.py"},
            "cwd": str(self._root),
        })
        with (
            patch.object(spike_gate, "_find_project_root", return_value=self._root),
            patch.object(spike_gate, "_current_branch", return_value=branch),
        ):
            with self.assertRaises(SystemExit) as cm:
                import io
                with patch("sys.stdin", io.StringIO(payload)):
                    spike_gate.main()
            return cm.exception.code

    # ── Scenario 1: blocked — armed, on main ────────────────────────────────

    def test_blocked_when_armed_and_on_main(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="main")
        self.assertEqual(exit_code, 2)

    # ── Scenario 2: allowed — armed, on spike/valid-name ────────────────────

    def test_allowed_when_armed_and_on_valid_spike_branch(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/refactor-auth-session-store")
        self.assertEqual(exit_code, 0)

    # ── Scenario 3: allowed — gate not armed, normal session ────────────────

    def test_allowed_when_gate_not_armed(self):
        # Gate file does NOT exist
        exit_code = self._run_hook(branch="main")
        self.assertEqual(exit_code, 0)

    # ── Scenario 4: trivial name blocked ────────────────────────────────────

    def test_blocked_trivial_name_fix(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/fix")
        self.assertEqual(exit_code, 2)

    def test_blocked_trivial_name_test(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/test")
        self.assertEqual(exit_code, 2)

    def test_blocked_trivial_name_misc(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/misc")
        self.assertEqual(exit_code, 2)

    def test_blocked_trivial_name_temp(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/temp")
        self.assertEqual(exit_code, 2)

    def test_blocked_trivial_name_wip(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/wip")
        self.assertEqual(exit_code, 2)

    def test_blocked_trivial_name_quick(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/quick")
        self.assertEqual(exit_code, 2)

    def test_blocked_slug_too_short(self):
        # "ab" is under 5 characters but not in the trivial list
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/ab")
        self.assertEqual(exit_code, 2)

    # ── Scenario 5: valid descriptive name allowed ───────────────────────────

    def test_allowed_descriptive_name(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/add-reports-menu-item")
        self.assertEqual(exit_code, 0)

    def test_allowed_descriptive_name_with_numbers(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="spike/fix-null-pointer-login-api")
        self.assertEqual(exit_code, 0)

    # ── Non-guarded tools pass through always ───────────────────────────────

    def test_non_guarded_tool_passes_unarmed(self):
        exit_code = self._run_hook(branch="main", tool="Bash")
        self.assertEqual(exit_code, 0)

    def test_non_guarded_tool_passes_armed(self):
        self._arm_gate()
        exit_code = self._run_hook(branch="main", tool="Read")
        self.assertEqual(exit_code, 0)


if __name__ == "__main__":
    unittest.main()
