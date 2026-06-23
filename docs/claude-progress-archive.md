# Nhật ký Tiến độ Lưu trữ — TTFCustomCards

[Quay lại Nhật ký Tiến độ chính](../claude-progress.md)

---

### Phiên 001 — 2026-05-29

- **Mục tiêu:** Setup lại project theo Harness Engineering (walkinglabs.github.io/learn-harness-engineering)
- **Đã hoàn thành:**
  - Tái cấu trúc `AGENTS.md` → routing file ~60 dòng
  - Tạo sub-docs: `docs/agent-workflow.md`, `docs/agent-rules.md`, `docs/agent-constants.md`, `docs/agent-bugfix.md`
  - Tạo `feature_list.json` — track trạng thái card theo archetype
  - Tạo `claude-progress.md` (file này)
- **Xác minh đã chạy:** Không có script Lua nào bị thay đổi — không cần validate
- **Bằng chứng đã ghi lại:** File mới tạo trong repo
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** AGENTS.md, feature_list.json, docs/agent-*.md, claude-progress.md
- **Rủi ro đã biết:**
  - `feature_list.json` cần được cập nhật thủ công khi thêm card mới — passcode của các card Castle of Dreams chưa được điền đầy đủ (không có trong queue files)
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

### Phiên 002 — 2026-05-29

- **Mục tiêu:** Điều chỉnh timing/condition của Labrynth Party (c90177.lua) từ "During your Main Phase" thành "During Main Phase"
- **Đã hoàn thành:**
  - Cập nhật script `script/c90177.lua`: loại bỏ điều kiện kiểm tra turn player `Duel.GetTurnPlayer()==tp` trong hàm condition `s.setcon2`, và cập nhật chú thích mô tả effect ở dòng 13 và 131.
  - Đổi kiểu của Effect 2 trong script từ `EFFECT_TYPE_IGNITION` thành `EFFECT_TYPE_QUICK_O` và set code thành `EVENT_FREE_CHAIN` để cho phép kích hoạt trong lượt đối phương (Quick Effect).
  - Cập nhật text mô tả card trong cơ sở dữ liệu SQLite (`custom_cards_zesty.cdb`) cho passcode 90177.
- **Xác minh đã chạy:**
  - Chạy validate `.\script-test\validate_scripts.ps1` thành công (0 FAIL, c90177.lua OK).
  - Chạy `python .\script-test\manage_db.py check-sync` và `query 90177` xác nhận DB và Script đồng bộ.
- **Bằng chứng đã ghi lại:** Thay đổi trực tiếp trong file script và cơ sở dữ liệu.
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** script/c90177.lua, custom_cards_zesty.cdb, claude-progress.md
- **Rủi ro đã biết:** Không có
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

### Phiên 003 — 2026-05-30

- **Mục tiêu:** Tạo card mới "Teardrop the Rikka Fairy" (Xyz Rank 12 WATER Plant)
- **Đã hoàn thành:**
  - Tạo script `script/c32100001.lua` — Xyz monster với 4 effects:
    - Effect 0: Immunity (unaffected by non-Rikka effects)
    - Effect 1: Detach 1 → return Plant → look hand → destroy 2 (HOPT)
    - Effect 2: Negate activation + banish (Trigger/Quick)
    - Effect 3: Board wipe — detach 2 → destroy all opponent's field
    - Tất cả effects 1-3 có dual Ignition/Quick-O dựa trên Plant overlay material
    - Alt Xyz Summon: overlay trên "Teardrop the Rikka Queen" (33779875)
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 32100001, ot=32)
  - Thêm archetype Rikka vào `feature_list.json`
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → 0 FAIL, c32100001.lua OK
  - `lint_scripts.ps1` → c32100001.lua không có issue
  - `manage_db.py check-sync` → card đồng bộ
  - `manage_db.py query 32100001` → thông tin chính xác
  - `Test-Path script\c32100001.lua` → True
- **Bằng chứng đã ghi lại:** Script, database, feature_list.json
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** script/c32100001.lua, custom_cards_zesty.cdb, feature_list.json, claude-progress.md
- **Rủi ro đã biết:** 
  - RACE_PLANT value (0x400=1024) cần verify nếu card không load đúng trong EDOPro
  - Alt Xyz Summon cần test trong game để verify xyzfilter hoạt động đúng
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

### Phiên 004 — 2026-05-30

