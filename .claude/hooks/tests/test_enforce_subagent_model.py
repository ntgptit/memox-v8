"""The Agent gate of enforce_subagent_model.py: Sonnet for every subagent, Opus
for the final whole-branch review and a root-cause investigation only."""

import json
import subprocess
import sys
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[1] / "enforce_subagent_model.py"


def run(tool_input):
    payload = {"tool_name": "Agent", "tool_input": tool_input}
    out = subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return json.loads(out)


def model_after(result, tool_input):
    updated = result.get("hookSpecificOutput", {}).get("updatedInput")
    return (updated or tool_input).get("model")


class AgentGateTest(unittest.TestCase):
    def test_a_sonnet_call_passes_unchanged(self):
        call = {"model": "sonnet", "description": "Explore the router"}
        self.assertEqual(run(call), {})

    def test_an_opus_call_is_moved_to_sonnet(self):
        call = {"model": "opus", "description": "Explore the router"}
        self.assertEqual(model_after(run(call), call), "sonnet")

    def test_a_call_without_a_model_is_moved_to_sonnet(self):
        call = {"description": "Scenario test"}
        self.assertEqual(model_after(run(call), call), "sonnet")

    def test_the_final_review_on_opus_passes(self):
        call = {"model": "opus", "description": "Final whole-branch review P1"}
        self.assertEqual(run(call), {})

    def test_the_final_review_on_another_model_is_moved_to_sonnet(self):
        call = {"model": "fable", "description": "Final whole-branch review P1"}
        self.assertEqual(model_after(run(call), call), "sonnet")

    def test_the_prefix_must_open_the_description(self):
        call = {"model": "opus", "description": "Not a Final whole-branch review"}
        self.assertEqual(model_after(run(call), call), "sonnet")

    def test_a_root_cause_investigation_on_opus_passes(self):
        call = {"model": "opus", "description": "Root-cause investigation DEV-301 overflow"}
        self.assertEqual(run(call), {})

    def test_a_root_cause_investigation_on_another_model_is_moved_to_sonnet(self):
        call = {"model": "fable", "description": "Root-cause investigation DEV-301"}
        self.assertEqual(model_after(run(call), call), "sonnet")

    def test_the_investigation_prefix_must_open_the_description(self):
        call = {"model": "opus", "description": "Fix after Root-cause investigation"}
        self.assertEqual(model_after(run(call), call), "sonnet")


if __name__ == "__main__":
    unittest.main()
