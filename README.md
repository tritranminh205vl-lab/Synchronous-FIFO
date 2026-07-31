# Synchronous FIFO Verification using SystemVerilog

<p align="center">
  <img src="docs/images/01-simulation-workspace.png" width="800" alt="Môi trường mô phỏng FIFO">
</p>

<p align="center">
  <b>Một hành trình verification: từ một module FIFO tưởng chừng đơn giản, đến một testbench tự kiểm tra hoàn chỉnh với reference model, scoreboard và functional coverage.</b>
</p>

---

## Giới thiệu

Dự án này verify một module **Synchronous FIFO** (`sync_fifo`) viết bằng SystemVerilog — cấu trúc dữ liệu tưởng chừng cơ bản nhưng lại là nơi rất nhiều lỗi verification kinh điển xảy ra: race condition giữa push/pop, sai lệch con trỏ đọc/ghi, sai logic ở biên `empty`/`full`, và các trường hợp push/pop đồng thời dễ bị bỏ sót nếu chỉ test bằng tay.

Toàn bộ repo được ghi lại như một cuốn nhật ký: xác định yêu cầu, đọc lại RTL, dựng testbench tự kiểm tra, chạy directed test, sau đó random test 200 chu kỳ, đo functional coverage thủ công, và cuối cùng tổng kết kết quả. Mục tiêu không phải là "code cho chạy", mà là **chứng minh được RTL đúng bằng chứng cứ đo được**.

---

## Thông số dự án

| Hạng mục | Giá trị |
|---|---|
| Module thiết kế | `sync_fifo` |
| Ngôn ngữ | SystemVerilog |
| DEPTH (mặc định) | 8 |
| WIDTH (mặc định) | 8 |
| Loại reset | Đồng bộ, active-low (`rst_n`) |
| Chu kỳ clock | 10 ns (`#5` mỗi nửa chu kỳ) |
| Tín hiệu chính | `clk`, `rst_n`, `push`, `pop`, `din`, `dout`, `empty`, `full`, `count` |
| Mô phỏng | Icarus Verilog (`iverilog` + `vvp`) |
| Xem waveform | GTKWave |
| Số chu kỳ random test | 200 |
| Kết quả cuối | PASS CHECKS = 948, FAIL CHECKS = 0, Coverage 12/12 = 100% |

---

## Nhật ký dự án

### Nhật ký 01 — Xác định yêu cầu

Trước khi viết một dòng testbench nào, tôi dành thời gian đọc kỹ đặc tả của `sync_fifo` để chốt lại "hợp đồng hành vi" mà RTL phải tuân theo:

- `write_accept = push && !full`
- `read_accept = pop && !empty`
- Khi `push` và `pop` cùng bật ở trạng thái **giữa** (không rỗng, không đầy): cả hai được chấp nhận, `count` giữ nguyên.
- Khi cả hai cùng bật lúc **rỗng**: chỉ `push` được chấp nhận.
- Khi cả hai cùng bật lúc **đầy**: chỉ `pop` được chấp nhận.
- `dout` là ngõ ra có thanh ghi (registered output), chỉ cập nhật khi có một `read_accept` hợp lệ tại cạnh clock đó — không phải ngõ ra tổ hợp đọc trực tiếp từ bộ nhớ.

Danh sách này sau đó trở thành checklist cho từng directed test và từng điểm functional coverage bên dưới. Nếu không viết ra rõ ràng từ đầu, rất dễ verify nhầm theo cách "RTL làm gì thì coi đó là đúng" — điều tối kỵ trong verification.

### Nhật ký 02 — Đọc lại RTL

Sau khi có đặc tả, tôi đọc từng khối của `sync_fifo.sv` để đối chiếu: bộ nhớ FIFO là mảng thanh ghi `DEPTH` phần tử, có hai con trỏ `wptr`/`rptr` độ rộng `PTR_WIDTH`, và `count` là thanh ghi riêng cập nhật bằng khối `case` dựa trên `{write_accept, read_accept}`. Điểm cần chú ý nhất là `full`/`empty` được suy ra từ `count` (`full = (count == DEPTH)`, `empty = (count == 0)`), chứ không so sánh trực tiếp `wptr`/`rptr` — cách này tránh được lỗi kinh điển "wrap-around ambiguity" của FIFO dùng con trỏ thuần túy.

### Nhật ký 03 — Dựng testbench tự kiểm tra

