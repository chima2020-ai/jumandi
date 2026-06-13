# Python API + prebuilt admin UI at /admin
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY admin_web/dist ./admin_web/dist
ENV PORT=8000
CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT
