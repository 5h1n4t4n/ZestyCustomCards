# Quy tắc Lua, passcode và CDB

Bổ sung cho mục "Ràng buộc viết card" trong `AGENTS.md`; không lặp lại các quy tắc đã có ở đó.

## 1. Script Lua (EDOPro)

1. Với effect kích hoạt có target callback, dùng `chk==0` kiểm tra legality; cost/target/operation là ba bước khác nhau. Continuous field target/filter không dùng cùng chữ ký callback.
2. `aux.Stringid(id,N)` dùng chỉ số 0-based vào `strings`; không bắt buộc N bằng số thứ tự effect nếu có nhiều prompt.
3. Kiểm tra zone ở thời điểm thích hợp; Extra Deck summon và zone giải phóng bởi cost/material cần API phù hợp theo reference.
4. Chỉ kiểm tra handler `IsRelateToEffect`/`IsFaceup` khi phần operation đó cần handler còn tại vị trí/trạng thái hợp lệ. Không chặn search/draw chỉ vì handler rời sân nếu luật không yêu cầu. Cảnh báo `STRUCT:` của `validate_scripts.ps1` về `IsRelateToEffect` hay `chk==0` là heuristic, không phải yêu cầu.
5. Với đối tượng được target, kiểm tra quan hệ/trạng thái tại resolution theo reference; card được chọn trong operation không mặc nhiên là target.
6. HOPT/SOPT và giới hạn activation/use phải theo text và reference; không thêm `EFFECT_COUNT_CODE_OATH` cho mọi HOPT.
7. API mới phải có bằng chứng từ official script/helper hoặc source engine. Qua được whitelist của validator chỉ chứng minh tên hàm tồn tại, không chứng minh cách dùng đúng.
8. Gán range/property/reset/category theo loại effect và reference, không áp dụng một công thức cho mọi effect.
9. Spell official chỉ dùng `EFFECT_TYPE_QUICK_O` khi card đang ngửa trên sân (`LOCATION_SZONE`/`LOCATION_FZONE`) hoặc khi cấp hiệu ứng cho monster; không có Spell official nào dùng Quick Effect từ tay hay GY. Hiệu ứng Spell phản ứng từ tay/GY phải dựa trên official card cùng cơ chế, không tự dựng `QUICK_O`.
10. Text nhắc tên card cụ thể thì khai báo `s.listed_names={...}`; searcher dựa trên `Card.ListsCode` không nhận diện được card thiếu khai báo này.

## 2. Passcode và setcode

### 2.1 Passcode

Giữ nguyên passcode hiện hữu. Card mới dùng range đã đăng ký trong `feature_list.json`. `manage_db.py validate`/`compile` tự đối chiếu ID với mọi CDB trong repo và CDB của bản cài EDOPro, trùng là ERROR (`docs/agent-workflow.md` §4). ID và setcode là hai định danh khác nhau: không ghép setcode thành ID rồi coi là bảo đảm không trùng.

### 2.2 Archetype official và fan-made

- **Official** (Dragonmaid, Labrynth, White Forest, Witchcrafter, Branded...): tra setcode hex trong `repositories/delta-bagooska/script/archetype_setcode_constants.lua` của bản cài game (không có game thì xem file cùng tên trong CardScripts, §5). Ghi setcode vào JSON dưới dạng decimal. EDOPro đã có sẵn các setcode này, **không thêm vào `script/constants.lua`**.
- **Fan-made**: thêm `SET_XXX = 0xYYY` vào [script/constants.lua](../script/constants.lua) và `!setname 0xYYY TênArchetype` vào [strings.conf](../strings.conf).

Cả hai loại phải được đăng ký bằng `python tools/manage_harness.py archetype add <Name> <setcode>` trước khi cấp passcode.

## 3. CDB

### 3.1 Schema

`card-data/c<passcode>.json` là nguồn dữ liệu duy nhất; `tools/manage_db.py` biên dịch toàn bộ specs vào `card-data.cdb` theo schema và cách đóng gói của Datacorn (editor CDB của ProjectIgnis).

