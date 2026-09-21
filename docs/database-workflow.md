# Database sinh từ card-data

## Ranh giới dữ liệu

Theo lựa chọn của chủ repo, **toàn bộ `card-data/c*.json`** được biên dịch vào **`card-data.cdb`**. Tên file biểu thị nguồn dữ liệu, không suy đoán tác giả qua Git. Card không có spec vẫn nằm trong các CDB anh em (`custom_cards_zesty.cdb`, `mycard.cdb`, `Chrysos Heirs.cdb`, `FlowerSpirit.cdb`, `Madoka.cdb`, `Mecha Three Kingdom.cdb`); compiler không ghi vào các file đó.

```powershell
python tools/manage_db.py validate
python tools/manage_db.py compile
python tools/manage_db.py check-sync
python tools/manage_db.py query <ID-or-name>
```

Sửa JSON rồi compile; không sửa CDB generated bằng editor hoặc chạy dump lên specs để giải quyết conflict. Compiler từ chối ghi đè nếu CDB đích chứa ID không có spec, thay vì âm thầm xóa card đó. Muốn bỏ một card phải xử lý rõ việc xóa ở cả nguồn và dữ liệu đích.

## Chuyển dữ liệu một lần

```powershell
python tools/migrate_card_data.py
python tools/migrate_card_data.py --apply
```

Đóng game và các trình sửa CDB trước khi chạy migration; không chạy đồng thời với compiler. Các file được thay lần lượt với cơ chế khôi phục khi lỗi, không phải một transaction chung.

Mặc định chỉ lập báo cáo. Khi apply: validate specs, dựng CDB đích, sao lưu dữ liệu trước thay đổi trong `backups/`, bỏ đúng ID có spec khỏi hai CDB cũ và kiểm tra card còn lại không thay đổi. Backup không được copy vào thư mục game. JSON là nguồn cho database mới; nếu dòng cũ khác spec, giữ bản cũ trong backup và ghi khác biệt để kiểm tra.

Migration không phải thao tác thường ngày. Sau khi áp dụng, phân phối đồng bộ `card-data.cdb` cùng các CDB còn lại để client không còn nạp cùng ID từ CDB cũ. Không suy đoán thứ tự nạp có thể giải quyết trùng ID.

## Làm việc nhóm

- Commit JSON + Lua/artwork liên quan + `card-data.cdb` sinh từ cùng phiên bản nguồn. Không commit backup.
- Khi merge conflict ở `card-data.cdb`, giải quyết JSON trước rồi compile lại. Không chọn cả file ours/theirs rồi bỏ qua dữ liệu bên kia.
- Không overwrite CDB của dev khác. Nếu thay đổi card ngoài card-data, thống nhất ownership và nhập spec riêng trước.
- Trước merge/commit, kiểm tra ID mới chưa có trong bất kỳ CDB nào của repo; không tự đổi ID hiện hữu vì có thể làm hỏng deck.
- Tách CDB ngăn compiler ghi đè database của dev khác; nhiều người cùng sửa chính `card-data.cdb` vẫn phải merge nguồn JSON rồi rebuild.
