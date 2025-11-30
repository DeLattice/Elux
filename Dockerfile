FROM node:20-alpine AS web
WORKDIR /app
COPY web/package.json web/yarn.lock ./
RUN yarn install --frozen-lockfile --silent
COPY web/ .
RUN yarn run build

# ==========================================
# 2. Xray Downloader Stage (Надежный метод)
# ==========================================
FROM alpine:latest AS xray-fetcher
WORKDIR /xray
RUN apk add --no-cache curl unzip
RUN curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip xray.zip && \
    rm xray.zip

# ==========================================
# 3. core Build Stage
# ==========================================
FROM rust:1.91slim AS core
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev libsqlite3-dev && rm -rf /var/lib/apt/lists/*
COPY core/ .
RUN mkdir -p static
COPY --from=web /app/dist/web/browser ./static
RUN RUSTFLAGS=-Awarnings cargo build --release

# ==========================================
# 4. Final Runtime Stage
# ==========================================
FROM ubuntu:24.04
WORKDIR /app

RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

ENV XDG_CONFIG_HOME=/app/config
RUN mkdir -p /app/config

RUN mkdir -p /usr/share/xray

COPY --from=xray-fetcher /xray/xray /usr/bin/xray
COPY --from=xray-fetcher /xray/geoip.dat /usr/share/xray/geoip.dat
COPY --from=xray-fetcher /xray/geosite.dat /usr/share/xray/geosite.dat

ENV XRAY_LOCATION_ASSET=/usr/share/xray
# ----------------------

COPY --from=core /app/target/release/server ./core
COPY --from=core /app/static ./static

EXPOSE 8400
CMD ["./core"]
