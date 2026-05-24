# --- Этап 1: Сборка и установка зависимостей ---
FROM node:18-alpine AS builder

# Устанавливаем git, необходимый для работы install.sh и загрузки скиллов
RUN apk add --no-cache git bash

WORKDIR /app

# Копируем файлы конфигурации npm
COPY package*.json ./

# Устанавливаем зависимости (включая dev-зависимости, если нужны для сборки)
RUN npm i

# Копируем остальные файлы исходного кода
COPY . .

WORKDIR /app

# Создаем структуру директорий в домашней папке (~/.augment/)
# и клонируем репозиторий superpowers, симулируя работу install.sh
# RUN mkdir -p /root/.augment/skills && \
#     git clone https://github.com/root/.augment/superpowers

# MCP-серверы общаются через стандартные потоки ввода-вывода (stdio)
ENTRYPOINT ["node", "superpowers-mcp.js"]
