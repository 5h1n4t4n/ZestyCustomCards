# Quy Tắc Lập Trình & Hướng Dẫn Tra Cứu Kỹ Thuật (LUA/CDB)

Tài liệu này bao gồm toàn bộ các quy tắc viết mã Lua, quy tắc chọn Passcode, Setcode và bảng tra cứu bitmask cho SQLite Database.

---

## 1. Quy Tắc Viết Script Lua (EDOPro Standards)

Các quy tắc lập trình bắt buộc để đảm bảo script tương thích và chạy ổn định trên Simulator EDOPro:

1. Khởi tạo bằng `local s,id=GetID()` và `s.initial_effect(c)`. Đăng ký effect theo official reference cùng cơ chế.
2. Với effect kích hoạt có target callback, dùng `chk==0` kiểm tra legality; cost/target/operation là ba bước khác nhau. Continuous field target/filter không dùng cùng chữ ký callback.
3. `aux.Stringid(id,N)` dùng chỉ số 0-based vào `strings`; không bắt buộc N bằng số thứ tự effect nếu có nhiều prompt.
4. Kiểm tra zone ở thời điểm thích hợp; Extra Deck summon và zone giải phóng bởi cost/material cần API phù hợp theo reference.
5. Chỉ kiểm tra handler `IsRelateToEffect`/`IsFaceup` khi phần operation đó cần handler còn tại vị trí/trạng thái hợp lệ. Không chặn search/draw chỉ vì handler rời sân nếu luật không yêu cầu.
6. Với đối tượng được target, kiểm tra quan hệ/trạng thái tại resolution theo reference; card được chọn trong operation không mặc nhiên là target.
7. HOPT/SOPT và giới hạn activation/use phải theo text và reference; không thêm `EFFECT_COUNT_CODE_OATH` cho mọi HOPT.
8. Dùng `tools/templates/` làm khung; xóa effect mẫu không dùng. Không sao chép custom cũ làm bằng chứng API đúng.
9. Nếu dùng định danh từ `script/constants.lua`, thêm `Duel.LoadScript("constants.lua")`. Tra setcode official trong tài liệu local.
10. API mới phải có bằng chứng từ official script/helper hoặc source engine. `tools/phantom_apis.txt` chỉ là danh sách lỗi đã biết, không chứng minh API còn lại hợp lệ.
11. Gán range/property/reset/category theo loại effect và reference, không áp dụng một công thức cho mọi effect.

---

## 2. Quy Tắc Chọn Passcode & Setcode

### 2.1 Quy tắc chọn Passcode
Giữ nguyên passcode hiện hữu. Với card mới, dùng range đã đăng ký trong `feature_list.json` và kiểm tra trùng trong **mọi CDB**, JSON và script. Ưu tiên range 9 chữ số được nhóm thống nhất; không ghép setcode thành ID rồi coi là bảo đảm không trùng. ID và setcode là hai định danh khác nhau.

### 2.2 Phân biệt Archetype Official và Fan-made
* **Archetype Official (Dragonmaid, Labrynth, White Forest, Witchcrafter, Branded...):**
  - Tra cứu setcode hex chuẩn xác tại [`docs/archetype_setcode_constants.lua`](archetype_setcode_constants.lua).
  - Sử dụng trực tiếp setcode hex này trong JSON specs (dưới dạng số decimal). EDOPro đã tích hợp sẵn các setcode này, **không được thêm chúng vào `script/constants.lua`**.
* **Archetype Fan-made mới:**
  1. Đăng ký hằng số `SET_XXX = 0xYYY` vào [script/constants.lua](../script/constants.lua).
  2. Đăng ký chuỗi hiển thị tên archetype `!setname 0xYYY TênArchetype` vào [strings.conf](../strings.conf).

---

## 3. CDB SQLite Schema Reference

Database do compiler quản lý là `card-data.cdb`; các CDB khác thuộc luồng dữ liệu riêng (xem `database-workflow.md`). Mọi thay đổi thuộc tính của card đều phải được chỉnh sửa trong tệp JSON Specs tương ứng tại `card-data/c<passcode>.json` (được xem là **Single Source of Truth**), sau đó CLI biên dịch tự động vào database.

### 3.1 Cấu trúc Bảng Database
Schema và quy tắc đóng gói dữ liệu tuân theo **Datacorn** (trình editor CDB chính thức của ProjectIgnis, source tham khảo tại `docs/resources/Datacorn/`).

