#!/usr/bin/env python3
import json
import argparse
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')
import os
import re
import shutil
import subprocess
from pathlib import Path

# manage_db nằm cùng thư mục; thêm tay vào sys.path để import được cả khi file
# này được nạp theo đường dẫn (test) chứ không qua `python tools/...`.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import manage_db

# Mapping of templates to default card types
TEMPLATE_TYPES = {
    "effect_monster": 0x21,       # Monster + Effect
    "normal_spell": 0x2,          # Spell
    "quick_play_spell": 0x10002,  # Spell + Quick-Play
    "continuous_spell": 0x20002,  # Spell + Continuous
    "normal_trap": 0x4,           # Trap
    "fusion_monster": 0x61,       # Monster + Fusion + Effect
    "synchro_monster": 0x2021,    # Monster + Synchro + Effect
    "xyz_monster": 0x800021,         # Monster + Xyz + Effect
    "link_monster": 0x4000021,    # Monster + Link + Effect
    "pendulum_monster": 0x1000021,# Monster + Pendulum + Effect
    "field_spell": 0x80002,       # Spell + Field
    "hand_trap": 0x21             # Monster + Effect (usually)
}

# Mỗi archetype giữ một block passcode = setcode * PASSCODE_BLOCK, theo quy ước
# đã dùng trong feature_list.json (0x16e -> 36600001-36699999).
PASSCODE_BLOCK = 100000
MAX_PASSCODE = 999999999
# Khóa archetype trùng tên thư mục docs/queues/<archetype>/
ARCHETYPE_KEY_RE = re.compile(r"[A-Za-z][A-Za-z0-9_]*$")

MONSTER_TEMPLATES = {
    "effect_monster", "fusion_monster", "synchro_monster", "xyz_monster",
    "link_monster", "pendulum_monster", "hand_trap",
}

# Đuôi ảnh chấp nhận trong queue; EDOPro chỉ nạp .jpg/.png
QUEUE_EXTS = (".jpg", ".jpeg", ".png", ".gif")
ARTWORK_EXTS = (".jpg", ".png")

# desc placeholder ghi vào spec JSON khi start; verify chặn nếu chưa thay
PLACEHOLDER_DESC = "Mô tả hiệu ứng..."
# Placeholder dạng <<...>> trong templates (vd <<ATK_VALUE>>) phải được thay hết
PLACEHOLDER_RE = re.compile(r"<<[^<>]*>>")

def get_project_paths():
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    return {
        "root": project_root,
        "feature_list": project_root / "feature_list.json",
        "script_dir": project_root / "script",
        "template_dir": project_root / "tools" / "templates",
        "card_data": project_root / "card-data",
        "queues_dir": project_root / "docs" / "queues",
        "pics_dir": project_root / "pics"
    }

def find_archetype_by_passcode(fl_data, passcode):
    for name, info in fl_data.get("archetypes", {}).items():
        pr = info.get("passcode_range")
        if pr:
            try:
                start, end = map(int, pr.split("-"))
                if start <= passcode <= end:
                    return name, info
            except:
                pass
    return "Common", fl_data.get("archetypes", {}).get("Common", {})

def normalize_archetype_key(name):
    """Khóa so sánh tên archetype, khớp cách scan dò thư mục queue."""
    return name.lower().replace("_", "")


def parse_setcode(raw):
    """'0x16e' hoặc decimal -> int. Trả về (setcode, error)."""
    text = str(raw).strip()
    try:
        value = int(text, 16) if text.lower().startswith("0x") else int(text, 10)
    except ValueError:
        return None, f"setcode không hợp lệ: {raw!r} (dùng dạng hex '0x16e' hoặc decimal)"
    if not 0 < value <= 0xFFFF:
        return None, f"setcode phải trong khoảng 0x1-0xFFFF, nhận {text}"
    return value, None


def parse_passcode_range(raw):
    """'36600001-36699999' -> (start, end). Trả về (range, error)."""
    parts = str(raw).split("-")
    if len(parts) != 2:
        return None, f"range không hợp lệ: {raw!r} (dạng '36600001-36699999')"
    try:
        start, end = (int(part.strip()) for part in parts)
    except ValueError:
        return None, f"range không hợp lệ: {raw!r} (dạng '36600001-36699999')"
    if not 0 < start <= end <= MAX_PASSCODE:
        return None, f"range phải tăng dần và tối đa {MAX_PASSCODE}, nhận {raw!r}"
    return (start, end), None


def derive_passcode_range(setcode):
    """Block passcode mặc định của một setcode. Trả về (range, error)."""
    start = setcode * PASSCODE_BLOCK + 1
    end = setcode * PASSCODE_BLOCK + PASSCODE_BLOCK - 1
    if end > MAX_PASSCODE:
        return None, (f"setcode {hex(setcode)} cho range {start}-{end} vượt quá {MAX_PASSCODE} "
                      "(passcode tối đa 9 chữ số) — truyền --range để chọn block khác")
    return (start, end), None


