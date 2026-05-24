# Superpowers MCP Server

MCP (Model Context Protocol) сервер, который подключает библиотеку навыков [Superpowers](https://github.com/obra/superpowers) к любому MCP-совместимому ассистенту (Claude, Augment, и т.д.). Навыки — это экспертные рабочие процессы, улучшающие результаты AI-ассистентов.

## Что это?

Сервер предоставляет навыки Superpowers в виде инструментов MCP.

**Доступные инструменты:**
- `find_skills` — показать список всех доступных навыков
- `use_skill` — загрузить конкретный навык для использования

## Быстрый старт

### 1. Сборка Docker-образа

```bash
git clone https://github.com/mrstreamer963/superpower-mcp.git
cd superpower-mcp
make build
```

Или вручную:

```bash
docker build -t superpower-mcp:latest .
```

### 2. Настройка MCP-клиента

Добавьте сервер в конфигурацию вашего MCP-клиента.

**Для Claude Desktop (`claude_desktop_config.json`):**

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "superpower-mcp:latest"
      ]
    }
  }
}
```

**Для Augment CLI (`~/.augment/settings.json`):**

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "superpower-mcp:latest"
      ]
    }
  }
}
```

> **Важно:** Используйте флаги `-i --rm` (без `-t`), чтобы сервер работал в stdio-режиме, который требуется для MCP.

### 3. Перезапустите клиент

Перезапустите MCP-клиент, чтобы загрузить новый сервер.

### 4. Проверка

Спросите ассистента:

```
"Какие навыки доступны?"
```

Вы должны увидеть список навыков из библиотеки Superpowers.

## Использование

### Поиск навыков

Попросите ассистента показать доступные навыки:

```
"Покажи доступные навыки"
"Какие навыки ты можешь использовать?"
```

Или используйте инструмент напрямую:

```
find_skills()
```

### Использование навыков

Загрузите навык по имени:

```
"Используй навык brainstorming"
"Загрузи навык test-driven-development"
```

Или напрямую:

```
use_skill("superpowers:brainstorming")
use_skill("superpowers:test-driven-development")
```

### Соглашение об именах

- **Навыки Superpowers**: `superpowers:имя-навыка` (из встроенного репозитория)
- **Личные навыки**: `моё-имя-навыка` (добавляются в образ)

## Создание личных навыков

Если вы собрали образ с собственными навыками (см. раздел про сборку), создайте структуру в `skills/ваш-навык/SKILL.md`:

```markdown
---
name: my-custom-skill
description: Используйте, когда нужно сделать что-то конкретное
---

# Мой навык

## Назначение
[Опишите, что делает этот навык]

## Когда использовать
[Опишите, когда использовать этот навык]

## Процесс
1. [Шаг 1]
2. [Шаг 2]
3. [Шаг 3]
```

Личные навыки с тем же именем, что и навыки Superpowers, переопределяют их.

## Архитектура

Проект использует overlay-подход:

- **Docker-образ** — содержит как встроенный репозиторий Superpowers, так и опциональные личные навыки из директории `./skills/` при сборке
- **MCP-сервер** — запускается внутри контейнера, общается через stdio
- **Клиент** — любой MCP-совместимый ассистент (Claude, Augment, и т.д.)

Dockerfile копирует `./skills` из репозитория прямо в образ, поэтому все навыки, добавленные в эту директорию, будут автоматически доступны.

## Управление

### Обновление навыков Superpowers

```bash
git pull                    # получить актуальный код
git submodule update --init --recursive  # обновить встроенный репозиторий superpowers
make build                  # пересобрать образ
```

После этого перезапустите MCP-клиент.

### Удаление

```bash
docker rmi superpower-mcp:latest
```

Не забудьте удалить конфигурацию сервера из настроек вашего MCP-клиента.

## Пересборка с личными навыками

1. Добавьте свои навыки в директорию `./skills/мой-навык/SKILL.md`
2. Пересоберите образ:
   ```bash
   make build
   ```
3. Личные навыки будут доступны через `find_skills` и `use_skill`

## Решение проблем

### Сервер не отображается

1. Проверьте, что образ собран: `docker images superpower-mcp`
2. Проверьте конфигурацию MCP-клиента — команда должна быть `docker run -i --rm superpower-mcp:latest` (без `-t`)
3. Проверьте, что Docker доступен: `docker --version`
4. Перезапустите MCP-клиент полностью

### Навыки не загружаются

1. Проверьте, что в образе есть навыки: `docker run --rm superpower-mcp:latest ls /app/skills/superpowers/skills`
2. Пересоберите образ после обновления подмодуля: `git submodule update --init --recursive && make build`

### Проверка работоспособности

```bash
# Проверить, что сервер отвечает на stdio
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm superpower-mcp:latest
```

Этот запрос должен вернуть JSON со списком инструментов (`find_skills` и `use_skill`).

## Ссылки

- **Superpowers Repository**: https://github.com/obra/superpowers
- **Blog Post**: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)
- **Model Context Protocol**: https://modelcontextprotocol.io/

## Вклад

Issues и pull request'ы приветствуются!

## Лицензия

MIT License — подробнее в файле LICENSE.

Репозиторий Superpowers имеет собственную лицензию. См. https://github.com/obra/superpowers.

## Благодарности

- **Superpowers** by [Jesse Vincent](https://github.com/obra)
- **MCP Server** [интеграция](https://github.com/jmcdice/superpower-mcp/)