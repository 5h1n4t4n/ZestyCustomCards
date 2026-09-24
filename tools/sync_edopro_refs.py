#!/usr/bin/env python3
"""Sinh danh sách hằng số và API thật của EDOPro từ thư mục cài game.

Lua không báo lỗi khi đọc một tên không tồn tại — nó trả về nil. Hằng số sai
tên (`TYPES_TOKEN_MONSTER`) hay hàm bịa (`Card.IsAbleToHandOrExtra`) vì thế qua được
kiểm tra cú pháp rồi mới crash trong duel. Hai file sinh ra ở đây là danh sách
trắng để validator chặn trước:

    tools/edopro_constants.txt   hằng số ALL_CAPS engine/script chuẩn định nghĩa
    tools/edopro_apis.txt        cặp Namespace.Function có thật

Nguồn dữ liệu là bản cài EDOPro; chỉ máy có game mới chạy được lệnh sync, nên
hai file sinh ra được commit để máy khác vẫn kiểm tra được.

    python tools/sync_edopro_refs.py --game-dir "F:/Game/ProjectIgnis"
    python tools/sync_edopro_refs.py --check
"""
import argparse
import os
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

# Thư mục script chỉ lấy từ repo ProjectIgnis (read_official.OFFICIAL_REPO_PREFIX):
# repo custom không phải nguồn API đúng — nhận vào là tự hợp thức hóa lỗi của mình.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from read_official import DEFAULT_GAME_DIR, collect_script_roots  # noqa: E402

# NAME = ..., local NAME = ..., NAME <const> = ...
CONST_RE = re.compile(r"(?m)^[ \t]*(?:local[ \t]+)?([A-Z][A-Z0-9_]{2,})[ \t]*(?:<const>[ \t]*)?=")
# Namespace.Function — chỉ namespace viết hoa đầu (Duel, Card, Witchcrafter...)
API_RE = re.compile(r"\b([A-Z][A-Za-z0-9_]*)\.([A-Za-z_]\w*)")
API_DEF_RE = re.compile(r"\bfunction[ \t]+([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z_]\w*)")
# Method gọi qua dấu hai chấm: c:IsCode(...). Cùng một hàm với Card.IsCode nên
# phải gom, nếu không mọi API chỉ từng được gọi dạng method sẽ bị báo nhầm.
METHOD_RE = re.compile(r":([A-Za-z_]\w*)[ \t]*\(")
# aux là alias của Auxiliary, chuẩn hóa về một tên
AUX_ALIASES = {"aux", "Auxiliary"}
# Bảng core do ocgcore.dll đăng ký, Lua source không khai báo
CORE_NAMESPACES = ("Duel", "Card", "Effect", "Group")


def collect_lua_paths(script_roots):
    """Gom file .lua theo đường dẫn tương đối, root ưu tiên cao thắng khi trùng.

    File ngay dưới root là thư viện; trong thư mục con là script từng card.
    """
    library, cards = {}, {}
    for root in script_roots:
        for path in root.rglob("*.lua"):
            bucket = library if path.parent == root else cards
            bucket.setdefault(path.relative_to(root).as_posix(), path)
    return sorted(library.values()), sorted(cards.values())


def normalize_namespace(name):
    return "aux" if name in AUX_ALIASES else name


def read_lua_sources(paths):
    """Đọc nội dung các file .lua, bỏ qua file không đọc được."""
    sources = []
    for path in paths:
        try:
            sources.append(path.read_text(encoding="utf-8", errors="replace"))
        except OSError as e:
            print(f"  [WARN ] bỏ qua {path.name}: {e}", file=sys.stderr)
    return sources


def collect_constants(library_sources):
    """Hằng số toàn cục, chỉ lấy từ file thư viện.

    Script của từng card cũng khai báo `local CARD_X = 12345`, nhưng đó là biến
    cục bộ của riêng card đó. Gom chúng vào danh sách trắng sẽ khiến một tên gõ
    sai lọt qua chỉ vì trùng biến cục bộ của một card không liên quan.
    """
    constants = set()
    for text in library_sources:
        constants.update(CONST_RE.findall(text))
    return constants


def collect_namespaces(library_sources):
    """Bảng toàn cục mà thư viện game định nghĩa (Duel, aux, Witchcrafter...).

    Chỉ những tên này mới được coi là namespace hợp lệ; `Cost.X` hay `A.I` nhặt
    được từ biến cục bộ trong script card thì không.
    """
    namespaces = set(CORE_NAMESPACES)
    for text in library_sources:
        for ns, _ in API_DEF_RE.findall(text):
            namespaces.add(normalize_namespace(ns))
    return namespaces