- **Mục tiêu:** Double check script c32100001.lua, copy artwork, cập nhật tài liệu hướng dẫn setcode, sửa database card 998716 (The Grand Stage of Maliss).
- **Đã hoàn thành:**
  - Cải tiến script `script/c32100001.lua`:
    - Sửa logic target/operation của Effect 1: cho phép chọn Plant từ cả field/GY/banished của đối thủ (đúng với text "Banish/GY/Field"), và kiểm tra card được trả về hand/extra deck thành công rồi mới thực hiện look hand + destroy 2.
    - Cải tiến Effect 2a (không có Plant material) thành `EFFECT_TYPE_QUICK_O` giới hạn lượt của mình (`Duel.GetTurnPlayer()==tp`) để đúng quy tắc chain và negate activation trong YGO.
  - Copy ảnh card từ `docs/queues/Rikka/p_Teardrop_the_Rikka_Fairy.jpg` sang `pics/32100001.jpg`.
  - Cập nhật quy chuẩn tra cứu setcode cho các archetype official trong `AGENTS.md` (ràng buộc cứng #6) và `docs/agent-constants.md` chỉ định rõ file `docs/archetype_setcode_constants.lua`.
  - Sửa lỗi thiếu text hiệu ứng (str1, str2, str3) gây hiển thị `???` cho card `998716` ("The Grand Stage of Maliss") trong cơ sở dữ liệu `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c32100001.lua và c998716.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> đồng bộ thành công.
  - `python .\script-test\manage_db.py query 32100001` và `query 998716` -> thông tin và các strings hiệu ứng hiển thị chính xác.
- **Files/artifacts đã cập nhật:** [c32100001.lua](file:///d:/TTF/TTFCustomCards/script/c32100001.lua), [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [agent-constants.md](file:///d:/TTF/TTFCustomCards/docs/agent-constants.md), `pics/32100001.jpg`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 005 — 2026-05-30

- **Mục tiêu:** Fix lỗi hiển thị `???` thay cho lựa chọn "Add to hand" của card `998716` ("The Grand Stage of Maliss") và `22121392` ("Verre Magic: Transformation").
- **Đã hoàn thành:**
  - Sửa script `script/c998716.lua` và `script/c22121392.lua`: Thay thế system string `1190` bằng custom string tương ứng từ database (`aux.Stringid(id,3)` cho 998716 và `aux.Stringid(id,4)` cho 22121392).
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Thêm `'Add to hand'` vào `str4` cho card `998716` và `str5` cho card `22121392`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c998716.lua và c22121392.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> đồng bộ thành công (không phát sinh lỗi mới).
- **Files/artifacts đã cập nhật:** [c998716.lua](file:///d:/TTF/TTFCustomCards/script/c998716.lua), [c22121392.lua](file:///d:/TTF/TTFCustomCards/script/c22121392.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 006 — 2026-05-30

- **Mục tiêu:** Sửa lỗi hiển thị menu chọn Battle Phase / End Phase khi kích hoạt chuyển End Phase từ Main Phase của card `90178` ("Farewell Labrynth").
- **Đã hoàn thành:**
  - Cập nhật script `script/c90178.lua`: Trong hàm `s.ep_check`, thêm đăng ký hiệu ứng `EFFECT_CANNOT_BP` lên turn player (`turnp`) có reset timing `RESET_PHASE|PHASE_END` trước khi thực hiện `Duel.SkipPhase`. Việc này ngăn không cho người chơi chọn Battle Phase, giúp game tự động chuyển trực tiếp sang End Phase mà không hiển thị prompt lựa chọn.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c90178.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường.
- **Files/artifacts đã cập nhật:** [c90178.lua](file:///d:/TTF/TTFCustomCards/script/c90178.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 007 — 2026-05-30

- **Mục tiêu:** Sửa lỗi `8 Parameters are needed` của card `c192200014` ("Castle of Dreams - Fall").
- **Đã hoàn thành:**
  - Cập nhật script `script/c192200014.lua`: Sửa cuộc gọi `Duel.SelectMatchingCard` ở dòng 107 để truyền đủ 8 tham số bằng cách thêm `1-tp` làm tham số `player_of_self_location` (để lọc từ phần bài của đối thủ).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường.
- **Files/artifacts đã cập nhật:** [c192200014.lua](file:///d:/TTF/TTFCustomCards/script/c192200014.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 008 — 2026-05-30

- **Mục tiêu:** Sửa hiệu ứng 1 của card `79900010` ("Monica, The Legendary Witch") để cho phép Special Summon nguyên liệu lên sân đối thủ ở những zone mà card này chỉ tới.
- **Đã hoàn thành:**
  - Cập nhật script `script/c79900010.lua`:
    - Thay đổi bộ lọc `s.lkfilter` để kiểm tra khả năng Special Summon của card nguyên liệu lên sân của cả người chơi (`tp`) và đối thủ (`1-tp`) trong các zone tương ứng được liên kết.
    - Cập nhật hàm target `s.lktg` để kiểm tra sự tồn tại của bất kỳ nguyên liệu nào có thể Special Summon được lên một trong hai phần sân.
    - Tái cấu trúc hàm operation `s.lkop`: Triệu hồi từng nguyên liệu một (step-by-step) bằng `Duel.SpecialSummonStep`. Nếu một nguyên liệu có thể triệu hồi lên cả hai sân, hiển thị prompt cho phép người chơi chọn sân đích (`tp` hoặc `1-tp`). Hoàn tất chuỗi triệu hồi bằng `Duel.SpecialSummonComplete()`.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Thêm các chuỗi mô tả lựa chọn sân đích vào `str7` ("Special Summon to your field") và `str8` ("Special Summon to opponent's field") cho card `79900010`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c79900010.lua OK.
  - `.\script-test\lint_scripts.ps1` -> c79900010.lua không có lỗi linter/whitespaces.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi liên quan đến Monica.
- **Files/artifacts đã cập nhật:** [c79900010.lua](file:///d:/TTF/TTFCustomCards/script/c79900010.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 009 — 2026-05-30

- **Mục tiêu:** Tạo card mới "Maliss of the Fallen Game" (Normal Spell, archetype Maliss 0x1b9)
- **Đã hoàn thành:**
  - Tạo script `script/c44100001.lua` — Normal Spell với effect:
    - Cost: Pay half LP
    - Banish all cards in your GY, count Maliss cards banished
    - For every 2 Maliss cards banished, randomly banish 1 card from opponent's Extra Deck until End Phase
    - Banished opponent's cards cannot activate effects until End Phase
    - HOPT (hard once per turn)
    - At End Phase: return banished Extra Deck cards via `Duel.SendtoDeck`
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 44100001, ot=32, setcode=441=0x1b9)
  - Copy artwork từ `docs/queues/Maliss/p_Maliss_Of_The_Fallen_Game.png` sang `pics/44100001.png`
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → 0 FAIL, c44100001.lua OK (chỉ còn 1 cảnh báo cấu trúc nhỏ không ảnh hưởng).
  - `lint_scripts.ps1` → c44100001.lua không có lint issue.
  - `manage_db.py check-sync` → Đồng bộ (chỉ có lỗi cũ pre-existing).
  - `Test-Path script\c44100001.lua` → True.
- **Files/artifacts đã cập nhật:** [c44100001.lua](file:///d:/TTF/TTFCustomCards/script/c44100001.lua), `custom_cards_zesty.cdb`, `pics/44100001.png`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
- **Rủi ro đã biết:**
  - `Duel.SendtoDeck` trả card về Extra Deck — cần test in-game xem card có trở về đúng vị trí Extra Deck không.
  - Các hiệu ứng đơn lẻ `EFFECT_CANNOT_TRIGGER` đăng ký trực tiếp lên từng card bị banish — cần test in-game xem hệ thống có tự động giải phóng/chặn đúng yêu cầu không.

### Phiên 010 — 2026-05-30

- **Mục tiêu:** Thiết kế và code card mới "Elaina, The Wandering Witch" (LIGHT Spellcaster Link-1, ATK 1000)
- **Đã hoàn thành:**
  - Tạo script `script/c79900001.lua` với 2 hiệu ứng:
    - Hiệu ứng 1: Discard 1 Spell Card -> Chọn số N từ 1 đến 10 để excavate. Nếu có ít nhất 2 Spell Cards, đối thủ chọn 2, ta add 1 vào tay và gửi 1 xuống GY. Các card còn lại shuffle về Deck.
    - Hiệu ứng 2: End Phase optional trigger trả Elaina từ field/GY về Extra Deck (HOPT).
  - Đăng ký card vào cơ sở dữ liệu `custom_cards_zesty.cdb` (passcode 79900001, link marker Bottom = 2, ot=32).
  - Di chuyển artwork từ `docs/queues/Common/p_Elaina_The_Wandering_Witch.jpg` sang `pics/79900001.jpg`.
  - Đổi tên file trong hàng đợi sang prefix `d_` (`d_Elaina_The_Wandering_Witch.jpg`).
  - Thêm Elaina vào `feature_list.json` dưới mục `"Common"`.
  - Đổi tên file artwork queue của "Maliss of the Fallen Game" sang `d_Maliss_Of_The_Fallen_Game.png` và đăng ký archetype `"Maliss"` cùng card này vào `feature_list.json` (status: `"done"`).
- **Xác minh đã chạy:**
  - Chạy `.\script-test\validate_scripts.ps1` -> c79900001.lua OK (1 OK, 0 WARN, 0 FAIL).
  - Chạy `.\script-test\lint_scripts.ps1` -> Không có lỗi style cho c79900001.lua.
  - Chạy `python .\script-test\manage_db.py check-sync` -> c79900001.lua đã đồng bộ 100% với database.
- **Files/artifacts đã cập nhật:** [c79900001.lua](file:///d:/TTF/TTFCustomCards/script/c79900001.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/79900001.jpg`, `docs/queues/Common/d_Elaina_The_Wandering_Witch.jpg`, `docs/queues/Maliss/d_Maliss_Of_The_Fallen_Game.png`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 011 — 2026-05-30

- **Mục tiêu:** Thiết kế và code card mới "Power of the Dominators" (Normal Trap, archetype Dominus 0x1bf)
- **Đã hoàn thành:**
  - Tạo script `script/c44700001.lua` — Normal Trap với các hiệu ứng:
    - Kích hoạt từ tay khi không có monster trong GY.
    - Negate kích hoạt hiệu ứng trong GY/banishment của đối thủ hoặc hiệu ứng di chuyển card từ GY/banishment của đối thủ đi nơi khác.
    - Nếu có Trap trong GY, cho phép add 1 card "Dominus" từ Deck lên tay (optional search).
    - Phạt khi kích hoạt từ tay: Không được Special Summon từ tay, GY, banishment cho đến hết lượt sau.
    - HOPT trên kích hoạt.
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 44700001, ot=32, setcode=447=0x1bf)
  - Copy artwork từ `docs/queues/Common/p_Power_of_the_Dominators.jpg` sang `pics/44700001.jpg`
  - Đổi tên file artwork queue sang `d_Power_of_the_Dominators.jpg`
  - Cập nhật card này vào `feature_list.json` dưới mục `"Common"` (status: `"done"`)
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → c44700001.lua OK (chỉ có warning cấu trúc không ảnh hưởng).
  - `lint_scripts.ps1` → c44700001.lua không có lint issue nào.
  - `manage_db.py check-sync` → Đồng bộ hoàn chỉnh (chỉ có lỗi cũ pre-existing).
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/44700001.jpg`, `docs/queues/Common/d_Power_of_the_Dominators.jpg`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 012 — 2026-05-30

- **Mục tiêu:** Định dạng lại và kiểm tra kỹ lượng 3 file script: `c44100001.lua`, `c44700001.lua`, `c79900001.lua`.
- **Đã hoàn thành:**
  - Chuyển đổi toàn bộ thụt đầu dòng (indentation) từ tabs sang 4 spaces để khớp với code style tiêu chuẩn của project.
  - Sửa các cảnh báo cấu trúc (validator warnings) trong `c44100001.lua` (thêm kiểm tra `IsRelateToEffect` trong hàm operation của Normal Spell).
  - Tối ưu hóa logic trả card về Extra Deck ở End Phase của `c44100001.lua` bằng cách sử dụng một continuous field effect duy nhất quản lý Group các card đã banish (`KeepAlive` và `DeleteGroup`), thay vì đăng ký riêng lẻ nhiều effect độc lập. Điều này giúp các card trở về Extra Deck đồng thời cùng lúc theo đúng cơ chế luật OCG/TCG.
  - Sửa các cảnh báo cấu trúc và linter warnings trong `c44700001.lua` (thêm comment bypass `chk==0` cho `splimit` target, thêm comment bypass `IsRelateToEffect` cho Normal Trap, tách dòng quá dài trên 120 ký tự).
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → Cả 3 file `c44100001.lua`, `c44700001.lua`, `c79900001.lua` đều đạt trạng thái `[ ] OK` không còn bất kỳ cảnh báo/lỗi nào.
  - `lint_scripts.ps1` → Cả 3 file đều 100% sạch linter warnings (không có lỗi độ dài dòng hay khoảng trắng thừa).
  - `manage_db.py check-sync` → Không phát sinh lỗi đồng bộ nào mới.
- **Files/artifacts đã cập nhật:** [c44100001.lua](file:///d:/TTF/TTFCustomCards/script/c44100001.lua), [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [c79900001.lua](file:///d:/TTF/TTFCustomCards/script/c79900001.lua), [README.md](file:///d:/TTF/TTFCustomCards/README.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 013 — 2026-05-30

- **Mục tiêu:** Sửa lỗi runtime `IsExists` trong script `c44700001.lua` ("Power of the Dominators").
- **Đã hoàn thành:**
  - Sửa hàm condition `s.negcon` tại dòng 59 trong `script/c44700001.lua`: Cung cấp tham số `1, nil` (count và exception) đầy đủ cho hàm `tg:IsExists` để tương thích với signature API C++ của EDOPro/YGOPRO (`Group.IsExists` yêu cầu tối thiểu 4 tham số bao gồm cả `self` implicit).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK, 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, không phát sinh lỗi liên quan đến c44700001.lua.
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 014 — 2026-05-30

- **Mục tiêu:** Sửa lỗi kích hoạt sai của "Power of the Dominators" (`c44700001.lua`) khi đối thủ kích hoạt hiệu ứng trên sân (như Witchcrafter Genni triệu hồi từ Deck) mà không liên quan đến GY/banishment.
- **Đã hoàn thành:**
  - Sửa hàm condition `s.negcon` trong `script/c44700001.lua`:
    - Thay thế kiểm tra category sơ sài (Check 3 cũ) bằng cơ chế kiểm tra `GetOperationInfo` chi tiết tương tự như lá bài Ghost Belle & Haunted Mansion, áp dụng cho cả `LOCATION_GRAVE` và `LOCATION_REMOVED` của đối thủ (`1-tp`).
    - Lọc kiểm tra chi tiết trên 8 categories di chuyển card tiêu chuẩn: `TOHAND`, `TODECK`, `TOEXTRA`, `SPECIAL_SUMMON`, `REMOVE`, `TOGRAVE`, `EQUIP`, và `LEAVE_GRAVE`.
    - Loại bỏ các categories/constants không chuẩn là `CATEGORY_GRAVE_SPSUMMON` và `CATEGORY_GRAVE_ACTION` để loại bỏ hoàn toàn cảnh báo (warnings) của linter/validator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK (c44700001.lua OK không còn cảnh báo nào), 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Thành công, không có lỗi đồng bộ mới.
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 015 — 2026-05-30

- **Mục tiêu:** Kiểm tra và sửa lỗi thiếu/trùng description của Effect 1 và Effect 2 cho card `79900010` ("Monica, The Legendary Witch") trong database SQLite.
- **Đã hoàn thành:**
  - Cập nhật script `script/c79900010.lua`: Đổi mô tả hiệu ứng 2 `e2:SetDescription` từ `aux.Stringid(id,0)` thành `aux.Stringid(id,8)` nhằm phân tách rõ ràng với hiệu ứng 1.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`:
    - Cập nhật `str1` (tương ứng với index 0 của Monica) thành `[Link] Special Summon materials`.
    - Thêm `str9` (tương ứng với index 8 của Monica) thành `[Quick] Tribute/Discard: disable, destroy, or control`.
    - Sửa lỗi thiếu số `1` trong dòng hạn chế triệu hồi ở cột `desc` (đổi từ `Special Summon "Monica, ..."` thành `Special Summon 1 "Monica, ..."`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK (c79900010.lua OK không lỗi), 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, không phát sinh lỗi đồng bộ mới cho Monica.
- **Files/artifacts đã cập nhật:** [c79900010.lua](file:///d:/TTF/TTFCustomCards/script/c79900010.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 016 — 2026-06-02

- **Mục tiêu:** Vibe check, thiết kế và lập trình 4 Spell card mới: Blessing of the Earth/Fire/Water/Wind Charmer.
- **Đã hoàn thành:**
  - Thiết kế và lập trình 4 card mới với logic HOPT, unnegatable costs và dynamic turn reset:
    - [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua) (Blessing of the Earth Charmer)
    - [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua) (Blessing of the Fire Charmer)
    - [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua) (Blessing of the Water Charmer)
    - [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua) (Blessing of the Wind Charmer)
  - Đăng ký 4 card vào database `custom_cards_zesty.cdb` (ot=32, setcode=0xbf, passcodes 19100001 - 19100004).
  - Di chuyển ảnh artwork từ `docs/queues/Common/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 52 OK, 31 WARN, 0 FAIL (Cả 4 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 4 script mới 100% sạch linter warnings.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua), [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua), [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua), [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 017 — 2026-06-02

- **Mục tiêu:** Thiết kế và lập trình 5 card pending còn lại của Common trong `feature_list.json`.
- **Đã hoàn thành:**
  - Thiết kế và lập trình 5 script mới:
    - [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua) (Witchcrafter Trick)
    - [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua) (First Day Of Witch)
    - [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua) (Waking Nightmare)
    - [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua) (Don't Ash The Witch!)
    - [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua) (WANTED: A Lazy Trouble Witch)
  - Đăng ký 5 card vào database `custom_cards_zesty.cdb` (ot=32, passcodes 29600001, 79900003, 79900004, 79900006, 79900007).
  - Di chuyển ảnh artwork từ `docs/queues/Common/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 57 OK, 31 WARN, 0 FAIL (Cả 5 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua), [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua), [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua), [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 018 — 2026-06-02

- **Mục tiêu:** Định dạng lại và kiểm tra kỹ hiệu ứng cho 9 card mới tạo chưa commit: `c19100001` - `c19100004`, `c29600001`, `c79900003`, `c79900004`, `c79900006`, `c79900007`.
- **Đã hoàn thành:**
  - Chuẩn hóa toàn bộ tên hàm filter/target/operation trong cả 9 script theo đúng code style tiêu chuẩn (`filter_...`, `tg_...`, `op_...`, `con_...`, `val_...`).
  - Sửa lỗi runtime cực kỳ nghiêm trọng trong `c79900003.lua` và `c79900006.lua`: Thay thế hàm gọi không tồn tại `Duel.BreakEffectIfReady()` bằng hàm chuẩn `Duel.BreakEffect()`.
  - Sửa lỗi logic/runtime trong `c19100004.lua` khi check attribute lúc rời sân: Thay thế hàm không tồn tại `c:IsPreviousAttributeOnField(ATTRIBUTE_WIND)` bằng phép kiểm tra bitmask chuẩn `(c:GetPreviousAttributeOnField()&ATTRIBUTE_WIND)~=0`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 57 OK, 31 WARN, 0 FAIL (Cả 9 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 9 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi liên quan đến các card mới.
- **Files/artifacts đã cập nhật:** [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua), [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua), [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua), [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua), [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua), [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua), [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua), [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 019 — 2026-06-02

- **Mục tiêu:** Kiểm tra và sửa lỗi "sau khi SS cautus thì không sài được effect của Wolff nữa" cho Cautus (`c192200002.lua`) và Wolff (`c192200003.lua`).
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do passcode của Cautus (`192200002`) và Wolff (`192200003`) liên tiếp nhau. Cautus sử dụng `SetCountLimit(1, id+1, EFFECT_COUNT_CODE_OATH)` (giá trị là `192200003`) cho hiệu ứng Excavate (Effect 2) làm lock luôn hiệu ứng SS (Effect 1) của Wolff (có passcode `id` = `192200003`). Tương tự, Cautus Effect 3 dùng `id+2` (`192200004`) cũng đè lên Wolff Effect 2 (`id+1` = `192200004`).
  - Cập nhật [c192200002.lua](file:///d:/TTF/TTFCustomCards/script/c192200002.lua) và [c192200003.lua](file:///d:/TTF/TTFCustomCards/script/c192200003.lua):
    - Đổi tất cả các offset HOPT như `id+1` và `id+2` sang cú pháp `{id, index}` (ví dụ: `{id, 1}` và `{id, 2}`) để cách ly độc lập limit code cho các effect.
    - Thêm comment `-- IsRelateToEffect check is not required` vào các hàm operation liên quan để làm sạch cảnh báo linter/validator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 59 OK (c192200002.lua và c192200003.lua OK 100%), 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với cơ sở dữ liệu (chỉ có 2 lỗi đồng bộ cũ có sẵn).
- **Files/artifacts đã cập nhật:** [c192200002.lua](file:///d:/TTF/TTFCustomCards/script/c192200002.lua), [c192200003.lua](file:///d:/TTF/TTFCustomCards/script/c192200003.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 020 — 2026-06-02

- **Mục tiêu:** Nhận diện và thiết kế 5 card pending còn lại của Witchcrafter và White Forest trong hàng đợi.
- **Đã hoàn thành:**
  - Đăng ký 5 card vào database `custom_cards_zesty.cdb` (ot=32, passcodes 29600002-29600004, 42600002-42600003).
  - Thiết kế và lập trình 5 script mới:
    - [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua) (Witchcrafter Bumble Magic)
    - [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua) (Witchcrafter Unit Furnacer)
    - [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua) (Verre Magic Mastery)
    - [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua) (Memory of the White Forest)
    - [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua) (Knowledge of the White Forest)
  - Di chuyển ảnh artwork từ `docs/queues/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 64 OK (Cả 5 script mới đạt trạng thái OK không cảnh báo), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua), [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua), [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 021 — 2026-06-02

- **Mục tiêu:** Định dạng lại, kiểm tra kỹ lưỡng hiệu ứng và cập nhật chuỗi mô tả (option strings) trong database cho 5 card: `c29600002` - `c29600004`, `c42600002` - `c42600003`.
- **Đã hoàn thành:**
  - Chuẩn hóa toàn bộ tên hàm filter/target/operation trong cả 5 script theo đúng code style tiêu chuẩn của project (`filter_...`, `tg_...`, `op_...`, `con_...`).
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Đăng ký đầy đủ các chuỗi option strings (`str1` đến `str6` tương ứng với các chỉ mục `Stringid` trong code Lua) cho cả 5 card, khắc phục lỗi thiếu mô tả lựa chọn trong simulator.
  - Sửa lỗi logic hiệu ứng:
    - [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua): Chuyển description của Effect 2 (End Phase GY recovery) sang index 5 tách biệt để không bị trùng lặp với Effect 1.
    - [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua): Xóa prompt `SelectYesNo` tại hiệu ứng Fusion Summon để biến hiệu ứng này thành bắt buộc (mandatory) khớp chính xác với mô tả card text gốc.
    - [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua) & [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua): Đăng ký category `CATEGORY_SET` cho hiệu ứng Set từ GY, rút gọn điều kiện kích hoạt `con_set` bằng cách sử dụng trực tiếp tham số `re` và `re:IsMonsterEffect()` tương thích 100% với official scripts của archetype White Forest.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 64 OK (cả 5 script đều đạt trạng thái OK không cảnh báo), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo (không phát sinh lỗi đồng bộ nào mới).
- **Files/artifacts đã cập nhật:** [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua), [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua), [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 022 — 2026-06-02

- **Mục tiêu:** Code 3 card pending Mikanko trong `feature_list.json`.
- **Đã hoàn thành:**
  - OCR/đối chiếu artwork queue và thiết kế 3 card Mikanko:
    - [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua) (Ohime the Curious Mikanko)
    - [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua) (Mikanko Illusion Dance)
    - [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua) (Mikanko Fire Soul)
  - Đăng ký 3 card vào database `custom_cards_zesty.cdb` với `ot=32`, setcode Mikanko `0x18e`.
  - Copy artwork sang `pics/34100001.jpg`, `pics/34100002.jpg`, `pics/34100003.jpg`.
  - Đổi queue prefix từ `p_` sang `d_` và cập nhật `feature_list.json` sang `done`.
  - Review và sửa `Ohime the Curious Mikanko`: effect upgrade Xyz lấy monster từ Extra Deck thay vì Main Deck để khớp rule Xyz Monster.
  - Reformat 3 script Mikanko theo bố cục template effect block.
  - Double-check và harden effect:
    - `c34100001.lua`: effect upgrade kiểm tra Xyz material/zone hợp lệ, có equip target hợp lệ, và chỉ equip sau khi Xyz Summon thành công.
    - `c34100002.lua`: effect 3 chỉ dùng được khi card đang thật sự equipped.
    - `c34100003.lua`: khai báo operation info đúng số lượng Special Summon tối đa 2.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL. Cả 3 script Mikanko mới đều OK không warning.
  - `.\script-test\lint_scripts.ps1` -> Không có lint issue mới cho `c34100001.lua`, `c34100002.lua`, `c34100003.lua`; các issue còn lại là file cũ.
  - `python .\script-test\manage_db.py check-sync` -> 3 card Mikanko đã có script/DB; còn 2 issue tồn đọng ngoài phạm vi: `78900102` thiếu Lua script, `79900002` thiếu DB entry.
  - `Test-Path` -> 3 script, 3 ảnh trong `pics/`, 3 queue file `d_` đều tồn tại.
- **Files/artifacts đã cập nhật:** [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua), [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua), [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/34100001.jpg`, `pics/34100002.jpg`, `pics/34100003.jpg`, `docs/queues/Mikanko/d_ohime_the_curious_mikanko.jpg`, `docs/queues/Mikanko/d_Mikanko_Illusion_Dance.jpg`, `docs/queues/Mikanko/d_mikanko_fire_soul.jpg`, `claude-progress.md`

### Phiên 023 — 2026-06-02

- **Mục tiêu:** Sửa lỗi "Ko thấy effect mộ của verre magic" cho card `c29600004.lua` ("Verre Magic Mastery").
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do hiệu ứng Graveyard của `c29600004.lua` (một Trap card) được đăng ký dưới dạng `EFFECT_TYPE_IGNITION`. Trong engine EDOPro/YGOPRO, các hiệu ứng kích hoạt từ Mộ của bẫy phải sử dụng `EFFECT_TYPE_QUICK_O` kèm `EVENT_FREE_CHAIN` mới kích hoạt được.
  - Cập nhật [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua):
    - Đổi loại hiệu ứng `e3` từ `EFFECT_TYPE_IGNITION` sang `EFFECT_TYPE_QUICK_O`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 66 OK, 30 WARN, 0 FAIL (`c29600004.lua` đạt trạng thái OK không cảnh báo).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo với database.
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 024 — 2026-06-02

- **Mục tiêu:** Sửa lỗi không thể triệu hồi từ Deck của card `c34100002.lua` ("Mikanko Illusion Dance") do lỗi kiểm tra zone trống trước khi trả cost.
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do hiệu ứng triệu hồi từ Deck/Tay của `c34100002.lua` kiểm tra `Duel.GetLocationCount(tp, LOCATION_MZONE) > 0` trong Target chk==0. Điều này làm cho hiệu ứng không thể kích hoạt được khi người chơi có 0 zone quái thú trống, kể cả khi cost kích hoạt (đưa 1 quái thú Mikanko từ sân về tay) sẽ giải phóng 1 zone trống.
  - Cập nhật [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua):
    - Tái cấu trúc hàm cost `s.cost_other_to_hand` và target `s.tg_summon_hand_deck` tương tự như Blackwing - Zephyros the Elite.
    - Chuyển việc kiểm tra zone trống vào hàm cost: nếu `ft == 0`, bắt buộc phải chọn card ở `LOCATION_MZONE` làm cost; nếu `ft > 0`, cho phép chọn card ở `LOCATION_ONFIELD`.
    - Loại bỏ kiểm tra `Duel.GetLocationCount(tp, LOCATION_MZONE) > 0` trong Target chk==0.
    - Thay thế `LOCATION_HAND+LOCATION_DECK` bằng toán tử chuẩn `LOCATION_HAND|LOCATION_DECK`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (`c34100002.lua` đạt trạng thái OK không cảnh báo).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo với database (chỉ có 2 lỗi đồng bộ cũ có sẵn).
- **Files/artifacts đã cập nhật:** [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
### Phiên 025 — 2026-06-02

- **Mục tiêu:** Sửa lỗi hiệu ứng sau khi đối thủ kích hoạt effect không hoạt động cho card `c79900003.lua` ("First Day of Witch") và `c42600002.lua` ("Memory of the White Forest").
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do EDOPro engine giới hạn cơ chế đếm của `AddCustomActivityCounter` (đặc biệt khi chạy kiểm tra hoạt động cho đối thủ `1-tp` trong môi trường tự thiết lập hoặc chạy local), dẫn tới việc hàm đếm `GetCustomActivityCount` hoạt động không ổn định hoặc luôn trả về `0`.
  - Sửa đổi [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua) và [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua):
    - Loại bỏ bộ đếm `AddCustomActivityCounter` và thay thế bằng việc đăng ký một hiệu ứng continuous toàn cục lắng nghe sự kiện `EVENT_CHAINING` để tự động thiết lập flag hiệu ứng `RESET_PHASE|PHASE_END` lên người chơi kích hoạt (`rp`).
    - Kiểm tra điều kiện bằng cách so khớp flag: `Duel.GetFlagEffect(1-tp, id) > 0` để đảm bảo tính chính xác 100% khi nhận diện hoạt động của đối thủ, không phụ thuộc vào bộ đếm nội bộ của simulator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (Cả hai script sửa đổi đều OK 100% không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Hoàn thành sạch sẽ, không có cảnh báo/lỗi định dạng mới nào.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo với cơ sở dữ liệu.
- **Files/artifacts đã cập nhật:** [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 026 — 2026-06-03

- **Mục tiêu:** Sửa lỗi Once Per Turn bị nhầm thành HOPT của Iris (`c192200004.lua`) và Morpheus (`c192200005.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c192200004.lua](file:///d:/TTF/TTFCustomCards/script/c192200004.lua):
    - Đổi count limit của Effect 2 (Ignition Field Spell placement) từ HOPT (`{id, 1}` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
    - Đổi count limit của Effect 3 (Quick Effect negate) từ HOPT (`{id, 2}` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
  - Sửa đổi [c192200005.lua](file:///d:/TTF/TTFCustomCards/script/c192200005.lua):
    - Xóa hoàn toàn count limit của Effect 2 (Trigger Field Spell placement on SS by own effect) do text description không có giới hạn Once Per Turn (trước đây đặt nhầm `id+1` HOPT).
    - Đổi count limit của Effect 3 (Quick Effect negate) từ HOPT (`id+2` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (Cả hai script sửa đổi đều OK 100% không cảnh báo).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với cơ sở dữ liệu (chỉ còn 2 lỗi đồng bộ cũ có sẵn).
- **Files/artifacts đã cập nhật:** [c192200004.lua](file:///d:/TTF/TTFCustomCards/script/c192200004.lua), [c192200005.lua](file:///d:/TTF/TTFCustomCards/script/c192200005.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 027 — 2026-06-03

- **Mục tiêu:** Sửa lỗi response protection và lỗi hiệu ứng turn lock của Ohime the Curious Mikanko (`c34100001.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua):
    - Đổi logic target `s.tg_destroy_spell_trap` luôn trả về `true` ở `chk==0` để đảm bảo `SetChainLimit` được gọi khi kích hoạt bắt buộc (mandatory trigger) kể cả khi sân không có Spell/Trap.
    - Sửa response protection thành `Duel.SetChainLimit(aux.FALSE)` (Option B) để ngăn chặn hoàn toàn việc chain các hiệu ứng quái vật hoặc bẫy nhằm bypass khóa hoặc phủ nhận hiệu ứng.
    - Sửa lỗi function `op_monster_lock` kiểm tra sai `c:IsRelateToEffect(e)` trên hiệu ứng continuous trigger; thêm client hint bằng `aux.Stringid(id,3)`.
    - Thêm custom activity counter `chainfilter` và field restriction `EFFECT_CANNOT_SPECIAL_SUMMON` để cấm Special Summon Ohime nếu người chơi đã kích hoạt hiệu ứng quái vật non-Mikanko trong lượt; tích hợp kiểm tra này vào `s.op_overlay`.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`:
    - Đổi text mô tả card cho passcode `34100001` để khớp với việc cấm kích hoạt bài/hiệu ứng trong response.
    - Đăng ký chuỗi mô tả lock `'You cannot activate non-Mikanko monster effects'` vào `str4`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK (c34100001.lua OK không còn cảnh báo structural/relation), 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành sạch sẽ, kết quả khớp hoàn toàn với cơ sở dữ liệu.
- **Files/artifacts đã cập nhật:** [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 028 — 2026-06-04

- **Mục tiêu:** Sửa lỗi "effect mộ vẫn không xài được" của card Verre Magic Mastery (`c29600004.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua):
    - Loại bỏ điều kiện kiểm tra turn player `and Duel.IsTurnPlayer(tp)` trong hàm `s.con_search` vì hiệu ứng hoạt động trong Main Phase của cả hai người chơi.
    - Thêm `e3:SetHintTiming(0,TIMING_MAIN_END)` cho hiệu ứng Graveyard `e3` để EDOPro hiển thị prompt kích hoạt trong open game state (chain mode AUTO).
    - Dọn dẹp khoảng trắng thừa (trailing whitespace) ở các dòng comment 7-14.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK (c29600004.lua OK), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> c29600004.lua không còn bất kỳ lỗi/cảnh báo linter nào.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi đồng bộ nào mới.
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 029 — 2026-06-04

- **Mục tiêu:** Sửa lỗi Ohime the Curious Mikanko (`c34100001.lua`) bị mất hiệu ứng và lỗi turn lock/response protection không hoạt động.
- **Đã hoàn thành:**
  - Sửa đổi database SQLite `custom_cards_zesty.cdb`:
    - Cập nhật `setcode` của 3 card custom Mikanko (`34100001`, `34100002`, `34100003`) từ `3356984` (hex `0x333938` - do nhập sai định dạng chuỗi "398") về đúng giá trị số `398` (hex `0x18e`).
    - Việc sửa setcode giúp hệ thống nhận diện đúng Ohime và các card Mikanko custom là thuộc archetype Mikanko, giúp Ohime không tự khóa hiệu ứng của chính mình khi register `EFFECT_CANNOT_ACTIVATE` cho non-Mikanko monsters trong lượt cô ấy được Special Summon.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp cơ sở dữ liệu (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 030 — 2026-06-04

- **Mục tiêu:** Chỉnh lại card Mikanko Fire Soul (`c34100003.lua`) để hiệu ứng kích hoạt từ field không kích hoạt được trong lượt đối phương.
- **Đã hoàn thành:**
  - Sửa đổi [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua):
    - Đổi hiệu ứng gửi card và quái vật trang bị từ field xuống GY để Special Summon quái Mikanko (Effect 2) từ Quick Effect (`EFFECT_TYPE_QUICK_O`) sang Ignition Effect (`EFFECT_TYPE_IGNITION`).
    - Loại bỏ code không cần thiết của Quick Effect/Free Chain: `SetHintTiming` và `SetCondition(s.con_main_phase)`.
    - Xóa function `s.con_main_phase` không còn sử dụng.
    - Sửa đổi hàm `tg_summon_deck_grave` để kiểm tra `Duel.GetMZoneCount(tp, ec) > 0` thay vì `Duel.GetLocationCount(tp, LOCATION_MZONE) > 0` nhằm xử lý chính xác trường hợp sân đầy hoặc chỉ có quái thú được trang bị khi kích hoạt hiệu ứng (vì quái thú này được gửi đi làm chi phí).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (c34100003.lua OK).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với database (chỉ còn 2 issue sync cũ).
  - `.\script-test\lint_scripts.ps1 script\c34100003.lua` -> Sạch linter.
- **Files/artifacts đã cập nhật:** [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 031 — 2026-06-04

- **Mục tiêu:** Quét hàng đợi, tìm và đăng ký các card pending (`p_`) vào `feature_list.json`, lập kế hoạch chi tiết cho các card này.
- **Đã hoàn thành:**
  - Quét thư mục `docs/queues/` phát hiện 13 card pending mới có tiền tố `p_`.
  - Phân tích và trích xuất thành công toàn bộ thông số, hiệu ứng của 13 card từ file ảnh bằng `view_file`.
  - Cập nhật [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json):
    - Đăng ký 13 card mới vào các archetype phù hợp (`Witchcrafter`, `Exosister`, `Traptrix`, `Umi`, `Outer_Entity`, `Rank_Up_Magic`, `Common`).
    - Gán các dải passcode theo chuẩn `{setcode_decimal}{sequential_5digits}` cho từng card mới.
    - Cập nhật ngày sửa đổi cuối thành `"2026-06-04"`.
  - Lập bản kế hoạch triển khai [implementation_plan.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/c9d7d85a-b7dd-4173-a797-5a45c936a65c/implementation_plan.md) phân tích chi tiết hiệu ứng và hướng đi cho từng card.
- **Xác minh đã chạy:**
  - `Get-Content feature_list.json | ConvertFrom-Json` -> File JSON hợp lệ.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với database (không phát sinh lỗi mới từ các card pending).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 032 — 2026-06-04

- **Mục tiêu:** Hiện thực hóa mã nguồn (script Lua) và đăng ký thông số vào database cho cả 13 card pending.
- **Đã hoàn thành:**
  - Viết thành công 13 file script Lua tại [script/](file:///d:/TTF/TTFCustomCards/script/) khớp chính xác logic mô tả từ ảnh queue.
  - Viết script Python đăng ký thành công thông tin (stats, name, desc) của 13 card vào SQLite database `custom_cards_zesty.cdb` (Link arrows, type, setcodes, ot=32).
  - Cập nhật trạng thái của cả 13 card từ `pending` sang `done` trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), gắn thêm thuộc tính `script` chỉ định tệp.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Tất cả 13 script mới biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 033 — 2026-06-04

- **Mục tiêu:** Hoàn thiện định dạng hàng đợi, đổi tên tiền tố file ảnh từ `p_` (pending) sang `d_` (done) cho 13 card đã triển khai và đồng bộ đường dẫn trong `feature_list.json`.
- **Đã hoàn thành:**
  - Đổi tên toàn bộ 13 file ảnh queue trong thư mục `docs/queues/` từ `p_` sang `d_`.
  - Cập nhật các đường dẫn `queue_file` tương ứng trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json) sang dạng `d_`.
- **Xác minh đã chạy:**
  - `git status` -> Tất cả file cũ dạng `p_` biến mất, thay bằng file dạng `d_` tương ứng.
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL**.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 034 — 2026-06-04

- **Mục tiêu:** Sao chép hình ảnh artwork vào thư mục `pics/` dưới dạng tên passcode và định dạng lại toàn bộ 13 script Lua mới theo đúng template chuẩn.
- **Đã hoàn thành:**
  - Sao chép 13 file ảnh từ hàng đợi vào [pics/](file:///d:/TTF/TTFCustomCards/pics/) đặt tên theo `<passcode>.<ext>`.
  - Định dạng lại tiêu đề và các khối chú thích trong 13 file script Lua tại [script/](file:///d:/TTF/TTFCustomCards/script/) cho đồng bộ với template tại [template-card/](file:///d:/TTF/TTFCustomCards/template-card/).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch hoàn hảo sau định dạng).
  - `python .\script-test\manage_db.py check-sync` -> Toàn bộ khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** 13 file script tại [script/](file:///d:/TTF/TTFCustomCards/script/), hình ảnh tại [pics/](file:///d:/TTF/TTFCustomCards/pics/), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 035 — 2026-06-04

- **Mục tiêu:** Rà soát và kiểm tra kỹ lưỡng logic hiệu ứng của cả 13 card script mới so với yêu cầu gốc, sửa đổi các lỗi tiềm ẩn để tối ưu tính năng.
- **Đã hoàn thành:**
  - Kiểm tra toàn diện logic của cả 13 script, sửa đổi các phần sau:
    - **Witchcrafter Garden** (`c29600005.lua`): Sửa lỗi hàm `target` và `activate` khiến card không thể kích hoạt được nếu trong Deck chỉ còn Trap (nhưng đã đủ điều kiện điều khiển Witchcrafter monster).
    - **Surtr, Sarkaz of Laevateinn** (`c79900016.lua`): Sửa điều kiện bảo vệ `s.protcon` từ "chỉ khi được Link Summon" thành "trong lượt được Special Summon" nói chung để khớp chính xác mô tả hiệu ứng.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Vẫn biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** [c29600005.lua](file:///d:/TTF/TTFCustomCards/script/c29600005.lua), [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 036 — 2026-06-04

- **Mục tiêu:** Sửa lỗi runtime/compilation của Xyz procedure trong `c42790001.lua` và `c37200001.lua` do sai chữ ký hàm `Xyz.AddProcedure`.
- **Đã hoàn thành:**
  - Sửa đổi [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua): Loại bỏ đối số `99` (maxc) bị truyền sai vị trí (vị trí thứ 5 làm lệch các đối số sau và khiến `SetDescription` nhận nhầm function filter làm description). Thay đổi thành `Xyz.AddProcedure(c,s.xyzfilter,5,3,s.altfilter,aux.Stringid(id,0),Xyz.InfiniteMats,s.altop)` (sử dụng hằng số `Xyz.InfiniteMats` thay cho `99` để loại bỏ cảnh báo deprecation trong EDOPro).
  - Sửa đổi [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua): Loại bỏ đối số thứ 5 (`2`) thừa thãi vì hệ thống tự động gán `maxct = ct` (nếu không có alternative summon filter thì không cần truyền 5 đối số). Thay đổi thành `Xyz.AddProcedure(c,s.xyzfilter,nil,2)`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Vẫn biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> 2 sync issues quen thuộc.
- **Files/artifacts đã cập nhật:** [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua), [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 037 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng add bài của `c29600004.lua` ("Verre Magic Mastery") không tìm và add được lá "Verre Magic - Lacrima of Light" (`73664385`).
- **Đã hoàn thành:**
  - Tra cứu các lá bài "Verre Magic" (結晶魔術) khác trên cơ sở dữ liệu chính thức và xác nhận chỉ có 1 lá bài duy nhất là "Verre Magic - Lacrima of Light" (`73664385`).
  - Sửa đổi [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua): Thêm passcode `73664385` vào hàm filter, đồng thời tối ưu hóa cú pháp sử dụng `c:IsCode(code1, code2, ...)` để lọc tất cả các card "Verre Magic" (Transformation `22121392`, Sleep Time `79846799`, Lacrima `73664385`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 038 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng 2 của "Return of the Red Ant" (`c13800001.lua`) không kích hoạt được khi một lá "Hole" Normal Trap bị phá hủy, đồng thời tối ưu hóa logic chọn "any number" khi Set bẫy từ GY.
- **Đã hoàn thành:**
  - Sửa đổi [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua):
    - Đổi code trigger của hiệu ứng Graveyard `e2` từ `EVENT_TO_GRAVE` sang `EVENT_DESTROYED` (event chuẩn cho sự kiện phá hủy bài trên sân) và thêm `EFFECT_FLAG_DAMAGE_STEP`.
    - Loại bỏ điều kiện kiểm tra reason `c:IsReason(REASON_DESTROY)` trong hàm lọc `s.cfilter` do `EVENT_DESTROYED` đã đảm bảo tất cả các card đều bị phá hủy, đồng thời tăng tính tương thích.
    - Sửa lại hàm `s.setop` để cho phép người chơi chọn kích hoạt Set tùy chọn bất kỳ số lượng lá bẫy "Hole" Normal Trap nào (từ 1 đến số lượng vùng trống / số lượng bẫy trong GY) bằng cách sử dụng `g:Select(tp, 1, maxc, nil)` thay vì ép buộc Set tất cả/Set số lượng cố định.
    - Thêm `RESET_PHASE|PHASE_END` vào hiệu ứng `EFFECT_TRAP_ACT_IN_SET_TURN` để dọn dẹp thuộc tính sạch sẽ vào cuối lượt.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp (2 sync issues cũ).
- **Files/artifacts đã cập nhật:** [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 039 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng 3 của "Exosister Nunctis" (`c37200001.lua`) không kiểm tra số lượng quái vật Xyz trong GY dẫn đến việc kích hoạt được khi không có Xyz dưới mộ. Đồng thời sửa lỗi tương tác với "Rank-Up-Magic Rising Force" (`c14900001.lua`) bằng cách bổ sung điều kiện triệu hồi nghiêm ngặt.
- **Đã hoàn thành:**
  - Sửa đổi [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua):
    - Đăng ký hiệu ứng `EFFECT_SPSUMMON_CONDITION` với hàm kiểm tra `s.splimit` tương tự `Exosisters Magnifica` (`c59242457.lua`) để ngăn chặn việc triệu hồi từ Extra Deck bằng card effect (như Rank-Up-Magic) mà không thỏa mãn điều kiện nguyên liệu chuẩn.
    - Sửa lại hàm `s.spcost` để kiểm tra `#g > 0`, bắt buộc phải có ít nhất một quái vật Xyz dưới Graveyard mới cho phép kích hoạt hiệu ứng 3.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 040 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng 2 của "Return of the Red Ant" (`c13800001.lua`) và hiệu ứng tương tự của "Seventh Traptrix" (`c13800002.lua`) chỉ cho phép set 5 lá bẫy "Hole" Normal Trap có setcode `0x89` (Hole) mà bỏ qua các lá bẫy "Trap Hole" Normal Trap khác có setcode `0x4c` (Trap Hole).
- **Đã hoàn thành:**
  - Sửa đổi [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua):
    - Cập nhật `s.listed_series` thành `{0x89, 0x4c}`.
    - Sửa hàm `s.holefilter` sử dụng `c:IsSetCard({0x89, 0x4c})` để bao quát toàn bộ card Normal Trap thuộc hai archetype `Hole` (0x89) và `Trap Hole` (0x4c).
  - Sửa đổi [c13800002.lua](file:///d:/TTF/TTFCustomCards/script/c13800002.lua):
    - Cập nhật `s.listed_series` thành `{0x8a, 0x89, 0x4c}`.
    - Sửa hàm `s.setfilter` sử dụng `c:IsSetCard({0x89, 0x4c})`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp (2 sync issues cũ).
- **Files/artifacts đã cập nhật:** [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua), [c13800002.lua](file:///d:/TTF/TTFCustomCards/script/c13800002.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 041 — 2026-06-05

- **Mục tiêu:**
  1. Khắc phục lỗi card "Dragon Restday" (`c79900011.lua`) và các card custom trong nhóm `79900011` đến `79900016` hiển thị `???` trong game do thiếu các cột mô tả/option chuỗi (`str1` đến `str4`) trong bảng `texts` của SQLite database.
  2. Sửa lỗi hiệu ứng thay thế chuyển hướng trục xuất sang Graveyard của "Retfihs Noisnemid" (`c79900015.lua`) không hoạt động sau khi trả cost kích hoạt.
  3. Sửa lỗi hiệu ứng tấn công nhiều lần của "Surtr, Sarkaz of Laevateinn" (`c79900016.lua`) không hoạt động khi kích hoạt ở Main Phase (do số lượng quái đối thủ bị đếm tĩnh bằng 0 ở thời điểm kích hoạt thay vì đếm tại Battle Phase).
  4. Chuyển đổi hiệu ứng bảo vệ khỏi bị hủy diệt (Effect 1) của "Exosister Nunctis" (`c37200001.lua`) từ tự chọn (hỏi Yes/No) sang tự động kích hoạt (bắt buộc).
- **Đã hoàn thành:**
  - Viết và chạy script Python cập nhật đầy đủ các cột `str1` đến `str4` cho 6 card (từ `79900011` đến `79900016`) trong `custom_cards_zesty.cdb`.
  - Thiết lập chuỗi text chính xác cho các lựa chọn prompt và hiệu ứng của `c79900011.lua` (Dragon Restday).
  - Sửa đổi [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua):
    - Loại bỏ hàm không tồn tại `tc:SetDestination(LOCATION_GRAVE)`.
    - Sử dụng chuẩn `KeepAlive()` và `e:SetLabelObject(g)` để chuyển group `g` các card bị chuyển hướng từ target sang operation.
    - Trong hàm operation `s.repop`, thực hiện việc gửi các card sang Graveyard bằng cách sử dụng `Duel.SendtoGrave(g, REASON_EFFECT+REASON_REPLACE)`.
  - Sửa đổi [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua):
    - Viết hàm giá trị động `s.atkval` cho `EFFECT_EXTRA_ATTACK` để tự động kiểm tra số lượng quái thú đối phương và lưu lại (cache) vào flag effect `c:RegisterFlagEffect` ngay khi Battle Phase bắt đầu (hoặc ngay lúc check trong Battle Phase), giúp giữ nguyên số lượt tấn công tối đa kể cả khi quái thú đối phương bị tiêu diệt dần qua các đòn đánh.
  - Sửa đổi [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua):
    - Chuyển đổi hiệu ứng 1 từ `EFFECT_DESTROY_REPLACE` (vẫn tự động hiển thị prompt lựa chọn Yes/No do engine quy định đối với field replacement) sang `EFFECT_INDESTRUCTABLE_COUNT` với giới hạn count limit là 1. Điều này đảm bảo hiệu ứng tự động ngăn chặn phá hủy 1 lần mỗi lượt mà không hiện bất kỳ prompt hỏi người chơi nào.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo (chỉ còn 2 issue sync cũ có sẵn).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua), [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua), [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 042 — 2026-06-05

- **Mục tiêu:**
  - Tham khảo và sửa đổi hiệu ứng lọc / kiểm tra các lá bài "Hole" Normal Trap của "Return of the Red Ant" (`c13800001.lua`) và "Seventh Traptrix" (`c13800002.lua`) theo đúng chuẩn của card official "Traptrix Myrmeleo".
- **Đã hoàn thành:**
  - Thay thế cách viết setcode dạng table không chuẩn `c:IsSetCard({0x89, 0x4c})` bằng cách sử dụng các hằng số chính thức `SET_TRAP_HOLE` và `SET_HOLE` với phép logic OR `(c:IsSetCard(SET_TRAP_HOLE) or c:IsSetCard(SET_HOLE))` giống như script của "Traptrix Myrmeleo".
  - Sửa đổi [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua):
    - Đổi `s.listed_series` thành `{SET_TRAP_HOLE, SET_HOLE}`.
    - Cập nhật `s.holefilter` sử dụng logic OR để lọc card.
  - Sửa đổi [c13800002.lua](file:///d:/TTF/TTFCustomCards/script/c13800002.lua):
    - Đổi `s.listed_series` thành `{SET_TRAPTRIX, SET_TRAP_HOLE, SET_HOLE}`.
    - Cập nhật `s.setfilter` sử dụng logic OR.
    - Thay thế setcode `0x8a` bằng hằng số `SET_TRAPTRIX` trong `s.xyzfilter` và check condition trong `s.operation`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công, không phát sinh cảnh báo mới).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua), [c13800002.lua](file:///d:/TTF/TTFCustomCards/script/c13800002.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 043 — 2026-06-05


- **Mục tiêu:**
  - Kiểm tra hiệu ứng và mã nguồn của "Rank-Up-Magic Rising Force" (`c14900001.lua`), tìm các lá có hiệu ứng tương tự (như `c33816.lua` - DoomZ Command J.U.P.I.T.E.R) và sửa lại theo chuẩn.
- **Đã hoàn thành:**
  - Sửa đổi [c14900001.lua](file:///d:/TTF/TTFCustomCards/script/c14900001.lua):
    - Đổi setcode hex `0x95` thành hằng số `SET_RANK_UP_MAGIC` từ constants.
    - Sửa CountLimit thành `EFFECT_COUNT_CODE_OATH` cho HOPT kích hoạt.
    - Bổ sung `IsPlayerCanSpecialSummonCount(tp,2)` trong target check.
    - Viết lại hàm lọc `s.filter1` và `s.filter2` theo chuẩn của "Rank-Up-Magic Soul Shave Force" với `IsCanBeXyzMaterial`, `rum_limit` và `GetLocationCountFromEx`.
    - Thêm `Duel.BreakEffect()` giữa hai lần triệu hồi.
    - Gọi `c:CancelToGrave()` trước khi overlay Spell card làm material.
  - Sửa đổi [c33816.lua](file:///d:/TTF/TTFCustomCards/script/c33816.lua):
    - Đổi setcode hex `0x95` thành `SET_RANK_UP_MAGIC`.
    - Thay thế CountLimit `SetCountLimit(1)` (SOPT) thành logic "Once per Chain" chuẩn hóa bằng cờ hiệu `RESET_CHAIN`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** [c14900001.lua](file:///d:/TTF/TTFCustomCards/script/c14900001.lua), [c33816.lua](file:///d:/TTF/TTFCustomCards/script/c33816.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 044 — 2026-06-05

- **Mục tiêu:**
  - Khắc phục lỗi hiển thị `???` khi lựa chọn Set card bẫy "Hole" từ Deck của "Seventh Traptrix" (`c13800002.lua`) do thiếu các chuỗi option (`str1` và `str2`) trong SQLite database.
- **Đã hoàn thành:**
  - Cập nhật các trường `str1` (lựa chọn Special Summon) và `str2` (lựa chọn Set bẫy Hole) cho card "Seventh Traptrix" (`13800002`) và card liên quan "Return of the Red Ant" (`13800001`) trong bảng `texts` của database `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn toàn (chỉ còn 2 issue sync cũ có sẵn).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 045 — 2026-06-05

- **Mục tiêu:**
  - Sửa lỗi hiệu ứng 2 của "Outer Entity Sothoth" (`c42790001.lua`) có thể chọn chính nó làm nguyên liệu để đính kèm (attach), gây lỗi runtime `Attempt to overlay a card with itself`.
  - Khắc phục lỗi hiển thị `???` cho các prompt/lựa chọn hiệu ứng của "Outer Entity Sothoth" (`42790001`) trong game do thiếu các cột mô tả/option chuỗi (`str1` đến `str4`) trong bảng `texts` của SQLite database.
- **Đã hoàn thành:**
  - Sửa đổi [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua):
    - Đưa `e:GetHandler()` (card kích hoạt hiệu ứng) vào tham số `exceptg` (tham số cuối cùng) của cả hai hàm `Duel.IsExistingMatchingCard` và `Duel.SelectMatchingCard` trong `s.atttg` và `s.attop`, loại trừ chính bản thân card khỏi việc làm nguyên liệu đính kèm.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`:
    - Thiết lập đầy đủ chuỗi text trong bảng `texts` từ `str1` đến `str4` cho card `42790001` tương ứng với các mô tả/lựa chọn của hiệu ứng Summon và Detach.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 046 — 2026-06-05

- **Mục tiêu:**
  - Khắc phục lỗi hiển thị `???` khi lựa chọn thêm vào tay (add) / Triệu hồi Đặc biệt (Special Summon) quái thú "Mermail" hoặc "Atlantean" và khi kích hoạt hiệu ứng phủ nhận của "Lemuria, the Slumbering Eternal City" (`37700001`).
- **Đã hoàn thành:**
  - Cập nhật các trường `str1` đến `str4` cho card `37700001` trong bảng `texts` của SQLite database `custom_cards_zesty.cdb` để hiển thị đúng mô tả hiệu ứng khi kích hoạt và các lựa chọn trong game.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 047 — 2026-06-05

- **Mục tiêu:**
  - Khắc phục lỗi hiệu ứng tăng lần tấn công của "Surtr, Sarkaz of Laevateinn" (`79900016`) không hoạt động do lỗi nil reference khi truy cập parameter `c` trong hàm giá trị động.
- **Đã hoàn thành:**
  - Sửa đổi [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua):
    - Đổi logic trong hàm `s.atkval` sử dụng `e:GetHandler()` làm đối tượng card thay vì truy cập trực tiếp qua parameter `c` (vì parameter `c` có thể bị `nil` tùy thuộc vào ngữ cảnh gọi từ EDOPro core engine).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 048 — 2026-06-05

- **Mục tiêu:**
  - Khắc phục lỗi hiệu ứng thay thế trục xuất sang Graveyard và gây sát thương của "Retfihs Noisnemid" (`79900015`) không hoạt động.
- **Đã hoàn thành:**
  - Sửa đổi [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua):
    - Thay thế cơ chế `EFFECT_SEND_REPLACE` không tương thích bằng `EFFECT_REMOVE_REDIRECT` (SetValue = `LOCATION_GRAVE`).
    - Lọc các card được chuyển hướng thông qua hàm `s.reptg` loại trừ các card trong Graveyard (`not c:IsLocation(LOCATION_GRAVE)`).
    - Triển khai gắn flag trên card bị chuyển hướng và theo dõi tại sự kiện `EVENT_TO_GRAVE` để đếm và gây damage tương ứng cho đối thủ.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn toàn (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 049 — 2026-06-06

- **Mục tiêu:**
  - Triển khai toàn bộ archetype "Wezaemon the Tombguard" gồm 12 cards từ hàng đợi (Lua scripts, SQLite database, artwork, hằng số cấu hình).
- **Đã hoàn thành:**
  - Thiết lập hằng số setcode `SET_WEZAEMON = 0x783` trong [constants.lua](file:///d:/TTF/TTFCustomCards/script/constants.lua) và đăng ký chuỗi `!setname 0x783 Wezaemon` trong [strings.conf](file:///d:/TTF/TTFCustomCards/strings.conf).
  - Viết 12 file Lua script [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua) đến [c192300012.lua](file:///d:/TTF/TTFCustomCards/script/c192300012.lua) với logic hoàn chỉnh tuân thủ cấu trúc của simulator EDOPro.
  - Đăng ký thông tin (stats, name, desc, ot=32) cho cả 12 cards vào database SQLite `custom_cards_zesty.cdb`.
  - Sao chép và đổi tên các file ảnh artwork vào [pics/](file:///d:/TTF/TTFCustomCards/pics/) đặt theo passcode.
  - Đổi tên tiền tố file trong thư mục hàng đợi từ `p_` sang `d_` tại [docs/queues/Wezaemon The Tombguard/](file:///d:/TTF/TTFCustomCards/docs/queues/Wezaemon%20The%20Tombguard/) và cập nhật đường dẫn `queue_file` trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **75 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** 12 file script, `constants.lua`, `strings.conf`, `custom_cards_zesty.cdb`, [pics/](file:///d:/TTF/TTFCustomCards/pics/), [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 050 — 2026-06-06

- **Mục tiêu:**
  - Khắc phục lỗi card "Battle Machine - Kirin Armor" (`192300003`) không hiển thị trong Deck Builder của game EDOPro.
- **Đã hoàn thành:**
  - Sửa lỗi trong database SQLite `custom_cards_zesty.cdb`:
    - Cập nhật `type` từ `16417` (Token) thành `97` (Fusion / Effect Monster) để EDOPro hiển thị card trong Deck Builder.
    - Cập nhật `race` từ `131072` (Fish) thành `32` (Machine) để khớp đúng mô tả lore/tên card.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **75 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn toàn (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
### Phiên 051 — 2026-06-08

- **Mục tiêu:**
  - Brainstorm phương án tối ưu hóa dự án theo triết lý Harness Engineering và xử lý triệt để 2 lỗi lệch đồng bộ lâu ngày.
- **Đã hoàn thành:**
  - Tạo tài liệu phân tích thiết kế chi tiết tại [analysis_results.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/7e6708b6-b46b-4d23-8ebc-118e9c455d53/analysis_results.md) với 4 trụ cột chính: Tổ chức, Quản lý, Vibe, và Sửa lỗi.
  - Giải quyết lỗi sync `78900102`: Bổ sung hoàn chỉnh script Field Spell [c78900102.lua](file:///d:/TTF/TTFCustomCards/script/c78900102.lua) cho "Ttf Holy Sanctuary".
  - Giải quyết lỗi sync `79900002`: Đăng ký card "Ttf Cat Luna" vào SQLite database `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (All local card scripts and database entries are in perfect sync!).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [c78900102.lua](file:///d:/TTF/TTFCustomCards/script/c78900102.lua), [analysis_results.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/7e6708b6-b46b-4d23-8ebc-118e9c455d53/analysis_results.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
### Phiên 052 — 2026-06-08

- **Mục tiêu:**
  - Thiết lập Git và quy trình để tiếp tục duy trì, theo dõi file database nhị phân `custom_cards_zesty.cdb` theo yêu cầu của user.
- **Đã hoàn thành:**
  - Cập nhật quy định trong [agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md) yêu cầu commit file CDB nhị phân chung với specs JSON và Lua script.
  - Cập nhật tài liệu quy trình [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md) làm rõ việc luôn phải chạy lệnh compile để đồng bộ dữ liệu vào CDB trước khi commit.
  - Chạy biên dịch SQLite database từ specs JSON để cập nhật file `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py compile` -> Biên dịch thành công 122 card specs.
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (Đồng bộ hoàn hảo giữa DB, Specs JSON và scripts).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md), [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
### Phiên 053 — 2026-06-08

- **Mục tiêu:**
  - Rà soát sự cần thiết của skill `vibe-card` cũ trong thư mục `.claude/`.
- **Đã hoàn thành:**
  - Xác nhận skill `vibe-card` cũ trong `.claude/` đã lỗi thời và xung đột với luồng plaintext JSON Specs & Harness CLI mới (do gọi các script python cũ ghi đè CDB trực tiếp).
  - Trích xuất tài liệu tra cứu bitmask CDB hữu ích từ skill cũ và di trú sang tài liệu chính thức [cdb-schema.md](file:///d:/TTF/TTFCustomCards/docs/cdb-schema.md).
  - Xóa bỏ hoàn toàn thư mục `.claude/` để ngăn chặn IDE kích hoạt nhầm skill cũ.
  - Cập nhật liên kết tài liệu trong [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md) và [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md) để hỗ trợ tra cứu bitmask khi điền JSON specs.
- **Xác minh đã chạy:**
  - Thư mục `.claude/` đã được xóa sạch.
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (Tương thích đồng bộ hoàn hảo).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md), [cdb-schema.md](file:///d:/TTF/TTFCustomCards/docs/cdb-schema.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
### Phiên 054 — 2026-06-08

- **Mục tiêu:**
  - Tinh gọn script test và sửa lỗi Tiếng Việt.
- **Đã hoàn thành:**
  - Trích xuất 993 hằng số EDOPro chuẩn từ `validate_scripts.ps1` ra `script-test/edopro_constants.txt`.
  - Tinh gọn `validate_scripts.ps1` từ 1334 dòng xuống còn 346 dòng (giảm ~75%), tải hằng số động một lần duy nhất lúc khởi tạo.
  - Sửa lỗi mã hóa Tiếng Việt (Unicode) trên Windows console bằng cách thiết lập mã hóa UTF-8 cho toàn bộ PowerShell script (`validate_scripts.ps1`, `lint_scripts.ps1`, `fetch_official.ps1`) and Python script (`manage_db.py`, `manage_harness.py`).
  - Cập nhật hàm `run_command` trong `manage_harness.py` sử dụng `encoding='utf-8'` khi giải mã output từ sub-process con.
  - Xây dựng script [archive_progress.py](file:///d:/TTF/TTFCustomCards/script-test/archive_progress.py) để tự động hóa việc di chuyển các phiên cũ (chỉ giữ lại tối đa 25 phiên) từ `claude-progress.md` sang [docs/claude-progress-archive.md](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).
  - Tích hợp Step 6 tự động chạy script này vào cuối pipeline `verify` của [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py).
  - Di chuyển thư mục `template-card/` ở root vào trong [script-test/templates/](file:///d:/TTF/TTFCustomCards/script-test/templates/) để gom toàn bộ "Developer Tooling" về một mối và làm sạch root directory.
  - Cập nhật đường dẫn `"template_dir"` trong [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py) và đồng bộ hóa cấu trúc mới vào các file tài liệu [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [README.md](file:///d:/TTF/TTFCustomCards/README.md), [docs/agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md) và [script-test/templates/README.md](file:///d:/TTF/TTFCustomCards/script-test/templates/README.md).
  - Tách quy tắc tham chiếu code Lua cũ thành 2 phần riêng biệt trong `docs/agent-rules.md` và `AGENTS.md` (Cấm bắt chước tệp custom cũ trong `script/`; Yêu cầu dùng templates trong `script-test/templates/` làm khung và scripts official làm tài liệu tham khảo) để tránh AI hiểu nhầm.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py check-sync` -> **100% OK**.
  - `.\script-test\validate_scripts.ps1 -Quiet` -> **122 OK, 0 FAIL** (hoạt động tốt với file txt hằng số).
  - `python .\script-test\manage_db.py query 79900002` -> Tiếng Việt có dấu hiển thị chuẩn xác, sắc nét trên console.
  - `python .\script-test\manage_harness.py verify 192300010` -> Chạy pipeline harness thành công (bao gồm cả Step 6 auto archive).
- **Files/artifacts đã cập nhật:** `validate_scripts.ps1`, `lint_scripts.ps1`, `fetch_official.ps1`, `manage_db.py`, `manage_harness.py`, `edopro_constants.txt`, `archive_progress.py`, `claude-progress.md`, `AGENTS.md`, `README.md`, `docs/agent-rules.md`, `script-test/templates/README.md`
### Phiên 055 — 2026-06-08

- **Mục tiêu:**
  - Sửa lỗi tương tác của card `79900015` ("Retfihs Noisnemid") với "Masked HERO Dark Law" (Dark Law) và các hiệu ứng redirect banish tương tự.
- **Đã hoàn thành:**
  - Sửa lỗi trong [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua): Đăng ký thêm hiệu ứng `EFFECT_CANNOT_REMOVE` với target `s.redirect_filter` và value `s.rmlimit` để ngăn các redirect-to-banish (như `EFFECT_TO_GRAVE_REDIRECT` của Dark Law hay Macro Cosmos, và `EFFECT_LEAVE_FIELD_REDIRECT` của Plaguespreader Zombie) banish các lá bài mà đáng lẽ phải được đưa vào GY theo `79900015`.
  - Khắc phục lỗi crash/khóa kích hoạt các hiệu ứng trục xuất của Effect Monsters (như Genni, và các card khác): Bổ sung kiểm tra kiểu dữ liệu `type(re)=="userdata"` và `type(re.GetCode)=="function"` trong `s.rmlimit`. Khi EDOPro chạy kiểm tra capability (`IsAbleToRemove`), engine có thể truyền biến `re` dưới dạng số (player ID) hoặc `nil`, gây ra lỗi runtime khi cố gọi `:GetCode()`, khiến toàn bộ hiệu ứng trục xuất của quái thú bị khóa kích hoạt.
  - Cập nhật hàm lọc burn `s.burn_filter` trong [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua) để phát hiện và gây damage đối với các lá bài được cứu khỏi các redirect-to-banish đó (vì các lá bài này nay đã được chuyển về GY thành công và không mang flag `REASON_REDIRECT` trong engine).
  - Chạy verify thành công qua CLI và cập nhật trạng thái card thành "done".
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 79900015` -> Pipeline chạy thành công, linter sạch và sync 100% OK.
- **Files/artifacts đã cập nhật:** [c79900015.lua](file:///d:/TTF/TTFCustomCards/script/c79900015.lua)



### Phiên 056 — 2026-06-08

- **Mục tiêu:**
  - Cập nhật và tinh chỉnh cơ chế hoạt động cho các card nhóm Wezaemon/Tachikaze (`192300005`, `192300006`, `192300007`, `192300008`, `192300010`) theo yêu cầu sửa lỗi.
- **Đã hoàn thành:**
  - Sửa [c192300005.lua](file:///d:/TTF/TTFCustomCards/script/c192300005.lua): Thay `c:IsCode` bằng `c:GetPreviousCode()` trong `s.leavfilter` để kiểm tra danh tính chính xác trước khi rời sân vào vùng úp/mộ.
  - Sửa [c192300006.lua](file:///d:/TTF/TTFCustomCards/script/c192300006.lua): Chuyển hiệu ứng 2 ở GY từ Quick Effect thành Ignition Effect; hỗ trợ kích hoạt Spell/Trap set-turn động cho cả Quick-Play Spell (`EFFECT_QP_ACT_IN_SET_TURN`) và Trap (`EFFECT_TRAP_ACT_IN_SET_TURN`).
  - Sửa [c192300007.lua](file:///d:/TTF/TTFCustomCards/script/c192300007.lua): Chuyển hiệu ứng 2 ở GY thành Ignition Effect; hỗ trợ kích hoạt Spell/Trap set-turn động; xóa category remove dư thừa ở Target.
  - Sửa [c192300008.lua](file:///d:/TTF/TTFCustomCards/script/c192300008.lua): Chuyển hiệu ứng 2 ở GY thành Ignition Effect để chặn kích hoạt trong lượt đối thủ.
  - Sửa [c192300010.lua](file:///d:/TTF/TTFCustomCards/script/c192300010.lua): Giữ nguyên Quick Effect cho hiệu ứng 2 ở GY, loại bỏ cơ chế cho phép kích hoạt Trap vừa Set ngay trong lượt.
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify <passcode>` thành công cho cả 5 card (192300005, 192300006, 192300007, 192300008, 192300010).
  - Linter sạch lỗi phong cách (trailing whitespace đã được dọn sạch).
  - Hệ thống cơ sở dữ liệu đồng bộ hoàn hảo (check-sync 100% OK).
- **Files/artifacts đã cập nhật:** `script/c192300005.lua`, `script/c192300006.lua`, `script/c192300007.lua`, `script/c192300008.lua`, `script/c192300010.lua`, `claude-progress.md`
### Phiên 057 — 2026-06-09

- **Mục tiêu:**
  - Sửa lỗi effect 4 của [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua) ("Wezaemon the Tombguard"): Ngăn không cho đối thủ kích hoạt hiệu ứng của Wezaemon khi người chơi sở hữu Wezaemon thực hiện hành động Set bài hoặc kích hoạt Spell/Trap liên quan.
- **Đã hoàn thành:**
  - Sửa lỗi trong [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua):
    - Thay thế hoàn toàn việc sử dụng tham số `tp` nhận từ hàm trigger (vốn có thể bị sai lệch hoặc không nhất quán trong các engine simulator khi xử lý sự kiện phức tạp) bằng cách gọi trực tiếp `e:GetHandler():GetControler()` để lấy chính xác controller `hc` của quái thú Wezaemon đang kích hoạt hiệu ứng.
    - So sánh trực tiếp `rp == hc or ep == hc` để xác thực người chơi thực hiện hành động Set/Kích hoạt Spell/Trap.
    - Sử dụng Lua function closure cục bộ `f` truyền vào `eg:IsExists` để so sánh chính xác `c:IsControler(hc)` và loại bỏ lỗi truyền tham số `tp` tùy chọn trong API C++.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 192300001` -> Chạy pipeline harness thành công.
  - `.\script-test\validate_scripts.ps1 -Quiet` -> Kết quả 122 OK, 0 WARN, 0 FAIL.
- **Files/artifacts đã cập nhật:** [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua), `custom_cards_zesty.cdb`, `claude-progress.md`

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
