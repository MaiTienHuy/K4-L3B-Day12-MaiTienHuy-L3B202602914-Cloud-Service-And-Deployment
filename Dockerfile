# ═══════════════════════════════════════════════════════════════════
# CP2 — Production-ready Dockerfile
# Multi-stage build: builder installs deps, runtime copies result
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder ─────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: runtime ─────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Copy installed dependencies from builder
COPY --from=builder /install /usr/local

# Copy source code
COPY app/ ./app/
COPY utils/ ./utils/

# Create non-root user
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Port configuration — cloud platforms set $PORT automatically
ENV PORT=8000
EXPOSE ${PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT:-8000}/health')" || exit 1

# Start the service, reading port from environment variable
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
