# Quy Trình Kiểm Thử Card Trong Game (EDOPro Testing Workflow)

Tài liệu hướng dẫn quy trình kiểm thử toàn diện từ kiểm tra tĩnh (Static Checks) đến kiểm thử thực chiến (Runtime Duel Testing) với bộ cài game EDOPro tại thư mục cục bộ (mặc định: `F:\Game\ProjectIgnis`).

---

## 1. Nguyên Tắc & Mục Tiêu

1. **Kiểm tra tĩnh không thay thế kiểm thử duel**: `validate_scripts.ps1` chỉ xác nhận cú pháp và tên API/hằng số có tồn tại trong whitelist, không đảm bảo logic timing, quan hệ chain, hay quy tắc engine ocgcore hỗ trợ tại runtime.
2. **Quy chuẩn Engine ocgcore cho Effect Types**:
   - `EFFECT_TYPE_QUICK_O` (Quick Effect): Engine ocgcore **chỉ cho phép Monster và Trap**. Tuyệt đối **không dùng `EFFECT_TYPE_QUICK_O` trên Spell** (kể cả Quick-Play Spell trong GY); ocgcore sẽ chặn kích hoạt (`is_can_be_effect_type` trả về `false`).
   - Hiệu ứng phản ứng dưới GY của Spell khi đối thủ kích hoạt card/effect phải dùng Trigger Effect: `EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O` với property `EFFECT_FLAG_DELAY` và code `EVENT_CHAINING`.
3. **Khai báo liên kết tên (`s.listed_names`)**:
   - Khi effect card đề cập trực tiếp đến tên card cụ thể (ví dụ `"Harpie Lady Sisters"`, `"Elegant Egotist"`...), bắt buộc phải khai báo `s.listed_names = { ... }`.
   - Thiếu khai báo này sẽ khiến các searcher phụ thuộc vào `Card.ListsCode` (như *Harpie Perfumer*, *Harpie Oracle*) không thể nhận diện hay tìm kiếm card.

---

## 2. Đồng Bộ Dữ Liệu Vào EDOPro (`F:\Game\ProjectIgnis`)

EDOPro nạp card custom thông qua các thư mục trong `repositories/` (mặc định là `repositories/custom_cards_zesty/`).

Để đồng bộ script, database CDB, hình ảnh artwork và sinh deck test mẫu, chạy:

```powershell
# Đồng bộ một card cụ thể và tự động tạo deck test
powershell -File .\tools\sync_game.ps1 -CardId <ID>

# Ví dụ cho Harpie's Prayer:
powershell -File .\tools\sync_game.ps1 -CardId 75142032

# Đồng bộ toàn bộ repo sang game:
powershell -File .\tools\sync_game.ps1
```

> **Lưu ý về Git trong thư mục game**: Thư mục `F:\Game\ProjectIgnis\repositories\custom_cards_zesty` nếu là clone Git thì phải ở nhánh `master` đồng bộ với repo chính. Nếu EDOPro báo lỗi cập nhật repository qua mạng hoặc bị kẹt ở nhánh `main` cũ, chạy `sync_game.ps1` sẽ ghi đè trực tiếp các file mới nhất từ workspace vào game để test ngay.

---

## 3. Quy Trình Kiểm Thử Từng Bước (Step-by-Step)

### Bước 1: Đối chiếu Effect Text với Artwork
- Xem file ảnh tại `pics/<ID>.png` hoặc `pics/<ID>.jpg`.
- Đọc kỹ từng câu chữ:
  - Loại card (Spell / Trap / Monster, Quick-Play, Continuous...).
  - Vị trí kích hoạt (Tay, Sân, GY, Banished).
  - Điều kiện kích hoạt (Timing: "When" vs "If", trigger event).
  - Cost (Banish, trả LP, discard...).
  - Mục tiêu (Target hay non-target).
  - Giới hạn lượt (HOPT: "You can only use each effect... once per turn").

### Bước 2: Kiểm tra tĩnh (Static Validation)
Chạy validator từ thư mục gốc của repo:
```powershell
powershell -File .\tools\validate_scripts.ps1 script\c<ID>.lua
```
Đảm bảo kết quả trả về `Results: 1 OK, 0 WARN, 0 FAIL`.