def add_archetype(name, setcode_raw, range_raw=None):
    """Đăng ký archetype mới vào feature_list.json.

    AGENTS.md cấm sửa tay feature_list.json, nên đây là đường duy nhất để mở
    một archetype mới trước khi 'start' cấp passcode cho card của nó.
    """
    from datetime import datetime
    paths = get_project_paths()

    if not ARCHETYPE_KEY_RE.match(name):
        print(f"Error: tên archetype '{name}' không hợp lệ — dùng chữ/số/'_' và bắt đầu bằng chữ "
              "(vd Icejade, White_Forest).", file=sys.stderr)
        return False
    if not paths["feature_list"].exists():
        print("Error: feature_list.json not found.", file=sys.stderr)
        return False

    setcode, error = parse_setcode(setcode_raw)
    if error:
        print(f"Error: {error}", file=sys.stderr)
        return False

    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)
    archetypes = fl_data.setdefault("archetypes", {})

    key = normalize_archetype_key(name)
    for existing_name, info in archetypes.items():
        if normalize_archetype_key(existing_name) == key:
            print(f"Error: archetype '{existing_name}' đã tồn tại trong feature_list.json.", file=sys.stderr)
            return False
        existing_setcode, _ = parse_setcode(info.get("setcode", "0"))
        if existing_setcode == setcode:
            print(f"Error: setcode {hex(setcode)} đã thuộc archetype '{existing_name}'.", file=sys.stderr)
            return False

    if range_raw:
        bounds, error = parse_passcode_range(range_raw)
    else:
        bounds, error = derive_passcode_range(setcode)
    if error:
        print(f"Error: {error}", file=sys.stderr)
        return False
    start, end = bounds

    # Range chồng nhau nghĩa là hai archetype cùng tranh một passcode khi 'scan'
    # hoặc 'start' cấp ID.
    for existing_name, info in archetypes.items():
        other, _ = parse_passcode_range(info.get("passcode_range", ""))
        if other and start <= other[1] and other[0] <= end:
            print(f"Error: range {start}-{end} chồng lên '{existing_name}' ({other[0]}-{other[1]}).", file=sys.stderr)
            return False

    archetypes[name] = {"setcode": f"0x{setcode:x}", "passcode_range": f"{start}-{end}", "cards": []}
    fl_data["last_updated"] = datetime.now().strftime("%Y-%m-%d")
    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)

    print(f"Registered archetype '{name}': setcode 0x{setcode:x}, passcode range {start}-{end}.")
    print("\n=== Việc cần làm tiếp theo ===")
    print("1. Archetype official: tra setcode tại docs/archetype_setcode_constants.lua và KHÔNG thêm vào "
          "script/constants.lua (EDOPro đã có sẵn).")
    print(f"2. Archetype fan-made: thêm 'SET_{name.upper()} = 0x{setcode:x}' vào script/constants.lua và "
          f"'!setname 0x{setcode:x} {name.replace('_', ' ')}' vào strings.conf (docs/agent-rules.md §2.2).")
    print(f"3. Ảnh queue đặt trong docs/queues/{name}/ với tiền tố p_ rồi chạy 'scan', hoặc tạo card trực tiếp:")
    print(f"   python tools/manage_harness.py start {start} \"<name>\" <template>")
    return True


def locate_queue_image(queues_dir, card_name, archetype):
    # Try searching under the specific archetype folder, then globally
    normalized_name = card_name.lower().replace(" ", "_").replace("'", "").replace("-", "_")
    search_dirs = []
    if queues_dir.joinpath(archetype).is_dir():
        search_dirs.append(queues_dir / archetype)
    search_dirs.append(queues_dir)
    
    extensions = [f"*{ext}" for ext in QUEUE_EXTS]
    
    for s_dir in search_dirs:
        for ext in extensions:
            for p in s_dir.rglob(ext):
                # Match files starting with p_ and containing card name words
                if p.name.startswith("p_"):
                    # Check if normalized name or keywords match the filename
                    cleaned_filename = p.stem.lower()
                    if normalized_name in cleaned_filename or all(word in cleaned_filename for word in normalized_name.split("_") if len(word) > 2):
                        return p
    return None

def strip_queue_prefix(stem):
    """Bỏ tiền tố trạng thái p_/w_/d_ khỏi tên file queue."""
    return stem[2:] if stem[:2] in ("p_", "w_", "d_") else stem


def queue_key(rel_path):
    """Khóa nhận dạng ảnh queue không phụ thuộc tiền tố trạng thái hay đuôi file,
    để cleanup vẫn khớp khi feature_list còn ghi 'w_' mà đĩa đã là 'd_'."""
    path = Path(rel_path)
    return f"{path.parent.as_posix()}/{strip_queue_prefix(path.stem)}".lower()


def find_artwork(pics_dir, passcode):
    """Artwork đang có trong pics/ cho passcode, hoặc None."""
    for ext in ARTWORK_EXTS:
        candidate = pics_dir / f"{passcode}{ext}"
        if candidate.exists():
            return candidate
    return None


