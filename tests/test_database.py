import contextlib
import io
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))
import manage_db as db
import migrate_card_data as migration


class DatabaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "card-data").mkdir()
        (self.root / "script").mkdir()
        self.spec = {"id": 123, "type": 2, "name": "Owned", "desc": "Draw a card."}
        self.write_spec()
        (self.root / "script/c123.lua").write_text("local s,id=GetID()")
        (self.root / "feature_list.json").write_text(json.dumps({"archetypes": {"A": {"cards": [
            {"passcode": "123", "status": "done"}, {"passcode": "555", "status": "pending"}]}}}))
        self.luna = self.root / "card-data.cdb"

    def write_spec(self):
        (self.root / "card-data/c123.json").write_text(json.dumps(self.spec))

    def source(self, name):
        path = self.root / name
        self.assertTrue(db.compile_db(path))
        with contextlib.closing(sqlite3.connect(path)) as conn, conn:
            conn.execute("INSERT INTO datas SELECT 999,ot,alias,setcode,type,atk,def,level,race,attribute,category FROM datas WHERE id=123")
            conn.execute("INSERT INTO texts SELECT 999,name,desc," + ",".join(f"str{i}" for i in range(1, 17)) + " FROM texts WHERE id=123")
            conn.execute("UPDATE texts SET name='Other developer' WHERE id=999")
            conn.execute("UPDATE texts SET name='Old owned text' WHERE id=123")
        return path

    def test_migration_preserves_other_devs_and_is_idempotent(self):
        sources = [self.source(name) for name in migration.SOURCES]
        before = {p: db.read_rows(p) for p in sources}
        original_bytes = {p: p.read_bytes() for p in sources}
        migration.migrate(self.root)
        self.assertFalse(self.luna.exists())
        self.assertEqual(original_bytes, {p: p.read_bytes() for p in sources})
        report = migration.migrate(self.root, apply=True)
        self.assertEqual(len(report["source_spec_differences"]), 2)
        for p in sources:
            for table in ("datas", "texts"):
                self.assertEqual(db.read_rows(p)[table], {999: before[p][table][999]})
        self.assertEqual(set(db.read_rows(self.luna)["texts"]), {123})
        backups = list((self.root / "backups").glob("*/*.cdb.bak"))
        self.assertEqual(len(backups), 2)
        after = {p: p.read_bytes() for p in sources + [self.luna]}
        migration.migrate(self.root, apply=True)
        self.assertEqual(after, {p: p.read_bytes() for p in after})

    def test_invalid_spec_and_unknown_ids_do_not_overwrite(self):
        self.assertTrue(db.compile_db(self.luna))
        before = self.luna.read_bytes()
        self.spec["type"] = 0
        self.write_spec()
        self.assertFalse(db.compile_db(self.luna))
        self.assertEqual(before, self.luna.read_bytes())
        self.spec["type"] = 2
        self.write_spec()
        with contextlib.closing(sqlite3.connect(self.luna)) as conn, conn:
            conn.execute("INSERT INTO texts (id,name) VALUES (999,'Orphan')")
        before = self.luna.read_bytes()
        self.assertFalse(db.compile_db(self.luna))
        self.assertEqual(before, self.luna.read_bytes())

    def test_invalid_migration_leaves_sources_unchanged(self):
        sources = [self.source(name) for name in migration.SOURCES]
        before = {p: p.read_bytes() for p in sources}
        self.spec["type"] = 0
        self.write_spec()
        with self.assertRaises(ValueError):
            migration.migrate(self.root, apply=True)
        self.assertEqual(before, {p: p.read_bytes() for p in sources})
        self.assertFalse(self.luna.exists())

    def test_sync_stale_exit_and_pending_legacy(self):
        self.assertTrue(db.compile_db(self.luna))
        (self.root / "script/c777.lua").write_text("-- legacy")
        self.assertTrue(db.check_sync(self.luna))
        self.spec["name"] = "Changed"
        self.write_spec()
        self.assertFalse(db.check_sync(self.luna))
        command = "import sys; sys.path.insert(0, sys.argv[1]); import manage_db; from pathlib import Path; manage_db.get_db_path=lambda: Path(sys.argv[2]); sys.argv=['manage_db','check-sync']; manage_db.main()"
        result = subprocess.run([sys.executable, "-c", command, str(TOOLS), str(self.luna)], capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(db.compile_db(self.luna))
        with contextlib.closing(sqlite3.connect(self.luna)) as conn, conn:
            conn.execute("DELETE FROM texts")
        self.assertFalse(db.check_sync(self.luna))

    def test_partial_publish_restores_databases(self):
        sources = [self.source(name) for name in migration.SOURCES]
        before = {p: p.read_bytes() for p in sources}
        original_replace = migration.os.replace
        def fail_second_source(src, dest):
            if Path(dest) == sources[1]:
                raise OSError("Simulated publish failure")
            return original_replace(src, dest)
        with patch.object(migration.os, "replace", side_effect=fail_second_source):
            with self.assertRaises(OSError):
                migration.migrate(self.root, apply=True)
        self.assertEqual(before, {p: p.read_bytes() for p in sources})
        self.assertFalse(self.luna.exists())


if __name__ == "__main__":
    unittest.main()
