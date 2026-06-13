# Build React admin UI
FROM node:20-alpine AS admin-builder
WORKDIR /build
COPY admin_web/package.json ./
RUN npm install
COPY admin_web/ ./
ENV VITE_API_URL=
RUN npm run build

# Python API + serve admin at /admin
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY --from=admin-builder /build/dist ./admin_web/dist
ENV PORT=8000
CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT
