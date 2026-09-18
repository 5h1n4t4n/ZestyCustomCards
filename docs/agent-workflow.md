# Quy trình tạo và sửa card

Chạy từ gốc repo; cần Python 3, PowerShell và Lua trong PATH. Thiếu parser thật thì không báo kiểm tra cú pháp thành công.

## 1. Chốt yêu cầu trước khi viết

Với từng effect, ghi ngắn trong mô tả công việc/PR: vị trí kích hoạt, event/timing, optional hay mandatory, cost, target, operation, count limit và reset. Xác định rõ "and", "then", "if you do"; nếu text mơ hồ thì hỏi, không tự thêm điều kiện.

Tìm official card cùng cơ chế, tải bằng `./tools/fetch_official.ps1 <official-ID>` và đọc `docs/official-reference/c<ID>.lua`. Ghi ID và hàm/effect dùng làm mẫu, phần nào khác yêu cầu. Đọc constants/helper mà script đó gọi nếu cần. Không coi template hay custom cũ là bằng chứng engine hỗ trợ.

## 2. Khởi tạo và triển khai

```powershell
python tools/manage_harness.py scan
python tools/manage_harness.py start <ID> "<name>" <template>
```

Chỉ scan khi cần đăng ký queue mới. Các template: effect_monster, normal_spell, normal_trap, fusion_monster, synchro_monster, xyz_monster, link_monster, pendulum_monster, field_spell, hand_trap.

`start` tạo JSON/Lua và cập nhật queue; không ghi đè file cũ. Điền hết placeholder, stats và effect text; xem `docs/agent-rules.md`. Đối chiếu type của Extra Deck có bit Effect nếu là effect monster. `aux.Stringid(id,N)` phải có phần tử strings[N] (Lua index logic bắt đầu 0).

## 3. Kiểm tra tĩnh

```powershell
python tools/manage_db.py validate
python tools/manage_harness.py verify <ID>
```

`verify` chạy preflight, compile card-data.cdb, Lua validation, lint và sync rồi cập nhật queue. Kiểm tra exit code; thông báo lint/fallback không phải bằng chứng runtime. CDB có thể đã compile dù bước Lua sau đó thất bại: không commit cho đến khi sửa xong.

### Danh sách tham chiếu EDOPro

Lua trả về `nil` cho tên không tồn tại thay vì báo lỗi, nên hằng số gõ sai (`CATEGORY_SET`) hay hàm bịa (`Card.IsAbleToHandOrExtra`) vẫn qua được bước kiểm tra cú pháp rồi mới crash trong duel. `validate_scripts.ps1` chặn bằng hai danh sách trắng sinh từ bản cài game:

| File | Nội dung |
| :--- | :--- |
| `tools/edopro_constants.txt` | hằng số ALL_CAPS do thư viện script EDOPro định nghĩa |
| `tools/edopro_apis.txt` | cặp `Namespace.Function` có thật, gồm cả hàm chỉ gọi dạng `c:Method()` |

Lỗi `CONST:` và `API:` là FAIL, không phải warning. Sai tên thì sửa theo tên thật; hằng số riêng của card thì khai báo `local` ngay trong file, hằng số dùng chung thì thêm vào `script/constants.lua` kèm `Duel.LoadScript("constants.lua")`.

Sinh lại khi cập nhật EDOPro (chỉ chạy được trên máy có cài game):

```powershell
python tools/sync_edopro_refs.py
python tools/sync_edopro_refs.py --check
python tools/sync_edopro_refs.py --game-dir "D:/EDOPro"
```

Mặc định đọc `$env:EDOPRO_DIR`, không có thì `F:/Game/ProjectIgnis`. `--check` chỉ so sánh và trả exit 1 khi lệch. Hai file sinh ra được commit để máy không cài game vẫn kiểm tra được; đừng sửa tay.

Chỉ hằng số khai báo trong file thư viện của game mới vào danh sách. Biến `local CARD_X = 12345` trong script từng card không tính, vì gộp vào sẽ khiến một tên gõ sai lọt qua chỉ nhờ trùng biến cục bộ của card khác.

Lưu ý phiên bản: EDOPro chạy Lua 5.4.7 (chuỗi trong `ocgcore.dll`), còn `validate_scripts.ps1` gọi `lua` trong PATH. Nếu script qua được parser máy mình mà EDOPro từ chối, kiểm tra lệch phiên bản trước tiên.

### Artwork và dọn queue

Sau khi các bước tĩnh đạt, `verify` copy ảnh queue thành `pics/<ID>.jpg|.png` nếu chưa có artwork, đọc lại bản copy để xác nhận rồi mới xóa ảnh trong `docs/queues/`. Không xác nhận được (đuôi `.gif`, copy lỗi) thì ảnh queue được giữ lại và chỉ đổi tên `w_` -> `d_` như trước, kèm warning. Tự đặt artwork vào `pics/` trước cũng được: lúc đó `verify` giữ bản của bạn và chỉ xóa ảnh queue.

Ảnh `d_` tồn đọng từ các card làm trước đó dọn bằng:

```powershell
python tools/manage_harness.py cleanup
python tools/manage_harness.py cleanup --apply
```

Mặc định là dry-run. Chỉ ảnh của card `done` và đã có artwork trong `pics/` mới bị xóa; file chưa đăng ký, chưa done hoặc thiếu artwork được giữ lại kèm lý do vì khi đó ảnh queue có thể là bản duy nhất. `--apply` xóa file và gỡ `queue_file` khỏi `feature_list.json`; ảnh đang được Git theo dõi nên vẫn khôi phục được từ history.

`done`/ảnh `d_` là trạng thái pipeline cũ, không chứng minh duel đã được test. Không viết "fully tested" khi chỉ chạy verify. Không cần ghi nhật ký phiên; dùng Git và feature_list.

## 4. Review logic và test duel

- Cost chỉ trả ở cost; target kiểm tra `chk==0`, lựa chọn và operation info đúng.
- Đối tượng target rời sân/đổi trạng thái trước resolution; handler rời sân có thực sự phải chặn effect hay không?
- Thiếu tài nguyên, không đủ zone, không có mục tiêu hợp lệ; zone được giải phóng bởi cost/material.
- Optional effect có thể từ chối; HOPT/SOPT, nhiều bản sao, negate activation so với negate effect.
- Hiệu ứng bị vô hiệu hóa, reset cuối lượt/rời sân; special summon restriction và summon procedure.
- JSON khớp text/stats, strings và Lua; constants custom đã load.

Test trong client/core đúng phiên bản với deck và trạng thái tái hiện được; lưu expected/actual cho các tình huống áp dụng. Không giả định EDOPro có console Lua bằng phím backtick. Nếu chưa chạy game, báo rõ "kiểm tra tĩnh đạt, runtime chưa kiểm thử".

## 5. Bàn giao

Nêu ID sửa, official reference, hành vi thay đổi, lệnh đã chạy/kết quả và test duel còn thiếu. Review `git diff --check` và `git diff --stat`. Đọc `docs/database-workflow.md` trước khi commit/migrate CDB. Chỉ commit/push khi được yêu cầu.
