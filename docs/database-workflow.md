# Database sinh từ card-data

## Ranh giới dữ liệu

Theo lựa chọn của chủ repo, **toàn bộ `card-data/c*.json`** được biên dịch vào **`card-data.cdb`**. Tên file biểu thị nguồn dữ liệu, không suy đoán tác giả qua Git. Card không có spec vẫn nằm trong các CDB anh em — mọi `*.cdb` khác ở gốc repo (`custom_cards_zesty.cdb`, `mycard.cdb` và các CDB cộng đồng); compiler không ghi vào các file đó nhưng đối chiếu passcode với tất cả.

```powershell
python tools/manage_db.py validate
python tools/manage_db.py compile
python tools/manage_db.py check-sync
python tools/manage_db.py query <ID-or-name>
```

Sửa JSON rồi compile; không sửa CDB generated bằng editor. Compiler từ chối ghi đè nếu CDB đích chứa ID không có spec, thay vì âm thầm xóa card đó. Muốn bỏ một card phải xử lý rõ việc xóa ở cả nguồn và dữ liệu đích.

## Làm việc nhóm

- Commit JSON + Lua/artwork liên quan + `card-data.cdb` sinh từ cùng phiên bản nguồn.
- Khi merge conflict ở `card-data.cdb`, giải quyết JSON trước rồi compile lại. Không chọn cả file ours/theirs rồi bỏ qua dữ liệu bên kia.
- Không overwrite CDB của dev khác. Muốn đưa card của CDB khác vào `card-data/`, thống nhất ownership, viết spec, rồi bỏ ID đó khỏi CDB cũ: `validate`/`compile` chặn mọi ID trùng giữa các CDB, và không được trông vào thứ tự nạp của client để giải quyết trùng ID.
- Không tự đổi ID hiện hữu vì có thể làm hỏng deck.
- Tách CDB ngăn compiler ghi đè database của dev khác; nhiều người cùng sửa chính `card-data.cdb` vẫn phải merge nguồn JSON rồi rebuild.
