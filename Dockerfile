# Многоэтапная сборка для минимизации размера образа
FROM golang:1.24.4-alpine AS builder

# Устанавливаем необходимые пакеты для сборки
RUN apk add --no-cache git ca-certificates

# Создаем рабочую директорию
WORKDIR /build

# Копируем go.mod и go.sum для кеширования зависимостей
COPY go.mod go.sum ./

# Загружаем зависимости
RUN go mod download

# Копируем исходный код
COPY . .

# Собираем приложение
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X main.version=1.0.0" -o criage-server .

# Финальный образ
FROM alpine:latest

# Устанавливаем ca-certificates для HTTPS запросов
RUN apk add --no-cache ca-certificates tzdata

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S criage && \
    adduser -u 1001 -S criage -G criage

# Создаем рабочую директорию
WORKDIR /app

# Копируем исполняемый файл из стадии сборки
COPY --from=builder /build/criage-server /usr/local/bin/criage-server

# Копируем конфигурационные файлы и веб-интерфейс
COPY config.json /app/config.json
COPY web/ /app/web/

# Создаем директории для пакетов и данных
RUN mkdir -p /app/packages /app/data && \
    chown -R criage:criage /app

# Переключаемся на непривилегированного пользователя
USER criage

# Переменные окружения
ENV CRIAGE_SERVER_VERSION=1.0.0
ENV CRIAGE_SERVER_CONFIG=/app/config.json
ENV CRIAGE_SERVER_PORT=8080

# Открываем порт для HTTP сервера
EXPOSE 8080

# Том для данных пакетов
VOLUME ["/app/packages", "/app/data"]

# Проверка здоровья
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Точка входа
ENTRYPOINT ["criage-server"]

# Команда по умолчанию
CMD ["-config", "/app/config.json"]

# Метаданные образа
LABEL maintainer="Criage Team"
LABEL version="1.0.0"
LABEL description="HTTP сервер репозитория пакетов Criage"
LABEL org.opencontainers.image.source="https://github.com/criage-oss/criage-server"
LABEL org.opencontainers.image.documentation="https://criage.ru/repository-server.html"
LABEL org.opencontainers.image.licenses="MIT"
LABEL dependencies="criage-common@1.0.0"