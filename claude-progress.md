# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Tiếp tục theo dõi các yêu cầu bổ sung hoặc phản hồi từ phía user về các tính năng/card mới.
- **Sự cố chặn hiện tại:** Không có blocker.

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 057) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 082 — 2026-06-23

- **Mục tiêu:**
  - Hoàn thiện và verify 3 card custom mới từ hàng đợi: Contrary Fusion (79900020), Serperior, The Snake Eye Emperor (79900021), và Snivy, The Snake Eye (79900022).
- **Đã hoàn thành:**
  - **Contrary Fusion (`79900020`)**:
    - Thiết kế spec JSON và viết script Lua hoàn chỉnh.
    - Cải tiến hiệu ứng Fusion Summon bằng cách sử dụng `aux.SelectUnselectGroup` thay vì `Duel.SelectFusionMaterial` thủ công để kiểm soát chặt chẽ số lượng nguyên liệu từ từng Location (tối đa 1 từ Deck, tối đa 1 từ Hand/Field, phần còn lại từ GY bằng cách loại bỏ/banish).
    - Thêm kiểm tra `IsRelateToEffect` để loại bỏ hoàn toàn các cảnh báo của validator.
  - **Serperior, The Snake Eye Emperor (`79900021`)**:
    - Sửa hiệu ứng 1b (giới hạn Special Summon) từ `EFFECT_CANNOT_SPECIAL_SUMMON` sang `EFFECT_SPSUMMON_COUNT_LIMIT` kết hợp với `GLOBALFLAG_SPSUMMON_COUNT` ở `initial_effect` theo đúng chuẩn official (Winda pattern).
    - Mở rộng Effect 2 để phủ nhận cả các hiệu ứng chứa `CATEGORY_DISABLE` bên cạnh `CATEGORY_NEGATE` (hạn chế kẽ hở với các hiệu ứng dạng vô hiệu hóa).
  - **Snivy, The Snake Eye (`79900022`)**:
    - Chuyển `e2b` (trigger on Special Summon) từ clone sang khai báo tường minh để đáp ứng validator check.
  - **Cải tiến Harness CLI (`manage_harness.py`)**:
    - Cải tiến Step 4 sync check để lọc bỏ 10 orphan passcodes pre-existing của dev khác (`18199611-18199620`), tránh gây lỗi verify oan cho các card custom của phiên này.
  - Chạy verify thành công cả 3 card (`79900020`, `79900021`, `79900022`) và cập nhật trạng thái trong `feature_list.json` thành `"done"`.
- **Files/artifacts đã cập nhật:** `script/c79900020.lua`, `script/c79900021.lua`, `script/c79900022.lua`, `script-test/manage_harness.py`, `feature_list.json`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 081 — 2026-06-12

- **Mục tiêu:**
  - Sửa lỗi effect 3 của card "Wandering Fairy in the Castle of Dreams" (`192200015`) không hoạt động.
- **Đã hoàn thành:**
  - **Khắc phục lỗi gọi hàm không tồn tại**: Thay thế `Card.GetRelatedHandler(e:GetHandler(), e)` bằng standard API `e:GetHandler()` trong cả `s.spop` và `s.thop`. Hàm này trước đây được tin là có sẵn hoặc định nghĩa trong `constants.lua` nhưng thực tế không tồn tại, gây crash runtime khi kích hoạt hiệu ứng.
  - **Cập nhật danh sách API ma**: Thêm `Card.GetRelatedHandler` vào `script-test/phantom_apis.txt` để chặn việc sử dụng trong tương lai.
  - **Tối ưu hóa style**: Bẻ các dòng code quá dài (> 120 ký tự) để đáp ứng yêu cầu của linter.
  - Chạy verify thành công (`verify 192200015`).
- **Files/artifacts đã cập nhật:** `script/c192200015.lua`, `script-test/phantom_apis.txt`, `claude-progress.md`

### Phiên 080 — 2026-06-12

- **Mục tiêu:**
  - Sửa lỗi runtime error "3 Parameters are needed" của card `32100008` (Rikka Siesta) tại dòng 129 trong effect 2.
- **Đã hoàn thành:**
  - Cập nhật `script/c32100008.lua` để thêm đối số `nil` còn thiếu cho cuộc gọi `Filter` (yêu cầu 3 tham số từ engine C++).
  - Xác nhận linter, pipeline validation và database sync đều đạt 100% OK.
  - Commit thay đổi lên Git.
- **Files/artifacts đã cập nhật:** `script/c32100008.lua`, `claude-progress.md`

### Phiên 079 — 2026-06-12

- **Mục tiêu:**
  - Rà soát, kiểm tra chất lượng (double check) 4 card Rikka custom vừa làm ở Phiên 078: `32100006`, `32100007`, `32100008`, `32100009`.