- **Bảng `datas`:**
  - `id`: passcode, phải khớp tên file.
  - `ot`: luôn là 32; compiler báo lỗi nếu khác.
  - `alias`: ID card gốc nếu là alt-art (0 = không có).
  - `setcode`: tối đa 4 setcode 16-bit trong một số 64-bit: `sc1 | (sc2 << 16) | (sc3 << 32) | (sc4 << 48)`.
  - `type`: bitmask, có **đúng 1** trong 3 bit khung Monster (`0x1`) / Spell (`0x2`) / Trap (`0x4`).
  - `atk`, `def`: -2 nghĩa là `?`.
  - `level`: Level/Rank/Link rating (0–13). Pendulum scale đóng gói vào cột này: `(base_level & 0x800000FF) | (left_scale << 24) | (right_scale << 16)`.
  - `race`, `attribute`: bitmask, monster phải có **đúng 1 bit** mỗi cột.
  - `category`: bitmask bộ lọc database (§4.4).
  - **Link Monster:** cột `def` là bitfield link marker: `0x1` Bottom-Left, `0x2` Bottom, `0x4` Bottom-Right, `0x8` Left, `0x20` Right, `0x40` Top-Left, `0x80` Top, `0x100` Top-Right (`0x10` không dùng).
  - **Spell/Trap:** `atk`, `def`, `level`, `race`, `attribute` phải bằng 0.
- **Bảng `texts`:** `name`, `desc`, `str1`–`str16` (prompt cho `aux.Stringid`).

### 3.2 Field thân thiện trong JSON

Nên dùng khi viết card mới; compiler tự đóng gói và validate. Không khai báo đồng thời field thô và field thân thiện với giá trị mâu thuẫn.

| Field JSON | Ý nghĩa | Ví dụ |
|------------|---------|-------|
| `"setcodes": [...]` | Tối đa 4 setcode (đóng gói vào `setcode`) | `"setcodes": [296, 4444]` |
| `"lscale"` / `"rscale"` | Pendulum Scale (đóng gói vào `level`) | `"lscale": 4, "rscale": 4` |
| `"linkmarkers": [...]` | Tên link marker (đóng gói vào `def`) | `"linkmarkers": ["Top", "Bottom"]` |
| `"atk"` / `"def"`: `"?"` | ATK/DEF `?` (chuyển thành -2) | `"atk": "?"` |

### 3.3 Lệnh CDB

```powershell
python tools/manage_db.py validate      # kiểm tra specs, không ghi CDB
python tools/manage_db.py compile       # validate rồi ghi CDB atomic
python tools/manage_db.py check-sync    # mỗi spec có Lua, entry feature_list và row CDB khớp
python tools/manage_db.py query <ID-or-name>
```

`compile` chỉ thay CDB khi 0 lỗi; có lỗi thì CDB cũ giữ nguyên và exit code = 1. Lỗi bị chặn gồm: `ot` ≠ 32, thiếu/thừa bit khung Monster-Spell-Trap, monster thiếu hoặc multi-bit race/attribute, link marker không hợp lệ hoặc rỗng, scale > 13, level > 13, Spell/Trap có chỉ số khác 0, `strings` > 16, `id` không khớp tên file, trùng passcode giữa các CDB. Compiler cũng từ chối ghi đè khi CDB đích chứa ID không có spec, thay vì âm thầm xóa card đó.

### 3.4 Ownership và làm việc nhóm

- Mọi `*.cdb` khác ở gốc repo là dữ liệu của dev khác; compiler không ghi vào đó nhưng đối chiếu passcode với tất cả.
- Commit JSON + Lua/artwork liên quan + `card-data.cdb` sinh từ cùng phiên bản nguồn.
- Conflict ở `card-data.cdb`: giải quyết JSON trước rồi compile lại. Không chọn cả file ours/theirs.
- Chuyển card từ CDB khác vào `card-data/`: thống nhất ownership, viết spec, rồi bỏ ID đó khỏi CDB cũ. Không trông vào thứ tự nạp của client để giải quyết trùng ID.
- Bỏ một card phải xóa rõ ràng ở cả JSON và CDB đích.

