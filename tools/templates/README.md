# EDOPro Card Templates — Usage Guide

Hướng dẫn cách dùng template trong thư mục này để sinh script card.

Tham khảo đầy đủ:
- **API & effect types**: `docs/card-scripting-guide.md`
- **Categories, CDB schema & Critical Rules**: `docs/agent-rules.md`
- **Workflow & Testing Guide**: `docs/agent-workflow.md`

---

## 1. Chọn template

| Card Type | Template File |
|-----------|---------------|
| Effect Monster (trigger + ignition) | `template_effect_monster.lua` |
| Normal Spell | `template_normal_spell.lua` |
| Quick-Play Spell | `template_normal_spell.lua` (đổi type constant) |
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
- **Đổi loại effect**: Xem bảng effect types trong `docs/card-scripting-guide.md` mục 3.

## 4. Đặt tên file

```
script/c<passcode>.lua
Ví dụ: script/c192200001.lua
```

## 5. Validate

```powershell
.\tools\validate_scripts.ps1
.\tools\lint_scripts.ps1
```
