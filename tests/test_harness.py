"""Regression checks for card scaffolding and fail-closed static validation.

Run from the repository root: python -m unittest discover -s tests -v
"""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
if not (TOOLS / "manage_harness.py").exists():
    TOOLS = ROOT / "tools"
_spec = importlib.util.spec_from_file_location("harness_under_test", TOOLS / "manage_harness.py")
harness = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(harness)
POWERSHELL = shutil.which("powershell") or shutil.which("pwsh")


class HarnessRegressionTests(unittest.TestCase):
    def test_extra_deck_effect_templates_preserve_effect_bit(self):
        # EDOPro type flags are independent of the harness mapping under test.
        type_monster, type_effect = 0x1, 0x20
        type_fusion, type_synchro = 0x40, 0x2000
        type_xyz, type_link = 0x800000, 0x4000000
        for template, subtype in {
            "fusion_monster": type_fusion,
            "synchro_monster": type_synchro,
            "xyz_monster": type_xyz,
            "link_monster": type_link,
        }.items():
            expected = type_monster | type_effect | subtype
            with self.subTest(template=template):
                spec = harness.build_spec_skeleton(12345678, "Test", template, 0)
                self.assertEqual(spec["type"], expected)

    def test_preflight_rejects_non_uppercase_placeholders(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("card-data", "script", "pics"):
                (root / name).mkdir()
            paths = {"card_data": root / "card-data", "script_dir": root / "script", "pics_dir": root / "pics"}
            (paths["card_data"] / "c12345678.json").write_text(json.dumps({"desc": "Real effect text"}), encoding="utf-8")
            for placeholder in ("<<mixed123>>", "<<text with spaces>>", "<<>>", "<<UPPER_CASE>>"):
                with self.subTest(placeholder=placeholder):
                    (paths["script_dir"] / "c12345678.lua").write_text("-- " + placeholder, encoding="utf-8")
                    errors, _ = harness.preflight_card(paths, 12345678)
                    self.assertTrue(any(placeholder in error for error in errors), errors)

    def test_sync_failure_prevents_status_and_queue_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            queue = root / "w_test.png"
            queue.write_bytes(b"test-artwork")
            features = root / "feature_list.json"
            features.write_text(json.dumps({"archetypes": {"Test": {"cards": [{"passcode": "12345678", "status": "working", "queue_file": queue.name}]}}}), encoding="utf-8")
            original = features.read_bytes()
            # No output text to parse: the nonzero process exit status alone must block.
            responses = [(0, "", ""), (0, "", ""), (0, "", ""), (1, "", "sync failed")]
            with patch.object(harness, "get_project_paths", return_value={"root": root, "feature_list": features}), patch.object(harness, "preflight_card", return_value=([], [])), patch.object(harness, "run_command", side_effect=responses) as run, contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertFalse(harness.verify_card(12345678))
                self.assertEqual(run.call_count, 4)
            self.assertEqual(features.read_bytes(), original)
            self.assertTrue(queue.exists())
            self.assertFalse((root / "d_test.png").exists())

    def test_verify_copies_artwork_then_deletes_queue_image(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pics").mkdir()
            queue = root / "w_test.png"
            queue.write_bytes(b"test-artwork")
            features = root / "feature_list.json"
            features.write_text(json.dumps({"archetypes": {"Test": {"cards": [{"passcode": "12345678", "status": "working", "queue_file": queue.name}]}}}), encoding="utf-8")
            paths = {"root": root, "feature_list": features, "pics_dir": root / "pics"}
            with patch.object(harness, "get_project_paths", return_value=paths), patch.object(harness, "preflight_card", return_value=([], [])), patch.object(harness, "run_command", return_value=(0, "", "")), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertTrue(harness.verify_card(12345678))
            # Ảnh queue chỉ được xóa sau khi bản copy trong pics/ đọc lại đúng nội dung.
            self.assertEqual((root / "pics" / "12345678.png").read_bytes(), b"test-artwork")
            self.assertFalse(queue.exists())
            card = json.loads(features.read_text(encoding="utf-8"))["archetypes"]["Test"]["cards"][0]
            self.assertEqual(card["status"], "done")
            self.assertNotIn("queue_file", card)

    def test_queue_image_survives_when_artwork_cannot_be_confirmed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pics").mkdir()
            # EDOPro không nạp .gif nên không thể copy sang pics/ — ảnh queue phải được giữ.
            queue = root / "w_test.gif"
            queue.write_bytes(b"test-artwork")
            deleted, _ = harness.retire_queue_image({"root": root, "pics_dir": root / "pics"}, 12345678, queue)
            self.assertFalse(deleted)
            self.assertTrue(queue.exists())
            self.assertEqual(list((root / "pics").iterdir()), [])

    def test_cleanup_requires_artwork_and_apply_flag(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            queues = root / "docs" / "queues" / "Test"
            queues.mkdir(parents=True)
            pics = root / "pics"
            pics.mkdir()
            copied = queues / "d_copied.jpg"
            copied.write_bytes(b"artwork")
            uncopied = queues / "d_uncopied.jpg"
            uncopied.write_bytes(b"artwork")
            (pics / "11111111.jpg").write_bytes(b"artwork")
            features = root / "feature_list.json"
            features.write_text(json.dumps({"archetypes": {"Test": {"cards": [
                # feature_list còn ghi tiền tố 'w_' trong khi đĩa đã đổi sang 'd_'
                {"passcode": "11111111", "status": "done", "queue_file": "docs/queues/Test/w_copied.jpg"},
                {"passcode": "22222222", "status": "done", "queue_file": "docs/queues/Test/d_uncopied.jpg"},
            ]}}}), encoding="utf-8")
            paths = {"root": root, "feature_list": features, "queues_dir": root / "docs" / "queues", "pics_dir": pics}
            with patch.object(harness, "get_project_paths", return_value=paths), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertTrue(harness.cleanup_queue())
                self.assertTrue(copied.exists(), "dry-run không được xóa file")
                self.assertTrue(harness.cleanup_queue(apply_changes=True))
            self.assertFalse(copied.exists())
            self.assertTrue(uncopied.exists(), "chưa có artwork trong pics/ thì phải giữ ảnh queue")
            cards = json.loads(features.read_text(encoding="utf-8"))["archetypes"]["Test"]["cards"]
            self.assertNotIn("queue_file", cards[0])
            self.assertIn("queue_file", cards[1])

    def test_cleanup_drops_refs_to_missing_images(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            queues = root / "docs" / "queues" / "Test"
            queues.mkdir(parents=True)
            pics = root / "pics"
            pics.mkdir()
            kept = queues / "w_present.jpg"
            kept.write_bytes(b"artwork")
            features = root / "feature_list.json"
            features.write_text(json.dumps({"archetypes": {"Test": {"cards": [
                # Ảnh đã bị gỡ khỏi repo, ref còn lại chỉ là rác
                {"passcode": "11111111", "status": "done", "queue_file": "docs/queues/Test/d_gone.jpg"},
                {"passcode": "22222222", "status": "pending", "queue_file": "docs/queues/Test/d_present.jpg"},
            ]}}}), encoding="utf-8")
            paths = {"root": root, "feature_list": features, "queues_dir": root / "docs" / "queues", "pics_dir": pics}
            with patch.object(harness, "get_project_paths", return_value=paths), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertTrue(harness.cleanup_queue())
                unchanged = json.loads(features.read_text(encoding="utf-8"))["archetypes"]["Test"]["cards"]
                self.assertIn("queue_file", unchanged[0], "dry-run không được sửa feature_list")
                self.assertTrue(harness.cleanup_queue(apply_changes=True))
            cards = json.loads(features.read_text(encoding="utf-8"))["archetypes"]["Test"]["cards"]
            self.assertNotIn("queue_file", cards[0])
            self.assertIn("queue_file", cards[1], "ref chỉ lệch tiền tố trạng thái không phải rác")
            self.assertTrue(kept.exists())


@unittest.skipUnless(POWERSHELL, "PowerShell is required for validator integration tests")
class LuaParserRegressionTests(unittest.TestCase):
    def run_validator(self, path, env=None):
        return subprocess.run(
            [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(TOOLS / "validate_scripts.ps1"), "-Path", str(path)],
            cwd=ROOT, env=env, capture_output=True, text=True, errors="replace", timeout=30,
        )

    @unittest.skipUnless(shutil.which("lua"), "Lua is required for actual syntax checks")
    def test_valid_and_invalid_lua_with_quoted_path(self):
        with tempfile.TemporaryDirectory(prefix="ttf-parser-'") as directory:
            path = Path(directory) / "c12345678.lua"
            valid = "local s,id=GetID()\nfunction s.initial_effect(c)\n c:RegisterEffect(nil)\nend\n"
            for content, expected in ((valid, 0), (valid + "this is invalid lua\n", 1)):
                with self.subTest(expected_exit=expected):
                    path.write_text(content, encoding="utf-8")
                    result = self.run_validator(path)
                    self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                    if expected:
                        self.assertIn("SYNTAX:", result.stdout)

    def test_missing_lua_cannot_report_success(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "c12345678.lua"
            path.write_text("local s,id=GetID()", encoding="utf-8")
            env = os.environ.copy()
            env["PATH"] = ""
            result = self.run_validator(path, env=env)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("Lua parser not found", result.stdout)


@unittest.skipUnless(POWERSHELL, "PowerShell is required for validator integration tests")
class ValidatorReferenceTests(unittest.TestCase):
    """Tên không tồn tại trong EDOPro chỉ là nil lúc chạy, cú pháp Lua vẫn hợp lệ,
    nên validator phải chặn bằng danh sách sinh từ bản cài game."""

    CLEAN = 'local s,id=GetID()\nlocal COUNTER_CUSTOM=0x1\nfunction s.initial_effect(c)\n\tlocal e1=Effect.CreateEffect(c)\n\te1:SetType(EFFECT_TYPE_ACTIVATE)\n\te1:SetCode(EVENT_FREE_CHAIN)\n\te1:SetOperation(s.activate)\n\tc:RegisterEffect(e1)\nend\nfunction s.activate(e,tp,eg,ep,ev,re,r,rp)\n\tDuel.Draw(tp,COUNTER_CUSTOM,REASON_EFFECT)\nend\n'
    BAD_CONST = 'local s,id=GetID()\nfunction s.initial_effect(c)\n\tlocal e1=Effect.CreateEffect(c)\n\te1:SetType(EFFECT_TYPE_ACTIVATE)\n\te1:SetCode(EVENT_FREE_CHAIN)\n\te1:SetCategory(CATEGORY_TOTALLY_NOT_REAL)\n\tc:RegisterEffect(e1)\nend\n'
    BAD_API = 'local s,id=GetID()\nfunction s.initial_effect(c)\n\tlocal e1=Effect.CreateEffect(c)\n\te1:SetType(EFFECT_TYPE_ACTIVATE)\n\te1:SetCode(EVENT_FREE_CHAIN)\n\te1:SetTarget(Card.IsTotallyNotReal)\n\tc:RegisterEffect(e1)\nend\n'
    WARN_ONLY = 'local s,id=GetID()\nfunction s.initial_effect(c)\n\tlocal e1=Effect.CreateEffect(c)\n\te1:SetType(EFFECT_TYPE_ACTIVATE)\n\te1:SetCode(EVENT_FREE_CHAIN)\n\te1:SetTarget(s.target)\n\tc:RegisterEffect(e1)\nend\nfunction s.target(e,tp,eg,ep,ev,re,r,rp,chk)\n\treturn true\nend\n'

    def run_validator(self, content, quiet=False):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "c12345678.lua"
            path.write_text(content, encoding="utf-8")
            command = [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                       str(TOOLS / "validate_scripts.ps1"), "-Path", str(path)]
            if quiet:
                command.append("-Quiet")
            return subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                  errors="replace", timeout=60)

    def test_clean_script_passes(self):
        result = self.run_validator(self.CLEAN)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("CONST:", result.stdout)
        self.assertNotIn("API:", result.stdout)

    def test_unknown_constant_fails(self):
        result = self.run_validator(self.BAD_CONST)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("CATEGORY_TOTALLY_NOT_REAL", result.stdout)

    def test_unknown_api_fails(self):
        result = self.run_validator(self.BAD_API)
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("Card.IsTotallyNotReal", result.stdout)

    def test_quiet_does_not_count_warnings_as_ok(self):
        result = self.run_validator(self.WARN_ONLY, quiet=True)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("1 WARN", result.stdout)
        self.assertIn("0 OK", result.stdout)


if __name__ == "__main__":
    unittest.main()