def copy_artwork_from_queue(pics_dir, passcode, queue_path):
    """Copy ảnh queue vào pics/<passcode>.<ext> rồi đọc lại đối chiếu byte.

    Trả về (pic_path, None) khi ghi và đọc lại khớp, ngược lại (None, lý do).
    .jpeg đổi sang .jpg vì EDOPro không nạp .jpeg.
    """
    ext = queue_path.suffix.lower()
    if ext == ".jpeg":
        ext = ".jpg"
    if ext not in ARTWORK_EXTS:
        return None, f"{queue_path.name} dùng đuôi {queue_path.suffix} — EDOPro chỉ nạp .jpg/.png, đổi thủ công trước"
    pic_path = pics_dir / f"{passcode}{ext}"
    try:
        pics_dir.mkdir(parents=True, exist_ok=True)
        source = queue_path.read_bytes()
        pic_path.write_bytes(source)
        if pic_path.read_bytes() != source:
            return None, f"ghi pics/{pic_path.name} xong nhưng đọc lại không khớp"
    except Exception as e:
        return None, f"copy {queue_path.name} -> pics/{passcode}{ext} thất bại: {e}"
    return pic_path, None


def retire_queue_image(paths, passcode, queue_path):
    """Xác nhận artwork đã nằm trong pics/ rồi mới xóa ảnh queue.

    Thiếu artwork thì copy từ chính ảnh queue và đọc lại để xác nhận. Chỉ xóa
    khi đã cầm chắc bản trong pics/; không xác nhận được thì giữ nguyên ảnh
    queue và trả lý do cho caller xử lý.
    Trả về (deleted: bool, message: str).
    """
    pic_path = find_artwork(paths["pics_dir"], passcode)
    if pic_path is None:
        pic_path, error = copy_artwork_from_queue(paths["pics_dir"], passcode, queue_path)
        if error:
            return False, error
        message = f"Đã copy artwork {queue_path.name} -> pics/{pic_path.name}"
    else:
        try:
            same = pic_path.read_bytes() == queue_path.read_bytes()
        except Exception as e:
            return False, f"không đọc được pics/{pic_path.name} hoặc {queue_path.name} để đối chiếu: {e}"
        message = f"Artwork pics/{pic_path.name} đã có" + ("" if same else " (khác bản queue — giữ bản trong pics/)")
    try:
        queue_path.unlink()
    except Exception as e:
        return False, f"{message}; xóa {queue_path.name} thất bại: {e}"
    return True, f"{message}; đã xóa queue image {queue_path.name}"


def build_spec_skeleton(passcode, card_name, template_type, setcode_val):
    """Tạo skeleton spec JSON theo loại template, ưu tiên field thân thiện
    (setcodes/linkmarkers/lscale/rscale) để compiler tự đóng gói bitfield."""
    t = template_type.lower()
    spec = {
        "id": passcode,
        "ot": 32,
        "alias": 0,
        "type": TEMPLATE_TYPES.get(t, 0x21),
    }
    if setcode_val:
        spec["setcodes"] = [setcode_val]
    else:
        spec["setcode"] = 0
    spec["atk"] = 0
    if t == "link_monster":
        spec["linkmarkers"] = []  # compiler đóng gói vào cột def
    else:
        spec["def"] = 0
    spec["level"] = 0
    if t == "pendulum_monster":
        spec["lscale"] = 0
        spec["rscale"] = 0
    spec["race"] = 0
    spec["attribute"] = 0
    spec["category"] = 0
    spec["name"] = card_name
    spec["desc"] = PLACEHOLDER_DESC
    spec["strings"] = []
    return spec


def print_next_steps(passcode, template_type):
    """In checklist các field bắt buộc phải điền — validator sẽ chặn nếu bỏ sót."""
    t = template_type.lower()
    print("\n=== Việc cần làm tiếp theo (validator sẽ chặn verify nếu bỏ sót) ===")
    print(f"1. card-data/c{passcode}.json — điền:")
    print(f"   - desc: effect text thật (placeholder '{PLACEHOLDER_DESC}' bị chặn)")
    if t in MONSTER_TEMPLATES:
        print("   - race / attribute: bắt buộc khác 0, đúng 1 bit")
        if t == "link_monster":
            print("   - level: Link rating; linkmarkers: tên marker (vd [\"Bottom-Left\",\"Bottom\"])")
            print("   - atk (Link không có def)")
        else:
            print("   - level (Rank nếu Xyz), atk, def (\"?\" nếu ATK/DEF ?)")
        if t == "pendulum_monster":
            print("   - lscale / rscale: Pendulum Scale")
    print("   - category: bitmask theo docs/agent-rules.md; strings: hint cho aux.Stringid")
    print(f"2. script/c{passcode}.lua — thay hết placeholder <<...>>, viết logic effect")
    print("   (tham khảo official qua .\\tools\\fetch_official.ps1 <passcode>)")
    print(f"3. Artwork pics/{passcode}.jpg|.png — verify tự copy từ queue image nếu còn;")
    print("   tự thêm thì KHÔNG dùng .jpeg (EDOPro không nạp)")
    print(f"4. Chạy: python .\\tools\\manage_harness.py verify {passcode}")