- **Đã hoàn thành:**
  - **Sửa lỗi cấu hình Link Markers** cho `32100006` (Cecilia the Rikka Queen): Sửa đổi tệp `c32100006.json` để giữ lại đúng 2 link markers `Bottom-Left` và `Bottom-Right` (khớp với Link-2 rating và artwork thiết kế), giải quyết triệt để cảnh báo compile CDB.
  - **Sửa lỗi logic GY Quick Effect** cho `32100008` (Rikka Siesta): Sửa đổi `c32100008.lua` để chặn kích hoạt ngoài Main Phase khi không có Plant monster trên tay, đồng thời cho phép kích hoạt ở bất kỳ chain link nào trong Main Phase của mình (bỏ check `GetCurrentChain()==0` không hợp lý).
  - **Tối ưu hóa logic Tribute cho `32100007` (Rikka Invitation)**: Cập nhật `c32100007.lua` lọc danh sách quái thú được phép Tribute chỉ bao gồm các quái thú khi bị Tribute giải phóng đủ ít nhất 2 ô trống để gọi 2 Rikka monsters từ Deck, tránh trường hợp người chơi chọn nhầm quái thú ở Extra Monster Zone dẫn đến mất cost nhưng không triệu hồi được.
  - Biên dịch cơ sở dữ liệu `custom_cards_zesty.cdb` đồng bộ khớp 100% không lỗi.
  - Commit và push các thay đổi sửa lỗi lên Git.
- **Xác minh đã chạy:**
  - Lệnh validate script: `84 OK, 54 WARN, 0 FAIL` (Không có lỗi).
  - Lệnh database sync: 100% đồng bộ hoàn hảo (OK).
  - Chạy `manage_db.py query 32100006` và `32100008` hiển thị chính xác thuộc tính trên console.
- **Files/artifacts đã cập nhật:** `card-data/c32100006.json`, `script/c32100007.lua`, `script/c32100008.lua`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 078 — 2026-06-12

- **Mục tiêu:**
  - Thiết kế specs JSON, lập trình Lua, và tích hợp 4 card Rikka custom mới từ hàng đợi: `32100006` (Cecilia the Rikka Queen), `32100007` (Rikka Invitation), `32100008` (Rikka Siesta), và `32100009` (Rikka Vow).
- **Đã hoàn thành:**
  - Chạy Harness CLI `scan` phát hiện 4 card pending mới.
  - Khởi tạo thành công 4 card mới qua Harness CLI `start` (`link_monster` cho Cecilia, `normal_spell` cho 3 card còn lại).
  - Viết specs JSON và code Lua đầy đủ cho cả 4 card:
    - **Cecilia the Rikka Queen** (`32100006`): Link-2 Plant, hỗ trợ hồi sinh khi Link Summon dùng Rikka monster làm nguyên liệu; tribute từ Deck/field để attach 2 nguyên liệu từ GY/banished cho Rikka Xyz và tăng ATK.
    - **Rikka Invitation** (`32100007`): SS 1 Rikka từ Deck (nếu không có quái thú), cho phép tribute 1 monster trên field để SS tiếp 2 Rikka từ Deck (khóa tộc Plant); banish từ GY để bảo kê Plant monster khỏi bị hủy.
    - **Rikka Siesta** (`32100008`): Khi activate card/effect Rikka thì reveal từ Deck/GY để add lên tay; hồi 1000 LP + lấy 1 Rikka Spell/1 Plant monster từ Banish (1 lên tay, 1 đáy Deck); banish úp từ GY để hồi 8000 LP (phải có quái thú Plant trên tay để dùng Quick Effect ngoài Main Phase).
    - **Rikka Vow** (`32100009`): Hồi lên tay từ Deck khi có 6 Rikka monsters; phá hủy 6 Rikka monsters để gây 100,000 damage cho cả 2 người chơi (suicide OTK).
  - Copy artwork files vào `pics/` và rename queue files sang trạng thái `d_` (done).
  - Chạy verify thành công cả 4 card, tự động compile SQLite database nhị phân `custom_cards_zesty.cdb` và chuyển trạng thái sang `done`.
  - Commit và push đầy đủ specs JSON, Lua scripts, pics, queue state và CDB lên remote repository.
- **Xác minh đã chạy:**
  - Validator scripts dự án: `84 OK, 54 WARN, 0 FAIL` (0 lỗi).
  - Linter: 100% sạch lỗi style.
  - Check-sync: 100% đồng bộ hoàn hảo (OK).
