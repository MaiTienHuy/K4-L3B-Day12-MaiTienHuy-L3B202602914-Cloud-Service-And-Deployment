# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Mai Tiến Huy |
| Mã học viên | 2A202602914 |
| Repo | K4-L3B-Day12-MaiTienHuy-L3B202602914-Cloud-Service-And-Deployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | http://localhost:8000 (local fallback) |
| Platform | Railway (local fallback via Docker Compose) |
| Ngày deploy | 2026-09-29 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | 8000, set trong docker-compose.yml |
| `AGENT_API_KEY` | ✅ | đặt trong .env, truyền qua nội suy ${AGENT_API_KEY} |
| `REDIS_URL` | ✅ | redis://redis:6379/0 (service name trong compose) |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

```bash
# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i http://localhost:8000/health

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i http://localhost:8000/ready

# 3. Không có API key — mong đợi 401
curl -i -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'
```

## Kết Quả Chạy Thật

```
HTTP/1.1 200 OK
{"status":"ok","service":"day12-agent","version":"1.0.0"}

HTTP/1.1 200 OK
{"status":"ready","redis":true}

HTTP/1.1 401 Unauthorized
{"detail":"invalid or missing API key"}
```

## Ảnh Chụp Màn Hình

Đặt ảnh trong thư mục `screenshots/`:

- `screenshots/dashboard.png` — docker compose ps output
- `screenshots/health.png` — kết quả gọi /health

---

## Nếu Dùng Phương Án Dự Phòng

```
Dùng phương án dự phòng LOCAL_FALLBACK=true vì đang chạy trên môi trường local
với Docker Compose. Service chạy đầy đủ các tính năng (health, ready, auth,
rate limit, cost guard, stateless store) trên docker compose stack gồm
agent + redis.
```