def start_card(passcode, card_name, template_type):
    paths = get_project_paths()

    # ===== Pre-flight: kiểm tra mọi điều kiện TRƯỚC khi thay đổi bất kỳ file nào =====
    # 1. Template phải tồn tại
    template_file = paths["template_dir"] / f"template_{template_type.lower()}.lua"
    if not template_file.exists():
        print(f"Error: Template '{template_type}' not found. Available templates:", file=sys.stderr)
        for t_file in paths["template_dir"].glob("template_*.lua"):
            print(f"  - {t_file.stem.replace('template_', '')}", file=sys.stderr)
        return False

    # 2. Không ghi đè file đã có (card đang code dở hoặc đã xong)
    json_path = paths["card_data"] / f"c{passcode}.json"
    script_path = paths["script_dir"] / f"c{passcode}.lua"
    clobber = [p for p in (json_path, script_path) if p.exists()]
    if clobber:
        for p in clobber:
            print(f"Error: {p.relative_to(paths['root'])} đã tồn tại — 'start' không ghi đè.", file=sys.stderr)
        print("Nếu muốn sửa card này, chỉnh trực tiếp file rồi chạy 'verify'. "
              "Nếu muốn làm lại từ đầu, xóa các file trên trước.", file=sys.stderr)
        return False

    # 3. Load and check feature_list.json
    if not paths["feature_list"].exists():
        print(f"Error: feature_list.json not found.", file=sys.stderr)
        return False

    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)

    # Check if passcode is already registered
    existing_card = None
    existing_archetype = None
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if card.get("passcode") == str(passcode):
                if card.get("status") != "pending":
                    print(f"Error: Passcode {passcode} is already registered under '{arch_name}' (Card: '{card['name']}') with status '{card.get('status')}'.", file=sys.stderr)
                    return False
                else:
                    existing_card = card
                    existing_archetype = arch_name

    # Find or guess archetype
    if existing_archetype:
        archetype = existing_archetype
        arch_info = fl_data["archetypes"][archetype]
    else:
        archetype, arch_info = find_archetype_by_passcode(fl_data, passcode)
    print(f"Assigning card to Archetype: {archetype}")

    # Parse setcode
    setcode_str = arch_info.get("setcode", "0")
    try:
        setcode_val = int(setcode_str, 16) if setcode_str.startswith("0x") else int(setcode_str)
    except:
        setcode_val = 0

    # ===== Mutations: tạo file trước, đổi tên queue & ghi feature_list sau cùng =====
    # 4. Create specs JSON
    paths["card_data"].mkdir(parents=True, exist_ok=True)
    spec_data = build_spec_skeleton(passcode, card_name, template_type, setcode_val)

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(spec_data, f, ensure_ascii=False, indent=2)
    print(f"Created specs spec JSON: {json_path.relative_to(paths['root'])}")

    # 5. Copy template Lua script (lỗi thì dọn JSON vừa tạo để không để lại trạng thái nửa vời)
    try:
        with open(template_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Replace template placeholders
        content = content.replace("<<CARD_NAME>>", card_name)
        content = content.replace("<<PASSCODE>>", str(passcode))
        content = content.replace("<<SETCODE>>", f"{setcode_val:x}" if setcode_val > 0 else "0")
        content = content.replace("<<ARCHETYPE_NAME>>", archetype)

        with open(script_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Created Lua script: {script_path.relative_to(paths['root'])}")
    except Exception as e:
        json_path.unlink(missing_ok=True)
        print(f"Error creating Lua script (đã rollback specs JSON): {e}", file=sys.stderr)
        return False

    # 6. Locate & rename queue file (p_ -> w_)
    queue_file = None
    if existing_card and existing_card.get("queue_file"):
        potential_path = paths["root"] / existing_card["queue_file"]
        if potential_path.exists():
            queue_file = potential_path

    if not queue_file:
        queue_file = locate_queue_image(paths["queues_dir"], card_name, archetype)

    new_queue_file_path = None
    if queue_file:
        # Rename from p_ to w_ (working)
        new_name = queue_file.name.replace("p_", "w_", 1)
        new_path = queue_file.parent / new_name
        try:
            shutil.move(str(queue_file), str(new_path))
            new_queue_file_path = str(new_path.relative_to(paths["root"]).as_posix())
            print(f"Located queue image: {queue_file.name} -> Renamed to {new_name}")
        except Exception as e:
            print(f"Warning: Failed to rename queue image: {e}", file=sys.stderr)
            new_queue_file_path = str(queue_file.relative_to(paths["root"]).as_posix())
    else:
        print("No pending queue image found matching card name.")

    # 7. Append or update in feature_list.json
    if existing_card:
        # Tên trong entry pending do scan suy từ tên file queue nên hay sai
        # chính tả; tên truyền vào lệnh start mới là tên chốt của card.
        if existing_card.get("name") != card_name:
            print(f"Renamed pending card {passcode}: '{existing_card.get('name')}' -> '{card_name}'")
        existing_card["name"] = card_name
        existing_card["status"] = "working"
        existing_card["script"] = f"script/c{passcode}.lua"
        if new_queue_file_path:
            existing_card["queue_file"] = new_queue_file_path
        print(f"Updated existing pending card {passcode} to 'working' status.")
    else:
        new_card_entry = {
            "name": card_name,
            "passcode": str(passcode),
            "status": "working",
            "script": f"script/c{passcode}.lua"
        }
        if new_queue_file_path:
            new_card_entry["queue_file"] = new_queue_file_path

        if archetype not in fl_data["archetypes"]:
            fl_data["archetypes"][archetype] = {"cards": []}
            
        fl_data["archetypes"][archetype]["cards"].append(new_card_entry)
    
    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
    print(f"Added/updated card in feature_list.json under '{archetype}'.")
    print(f"Status set to 'working'. Happy coding!")
    print_next_steps(passcode, template_type)
    return True

def run_command(args, cwd):
    # Dùng sys.executable cho lệnh python để không phụ thuộc PATH/alias
    if args and args[0] == "python":
        args = [sys.executable] + args[1:]
    result = subprocess.run(args, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            encoding='utf-8', errors='replace')
    return result.returncode, result.stdout, result.stderr

def preflight_card(paths, passcode):
    """Kiểm tra nhanh trước pipeline: file tồn tại, hết placeholder, artwork đúng đuôi.

    Trả về (errors, warnings). errors khác rỗng -> chặn verify ngay, đỡ tốn
    thời gian compile/validate cả project chỉ để fail vì thiếu file.
    """
    errors, warnings = [], []
    json_path = paths["card_data"] / f"c{passcode}.json"
    script_path = paths["script_dir"] / f"c{passcode}.lua"

    if not json_path.exists():
        errors.append(f"Thiếu specs JSON: card-data/c{passcode}.json (chạy 'start' trước)")
    else:
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                spec = json.load(f)
            desc = spec.get("desc", "")
            if not isinstance(desc, str) or not desc.strip() or desc.strip() == PLACEHOLDER_DESC:
                errors.append(f"Specs JSON: 'desc' rỗng hoặc vẫn là placeholder '{PLACEHOLDER_DESC}' — điền effect text thật")
        except Exception as e:
            errors.append(f"Specs JSON không đọc được: {e}")

    if not script_path.exists():
        errors.append(f"Thiếu Lua script: script/c{passcode}.lua (chạy 'start' trước)")
    else:
        try:
            content = script_path.read_text(encoding="utf-8")
            leftover = sorted(set(PLACEHOLDER_RE.findall(content)))
            if leftover:
                errors.append(f"Lua script còn placeholder template chưa thay: {', '.join(leftover)}")
            if "XXXXXXXXX" in content:
                errors.append("Lua script còn placeholder passcode 'XXXXXXXXX'")
        except Exception as e:
            errors.append(f"Lua script không đọc được: {e}")

    # Artwork: EDOPro chỉ load .jpg/.png; .jpeg từng gây bug ảnh trống (Phiên 063)
    pics_dir = paths["pics_dir"]
    wrong_ext = pics_dir / f"{passcode}.jpeg"
    if wrong_ext.exists():
        errors.append(f"Artwork pics/{passcode}.jpeg dùng đuôi .jpeg — EDOPro không load, đổi tên thành .jpg")
    elif find_artwork(pics_dir, passcode) is None:
        warnings.append(f"Chưa có artwork pics/{passcode}.jpg|.png — verify sẽ copy từ queue image nếu còn, "
                        "không thì card hiển thị ảnh trống trong game")

    return errors, warnings


def verify_card(passcode):
    paths = get_project_paths()
    print(f"Starting verification pipeline for Card passcode: {passcode}...")

    # 0. Pre-flight: file tồn tại, hết placeholder, artwork hợp lệ
    print("Step 0: Pre-flight checks (files, placeholders, artwork)...")
    pf_errors, pf_warnings = preflight_card(paths, passcode)
    for w in pf_warnings:
        print(f"  [WARN ] {w}")
    if pf_errors:
        for e in pf_errors:
            print(f"  [ERROR] {e}", file=sys.stderr)
        print("Error: Pre-flight failed. Sửa các lỗi trên rồi chạy lại verify.", file=sys.stderr)
        return False
    print("Pre-flight passed.")

    # 1. Validate + Compile Database Specs (atomic, theo chuẩn Datacorn)
    print("Step 1: Validating & compiling JSON specs to database...")
    rc, stdout, stderr = run_command(["python", "tools/manage_db.py", "compile"], paths["root"])
    if rc != 0:
        print("Error: DB Validation/Compilation failed! CDB cũ được giữ nguyên.", file=sys.stderr)
        if stdout and stdout.strip():
            print(stdout.strip(), file=sys.stderr)
        if stderr and stderr.strip():
            print(stderr.strip(), file=sys.stderr)
        return False
    # Hiển thị warning validation (không chặn nhưng nên xử lý)
    for line in (stdout or "").splitlines():
        if "[WARN" in line:
            print(f"  {line.strip()}")
    print("Database validated & compiled successfully.")

    # 2. Run validate_scripts.ps1 (chỉ file của card này — nhanh hơn quét cả project,
    #    và rc!=0 chặn trực tiếp thay vì chỉ soi text output)
    print("Step 2: Validating script structure and syntax...")
    rc, stdout, stderr = run_command(
        ["powershell", "-ExecutionPolicy", "Bypass", "-File", "tools/validate_scripts.ps1",
         "-Path", f"script/c{passcode}.lua"], paths["root"])

    file_failed = False
    for line in (stdout or "").splitlines():
        if f"c{passcode}.lua" in line:
            print(f"  Validator output: {line.strip()}")
            if "FAIL" in line:
                file_failed = True

    if rc != 0 or file_failed:
        print("Error: Script validation failed for this passcode. Please fix errors before declaring success.", file=sys.stderr)
        if stderr and stderr.strip():
            print(stderr.strip(), file=sys.stderr)
        return False
    print("Script validation checked out.")

    # 3. Run basic style check (Linter)
    print("Step 3: Checking style linter...")
    rc, stdout, stderr = run_command(["powershell", "-ExecutionPolicy", "Bypass", "-File", "tools/lint_scripts.ps1", "-Path", f"script/c{passcode}.lua"], paths["root"])
    print(stdout.strip())
    # Style issues không chặn pipeline nhưng phải được thông báo rõ (cả fallback lẫn luacheck)
    if "Total files with issues" in (stdout or "") or rc != 0:
        print("Warning: Linter reported code style issues in your script. Highly recommended to fix them.")

    # 4. Check sync status
    print("Step 4: Running system sync check...")
    rc, stdout, stderr = run_command(["python", "tools/manage_db.py", "check-sync"], paths["root"])
    print(stdout.strip())
    if rc != 0:
        print("Error: System synchronization failed. Cannot declare passing.", file=sys.stderr)
        if stderr and stderr.strip():
            print(stderr.strip(), file=sys.stderr)
        return False
    print("System sync verified successfully.")

    # 5. Update status to done and finalize queue file name
    print("Step 5: Updating state to done...")
    if not paths["feature_list"].exists():
        print("Error: feature_list.json not found.", file=sys.stderr)
        return False
        
    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)
        
    card_found = False
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if card.get("passcode") == str(passcode):
                card_found = True
                card["status"] = "done"
                
                # Ảnh queue hết vai trò khi artwork đã vào pics/: copy nếu thiếu,
                # xác nhận, rồi xóa để queue không phình ra theo thời gian.
                queue_path_str = card.get("queue_file")
                if queue_path_str:
                    q_path = paths["root"] / queue_path_str
                    if q_path.exists():
                        deleted, message = retire_queue_image(paths, passcode, q_path)
                        if deleted:
                            card.pop("queue_file", None)
                            print(message)
                        else:
                            print(f"Warning: {message}", file=sys.stderr)
                            # Chưa xác nhận được artwork: giữ ảnh, chỉ đánh dấu done
                            if q_path.name.startswith("w_"):
                                new_path = q_path.parent / q_path.name.replace("w_", "d_", 1)
                                try:
                                    shutil.move(str(q_path), str(new_path))
                                    card["queue_file"] = str(new_path.relative_to(paths["root"]).as_posix())
                                    print(f"Giữ queue image, đổi tên sang trạng thái done: {new_path.name}")
                                except Exception as e:
                                    print(f"Warning: Failed to rename queue image: {e}", file=sys.stderr)
                break
        if card_found:
            break
            
    if not card_found:
        print(f"Warning: Card {passcode} not found in feature_list.json. Cannot update status.")
        return False

    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
        
    print(f"\nSUCCESS: Card {passcode} passed static validation; legacy status set to 'done'.")
    print("EDOPro runtime behavior is NOT verified. Run in-game scenarios before declaring the card complete.")

    return True

def scan_pending_cards():
    from datetime import datetime
    paths = get_project_paths()
    if not paths["feature_list"].exists():
        print(f"Error: feature_list.json not found.", file=sys.stderr)
        return

    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)

    # Gather all registered stems and passcodes to prevent duplicates
    registered_stems = set()
    registered_passcodes = set()
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if "queue_file" in card:
                registered_stems.add(strip_queue_prefix(Path(card["queue_file"]).stem).lower())
            if "passcode" in card:
                registered_passcodes.add(card["passcode"])

    # Locate all p_ files in queues
    queues_dir = paths["queues_dir"]
    extensions = [f"*{ext}" for ext in QUEUE_EXTS]
    found_pending = []
    
    for ext in extensions:
        for p in queues_dir.rglob(ext):
            if p.name.startswith("p_"):
                if strip_queue_prefix(p.stem).lower() not in registered_stems:
                    found_pending.append(p)

    if not found_pending:
        print("No new pending cards found in the queue directory.")
        return

    print(f"Found {len(found_pending)} new pending queue files. Registering...")

    # Passcode phải chưa dùng trong MỌI CDB, không chỉ trong feature_list
    # (docs/agent-rules.md §2.1) — trùng ID thì EDOPro nạp nhầm card.
    taken_codes, missing_game_dir = manage_db.external_passcodes(paths["root"])
    if missing_game_dir is not None:
        print(f"Warning: không thấy bản cài EDOPro tại {missing_game_dir} — passcode chỉ được đối chiếu với "
              "CDB trong repo. Đặt $EDOPRO_DIR để kiểm tra cả CDB của game.", file=sys.stderr)
    taken_codes |= {int(code) for code in registered_passcodes if str(code).isdigit()}

    # For each found pending file:
    added_count = 0
    for p_path in found_pending:
        # Determine archetype from parent folder name
        # If parent folder is queues_dir, default to Common
        arch_dir = p_path.parent
        if arch_dir == queues_dir:
            archetype = "Common"
        else:
            archetype = arch_dir.name
            
        # Normalize/Clean archetype name to match feature_list.json keys
        actual_arch_name = "Common"
        for name in fl_data.get("archetypes", {}).keys():
            if name.lower().replace("_", "") == archetype.lower().replace("_", ""):
                actual_arch_name = name
                break

        if actual_arch_name not in fl_data["archetypes"]:
            actual_arch_name = "Common"

        arch_info = fl_data["archetypes"][actual_arch_name]

        # Generate name from filename
        words = strip_queue_prefix(p_path.stem).split("_")
        formatted_words = []
        for word in words:
            if word.lower() == "and":
                formatted_words.append("&")
            elif word.lower() == "the" and formatted_words:
                formatted_words.append("the")
            elif word.lower() in ("in", "of", "to", "for", "with", "by", "at", "from"):
                formatted_words.append(word.lower())
            else:
                formatted_words.append(word.capitalize())
        card_name = " ".join(formatted_words)

        # Generate passcode
        passcode = None
        pr = arch_info.get("passcode_range")
        if pr:
            try:
                start_range, end_range = map(int, pr.split("-"))
                candidate = start_range
                while candidate in taken_codes:
                    candidate += 1
                if candidate <= end_range:
                    passcode = str(candidate)
            except Exception as e:
                print(f"Error calculating passcode range for {actual_arch_name}: {e}")
                
        if not passcode:
            common_candidates = [code for code in taken_codes if str(code).startswith("799000")]
            candidate = max(common_candidates) + 1 if common_candidates else 79900001
            while candidate in taken_codes:
                candidate += 1
            passcode = str(candidate)

        registered_passcodes.add(passcode)
        taken_codes.add(int(passcode))

        # Build card entry
        rel_path = str(p_path.relative_to(paths["root"]).as_posix())
        new_card_entry = {
            "name": card_name,
            "passcode": passcode,
            "status": "pending",
            "queue_file": rel_path
        }

        arch_info["cards"].append(new_card_entry)
        print(f"  [+] Registered: {card_name} (Passcode: {passcode}) under '{actual_arch_name}'")
        added_count += 1

    fl_data["last_updated"] = datetime.now().strftime("%Y-%m-%d")

    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully registered {added_count} new pending cards in feature_list.json!")

