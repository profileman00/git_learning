# --- Build stage: install dependencies in isolation ---
FROM python:3.12-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# --- Runtime stage: copy only what's needed to run ---
FROM python:3.12-slim
WORKDIR /app

# Run as a non-root user (never run production containers as root)
RUN useradd --create-home appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY app/ .
RUN chown -R appuser:appuser /app
USER appuser

ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["python", "main.py"]
