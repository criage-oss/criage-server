# Criage Repository Server

[![Go Reference](https://pkg.go.dev/badge/github.com/criage-oss/criage-server.svg)](https://pkg.go.dev/github.com/criage-oss/criage-server)

Сервер репозитория для хранения и управления пакетами Criage.

[🇬🇧 English Version](README.md) | 🇷🇺 Русская версия

## Возможности

- 📦 **Хранение пакетов** - автоматическое индексирование загружаемых пакетов
- 🔍 **Поиск пакетов** - быстрый поиск по названию, описанию, автору
- 📊 **Статистика** - отслеживание скачиваний и популярности пакетов
- 🌐 **REST API** - полноценный API для интеграций
- 🚀 **Веб интерфейс** - простой веб интерфейс для просмотра пакетов
- 🔒 **Безопасность** - аутентификация для загрузки пакетов

## Установка и запуск

### Требования

- Go 1.24.4 или выше
- Git

### Сборка и запуск

```bash
# Клонируем репозиторий
git clone <repository-url>
cd criage/repository

# Устанавливаем зависимости
go mod tidy

# Собираем сервер
go build -o criage-repository

# Запускаем с конфигурацией по умолчанию
./criage-repository

# Или с указанием файла конфигурации
./criage-repository -config /path/to/config.json
```

Сервер будет доступен по адресу: `http://localhost:8080`

## Конфигурация

При первом запуске создается файл конфигурации `config.json`:

```json
{
  "port": 8080,
  "storage_path": "./packages",
  "index_path": "./index.json",
  "upload_token": "your-secret-token",
  "max_file_size": 104857600,
  "allowed_formats": [
    "tar.zst",
    "tar.lz4", 
    "tar.xz",
    "tar.gz",
    "zip"
  ],
  "enable_cors": true,
  "log_level": "info"
}
```

### Параметры конфигурации

- `port` - порт HTTP сервера (по умолчанию 8080)
- `storage_path` - путь к директории с пакетами (./packages)
- `index_path` - путь к файлу индекса (./index.json)
- `upload_token` - токен для загрузки пакетов
- `max_file_size` - максимальный размер загружаемого файла в байтах
- `allowed_formats` - разрешенные форматы архивов
- `enable_cors` - включить CORS заголовки
- `log_level` - уровень логирования

## API Endpoints

### Информация о репозитории

```
GET /api/v1/
```

Возвращает информацию о репозитории, количество пакетов и поддерживаемые форматы.

### Список пакетов

```
GET /api/v1/packages?page=1&limit=20
```

Возвращает список всех пакетов с пагинацией.

### Информация о пакете

```
GET /api/v1/packages/{name}
```

Возвращает подробную информацию о пакете со всеми версиями.

### Информация о версии

```
GET /api/v1/packages/{name}/{version}
```

Возвращает информацию о конкретной версии пакета.

### Поиск пакетов

```
GET /api/v1/search?q={query}&limit=20
```

Выполняет поиск пакетов по названию, описанию, ключевым словам.

### Скачивание пакета

```
GET /api/v1/download/{name}/{version}/{filename}
```

Скачивает файл пакета. Автоматически увеличивает счетчик скачиваний.

### Загрузка пакета

```
POST /api/v1/upload
Headers: Authorization: Bearer {token}
Content-Type: multipart/form-data
```

Загружает новый пакет. Требует токен авторизации.

### Статистика

```
GET /api/v1/stats
```

Возвращает статистику репозитория: популярные пакеты, количество скачиваний, разбивка по лицензиям и авторам.

### Обновление индекса

```
POST /api/v1/refresh
Headers: Authorization: Bearer {token}
```

Принудительно обновляет индекс пакетов.

## Использование

### Загрузка пакета через curl

```bash
curl -X POST \
  -H "Authorization: Bearer your-secret-token" \
  -F "package=@test-package-1.0.0.tar.zst" \
  http://localhost:8080/api/v1/upload
```

### Поиск пакетов

```bash
curl "http://localhost:8080/api/v1/search?q=test"
```

### Скачивание пакета

```bash
curl -O "http://localhost:8080/api/v1/download/test-package/1.0.0/test-package-1.0.0.tar.zst"
```

## Интеграция с criage

Для публикации пакетов в репозиторий используйте команду:

```bash
criage publish --registry http://localhost:8080 --token your-secret-token
```

Для установки пакетов из репозитория:

```bash
criage config set registry http://localhost:8080
criage install package-name
```

## Структура данных

### Индекс репозитория

Сервер автоматически поддерживает JSON индекс всех пакетов в файле `index.json`:

```json
{
  "last_updated": "2024-01-15T10:30:45Z",
  "total_packages": 25,
  "packages": {
    "package-name": {
      "name": "package-name",
      "description": "Package description",
      "author": "Author Name",
      "license": "MIT",
      "versions": [
        {
          "version": "1.0.0",
          "files": [
            {
              "os": "linux",
              "arch": "amd64",
              "format": "tar.zst",
              "filename": "package-1.0.0-linux-amd64.tar.zst",
              "size": 1024,
              "checksum": "sha256:..."
            }
          ]
        }
      ]
    }
  }
}
```

### Извлечение метаданных

Сервер автоматически извлекает метаданные из загружаемых пакетов criage:

- Манифест пакета (`criage.yaml`)
- Манифест сборки (`build.json`)
- Информация о сжатии
- Зависимости и описания

## Развертывание

### Docker

```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .
RUN go mod tidy
RUN go build -o criage-repository

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/criage-repository .
COPY --from=builder /app/web ./web/

EXPOSE 8080
CMD ["./criage-repository"]
```

### Systemd Service

```ini
[Unit]
Description=Criage Repository Server
After=network.target

[Service]
Type=simple
User=criage
WorkingDirectory=/opt/criage-repository
ExecStart=/opt/criage-repository/criage-repository -config /etc/criage/config.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Мониторинг

Сервер логирует все HTTP запросы и операции с пакетами. Логи включают:

- HTTP запросы с временем выполнения
- Загрузку новых пакетов
- Ошибки индексации
- Статистику скачиваний

## Безопасность

- Аутентификация через Bearer токены
- Ограничение размера загружаемых файлов
- Проверка форматов файлов
- CORS поддержка для веб интерфейсов

## Производительность

- Асинхронное обновление индекса
- Кеширование метаданных пакетов
- Эффективный поиск по индексу
- Поддержка HTTP Keep-Alive

## Лицензия

MIT License - см. файл LICENSE для подробностей.