### Bước 3: Đồng bộ sang game và chuẩn bị Deck test
Chạy `sync_game.ps1 -CardId <ID>` để copy file và sinh `deck/test_<ID>.ydk`.
Trong EDOPro:
- Mở mục **Deck Edit**.
- Chọn deck `test_<ID>` vừa sinh. Kiểm tra xem card có hiện đúng tên, artwork, stats và mô tả hay không.

### Bước 4: Test thực chiến trong EDOPro (Duel Simulation)
Có 2 cách thực hiện thuận tiện:
1. **Đấu với AI / WindBot**:
   - Vào **Duel** -> **Test Bot** -> Chọn deck `test_<ID>`.
   - Đi trước hoặc đi sau để kích hoạt các tình huống.
2. **Local Duel (Mở 2 cửa sổ EDOPro để điều khiển cả 2 bên)**:
   - Cửa sổ 1: Vào **Duel** -> **Host Game** (chế độ LAN / Localhost, đặt IP `127.0.0.1`, cổng `7911`).
   - Cửa sổ 2: Vào **Duel** -> **Join Game** (`127.0.0.1`).
   - Cách này cho phép chủ động kích hoạt card ở bên đối thủ để kiểm tra các hiệu ứng phản ứng chuỗi (Chain).

### Bước 5: Kiểm tra nhật ký lỗi (Runtime Log)
Nếu trong quá trình duel có lỗi (card không kích hoạt, bị crash, hoặc báo lỗi script):
- Mở tệp `F:\Game\ProjectIgnis\error.log`.
- Kéo xuống cuối để xem traceback Lua (tên hàm `nil`, kiểu dữ liệu sai, hoặc `is_can_be_effect_type` thất bại).

---

## 4. Test Matrix Mẫu — Card "Harpie's Prayer" (Passcode 75142032)

| STT | Kịch bản kiểm thử | Hành động thực hiện | Kết quả mong đợi |
| :--- | :--- | :--- | :--- |
| **TC1** | **Kích hoạt Hiệu ứng 1 từ trên tay** | Có "Harpie Lady" hoặc "Harpie Lady Sisters" ngửa mặt trên sân. Kích hoạt Harpie's Prayer. | Chọn Special Summon thành công 1 quái vật WIND Winged Beast hoặc WIND Dragon từ Deck hoặc GY. |
| **TC2** | **Kích hoạt khi không đủ điều kiện** | Sân không có "Harpie Lady" / "Harpie Lady Sisters", hoặc MZONE đã đầy 5 ô. | Card không sáng lên để cho phép kích hoạt. |
| **TC3** | **Tìm kiếm bởi Harpie Perfumer** | Normal Summon "Harpie Perfumer" (39392286). | Prompt search hiện ra và cho phép add "Harpie's Prayer" lên tay (nhờ `s.listed_names` có `12206212`). |
| **TC4** | **Thu hồi bởi Harpie Oracle** | Harpie's Prayer ở dưới GY, có quái Harpie Lv5+ trên sân, kích hoạt Harpie Oracle (90953320). | Cho phép chọn thu hồi Harpie's Prayer từ GY lên tay. |
| **TC5** | **Tìm kiếm bởi Hysteric Sign** | Kích hoạt Hysteric Sign (19337371). | Cho phép add Harpie's Prayer lên tay như một "Elegant Egotist". |
| **TC6** | **Kích hoạt Hiệu ứng 2 dưới GY** | Harpie's Prayer trong GY, trên sân có "Harpie Lady" hoặc "Harpie's Pet Dragon". Đối thủ kích hoạt 1 card/effect bất kỳ. | Game hiện prompt hỏi người chơi có muốn banish Harpie's Prayer để destroy 1 card trên sân hay không. Chọn phá hủy thành công. |
| **TC7** | **Kiểm tra HOPT** | Trong cùng 1 lượt, cố gắng kích hoạt Hiệu ứng 1 lần thứ hai từ bản sao thứ hai; hoặc kích hoạt Hiệu ứng 2 lần thứ hai. | Không được phép kích hoạt lại hiệu ứng đó trong cùng lượt. |
| **TC8** | **Tương tác với Necrovalley** | Necrovalley đang hoạt động trên sân. | Hiệu ứng 1 vẫn có thể summon từ Deck, nhưng nếu chọn mục tiêu từ GY thì bị chặn hợp lệ; Hiệu ứng 2 tự banish bản thân không bị Necrovalley chặn (trừ khi Necrovalley cấm banish từ GY). |