Thay vì chỉ nhìn waveform bằng mắt, tôi xây một **reference model độc lập** ngay trong testbench: một mảng bộ nhớ `ref_mem`, hai con trỏ `ref_wr_ptr`/`ref_rd_ptr` và một biến `ref_count`, cập nhật hoàn toàn tách biệt với DUT theo đúng đặc tả ở Nhật ký 01. Mỗi chu kỳ, testbench tính trước giá trị `count`, `full`, `empty`, `dout` kỳ vọng, rồi mới chờ cạnh clock và so sánh với DUT thực tế qua scoreboard (`check_count_value`, `check_full_value`, `check_empty_value`, `check_dout_value`).

<p align="center">
  <img src="docs/images/02-waveform-overview.png" width="800" alt="Waveform tổng quan">
</p>

Nhìn tổng thể sóng `clk`, `count`, `empty`, `pop`, `push` ngay từ những chu kỳ đầu tiên giúp xác nhận trực quan rằng `count` tăng/giảm đúng nhịp với các thao tác push/pop trước khi tin tưởng vào con số scoreboard.

### Nhật ký 04 — Kiểm tra dữ liệu din/dout

Waveform tiếp theo tập trung vào đường dữ liệu: giá trị `din` được đẩy vào và giá trị `dout` trả ra sau các lần `pop`.

<p align="center">
  <img src="docs/images/04-data-flow-din-dout.png" width="800" alt="Kiểm tra din/dout">
</p>

Ở đây tôi xác nhận đặc điểm quan trọng của thiết kế: `dout` chỉ thay đổi tại đúng chu kỳ có `read_accept`, và giá trị đó phải là phần tử đã được ghi vào FIFO trước đó theo đúng thứ tự FIFO (first-in, first-out), khớp với những gì reference model tính ra.

### Nhật ký 05 — Trạng thái FIFO đầy

Một trong những vùng dễ sai nhất của FIFO là biên `full`. Tôi cố tình đẩy dữ liệu liên tục cho đến khi `count` chạm `DEPTH` để quan sát.

<p align="center">
  <img src="docs/images/03-full-state.png" width="800" alt="Trạng thái FIFO đầy">
</p>

Tại đây `full=1`, và một lệnh `push` tiếp theo (khi không có `pop` đi kèm) phải bị bỏ qua hoàn toàn — `count` không được vượt quá `DEPTH`, dữ liệu cũ trong FIFO không được ghi đè.

### Nhật ký 06 — Reset và random test

<p align="center">
  <img src="docs/images/05-reset-and-random-test.png" width="800" alt="Reset và random test">
</p>

Sau khối directed test, tôi thêm một lần `reset_dut()` giữa lúc FIFO còn dữ liệu, để chắc chắn reset đồng bộ active-low đưa toàn bộ trạng thái (`wptr`, `rptr`, `count`, `dout`) về 0 bất kể trạng thái trước đó. Ngay sau đó là 200 chu kỳ random, nơi `push`/`pop`/`din` được sinh ngẫu nhiên với `$random`, cố tình thiên về các tổ hợp có xác suất cao chạm vào các trạng thái biên.

### Nhật ký 07 — Console log của directed test

<p align="center">
  <img src="docs/images/06-directed-test-log.png" width="600" alt="Console log directed test">
</p>

Mỗi dòng log in ra đầy đủ `push`, `pop`, `din`, và giá trị `dout`/`count`/`empty`/`full` đo được ngay sau cạnh clock, giúp truy vết lại chính xác chu kỳ nào gây fail nếu có, thay vì phải dò lại toàn bộ waveform.

### Nhật ký 08 — Tổng kết kết quả

<p align="center">
  <img src="docs/images/07-final-coverage-report.png" width="500" alt="Báo cáo kết quả cuối cùng">
</p>

Sau khi chạy xong directed test và 200 chu kỳ random test, scoreboard báo cáo **948 PASS CHECKS, 0 FAIL CHECKS**, và bảng functional coverage thủ công đạt **12/12 = 100%**. Kết quả cuối: `FINAL RESULT: TEST PASSED`.

---

## ️ Kiến trúc FIFO: circular buffer, con trỏ và biến count

`sync_fifo` được cài đặt theo mô hình **circular buffer**: một mảng thanh ghi `fifo[0:DEPTH-1]` cùng hai con trỏ độc lập:

- `wptr` (write pointer) — chỉ vào vị trí sẽ ghi dữ liệu tiếp theo khi có `write_accept`.
- `rptr` (read pointer) — chỉ vào vị trí sẽ đọc dữ liệu tiếp theo khi có `read_accept`.