## 4. Bảng bitmask (decimal)

JSON trong `card-data/` dùng giá trị **thập phân**.

### 4.1 Card type (`type`)

| Loại Card | Hex | Dec |
|-----------|-----|-----|
| Normal Monster | `0x11` | **17** |
| Effect Monster | `0x21` | **33** |
| Fusion Effect Monster | `0x61` | **97** |
| Synchro Monster | `0x2021` | **8225** |
| Xyz Monster | `0x800021` | **8388641** |
| Link Monster | `0x4000021` | **67108897** |
| Pendulum Effect Monster | `0x1000021` | **16777249** |
| Tuner Effect Monster | `0x1021` | **4129** |
| Normal Spell | `0x2` | **2** |
| Quick-Play Spell | `0x10002` | **65538** |
| Continuous Spell | `0x20002` | **131074** |
| Field Spell | `0x80002` | **524290** |
| Equip Spell | `0x40002` | **262146** |
| Normal Trap | `0x4` | **4** |
| Continuous Trap | `0x20004` | **131076** |
| Counter Trap | `0x100004` | **1048580** |

### 4.2 Race (`race`)

| Race | Hex | Dec |
|------|-----|-----|
| Warrior | `0x1` | **1** |
| Spellcaster | `0x2` | **2** |
| Fairy | `0x4` | **4** |
| Fiend | `0x8` | **8** |
| Zombie | `0x10` | **16** |
| Machine | `0x20` | **32** |
| Aqua | `0x40` | **64** |
| Pyro | `0x80` | **128** |
| Rock | `0x100` | **256** |
| Winged Beast | `0x200` | **512** |
| Plant | `0x400` | **1024** |
| Insect | `0x800` | **2048** |
| Thunder | `0x1000` | **4096** |
| Dragon | `0x2000` | **8192** |
| Beast | `0x4000` | **16384** |
| Beast-Warrior | `0x8000` | **32768** |
| Dinosaur | `0x10000` | **65536** |
| Fish | `0x20000` | **131072** |
| Sea Serpent | `0x40000` | **262144** |
| Reptile | `0x80000` | **524288** |
| Psychic | `0x100000` | **1048576** |
| Wyrm | `0x800000` | **8388608** |
| Cyberse | `0x1000000` | **16777216** |
| Illusion | `0x2000000` | **33554432** |

### 4.3 Attribute (`attribute`)

| Attribute | Hex | Dec |
|-----------|-----|-----|
| EARTH | `0x1` | **1** |
| WATER | `0x2` | **2** |
| FIRE | `0x4` | **4** |
| WIND | `0x8` | **8** |
| LIGHT | `0x10` | **16** |
| DARK | `0x20` | **32** |
| DIVINE | `0x40` | **64** |

### 4.4 CDB category khác Lua CATEGORY_*

`category` trong JSON/CDB là bitmask bộ lọc database, **không phải** hằng Lua `CATEGORY_*` truyền cho `SetCategory`/`SetOperationInfo`. Tra bảng `CATEGORIES` trong `tools/manage_db.py` cho CDB; tra constants của engine/reference cho Lua. Không chuyển thẳng số từ bảng Lua sang JSON.

## 5. Tham khảo API

Bằng chứng ưu tiên là official script cùng cơ chế (`python tools/read_official.py`) và thư viện script trong bản cài game. Tên hằng số/hàm có thật nằm trong `tools/edopro_constants.txt` và `tools/edopro_apis.txt`. Tài liệu online:

- Scrapi-book (API docs): https://projectignis.github.io/scrapi-book/
- CardScripts (`utility.lua`, `constant.lua`, `official/`): https://github.com/ProjectIgnis/CardScripts
- CardScripts wiki: https://github.com/ProjectIgnis/CardScripts/wiki
