# Build stage
FROM dart:3.5.0 AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:bookworm-slim
WORKDIR /app

COPY --from=build /app/bin/server server
RUN chmod +x server

COPY --from=build /app/config/ config/
COPY --from=build /app/web/ web/
COPY --from=build /app/migrations/ migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "-c", "./server --port=$PORT --mode=production --server-id=default --logging=normal --role=monolith"]