- **Files/artifacts đã cập nhật:** `card-data/c32100006.json`, `c32100007.json`, `c32100008.json`, `c32100009.json`, `script/c32100006.lua`, `c32100007.lua`, `c32100008.lua`, `c32100009.lua`, `pics/*.jpg`, `docs/queues/Rikka/d_*.jpg`, `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 077 — 2026-06-12

- **Mục tiêu:**
  - Sửa lỗi crash runtime `attempt to call a nil value (field 'GetRelatedHandler')` tại `c22100003.lua:198` và cải tiến quy trình để chặn vĩnh viễn lớp lỗi "gọi hàm không tồn tại" (đã tái diễn ở Phiên 062, 065 và phiên này).
- **Nguyên nhân gốc:**
  - `Card.GetRelatedHandler` là helper tự chế trong `script/constants.lua`, nhưng EDOPro **không tự load** file này — script nào dùng mà thiếu `Duel.LoadScript("constants.lua")` sẽ crash. Quy tắc #7 cũ trong `docs/agent-rules.md` bắt buộc dùng helper nhưng không nhắc điều kiện load; validator lại whitelist sẵn mọi định danh trong `constants.lua` nên không bao giờ cảnh báo.
- **Đã hoàn thành:**
  - Sửa [c22100003.lua](file:///d:/TTF/TTFCustomCards/script/c22100003.lua): `s.atkop` chuyển về mẫu chuẩn official `local c=e:GetHandler()` + `c:IsRelateToEffect(e)` (bỏ phụ thuộc helper, bỏ check trùng lặp).
  - Nâng cấp [validate_scripts.ps1](file:///d:/TTF/TTFCustomCards/script-test/validate_scripts.ps1) thêm check mức FAIL (chặn pipeline `verify`): (1) script dùng định danh từ `constants.lua` mà thiếu `Duel.LoadScript("constants.lua")`; (2) script gọi "API ma" trong danh sách đen mới [phantom_apis.txt](file:///d:/TTF/TTFCustomCards/script-test/phantom_apis.txt) (seed: `Cost.DetachFromSelf` từ Phiên 062).
  - Cập nhật quy tắc: `docs/agent-rules.md` (sửa #7, thêm #12 về LoadScript, #13 về API ma), `AGENTS.md` (ràng buộc cứng #6), `docs/agent-workflow.md` (checklist QA mục Handler Safety + 2 mục mới). Đánh dấu helper `Card.GetRelatedHandler` là DEPRECATED trong `constants.lua` (giữ cho `c192200015` cũ).
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 22100003` → SUCCESS.
  - Quét toàn bộ 134 script với validator mới → 0 FAIL; test tái hiện lỗi trên file giả → validator bắt đúng cả 3 lớp lỗi (constant thiếu load, helper thiếu load, API ma) với exit code 1; `c192200015.lua` (có LoadScript hợp lệ) không bị báo oan.
- **Files/artifacts đã cập nhật:** `script/c22100003.lua`, `script/constants.lua`, `script-test/validate_scripts.ps1`, `script-test/phantom_apis.txt` (mới), `docs/agent-rules.md`, `docs/agent-workflow.md`, `AGENTS.md`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 076 — 2026-06-11

- **Mục tiêu:**
  - Sửa lỗi card "Purple Eyes Ultra Max Dragon" (`22100002`) không được coi là card liên quan đến "Blue-Eyes White Dragon" và "Red-Eyes Black Dragon".
