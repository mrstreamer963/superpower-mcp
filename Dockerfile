# Используем легковесный образ Node.js
FROM node:18-alpine

# Устанавливаем Git (он необходим для работы сервера)
RUN apk add --no-cache git

# Создаем рабочую директорию
WORKDIR /app

# Копируем файлы конфигурации зависимостей
COPY package*.json ./

# Устанавливаем только production-зависимости
RUN npm install --production

# Копируем исходный код сервера
COPY superpowers-mcp.js ./

COPY ./skills ./skills

# Создаем стандартные директории для хранения навыков
# RUN mkdir -p /root/.augment/superpowers /root/.augment/skills

# По умолчанию запускаем сервер через stdio
CMD ["node", "superpowers-mcp.js"]