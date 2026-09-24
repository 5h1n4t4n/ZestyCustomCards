#!/usr/bin/env python3
"""Move all card-data IDs to card-data.cdb. Dry-run by default; --apply writes backups first."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import tempfile

from manage_db import collect_specs, compile_db, expected_rows, read_rows

SOURCES = ("custom_cards_zesty.cdb", "mycard.cdb")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def migrate(root, apply=False):
    root = Path(root).resolve()
    cards, errors, _ = collect_specs(root / "card-data")
    if errors:
        raise ValueError("Invalid specs; no database changed")
    expected = expected_rows(cards)
    owned = set(expected["datas"])
    paths = [root / name for name in (*SOURCES, "card-data.cdb")]
    hashes = {path: digest(path) for path in paths}
    originals = {path: read_rows(path) for path in paths if path.exists()}
    for path in paths[:2]:
        if path not in originals:
            raise ValueError(f"Required source missing: {path}")
    for path in originals:
        for suffix in ("-wal", "-journal"):
            if Path(str(path) + suffix).exists():
                raise ValueError(f"Close database writers before migrating: {path}{suffix}")
    if paths[-1] in originals:
        extra = set().union(*(set(rows) for rows in originals[paths[-1]].values())) - owned
        if extra:
            raise ValueError(f"card-data.cdb has IDs outside specs: {sorted(extra)}")
    differences = []
    for path, tables in originals.items():
        for table, rows in tables.items():
            for code in sorted(owned & set(rows)):
                if rows[code] != expected[table][code]:
                    differences.append({"source": path.name, "table": table, "id": code,
                                        "before": rows[code], "spec": expected[table][code]})
    with tempfile.TemporaryDirectory(prefix="card-data-migration-", dir=root) as tmp:
        stage = Path(tmp)
        shutil.copytree(root / "card-data", stage / "card-data")
        if not compile_db(stage / "card-data.cdb"):
            raise ValueError("Compilation failed; no database changed")
        for path in paths[:2]:
            staged = stage / path.name
            shutil.copy2(path, staged)
            conn = sqlite3.connect(staged)
            try:
                with conn:
                    for table in ("datas", "texts"):
                        conn.executemany(f"DELETE FROM {table} WHERE id=?", ((code,) for code in owned))
            finally:
                conn.close()
        outputs = {path: read_rows(stage / path.name) for path in paths}
        for path in paths[:2]:
            for table in ("datas", "texts"):
                untouched = {code: row for code, row in originals[path][table].items() if code not in owned}
                if outputs[path][table] != untouched:
                    raise ValueError(f"Non-owned rows changed: {path.name}/{table}")
        for table in ("datas", "texts"):
            before = set().union(*(set(tables[table]) for tables in originals.values()))
            after = set().union(*(set(tables[table]) for tables in outputs.values()))
            if after != before | owned:
                raise ValueError(f"ID loss detected in {table}")
        if outputs[paths[-1]] != expected:
            raise ValueError("Compiled card-data differs from validated specs")
        report = {"owned_ids": sorted(owned), "source_spec_differences": differences,
                  "original_sha256": {p.name: h for p, h in hashes.items()}}
        print(f"Selected {len(owned)} spec IDs; {len(differences)} source rows differ from specs.")
        for item in differences:
            print(f"  {item['source']}: {item['id']} {item['table']} differs; specs win, original retained in backup")
        changed = [path for path in paths if originals.get(path) != outputs[path]]
        if not changed:
            print("Already migrated; no changes.")
            return report
        if not apply:
            print("DRY RUN: verified preservation of unrelated rows and all IDs. Use --apply to write.")
            return report
        backup = root / "backups" / datetime.now(timezone.utc).strftime("card-data-%Y%m%dT%H%M%S-%fZ")
        backup.mkdir(parents=True)
        for path in originals:
            shutil.copy2(path, backup / (path.name + ".bak"))
        (backup / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        if any(digest(path) != hashes[path] for path in paths):
            raise ValueError(f"Database changed during migration; retry. Backups: {backup}")
        replaced = []
        try:
            for path in changed:
                os.replace(stage / path.name, path)
                replaced.append(path)
            if any(read_rows(path) != outputs[path] for path in paths):
                raise ValueError("Post-write verification failed")
        except Exception:
            restore_errors = []
            for path in reversed(replaced):
                try:
                    if hashes[path] is None:
                        path.unlink(missing_ok=True)
                    else:
                        shutil.copy2(backup / (path.name + ".bak"), path)
                except OSError as exc:
                    restore_errors.append(f"{path}: {exc}")
            if restore_errors:
                raise RuntimeError(f"Restore incomplete: {restore_errors}. Recover from {backup}")
            raise
        print(f"Migration verified. Original databases and difference report: {backup}")
        return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--apply", action="store_true", help="Apply staged changes after creating recoverable backups")
    args = parser.parse_args()
    try:
        migrate(args.root, args.apply)
    except (OSError, ValueError, sqlite3.Error, RuntimeError) as exc:
        parser.exit(1, f"ERROR: {exc}\n")


if __name__ == "__main__":
    main()
