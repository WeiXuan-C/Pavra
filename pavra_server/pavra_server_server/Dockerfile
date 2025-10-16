# ===== Build stage =====
FROM dart:3.5.0 AS build

# 设置工作目录
WORKDIR /app

# 拷贝整个 build context（确保在 Railway UI 或本地 build 时，context 是 pavra_server_server）
COPY . .

# 安装依赖
RUN dart pub get

# 编译 Dart 项目为可执行文件
RUN dart compile exe bin/main.dart -o bin/server

# ===== Final stage =====
FROM debian:bookworm-slim

WORKDIR /app

# 复制编译好的 server 可执行文件
COPY --from=build /app/bin/server ./server
RUN chmod +x ./server

# 复制配置文件和资源（确保这些路径在 build context 内存在）
COPY --from=build /app/config ./config
COPY --from=build /app/web ./web
COPY --from=build /app/migrations ./migrations
COPY --from=build /app/lib/src/generated/protocol.yaml ./lib/src/generated/protocol.yaml

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["./server", "--mode=production", "--server-id=default", "--logging=normal", "--role=monolith"]