* **Bảng `datas` (Metadata):** Chứa các thuộc tính số của card.
  - `id`: Passcode nguyên của card; phải khớp tên file.
  - `ot`: **Luôn đặt là 32** (Custom card). Compiler sẽ báo lỗi nếu khác 32.
  - `alias`: ID của card gốc nếu là Alt-art (0 = không có).
  - `setcode`: Tối đa **4 setcode 16-bit** đóng gói trong 1 số 64-bit: `setcode = sc1 | (sc2 << 16) | (sc3 << 32) | (sc4 << 48)`.
  - `type`: Loại card (dạng bitmask). Phải có **đúng 1** trong 3 bit khung: Monster (`0x1`) / Spell (`0x2`) / Trap (`0x4`).
  - `atk`, `def`: ATK/DEF (-2 đại diện cho `?`).
  - `level`: Cấp độ/Rank/Link rating (0–13). Với **Pendulum scale**, scale được mã hóa vào cột level theo công thức Datacorn: `level = (base_level & 0x800000FF) | (left_scale << 24) | (right_scale << 16)`.
  - `race`: Tộc quái vật (bitmask, monster phải có **đúng 1 bit**).
  - `attribute`: Hệ quái vật (bitmask, monster phải có **đúng 1 bit**).
  - `category`: Phân loại hiệu ứng (dạng bitmask).
  - **Link Monster:** cột `def` KHÔNG phải DEF mà là **bitfield link marker**: `0x1` Bottom-Left, `0x2` Bottom, `0x4` Bottom-Right, `0x8` Left, `0x20` Right, `0x40` Top-Left, `0x80` Top, `0x100` Top-Right (bit `0x10` không dùng). Link rating nằm trong cột `level`.
  - **Spell/Trap:** các cột `atk`, `def`, `level`, `race`, `attribute` phải bằng 0.
* **Bảng `texts` (Văn bản):** Chứa `name`, `desc` và `str1` đến `str16` (các option prompt khi chọn hiệu ứng).

### 3.2 Field thân thiện trong Specs JSON (khuyến nghị dùng)
Ngoài giá trị thô đã đóng gói, compiler hỗ trợ các field dễ đọc sau (ưu tiên dùng khi viết card mới — compiler tự đóng gói và validate):

| Field JSON | Ý nghĩa | Ví dụ |
|------------|---------|-------|
| `"setcodes": [...]` | Danh sách tối đa 4 setcode (tự đóng gói vào `setcode`) | `"setcodes": [296, 4444]` |
| `"lscale"` / `"rscale"` | Pendulum Scale trái/phải (tự đóng gói vào `level`) | `"lscale": 4, "rscale": 4` |
| `"linkmarkers": [...]` | Tên link marker (tự đóng gói vào `def`) | `"linkmarkers": ["Top", "Bottom"]` |
| `"atk"` / `"def"`: `"?"` | ATK/DEF `?` (tự chuyển thành -2) | `"atk": "?"` |

Lưu ý: không khai báo đồng thời field thô và field thân thiện với giá trị mâu thuẫn (compiler báo lỗi).

### 3.3 Validation & Compile Atomic
* `python .\tools\manage_db.py validate` — kiểm tra toàn bộ specs theo quy tắc Datacorn mà **không ghi CDB** (nhanh, dùng khi đang sửa spec).
* `python .\tools\manage_db.py compile` — validate trước, chỉ khi **0 lỗi** mới biên dịch ra file tạm rồi thay thế CDB (atomic; nếu có lỗi, CDB cũ giữ nguyên và exit code = 1).
* Các lỗi bị chặn: `ot` ≠ 32, thiếu/thừa bit khung Monster-Spell-Trap, monster thiếu hoặc multi-bit race/attribute, link marker không hợp lệ hoặc rỗng, scale > 13, level > 13, Spell/Trap có chỉ số khác 0, `strings` > 16, `id` không khớp tên file...

---

## 4. Bảng Tra Cứu Bitmasks Thập Phân (Decimal)

Khi điền Specs JSON tại `card-data/`, bạn bắt buộc phải điền **giá trị thập phân (Decimal)** của các bitmask.

### 4.1 Card Type Bitmask (`type`)

| Loại Card | Giá trị Hex | Thập phân (Dec) |
|-----------|-------------|-----------------|
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

### 4.2 Monster Race Bitmask (`race`)

| Tộc (Race) | Giá trị Hex | Thập phân (Dec) |
|------------|-------------|-----------------|
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

### 4.3 Monster Attribute Bitmask (`attribute`)

| Hệ (Attribute) | Giá trị Hex | Thập phân (Dec) |
|----------------|-------------|-----------------|
| EARTH | `0x1` | **1** |
| WATER | `0x2` | **2** |
| FIRE | `0x4` | **4** |
| WIND | `0x8` | **8** |
| LIGHT | `0x10` | **16** |
| DARK | `0x20` | **32** |
| DIVINE | `0x40` | **64** |

### 4.4 CDB category khác Lua CATEGORY_*

`category` trong JSON/CDB là bitmask bộ lọc database, **không phải** hằng Lua `CATEGORY_*` truyền cho `SetCategory`/`SetOperationInfo`. Tra bảng `CATEGORIES` trong `tools/manage_db.py` cho CDB; tra constants của engine/reference cho Lua. Không chuyển thẳng số từ bảng Lua sang JSON.