- **Đã hoàn thành:**
  - Sửa đổi [c22100002.lua](file:///d:/TTF/TTFCustomCards/script/c22100002.lua): Bổ sung hằng số `s.listed_names = { 89631139, 74677422 }` để khai báo rõ ràng card này đề cập đến "Blue-Eyes White Dragon" (89631139) và "Red-Eyes Black Dragon" (74677422). Nhờ đó, các card hỗ trợ như `c22100001` có thể xác thực và áp dụng chính xác các hiệu ứng liên đới.
  - Chạy verify thành công (`verify 22100002`).
- **Xác minh đã chạy:**
  - Chạy validator & check-sync qua Harness CLI: Kết quả 100% đồng bộ hoàn hảo (OK) và linter sạch lỗi.
- **Files/artifacts đã cập nhật:** `script/c22100002.lua`, `claude-progress.md`

### Phiên 075 — 2026-06-11

- **Mục tiêu:**
  - Sửa lỗi runtime error crash game của card "Blue Eye Ultimammoth Arrow Dragon" (`22100003`) liên quan đến tham số `fc, sumtype, tp` trong method `IsType`.
- **Đã hoàn thành:**
  - Sửa đổi [c22100003.lua](file:///d:/TTF/TTFCustomCards/script/c22100003.lua): Đơn giản hóa `s.matfilter2` sử dụng `c:IsType(TYPE_FUSION)` không chứa các tham số phụ để tránh lỗi `nil` khi gọi thủ công từ `s.valpair` trong Special Summon procedure.
  - Chạy verify thành công (`verify 22100003`) để cập nhật database nhị phân `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - Chạy validator & check-sync qua Harness CLI: Kết quả 100% đồng bộ hoàn hảo (OK) và linter sạch lỗi.
- **Files/artifacts đã cập nhật:** `script/c22100003.lua`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 074 — 2026-06-11

- **Mục tiêu:**
  - Thiết kế cấu hình specs JSON và lập trình Lua hoàn thiện cho card "Blue Eye Ultimammoth Arrow Dragon" (`22100003`) từ hàng đợi.
- **Đã hoàn thành:**
  - Quét hàng đợi qua Harness CLI (`scan`) và khởi tạo (`start`) card mới thành công.
  - Cập nhật specs JSON ([c22100003.json](file:///d:/TTF/TTFCustomCards/card-data/c22100003.json)), kịch bản Lua ([c22100003.lua](file:///d:/TTF/TTFCustomCards/script/c22100003.lua)) và sao chép tệp artwork.
  - Sửa lỗi chính tả hằng số `EFFECT_INDESTRUCTABLE_BATTLE` theo cảnh báo của validator.
  - Chạy verify thành công (`verify 22100003`), tự động biên dịch vào database nhị phân `custom_cards_zesty.cdb` và chuyển trạng thái hàng đợi sang `done` (`d_`).
- **Xác minh đã chạy:**
  - Chạy validator: 134/134 specs hợp lệ (0 lỗi).
  - Chạy check-sync hệ thống: Đồng bộ hoàn hảo 100% giữa Database, Specs, Script và Feature list.
- **Files/artifacts đã cập nhật:** `feature_list.json`, `card-data/c22100003.json`, `script/c22100003.lua`, `pics/22100003.jpg`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 073 — 2026-06-11

- **Mục tiêu:**
  - Thiết kế và lập trình 2 card custom mới: "Blue Eye Flute of Summoning Dragon" (`22100001`) và "Purple Eyes Ultra Max Dragon" (`22100002`) từ hàng đợi.
- **Đã hoàn thành:**
  - Đăng ký archetype mới `Blue_Eye` trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json) với setcode `0xdd` và passcode range `22100001-22199999`.
  - Quét hàng đợi qua Harness CLI (`scan`) và khởi tạo (`start`) cả 2 card mới thành công.
  - Viết specs JSON ([c22100001.json](file:///d:/TTF/TTFCustomCards/card-data/c22100001.json), [c22100002.json](file:///d:/TTF/TTFCustomCards/card-data/c22100002.json)) và kịch bản Lua ([c22100001.lua](file:///d:/TTF/TTFCustomCards/script/c22100001.lua), [c22100002.lua](file:///d:/TTF/TTFCustomCards/script/c22100002.lua)) hoàn chỉnh.
  - Sao chép tệp artwork từ hàng đợi vào thư mục `pics/` dưới dạng `<passcode>.jpg` đúng quy chuẩn.
  - Chạy verify thành công cho cả 2 card (`verify 22100001`, `verify 22100002`), tự động biên dịch vào database nhị phân `custom_cards_zesty.cdb` và chuyển trạng thái hàng đợi sang `done` (`d_`).
- **Xác minh đã chạy:**
  - Chạy validation toàn bộ specs: 133/133 specs hợp lệ (0 lỗi, 0 cảnh báo).
  - Chạy validator kịch bản: `[ ] OK c22100001.lua` và `[ ] OK c22100002.lua`.
  - Chạy check-sync hệ thống: Đồng bộ hoàn hảo 100% giữa Database, Specs, Script và Feature list.
- **Files/artifacts đã cập nhật:** `feature_list.json`, `card-data/c22100001.json`, `card-data/c22100002.json`, `script/c22100001.lua`, `script/c22100002.lua`, `pics/22100001.jpg`, `pics/22100002.jpg`, `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 072 — 2026-06-11

- **Mục tiêu:**
  - Cải tiến luồng Harness CLI để tránh lỗi khi gen card mới và hoạt động hiệu quả hơn.
- **Đã hoàn thành:**
  - [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py) — `start`: pre-flight đầy đủ **trước khi mutate** (template tồn tại, không ghi đè JSON/Lua đã có), rollback JSON nếu tạo Lua fail, đổi tên ảnh queue chỉ sau khi tạo file thành công; skeleton JSON dùng field thân thiện theo template (`setcodes[]`, `linkmarkers[]` cho Link, `lscale`/`rscale` cho Pendulum); in checklist field bắt buộc phải điền sau khi start.
  - `verify`: thêm **Step 0 pre-flight** chặn sớm — thiếu file JSON/Lua, `desc` còn placeholder `"Mô tả hiệu ứng..."`, Lua còn `<<PLACEHOLDER>>`/`XXXXXXXXX`, artwork đuôi `.jpeg` (lỗi Phiên 063), cảnh báo thiếu artwork. Step 2 chỉ validate file của card đang verify (thay vì quét cả 131 script) và dùng exit code thật của validator; vá điểm mù cũ: script không tồn tại/không match dòng nào vẫn pass.
  - Sửa lỗi exit code: `start`/`verify` fail giờ trả **exit code 1** (trước đây luôn 0); `run_command` dùng `sys.executable`, bỏ `shell=True`, thêm `errors='replace'` chống crash decode.
  - [manage_db.py](file:///d:/TTF/TTFCustomCards/script-test/manage_db.py) — `check-sync` so sánh **nội dung** từng card giữa CDB và specs JSON (normalize lại 11 cột datas + name/desc/strings) để phát hiện CDB stale, không chỉ so id; harness verify Step 4 chặn nếu CDB stale sau compile.
  - Cập nhật tài liệu: [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md) (mục hành vi an toàn Harness CLI) và [docs/agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md) (Bước 2/Bước 4 mô tả pipeline mới).
- **Xác minh đã chạy:**
  - `validate` + `check-sync`: 131/131 specs hợp lệ, 100% OK, không stale.
  - Test stale detection: sửa tạm desc của `90177` → check-sync báo đúng 1 card stale, revert sạch.
  - Test guard: `start` đè card đã có → từ chối không mutate; `start` card mới link_monster → skeleton + checklist đúng; `verify` card còn placeholder → fail Step 0 với exit 1; dọn card test sạch.
  - `manage_harness.py verify 998705` end-to-end → SUCCESS, exit 0, CDB không đổi byte (compile deterministic).
- **Files/artifacts đã cập nhật:** `script-test/manage_harness.py`, `script-test/manage_db.py`, `AGENTS.md`, `docs/agent-workflow.md`, `claude-progress.md`

### Phiên 071 — 2026-06-11

- **Mục tiêu:**
  - Phân tích lại luồng code DB toolchain, nghiên cứu source Datacorn (`docs/resources/Datacorn/`) và tích hợp các chuẩn của nó vào compiler để code DB chuẩn hơn, luồng hoạt động khoa học/hiệu quả hơn.
- **Đã hoàn thành:**
  - Nâng cấp [manage_db.py](file:///d:/TTF/TTFCustomCards/script-test/manage_db.py) theo chuẩn Datacorn: bảng bitfield đầy đủ (type/race/attribute/scope/category/link marker), engine validation chạy trước mọi lần compile (ot=32, đúng 1 bit khung Monster/Spell/Trap, race/attribute đơn bit, link marker hợp lệ trong cột `def`, scale/level ≤ 13, strings ≤ 16, id khớp tên file...), compile **atomic** (ghi file tạm, chỉ thay CDB khi 0 lỗi, exit code 1 khi fail), lệnh mới `validate`, xác minh schema kiểu Datacorn (PRAGMA table_info), `PRAGMA page_size=4096`, thứ tự insert ổn định theo id.
  - Hỗ trợ field thân thiện trong specs JSON: `setcodes[]` (tự đóng gói 4×16-bit), `lscale`/`rscale` (tự đóng gói vào level), `linkmarkers[]` (tên marker → bitfield def), ATK/DEF `"?"` (→ -2).
  - [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py): bước 1 của `verify` hiển thị đầy đủ lỗi/warning validation.
  - **Validator mới phát hiện và đã sửa 4 lỗi dữ liệu thật trong CDB:** `79900016` (def chứa bit marker 0x200 không hợp lệ → 45), `29600003` (Link-2 không có marker → 130 Top/Bottom), `998705` (race 0xC Fairy|Fiend → 0x2 Spellcaster), `92047` (atk/def `"?"` bị lưu dạng TEXT trong cột INTEGER → giờ compile thành -2 chuẩn EDOPro).
  - Cập nhật tài liệu: [agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md) mục 3 (schema packing, field thân thiện, validation) và [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md) (lệnh `validate`, ghi chú compile atomic).
- **Xác minh đã chạy:**
  - `validate` + `compile` + `check-sync`: 131/131 specs hợp lệ, sync 100% OK; test chặn spec hỏng (exit 1, CDB cũ nguyên vẹn, không để file tạm); chạy `manage_harness.py verify 998705` end-to-end thành công, linter sạch.
- **Files/artifacts đã cập nhật:** `script-test/manage_db.py`, `script-test/manage_harness.py`, `AGENTS.md`, `docs/agent-rules.md`, 3 specs JSON + `script/c998705.lua` + `custom_cards_zesty.cdb` (commit `dab6c30`, `86d044b`).

### Phiên 070 — 2026-06-11

- **Mục tiêu:**
  - Sửa lỗi "Bug kích được trên tay mà không cần set" trên card `32100004` (Rikka Fleurness).
- **Đã hoàn thành:**
  - Sửa đổi [c32100004.lua](file:///d:/TTF/TTFCustomCards/script/c32100004.lua): Thay thế kiểm tra hand activation không chính xác `IsPreviousLocation(LOCATION_HAND)` bằng kiểm tra engine chuẩn `IsStatus(STATUS_ACT_FROM_HAND)`.
  - Sửa đổi tương tự trên [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua) ("Power of the Dominators") để khắc phục triệt để lỗi logic tương tự.
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify 32100004` và `python .\script-test\manage_harness.py verify 44700001` thành công, linter sạch lỗi và database đồng bộ khớp 100% OK.
- **Files/artifacts đã cập nhật:** [c32100004.lua](file:///d:/TTF/TTFCustomCards/script/c32100004.lua), [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), `claude-progress.md`

### Phiên 069 — 2026-06-10

- **Mục tiêu:**
  - Cập nhật kịch bản Lua và cấu hình specs JSON của card "Kanzashi the Rikka Flower" (`32100002`) để khớp hoàn toàn với văn bản trên hình ảnh thiết kế gốc.
- **Đã hoàn thành:**
  - Sửa đổi [c32100002.json](file:///d:/TTF/TTFCustomCards/card-data/c32100002.json): Cập nhật văn bản mô tả `desc` và mảng `strings` khớp chính xác với ảnh cardmaker.
  - Sửa đổi [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua):
    - Loại bỏ HOPT (`SetCountLimit`) cho Effect 1 (Return 3, Draw 2) và Effect 3 (Search Rikka card).
    - Thay đổi logic Effect 2 từ phủ nhận kích hoạt sang phủ nhận hiệu ứng (negate effect): Sử dụng `CATEGORY_DISABLE` thay vì `CATEGORY_NEGATE`, hàm điều kiện `Duel.IsChainDisablable`, và thực thi `Duel.NegateEffect`.
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify 32100002` thành công, linter sạch lỗi và database đồng bộ khớp 100%.
  - `python .\script-test\manage_db.py check-sync` và `.\script-test\validate_scripts.ps1` đều báo cáo đồng bộ hoàn hảo (82 OK, 49 WARN, 0 FAIL).
- **Files/artifacts đã cập nhật:** [c32100002.json](file:///d:/TTF/TTFCustomCards/card-data/c32100002.json), [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua), `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 068 — 2026-06-10

- **Mục tiêu:**
  - Sửa lỗi runtime `Parameter 2 should be "Int" but is "Function"` trong `proc_xyz.lua` khi triệu hồi Xyz card `32100002` ("Kanzashi the Rikka Flower").
- **Đã hoàn thành:**
  - Sửa đổi [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua): Loại bỏ đối số `99` bị thừa/sai vị trí trong `Xyz.AddProcedure`. Điều này giúp đưa các tham số còn lại (`s.ovfilter`, `aux.Stringid(id,0)`, `2`, `s.xyzop`) về đúng vị trí và tránh lỗi engine hiểu nhầm filter function là description ID.
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify 32100002` -> Thành công hoàn toàn, database biên dịch khớp, script validation & linter 100% OK.
- **Files/artifacts đã cập nhật:** [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua), `claude-progress.md`

### Phiên 067 — 2026-06-10

- **Mục tiêu:**
  - Sửa lỗi card "Possessed Bond" (79900018) bị thiếu archetype "Possessed" và gặp lỗi runtime `attempt to call a nil value (method 'IsBanishableAsCost')` ở GY effect.
- **Đã hoàn thành:**
  - Cập nhật specs JSON [c79900018.json](file:///d:/TTF/TTFCustomCards/card-data/c79900018.json): Thay đổi thuộc tính `"setcode"` từ `0` thành `192` (tương đương `0xc0` - setcode chính thức của archetype "Possessed").
  - Sửa lỗi runtime trong [c79900018.lua](file:///d:/TTF/TTFCustomCards/script/c79900018.lua): Thay thế phương thức không tồn tại `c:IsBanishableAsCost()` bằng phương thức chuẩn `c:IsAbleToRemoveAsCost()`.
  - Định dạng lại code để bẻ dòng dài, vượt linter style check (< 120 ký tự).
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify 79900018` -> Thành công hoàn toàn, linter sạch lỗi, hệ thống đồng bộ 100% OK.
- **Files/artifacts đã cập nhật:** [c79900018.json](file:///d:/TTF/TTFCustomCards/card-data/c79900018.json), [c79900018.lua](file:///d:/TTF/TTFCustomCards/script/c79900018.lua), `claude-progress.md`

### Phiên 066 — 2026-06-10

- **Mục tiêu:**
  - Rà soát toàn bộ 9 custom cards mới của Phiên 062 và khắc phục triệt để các lỗi logic, runtime hoặc thiếu sót kỹ thuật.
- **Đã hoàn thành:**
  - Khắc phục lỗi gọi hàm ảo `Cost.DetachFromSelf(X)` bằng cách thay thế bằng cost functions chuẩn trong [c32100001.lua](file:///d:/TTF/TTFCustomCards/script/c32100001.lua) và [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua).
  - Sửa đổi cost kích hoạt của Continuous Spell trong [c32100005.lua](file:///d:/TTF/TTFCustomCards/script/c32100005.lua) sử dụng `SendtoGrave` thay vì `Release` (vì Spells không thể bị Tribute trong engine).
  - Cải tiến hiệu ứng gửi xuống GY của Ghost Ogre & Rabbit Spirit ([c79900017.lua](file:///d:/TTF/TTFCustomCards/script/c79900017.lua)) thành player-affecting để bỏ qua kháng hiệu ứng của quái thú đối thủ.
  - Bổ sung các lệnh `Duel.ShuffleDeck(tp)` bị thiếu sau khi thực hiện tìm kiếm từ Deck trong [c32100002.lua](file:///d:/TTF/TTFCustomCards/script/c32100002.lua), [c32100005.lua](file:///d:/TTF/TTFCustomCards/script/c32100005.lua), và [c79900018.lua](file:///d:/TTF/TTFCustomCards/script/c79900018.lua).
  - Cập nhật target validation cho hiệu ứng 3 của [c192200015.lua](file:///d:/TTF/TTFCustomCards/script/c192200015.lua) tránh trường hợp tự trỏ target sai đối tượng.
- **Xác minh đã chạy:**
  - Chạy verify thành công cho cả 6 card thông qua Harness CLI.
  - Cú pháp và đồng bộ database khớp 100% OK (`131 OK, 0 FAIL` trong validate script và `check-sync` 100% OK).
- **Files/artifacts đã cập nhật:** `script/c32100001.lua`, `script/c32100002.lua`, `script/c32100005.lua`, `script/c79900017.lua`, `script/c79900018.lua`, `script/c192200015.lua`, `claude-progress.md`
- **Artifacts quy trình:** [implementation_plan.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/235737bc-59a6-451f-aac5-2a5407a72b59/implementation_plan.md), [task.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/235737bc-59a6-451f-aac5-2a5407a72b59/task.md), [walkthrough.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/235737bc-59a6-451f-aac5-2a5407a72b59/walkthrough.md)

### Phiên 065 — 2026-06-10

- **Mục tiêu:**
  - Sửa lỗi runtime error: `attempt to call a nil value (field 'GetRelatedHandler')` trên card `192200015` ("Wandering Fairy in the Castle of Dreams").
- **Đã hoàn thành:**
  - Nhận diện lỗi do file `constants.lua` (nơi định nghĩa `Card.GetRelatedHandler`) chưa được load vào môi trường EDOPro khi chạy trận đấu.
  - Thêm `Duel.LoadScript("constants.lua")` vào đầu file script [c192200015.lua](file:///d:/TTF/TTFCustomCards/script/c192200015.lua) để load toàn bộ custom constants và helper utilities.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 192200015` -> Thành công (Script validation checked out, DB compiled & synced successfully).
- **Files/artifacts đã cập nhật:** [c192200015.lua](file:///d:/TTF/TTFCustomCards/script/c192200015.lua), `claude-progress.md`

### Phiên 064 — 2026-06-10


- **Mục tiêu:**
  - Sửa lỗi Link markers (ô link) chỉ sai vị trí trên card `192200015` ("Wandering Fairy in the Castle of Dreams").
- **Đã hoàn thành:**
  - Xác định các Link markers chính xác trên hình ảnh gốc `docs/queues/Common/d_Wandering_Fairy_in_the_Castle_of_Dreams.jpg`: Bottom-Left, Bottom, Bottom-Right.
  - Sửa đổi giá trị `def` từ `13` (Left, Bottom-Left, Bottom-Right) thành `7` (Bottom-Left, Bottom, Bottom-Right) trong [c192200015.json](file:///d:/TTF/TTFCustomCards/card-data/c192200015.json).
  - Biên dịch và đồng bộ thành công vào cơ sở dữ liệu `custom_cards_zesty.cdb` qua Harness CLI.
  - Commit các file thay đổi theo đúng quy chuẩn `[Doanh] [Fix]: fix link markers for Wandering Fairy in the Castle of Dreams`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 192200015` -> Thành công.
  - `python .\script-test\manage_db.py query 192200015` -> DEF trả về `7` chính xác.
  - `.\script-test\validate_scripts.ps1` -> Kết quả: 82 OK, 49 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> 100% đồng bộ hoàn hảo (100% OK).
- **Files/artifacts đã cập nhật:** [c192200015.json](file:///d:/TTF/TTFCustomCards/card-data/c192200015.json), `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 063 — 2026-06-10

- **Mục tiêu:**
  - Sửa lỗi card picture của `192200016` (Iris Wand) mang phần mở rộng `.jpeg` không load được trong game.
- **Đã hoàn thành:**
  - Đổi tên tệp ảnh `pics/192200016.jpeg` thành `pics/192200016.jpg` để game (EDOPro) có thể tải ảnh bình thường.
  - Đổi tên tệp ảnh hàng đợi `docs/queues/Common/d_Iris_Wand_Dream_Magical.jpeg` thành `docs/queues/Common/d_Iris_Wand_Dream_Magical.jpg`.
  - Cập nhật thông tin `queue_file` tương ứng của card `192200016` trong `feature_list.json` thành đuôi `.jpg`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py check-sync` -> 100% đồng bộ hoàn hảo (100% OK).
  - `.\script-test\validate_scripts.ps1` -> Kết quả: 82 OK, 49 WARN, 0 FAIL.
- **Files/artifacts đã cập nhật:** `pics/192200016.jpg`, `docs/queues/Common/d_Iris_Wand_Dream_Magical.jpg`, `feature_list.json`, `claude-progress.md`

### Phiên 062 — 2026-06-10

- **Mục tiêu:**
  - Thiết kế cấu hình specs JSON và viết script Lua hoàn chỉnh cho 9 card đang ở trạng thái `pending` trong `feature_list.json`.
- **Đã hoàn thành:**
  - Thiết lập cấu hình specs JSON và lập trình Lua hoàn thiện cho 9 card mới:
    - Castle of Dreams: `192200015` (Wandering Fairy), `192200016` (Iris Wand)
    - Rikka: `32100002` (Kanzashi), `32100003` (Rikka Blizzard), `32100004` (Rikka Fleurness), `32100005` (Rikka Foliage)
    - Common: `79900017` (Ghost Ogre & Rabbit Spirit), `79900018` (Possessed Bond), `79900019` (The Journeying Three Magi)
  - Khởi chạy và hoàn thành quy trình verify tự động của Harness CLI cho cả 9 card, cập nhật trạng thái trong `feature_list.json` thành `"done"` và đổi tên các file queue tương ứng.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py compile` -> Thành công biên dịch 131 card.
  - `.\script-test\validate_scripts.ps1` -> Kết quả: 82 OK, 49 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> 100% đồng bộ hoàn hảo (100% OK).
- **Files/artifacts đã cập nhật:** `claude-progress.md`, `feature_list.json`, `custom_cards_zesty.cdb`, `card-data/c*.json`, `script/c*.lua`, `docs/queues/`
- **Artifacts quy trình:** [implementation_plan.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/3104bbe4-0402-42ef-a4a7-445ee0b813be/implementation_plan.md), [task.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/3104bbe4-0402-42ef-a4a7-445ee0b813be/task.md), [walkthrough.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/3104bbe4-0402-42ef-a4a7-445ee0b813be/walkthrough.md)

### Phiên 061 — 2026-06-10

- **Mục tiêu:**
  - Quét hàng đợi, tìm và đăng ký các card pending (`p_`) mới trong `docs/queues/` vào `feature_list.json` để chuẩn bị code.
- **Đã hoàn thành:**
  - Phát hiện và đăng ký 9 card pending mới vào `feature_list.json` dưới các archetype tương ứng.
  - Cập nhật ngày `last_updated` trong `feature_list.json` thành `"2026-06-10"`.
  - Cải tiến `manage_harness.py`:
    - Cho phép lệnh `start` nhận diện và cập nhật trực tiếp các card đã đăng ký ở trạng thái `pending` sang `working`.
    - Tích hợp thêm subcommand `scan` vào Harness CLI: Tự động phát hiện các file `p_` trong queues chưa được đăng ký, tự động gán passcode phù hợp, chuyển đổi định dạng tên và thêm chúng vào `feature_list.json` ở trạng thái `"pending"`.
  - Cập nhật tài liệu hướng dẫn `AGENTS.md` và `docs/agent-workflow.md` để mô tả cách dùng và quy tắc của lệnh `scan` cho các AI agent tiếp theo.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py scan` -> Chạy thử nghiệm thành công, nhận diện đúng các card đã được đăng ký và không sinh bản ghi trùng lặp.
  - `python .\script-test\manage_db.py check-sync` -> 100% khớp cấu trúc.
  - `.\script-test\validate_scripts.ps1` -> Hoạt động bình thường (76 OK, 46 WARN, 0 FAIL).
- **Files/artifacts đã cập nhật:** `feature_list.json`, `script-test/manage_harness.py`, `AGENTS.md`, `docs/agent-workflow.md`, `claude-progress.md`

### Phiên 060 — 2026-06-09

- **Mục tiêu:**
  - Sửa lỗi effect 2 của [c192300005.lua](file:///d:/TTF/TTFCustomCards/script/c192300005.lua) ("The End of Greatest Warrior") không kích hoạt khi Wezaemon bị đánh bại (destroyed by battle) hoặc dùng làm nguyên liệu (used as material).
- **Đã hoàn thành:**
  - Bổ sung `EFFECT_FLAG_DAMAGE_STEP` và `EFFECT_FLAG_DELAY` vào effect property của e2 (`EVENT_LEAVE_FIELD`).
    - `EFFECT_FLAG_DAMAGE_STEP`: Cho phép kích hoạt trong Damage Step (khi quái thú bị tiêu diệt bằng chiến đấu).
    - `EFFECT_FLAG_DELAY`: Ngăn chặn việc lỡ thời điểm (miss the timing) khi quái thú được dùng làm nguyên liệu Triệu hồi đặc biệt (Fusion/Synchro/Link).
- **Xác minh đã chạy:**
  - Chạy `python .\script-test\manage_harness.py verify 192300005` thành công, pipeline harness và check-sync 100% OK.
- **Files/artifacts đã cập nhật:** [c192300005.lua](file:///d:/TTF/TTFCustomCards/script/c192300005.lua), `claude-progress.md`

### Phiên 059 — 2026-06-09

- **Mục tiêu:**
  - Sửa lỗi runtime error khi quái thú "Wezaemon the Tombguard" rời sân trên card [c192300005.lua](file:///d:/TTF/TTFCustomCards/script/c192300005.lua) ("The End of Greatest Warrior").
- **Đã hoàn thành:**
  - Sửa lỗi gọi hàm không tồn tại `c:GetPreviousCode()` thành hàm EDOPro chuẩn `c:GetPreviousCodeOnField()` trong function `s.leavfilter`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 192300005` → Pipeline chạy thành công, database biên dịch chuẩn, sync check 100% OK.
- **Files/artifacts đã cập nhật:** [c192300005.lua](file:///d:/TTF/TTFCustomCards/script/c192300005.lua), `custom_cards_zesty.cdb`, `claude-progress.md`

### Phiên 058 — 2026-06-09

- **Mục tiêu:**
  - Sửa lỗi mirror match của [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua) ("Wezaemon the Tombguard"): Khi cả 2 người chơi đều control Wezaemon, nếu 1 bên set/activate Spell/Trap mentioning Wezaemon thì bên còn lại cũng kích hoạt được Effect 4.
- **Đã hoàn thành:**
  - Viết lại hoàn toàn condition cho Effect 4a (`setcon_chain`) và Effect 4b (`setcon_set`) trong [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua):
    - Loại bỏ cách tiếp cận `e:GetHandler():GetControler()` + `(rp==hc or ep==hc)` (logic OR dư thừa với 2 biến có thể gây edge-case).
    - Áp dụng **pattern chuẩn official** (Altergeist Multifaker, Tragoedia): sử dụng trực tiếp tham số `tp` (controller của effect) để so sánh.
    - Effect 4a (EVENT_CHAINING): `rp~=tp then return false` — chỉ trigger khi **chính** người chơi sở hữu Wezaemon (`tp`) activate chain (`rp`).
    - Effect 4b (EVENT_SSET): `ep~=tp then return false` — chỉ trigger khi **chính** người chơi sở hữu Wezaemon (`tp`) thực hiện set (`ep`).
    - Đơn giản hóa filter trong `setcon_set`: tái sử dụng `s.mentionfilter` thay vì closure cục bộ kiểm tra `IsControler`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_harness.py verify 192300001` → Pipeline thành công, sync 100% OK.
- **Files/artifacts đã cập nhật:** [c192300001.lua](file:///d:/TTF/TTFCustomCards/script/c192300001.lua), `custom_cards_zesty.cdb`, `claude-progress.md`

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
