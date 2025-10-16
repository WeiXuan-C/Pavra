# ===== Build stage =====
FROM dart:3.5.0 AS build
WORKDIR /app  # 容器里的工作目录
COPY . .      # copy 当前 context (pavra_server_server/) 到 /app
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# ===== Final stage =====
FROM debian:bookworm-slim
WORKDIR /app

# 复制 build stage 的 server 可执行文件
COPY --from=build /app/bin/server server
RUN chmod +x server

# 复制配置文件和其他资源
COPY --from=build /app/config/ config/
COPY --from=build /app/web/ web/
COPY --from=build /app/migrations/ migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

EXPOSE 8080

# Use shell form to allow environment variable expansion
CMD ./server --port=${PORT:-8080} --mode=production --server-id=default --logging=normal --role=monolith
