# TTF Custom Cards — Agent Guide

Đọc file này trước, rồi chỉ đọc tài liệu liên quan. Repo dùng Lua (EDOPro), Python và PowerShell; chạy lệnh từ thư mục gốc.

## Nguồn dữ liệu và ranh giới

- Nhánh chính của repo là **`master`** (đồng bộ với `upstream/master`). Không tạo feature branch: commit rồi push thẳng lên `origin/master` (đang ở worktree thì `git push origin HEAD:master`). Chỉ mở Pull Request sang repo gốc khi được yêu cầu; PR mở từ `LeDoanh:master`, nên commit mới trên `master` tự vào PR đang mở.
- `card-data/c<ID>.json`: nguồn dữ liệu cho card được quản lý bằng specs; compiler sinh **`card-data.cdb`**.
- `script/c<ID>.lua`: code chạy trong game. `tools/`: công cụ phát triển và templates, không phải script game.
- `custom_cards_zesty.cdb`, `mycard.cdb` và các CDB cộng đồng (`Chrysos Heirs.cdb`, `FlowerSpirit.cdb`, `Madoka.cdb`, `Mecha Three Kingdom.cdb`): dữ liệu của dev khác. Không compile đè, dump đè specs hoặc giải quyết conflict bằng chọn cả file ours/theirs.
- `feature_list.json`: hàng đợi và trạng thái; dùng Harness CLI để thay đổi, không chỉnh thủ công.
- Git diff/log là lịch sử thay đổi. Nhật ký phiên cũ nằm trong `docs/archive/`, chỉ đọc khi điều tra lịch sử; không tạo lại nhật ký bắt buộc.

## Quy trình tối thiểu

1. Đọc `docs/agent-workflow.md`; chốt effect text, passcode chưa dùng trong tất cả CDB, và các tình huống cần kiểm tra.
2. Tra setcode tại `docs/archetype_setcode_constants.lua`. Đọc official reference từ game bằng `python tools/read_official.py <ID>` (hoặc `tools/read_official.ps1 <ID>`, hỗ trợ tra cứu theo tên hoặc dùng `tools/fetch_official.ps1` làm fallback online); ghi card ID, effect/function tham khảo và phần khác biệt. Không lấy custom card cũ làm bằng chứng API đúng.
3. Card mới: `python tools/manage_harness.py start <ID> "<name>" <template>`. Archetype chưa đăng ký thì chạy `archetype add <Name> <setcode>` trước. Dùng template như khung, không giữ hiệu ứng mẫu không thuộc yêu cầu.
4. Sửa JSON và Lua; đối chiếu từng effect với `docs/agent-rules.md`. Không bịa API, không suy ra timing từ tên hàm.
5. `python tools/manage_harness.py verify <ID>`; kiểm tra exit code. Đây là kiểm tra **tĩnh**, không chứng minh hiệu ứng chạy đúng.
6. Kiểm thử duel theo kịch bản trong workflow; báo rõ những gì chưa chạy. Trạng thái queue `done` chỉ có nghĩa hoàn tất pipeline hiện có, không là chứng nhận runtime.
7. Review diff; khi được yêu cầu commit, gom JSON, Lua, artwork liên quan và `card-data.cdb`. Format: `[<Git user>] [Fix|Feature|Refactor|Chore]: <English description>`.

## Ràng buộc viết card

- `local s,id=GetID()` và `s.initial_effect(c)`; header có tên, passcode, loại, các effect.
- Đọc `docs/agent-rules.md` cho cost/target/operation, count limit, reset và bitfields.
- Nếu dùng hằng/helper custom trong `script/constants.lua`, load bằng `Duel.LoadScript("constants.lua")`.
- `ot=32`; không thay ID card hiện hữu. ID cũ có độ dài khác nhau: không đổi ID chỉ để đủ 9 chữ số.
- Không áp đặt `IsRelateToEffect` lên mọi operation: chỉ kiểm tra đối tượng cần còn liên hệ để thực hiện phần hiệu ứng đó, theo official reference.
- Không chỉnh code gameplay ngoài yêu cầu, không coi lint hoặc mock là test duel.

## Điều hướng

- `docs/agent-workflow.md`: trình tự làm card, bằng chứng và QA.
- `docs/agent-rules.md`: quy tắc Lua và schema/bitmask.
- `docs/database-workflow.md`: ownership, compile, migration và conflict CDB.
- `docs/card-scripting-guide.md`: tham khảo mở rộng; đối chiếu với official script thực tế.

Kiểm tra công cụ: `python -m unittest discover -s tests -v`.
