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

# 安装 gettext-base (提供 envsubst 命令用于替换环境变量)
RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*

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

# 创建启动脚本
COPY <<'EOF' /app/start.sh
#!/bin/sh
set -e

echo "=== Generating passwords.yaml from environment variables ==="

# 生成 passwords.yaml
cat > /app/config/passwords.yaml << PWDEOF
production:
  database: "${PGPASSWORD}"
  redis: "${REDIS_PASSWORD}"
  serviceSecret: "${SERVICE_SECRET}"
  SUPABASE_URL: "${SUPABASE_URL}"
  SUPABASE_SERVICE_ROLE_KEY: "${SUPABASE_SERVICE_ROLE_KEY}"
PWDEOF

echo "=== Replacing environment variables in production.yaml ==="

# 只替换特定的环境变量，避免破坏 YAML 格式
# 使用 sed 替换特定变量
sed -i "s|\${PUBLIC_HOST}|${PUBLIC_HOST}|g" /app/config/production.yaml
sed -i "s|\${PGPASSWORD}|${PGPASSWORD}|g" /app/config/production.yaml
sed -i "s|\${REDIS_PASSWORD}|${REDIS_PASSWORD}|g" /app/config/production.yaml
sed -i "s|\${SERVICE_SECRET}|${SERVICE_SECRET}|g" /app/config/production.yaml

echo "=== Applying database migrations ==="

# 安装 PostgreSQL 客户端（如果需要）
if ! command -v psql > /dev/null 2>&1; then
    apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
fi

# 应用数据库迁移
PGPASSWORD="${PGPASSWORD}" psql -h postgres.railway.internal -U postgres -d postgres -f /app/migrations/20251013093515748/migration.sql || echo "Migration may have already been applied"

echo "=== Starting Serverpod server ==="

# 启动服务器
exec ./server --mode=production --server-id=default --logging=normal --role=monolith
EOF

RUN chmod +x /app/start.sh

# 启动命令
CMD ["/app/start.sh"]