Cả hai con trỏ đều tự "quay vòng" về 0 khi chạm `DEPTH-1`, thay vì tăng vô hạn — đó là bản chất của circular buffer. Vì hai con trỏ độc lập không đủ để phân biệt trạng thái rỗng và đầy (cả hai đều có thể xảy ra khi `wptr == rptr`), thiết kế dùng thêm một thanh ghi riêng là `count` để theo dõi số phần tử hiện có trong FIFO:

```systemverilog
assign full  = (count == DEPTH);
assign empty = (count == 0);
```

`count` được cập nhật đồng bộ mỗi cạnh clock dựa trên tổ hợp `write_accept`/`read_accept`, tăng 1 khi chỉ ghi, giảm 1 khi chỉ đọc, và giữ nguyên khi cả hai cùng xảy ra hoặc không thao tác nào xảy ra.

---

## Bảng hành vi push/pop theo trạng thái

| Trạng thái | push | pop | Kết quả |
|---|---|---|---|
| Rỗng (empty) | 1 | 0 | Ghi được chấp nhận, `count` tăng 1 |
| Rỗng (empty) | 0 | 1 | `pop` bị bỏ qua (không có dữ liệu để đọc), `count` giữ nguyên |
| Rỗng (empty) | 1 | 1 | Chỉ `push` được chấp nhận, `count` tăng 1 |
| Giữa (middle) | 1 | 0 | Ghi được chấp nhận, `count` tăng 1 |
| Giữa (middle) | 0 | 1 | Đọc được chấp nhận, `count` giảm 1 |
| Giữa (middle) | 1 | 1 | Cả hai được chấp nhận, `count` giữ nguyên |
| Đầy (full) | 1 | 0 | `push` bị bỏ qua (FIFO đã đầy), `count` giữ nguyên |
| Đầy (full) | 0 | 1 | Đọc được chấp nhận, `count` giảm 1 |
| Đầy (full) | 1 | 1 | Chỉ `pop` được chấp nhận, `count` giảm 1 |

---

## Trích đoạn RTL đáng chú ý

Logic quyết định thao tác nào thực sự được chấp nhận, đặt nền cho toàn bộ hành vi của FIFO:

```systemverilog
assign write_accept = push && !full;
assign read_accept  = pop  && !empty;
```

Cập nhật `count` bằng `case` trên tổ hợp hai tín hiệu chấp nhận, thể hiện rõ quy tắc "cả hai cùng chấp nhận thì count giữ nguyên":

```systemverilog
case ({write_accept, read_accept})
    2'b10: count <= count + 1'b1;
    2'b01: count <= count - 1'b1;
    default: count <= count;
endcase
```

`dout` chỉ được gán trong nhánh `read_accept`, đúng đặc trưng của ngõ ra có thanh ghi:

```systemverilog
if (read_accept) begin
    dout <= fifo[rptr];
    ...
end
```

---

## Testbench, scoreboard, directed test, random test và coverage

### Reference model & scoreboard

Testbench (`tb_top`) không chỉ áp xung tín hiệu — nó duy trì một **reference model độc lập** (`ref_mem`, `ref_wr_ptr`, `ref_rd_ptr`, `ref_count`) hoàn toàn tách biệt khỏi DUT. Mỗi chu kỳ, task `apply_cycle` tính trước `expected_count`, `expected_full`, `expected_empty`, `expected_dout` dựa trên đặc tả, sau đó mới `@(posedge clk)` và gọi các task scoreboard (`check_count_value`, `check_full_value`, `check_empty_value`, `check_dout_value`) để đối chiếu với giá trị thực tế trên DUT. Mọi sai lệch được đếm vào `fail_count` kèm log chi tiết.

### Directed test

Khối directed test đi qua từng tình huống theo đúng đặc tả: idle, pop khi rỗng, push+pop đồng thời khi rỗng, push/pop cơ bản, lấp đầy FIFO, push khi đầy, push+pop đồng thời khi đầy, push+pop đồng thời ở trạng thái giữa, và reset giữa lúc FIFO còn dữ liệu.

<p align="center">
  <img src="docs/images/08-extended-waveform.png" width="800" alt="Waveform mở rộng">
</p>

### Random test

Sau directed test, 200 chu kỳ ngẫu nhiên được sinh bằng `$random`, với tỉ lệ được cân chỉnh để không chỉ toàn "idle" mà còn thiên về push/pop/cả-hai, giúp tăng khả năng chạm vào các trạng thái biên (đầy, rỗng) một cách tự nhiên thay vì chỉ dựa vào directed test.

### Functional coverage thủ công

Vì mô phỏng bằng Icarus Verilog không hỗ trợ đầy đủ `covergroup` của SystemVerilog, coverage được cài đặt thủ công bằng 12 cờ đếm, lấy mẫu tại từng chu kỳ trước khi thao tác được áp dụng:

