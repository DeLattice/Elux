FROM node:20-alpine AS frontend
WORKDIR /app
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install --frozen-lockfile --silent
COPY frontend/ .
RUN yarn run build

# ==========================================
# 2. Xray Downloader Stage (Надежный метод)
# ==========================================
FROM alpine:latest AS xray-fetcher
WORKDIR /xray
RUN apk add --no-cache curl unzip
# Скачиваем и распаковываем официальный релиз Xray
RUN curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip xray.zip && \
    rm xray.zip

# ==========================================
# 3. Backend Build Stage
# ==========================================
FROM rust:slim AS backend
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev libsqlite3-dev && rm -rf /var/lib/apt/lists/*
COPY backend/ .
RUN mkdir -p static
COPY --from=frontend /app/dist/frontend/browser ./static
RUN RUSTFLAGS=-Awarnings cargo build --release

# ==========================================
# 4. Final Runtime Stage
# ==========================================
# Используем Ubuntu 24.04, чтобы избежать ошибки GLIBC_2.39 not found
FROM ubuntu:24.04
WORKDIR /app

# Устанавливаем runtime зависимости
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Создаем папку для конфигов приложения
ENV XDG_CONFIG_HOME=/app/config
RUN mkdir -p /app/config

# --- Настройка Xray ---
# Создаем папку для geo-файлов
RUN mkdir -p /usr/share/xray

# Копируем файлы из стадии xray-fetcher
COPY --from=xray-fetcher /xray/xray /usr/bin/xray
COPY --from=xray-fetcher /xray/geoip.dat /usr/share/xray/geoip.dat
COPY --from=xray-fetcher /xray/geosite.dat /usr/share/xray/geosite.dat

# Указываем Xray, где искать dat файлы
ENV XRAY_LOCATION_ASSET=/usr/share/xray
# ----------------------

COPY --from=backend /app/target/release/server ./backend
COPY --from=backend /app/static ./static

EXPOSE 8400
CMD ["./backend"]