def tracked_paths(root, subdir):
    """Đường dẫn dưới subdir đang được Git theo dõi; None khi không hỏi được Git.

    Chỉ file đã commit mới khôi phục được sau khi xóa, nên file chưa track phải
    được cảnh báo riêng thay vì gộp chung vào câu "vẫn khôi phục từ history".
    """
    try:
        result = subprocess.run(["git", "ls-files", "-z", "--", subdir],
                                cwd=str(root), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    except OSError:
        return None
    if result.returncode != 0:
        return None
    return {entry for entry in result.stdout.decode("utf-8", "replace").split("\0") if entry}


def cleanup_queue(apply_changes=False):
    """Dọn ảnh queue đã done, chỉ xóa file đã có artwork tương ứng trong pics/.

    Mặc định chỉ liệt kê. Cần --apply mới xóa thật và gỡ 'queue_file' khỏi
    feature_list. File chưa đăng ký, chưa done hoặc chưa có artwork đều được
    giữ lại và báo lý do, vì lúc đó ảnh queue có thể là bản duy nhất.
    """
    paths = get_project_paths()
    if not paths["feature_list"].exists():
        print("Error: feature_list.json not found.", file=sys.stderr)
        return False

    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)

    if not paths["queues_dir"].is_dir():
        print(f"Error: {paths['queues_dir']} không tồn tại.", file=sys.stderr)
        return False

    # Khóa của mọi ảnh còn trên đĩa, kể cả ảnh chưa done: ref chỉ lệch tiền tố
    # trạng thái vẫn khớp được nhờ queue_key.
    existing_keys = {
        queue_key(image.relative_to(paths["root"]).as_posix())
        for image in paths["queues_dir"].rglob("*")
        if image.is_file() and image.suffix.lower() in QUEUE_EXTS
    }

    # Tra ngược từ đường dẫn ảnh về card để biết passcode và trạng thái.
    # Ref không khớp ảnh nào là rác: ảnh đã bị dọn hoặc gỡ khỏi repo từ trước.
    # Giữ lại chỉ làm mọi lệnh đọc queue hiểu sai trạng thái card.
    card_by_queue = {}
    stale_refs = []
    for arch_info in fl_data.get("archetypes", {}).values():
        for card in arch_info.get("cards", []):
            queue_file = card.get("queue_file")
            if not queue_file:
                continue
            key = queue_key(queue_file)
            if key in existing_keys:
                card_by_queue[key] = card
            else:
                stale_refs.append((card, queue_file))

    for card, queue_file in stale_refs:
        print(f"  [GỠ  ] {queue_file} — ảnh không còn, gỡ 'queue_file' của {card.get('passcode')}")
        if apply_changes:
            card.pop("queue_file", None)

    images = sorted(
        p for p in paths["queues_dir"].rglob("d_*")
        if p.is_file() and p.suffix.lower() in QUEUE_EXTS
    )
    if not images:
        print("Queue không còn ảnh done nào để dọn.")

    ready, kept = [], []
    for image in images:
        rel = image.relative_to(paths["root"]).as_posix()
        card = card_by_queue.get(queue_key(rel))
        if card is None:
            kept.append((rel, "chưa đăng ký trong feature_list"))
        elif card.get("status") != "done":
            kept.append((rel, f"status='{card.get('status')}', chưa done"))
        elif not card.get("passcode"):
            kept.append((rel, "card thiếu passcode"))
        elif find_artwork(paths["pics_dir"], card["passcode"]) is None:
            kept.append((rel, f"chưa có artwork pics/{card['passcode']}.jpg|.png — copy artwork trước"))
        else:
            ready.append((rel, image, card))

    for rel, reason in kept:
        print(f"  [GIỮ ] {rel} — {reason}")

    tracked = tracked_paths(paths["root"], paths["queues_dir"].relative_to(paths["root"]).as_posix())
    untracked = 0
    freed = 0
    failed = 0
    for rel, image, card in ready:
        size = image.stat().st_size
        note = ""
        if tracked is not None and rel not in tracked:
            note = " [CHƯA COMMIT — xóa là mất hẳn]"
            untracked += 1
        if not apply_changes:
            print(f"  [XÓA ] {rel} (artwork pics/{card['passcode']} đã có, {size / 1024:.0f} KB){note}")
            freed += size
            continue
        try:
            image.unlink()
        except Exception as e:
            print(f"  [LỖI ] {rel} — xóa thất bại: {e}", file=sys.stderr)
            failed += 1
            continue
        card.pop("queue_file", None)
        freed += size
        print(f"  [XÓA ] {rel}{note}")

    if apply_changes and (ready or stale_refs):
        with open(paths["feature_list"], "w", encoding="utf-8") as f:
            json.dump(fl_data, f, ensure_ascii=False, indent=2)

    verb = "Đã xóa" if apply_changes else "Sẽ xóa"
    print()
    print(f"{verb} {len(ready) - failed}/{len(images)} ảnh queue (~{freed / 1048576:.1f} MB), giữ lại {len(kept)}.")
    if stale_refs:
        gone = "Đã gỡ" if apply_changes else "Sẽ gỡ"
        print(f"{gone} {len(stale_refs)} tham chiếu 'queue_file' trỏ tới ảnh không còn.")
    if untracked:
        print(f"Cảnh báo: {untracked} ảnh chưa được Git theo dõi — xóa xong KHÔNG khôi phục được từ history. "
              "Commit trước nếu còn cần bản gốc.")
    if not apply_changes and (ready or stale_refs):
        print("Đây là dry-run. Chạy lại với --apply để áp dụng thật (ảnh đã commit vẫn khôi phục được từ Git history).")
    return failed == 0


def main():
    parser = argparse.ArgumentParser(description="TTF Custom Cards Harness Management CLI Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: start
    start_parser = subparsers.add_parser("start", help="Initialize a new custom card development")
    start_parser.add_argument("passcode", type=int, help="Card passcode (9 digits)")
    start_parser.add_argument("name", type=str, help="Card name")
    start_parser.add_argument("template", type=str, choices=list(TEMPLATE_TYPES.keys()), help="Template type to copy")

    # Subcommand: verify
    verify_parser = subparsers.add_parser("verify", help="Run static check-sync and syntax checks (runtime unverified); set legacy done status")
    verify_parser.add_argument("passcode", type=int, help="Card passcode to verify")

    # Subcommand: scan
    subparsers.add_parser("scan", help="Scan queues directory for new pending cards and register them in feature_list.json")

    # Subcommand: archetype
    archetype_parser = subparsers.add_parser("archetype", help="Manage the archetype registry in feature_list.json")
    archetype_sub = archetype_parser.add_subparsers(dest="archetype_command", required=True)
    archetype_add = archetype_sub.add_parser("add", help="Register a new archetype with its setcode and passcode range")
    archetype_add.add_argument("name", type=str, help="Archetype key, e.g. Icejade or White_Forest")
    archetype_add.add_argument("setcode", type=str, help="Setcode in hex (0x16e) or decimal")
    archetype_add.add_argument("--range", dest="passcode_range", type=str,
                               help="Override the derived passcode range, e.g. 36600001-36699999")

    # Subcommand: cleanup
    cleanup_parser = subparsers.add_parser("cleanup", help="Delete done queue images whose artwork is already in pics/ (dry-run by default)")
    cleanup_parser.add_argument("--apply", action="store_true", help="Actually delete the confirmed images instead of listing them")

    args = parser.parse_args()

    # Exit code phản ánh kết quả thật để agent/CI dựa vào được
    if args.command == "start":
        sys.exit(0 if start_card(args.passcode, args.name, args.template) else 1)
    elif args.command == "verify":
        sys.exit(0 if verify_card(args.passcode) else 1)
    elif args.command == "scan":
        scan_pending_cards()
    elif args.command == "archetype":
        sys.exit(0 if add_archetype(args.name, args.setcode, args.passcode_range) else 1)
    elif args.command == "cleanup":
        sys.exit(0 if cleanup_queue(args.apply) else 1)

if __name__ == "__main__":
    main()
