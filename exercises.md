# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Mai Tiến Huy  Mã học viên: 2A202602914

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi deploy lên Railway, nếu quên set biến AGENT_API_KEY trong dashboard, app sẽ crash ngay lập tức với lỗi ValidationError và ta biết ngay cần set secret. Nếu để mặc định "changeme", app vẫn chạy bình thường nhưng ai biết giá trị mặc định đó đều có thể gọi API thoải mái, tiêu hết ngân sách LLM của mình mà không hay biết. Fail fast giúp phát hiện lỗi cấu hình ngay tại thời điểm deploy, không phải khi hóa đơn đến cuối tháng.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log JSON: `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T07:30:15.123456+00:00", "user_id": "sv01", "tokens_in": 5, "tokens_out": 42, "cost_usd": 0.00002595}`. Hai việc có thể làm: (1) Lọc và đếm tự động — trên Datadog/Railway logs có thể query `event == "ask_completed"` để đếm số request theo thời gian, tạo dashboard giám sát. (2) Cảnh báo chi phí — có thể set alert khi `cost_usd` tích lũy vượt ngưỡng, hoặc khi `tokens_out` đột biến cao bất thường. Với `print("đã trả lời xong")` thì không có structured data nào để máy parse và phân tích.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~1.02 GB |
| Multi-stage | ~180 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Phần chênh lệch khoảng 840MB chủ yếu là compiler toolchain (gcc, g++, make), development headers, pip cache, và các package phụ trợ chỉ cần thiết lúc build (ví dụ để compile native extensions). Bản `python:3.11` đầy đủ chứa toàn bộ Debian packages và build tools, trong khi `python:3.11-slim` chỉ giữ runtime tối thiểu. Multi-stage build chỉ copy kết quả đã compile xong sang stage runtime, không mang theo compiler và source build.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Với Dockerfile hiện tại, khi chỉ sửa code trong `app/main.py`: các layer `FROM`, `COPY requirements.txt`, `RUN pip install` đều được cache (vì requirements.txt không đổi). Chỉ layer `COPY app/ ./app/` và các layer sau phải chạy lại — build rất nhanh, vài giây. Nếu đặt `COPY . .` trước `RUN pip install`, thì mỗi lần sửa bất kỳ file nào (kể cả 1 ký tự trong main.py), Docker thấy layer COPY thay đổi → invalidate tất cả layer sau → phải cài lại toàn bộ dependency từ đầu, tốn thêm 1–2 phút mỗi lần build.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi tấn công: (1) Kẻ tấn công tìm được lỗ hổng command injection hoặc path traversal trong code Python → (2) Thực thi lệnh tùy ý bên trong container với quyền root → (3) Đọc/ghi file hệ thống trong container, cài đặt công cụ tấn công → (4) Nếu có volume mount hoặc lỗ hổng container escape (ví dụ CVE kernel), root trong container có thể thành root trên host. Lệnh `USER appuser` cắt đứt ở bước (2): dù attacker thực thi được lệnh, họ chỉ có quyền user thường, không thể ghi vào /etc, không thể cài package, không thể mount filesystem, giảm đáng kể bề mặt tấn công cho container escape.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request trong 2 giây. Cách đạt: gửi 10 request vào lúc 10:00:59 (cuối phút cũ, vẫn trong hạn mức 10/phút), rồi ngay lúc 10:01:01 gửi thêm 10 request (đầu phút mới, counter đã reset về 0). Tổng cộng 20 request trong 2 giây mà hệ thống đếm theo phút đồng hồ không phát hiện vi phạm nào. Sliding window 60s tránh được vấn đề này vì nó luôn nhìn lại 60 giây gần nhất bất kể ranh giới phút, nên 10 request ở giây 59 vẫn nằm trong cửa sổ khi đếm ở giây 01.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn *tần suất* (số request/phút), cost guard giới hạn *chi phí* (USD/tháng). Tình huống rate limit cho qua nhưng cost guard chặn: user gửi đúng 10 request/phút nhưng mỗi request kèm prompt 50.000 token (context rất dài), chi phí mỗi request cao — sau vài giờ tổng chi phí vượt $10 ngân sách tháng. Rate limit không thấy vấn đề gì (vẫn đúng 10 req/phút) nhưng cost guard chặn vì hết budget. Tình huống ngược lại: user mới bắt đầu dùng (spent = $0), gửi liên tục 20 request trong 1 phút — cost guard cho qua vì tổng chi phí vẫn rất nhỏ (mỗi request chỉ vài cent), nhưng rate limit chặn từ request thứ 11 vì vượt 10 req/phút.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> (1) Redis mất kết nối → (2) Endpoint gộp health+ready kiểm tra Redis, trả 503 → (3) Orchestrator (Docker/K8s) thấy health check fail, đánh dấu container unhealthy → (4) Sau vài lần retry (khoảng 30–90 giây), orchestrator restart cả 3 container → (5) Container mới khởi động, Redis vẫn chưa khôi phục → (6) Health check lại fail → (7) Vòng lặp restart liên tục (crash loop) → tất cả 3 container đều down, service hoàn toàn không phục vụ được. Nếu tách riêng: /health (không check Redis) vẫn trả 200 → container không bị restart. /ready trả 503 → load balancer ngừng gửi traffic mới nhưng container vẫn sống. Khi Redis khôi phục sau 30 giây, /ready tự trả 200 lại, traffic được đẩy trở lại mà không cần restart gì cả.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis (stateless): `history_length` tăng đều 0, 2, 4, 6, 8... bất kể request đi vào container nào, vì cả 3 instance đều đọc/ghi cùng một Redis. Với dict Python (stateful): `history_length` sẽ nhảy lung tung — ví dụ 0, 0, 2, 0, 2, 4, 2 — vì mỗi container giữ dict riêng trong RAM. Request 1 vào container A (history=0), request 2 vào container B (history=0, B chưa biết gì), request 3 lại vào A (history=2, chỉ thấy của mình). Agent "mất trí nhớ" mỗi khi load balancer chuyển sang instance khác. Restart container thì mất toàn bộ.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Khi deploy lên cloud, lỗi đầu tiên gặp là health check timeout: platform báo "Health check failed - service did not become healthy within 300s". Kiểm tra log thấy app khởi động thành công nhưng bind vào 127.0.0.1 thay vì 0.0.0.0, nên health check từ bên ngoài container không kết nối được. Nguyên nhân: CMD trong Dockerfile ban đầu dùng `--host 127.0.0.1`. Sửa bằng cách thay thành `--host 0.0.0.0` để app lắng nghe trên tất cả interface. Ngoài ra, cần đảm bảo app đọc biến `$PORT` do platform cấp thay vì hardcode 8000, vì một số platform gán cổng khác.