| # | Điểm coverage |
|---|---|
| 1 | empty state |
| 2 | middle state |
| 3 | full state |
| 4 | idle |
| 5 | push only |
| 6 | pop only |
| 7 | push + pop |
| 8 | push when full |
| 9 | pop when empty |
| 10 | both in middle |
| 11 | both when empty |
| 12 | both when full |

### Waveform dump & watchdog

Testbench dump toàn bộ `tb_top` ra `fifo.vcd` bằng `$dumpvars`, và có một watchdog dùng `#100000` để tự động `$finish` nếu mô phỏng bị treo — tránh việc CI hoặc máy cá nhân chạy vô thời hạn nếu RTL có lỗi logic gây deadlock giả định.

---

## Cấu trúc thư mục

```
.
├── rtl/
│   └── sync_fifo.sv          # RTL của FIFO cần verify
├── tb/
│   └── sync_fifo_tb.sv       # Testbench tự kiểm tra
├── docs/
│   └── images/                # Ảnh waveform và console log dùng trong README
│       ├── 01-simulation-workspace.png
│       ├── 02-waveform-overview.png
│       ├── 03-full-state.png
│       ├── 04-data-flow-din-dout.png
│       ├── 05-reset-and-random-test.png
│       ├── 06-directed-test-log.png
│       ├── 07-final-coverage-report.png
│       └── 08-extended-waveform.png
├── sim/
│   └── fifo.vcd                # Waveform dump sinh ra sau khi mô phỏng
└── README.md
```

---

## ▶️ Hướng dẫn chạy bằng Icarus Verilog

```bash
# 1. Biên dịch RTL và testbench
iverilog -Wall -g2012 -s tb_top -o sim/a.out rtl/sync_fifo.sv tb/sync_fifo_tb.sv

# 2. Chạy mô phỏng
vvp sim/a.out

# 3. Mở waveform để quan sát trực quan
gtkwave sim/fifo.vcd
```

Sau khi chạy xong, console sẽ in log directed test, log random test, và bảng tổng kết `FINAL SCOREBOARD REPORT` cùng `MANUAL FUNCTIONAL COVERAGE` ở cuối.

---

## Những điều tôi học được

- **Reference model độc lập là xương sống của self-checking testbench.** Không có nó, mọi so sánh chỉ là "nhìn waveform đoán đúng sai", rất dễ bỏ sót lỗi ở các trạng thái biên.
- **Trạng thái biên (empty/full) luôn là nơi bug tập trung nhiều nhất.** Các tổ hợp push+pop đồng thời ở đúng lúc rỗng hoặc đầy là những case dễ bị quên nhất nếu chỉ viết test theo cảm tính.
- **Directed test và random test bổ sung cho nhau, không thay thế nhau.** Directed test đảm bảo các case đã biết chắc chắn được kiểm tra; random test giúp phát hiện những tổ hợp không lường trước.
- **Coverage thủ công vẫn có giá trị khi công cụ không hỗ trợ đầy đủ.** Việc tự định nghĩa 12 điểm coverage buộc tôi phải suy nghĩ rõ ràng về "thế nào là đã verify đủ", thay vì chỉ dựa vào số lượng test case chạy qua.

## Hướng phát triển tiếp theo

- Bổ sung mô hình FIFO bất đồng bộ (asynchronous FIFO) với hai miền clock khác nhau, xử lý đồng bộ hóa con trỏ qua Gray code.
- Chuyển sang SystemVerilog `covergroup`/`coverpoint` thực sự khi dùng mô phỏng hỗ trợ đầy đủ (VCS, Questa, Xcelium) thay vì coverage thủ công.
- Thêm constrained-random test với `randc`/`randsequence` để sinh chuỗi thao tác có kiểm soát hơn là chỉ dùng `$random` thuần túy.
- Thử nghiệm với các giá trị `DEPTH`/`WIDTH` khác nhau để kiểm tra tính tổng quát của tham số hóa.

## Kết luận

Dự án đã verify thành công module `sync_fifo` với tổng cộng **948 phép kiểm tra pass, 0 phép kiểm tra fail**, và đạt **100% functional coverage thủ công** trên cả 12 điểm đã định nghĩa. Kết quả này không chứng minh RTL "hoàn hảo tuyệt đối" — nó chứng minh rằng, trong phạm vi các tình huống đã được xác định và kiểm tra, RTL hoạt động đúng theo đặc tả đã đề ra. Đó là ranh giới trung thực mà bất kỳ báo cáo verification nghiêm túc nào cũng nên nêu rõ.