def collect_apis(all_sources, namespaces):
    """Cặp Namespace.Function có thật, giới hạn trong các namespace đã biết.

    Lấy lời gọi trong script chính thức: script official chạy được trong game
    nên mọi tên chúng gọi đều tồn tại, kể cả hàm core do C++ đăng ký mà Lua
    source không khai báo.

    Method gọi qua `:` không cho biết bảng chủ là Card hay Effect hay Group,
    nên tên method được chấp nhận cho cả bốn bảng core. Đánh đổi này giữ cho
    validator không báo nhầm, vẫn đủ chặn tên hàm bịa hoàn toàn.
    """
    apis = set()
    methods = set()
    for text in all_sources:
        for ns, fn in API_RE.findall(text):
            ns = normalize_namespace(ns)
            if ns in namespaces:
                apis.add(f"{ns}.{fn}")
        methods.update(METHOD_RE.findall(text))
    for ns in CORE_NAMESPACES:
        for fn in methods:
            apis.add(f"{ns}.{fn}")
    return apis


def write_list(path, values, description, game_dir):
    body = "\n".join(sorted(values))
    header = (
        f"# Sinh tự động bởi tools/sync_edopro_refs.py — KHÔNG sửa tay.\n"
        f"# {description}\n"
        f"# Nguồn: {game_dir}\n"
    )
    path.write_text(header + body + "\n", encoding="utf-8")


def read_list(path):
    if not path.exists():
        return set()
    return set(
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )


def report_diff(label, old, new):
    added = sorted(new - old)
    removed = sorted(old - new)
    print(f"{label}: {len(new)} mục ({len(added)} thêm, {len(removed)} bỏ)")
    for name in added[:15]:
        print(f"    + {name}")
    if len(added) > 15:
        print(f"    + ... và {len(added) - 15} mục nữa")
    for name in removed[:15]:
        print(f"    - {name}")
    if len(removed) > 15:
        print(f"    - ... và {len(removed) - 15} mục nữa")
    return added, removed


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--game-dir", default=os.environ.get("EDOPRO_DIR", DEFAULT_GAME_DIR),
                        help="Thư mục cài EDOPro (mặc định: $EDOPRO_DIR hoặc %s)" % DEFAULT_GAME_DIR)
    parser.add_argument("--check", action="store_true",
                        help="Chỉ so sánh, không ghi file; exit 1 nếu lệch bản game")
    args = parser.parse_args()

    game_dir = Path(args.game_dir)
    script_roots = collect_script_roots(game_dir)
    if not script_roots:
        print(f"Error: không thấy thư mục script nào trong {game_dir}. "
              "Truyền --game-dir hoặc đặt EDOPRO_DIR.", file=sys.stderr)
        return 1

    tools_dir = Path(__file__).resolve().parent
    constants_path = tools_dir / "edopro_constants.txt"
    apis_path = tools_dir / "edopro_apis.txt"

    print("Đọc script EDOPro từ (ưu tiên giảm dần):")
    for root in script_roots:
        print(f"    {root}")
    library_paths, card_paths = collect_lua_paths(script_roots)
    library_sources = read_lua_sources(library_paths)
    card_sources = read_lua_sources(card_paths)
    print(f"Đã đọc {len(library_sources)} file thư viện, {len(card_sources)} script card")

    constants = collect_constants(library_sources)
    namespaces = collect_namespaces(library_sources)
    print(f"Namespace hợp lệ ({len(namespaces)}): {', '.join(sorted(namespaces))}")
    apis = collect_apis(library_sources + card_sources, namespaces)

    const_added, const_removed = report_diff("Hằng số", read_list(constants_path), constants)
    api_added, api_removed = report_diff("API", read_list(apis_path), apis)

    if args.check:
        stale = const_added or const_removed or api_added or api_removed
        print("\nLệch bản game — chạy lại không có --check để cập nhật." if stale
              else "\nĐã khớp bản game.")
        return 1 if stale else 0

    write_list(constants_path, constants, "Hằng số ALL_CAPS do script EDOPro định nghĩa.", game_dir)
    write_list(apis_path, apis, "Cặp Namespace.Function có thật trong EDOPro.", game_dir)
    print(f"\nĐã ghi {constants_path.name} và {apis_path.name}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
