# EDOPro Card Templates — Usage Guide

Hướng dẫn cách dùng template trong thư mục này để sinh script card.

Tham khảo đầy đủ:
- **Quy tắc Lua, CDB schema, bitmask và tài liệu API**: `docs/agent-rules.md`
- **Quy trình tạo card**: `docs/agent-workflow.md`
- **Test card trong game**: `docs/game-testing-workflow.md`

---

## 1. Chọn template

| Card Type | Template File |
|-----------|---------------|
| Effect Monster (trigger + ignition) | `template_effect_monster.lua` |
| Normal Spell | `template_normal_spell.lua` |
| Quick-Play Spell | `template_quick_play_spell.lua` |
| Continuous Spell | `template_continuous_spell.lua` |
| Normal Trap | `template_normal_trap.lua` |
| Fusion Monster | `template_fusion_monster.lua` |
| Synchro Monster | `template_synchro_monster.lua` |
| Xyz Monster | `template_xyz_monster.lua` |
| Link Monster | `template_link_monster.lua` |
| Pendulum Monster | `template_pendulum_monster.lua` |
| Field Spell | `template_field_spell.lua` |
| Hand Trap / Quick Effect | `template_hand_trap.lua` |

## 2. Thay placeholder

Mỗi template dùng `<<PLACEHOLDER>>`. Thay tất cả:

| Placeholder | Thay bằng |
|-------------|-----------|
| `XXXXXXXXX` | Passcode (9 chữ số) |
| `<<SETCODE>>` | Archetype hex (e.g. `0x789`) |
| `<<RANK>>` | Rank (Xyz) |
| `<<MATERIAL_COUNT>>` | Số Xyz material |
| `<<LINK_COUNT>>` | Link rating |
| `<<MIN_MATERIAL>>` | Số Link material tối thiểu |
| `<<ATK_VALUE>>` | ATK/DEF boost |
| `<<LP_AMOUNT>>` | LP gain/loss |

## 3. Thêm/bớt effect

Mỗi template có comment `<< Effect 1 >>`, `<< Effect 2 >>` đánh dấu slot.

- **Thêm effect**: Copy block `Effect.CreateEffect` → `c:RegisterEffect(eN)` + các hàm filter/target/operation. Đổi tên biến (`e2` → `e3`) và `aux.Stringid(id,N)` (N tăng dần).
- **Bớt effect**: Xóa block effect + tất cả hàm liên quan.
- **Đổi loại effect**: Lấy official card cùng cơ chế làm mẫu (`python tools/read_official.py <ID|"Tên">`).

## 4. Đặt tên file

```
script/c<passcode>.lua
Ví dụ: script/c192200001.lua
```

## 5. Validate

```powershell
python tools/manage_harness.py verify <passcode>
```

`verify` chạy `validate_scripts.ps1` cho đúng script của card, cùng các bước kiểm tra dữ liệu (`docs/agent-workflow.md` §4).
