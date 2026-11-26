# backend/ — правила для агентів

Модульний моноліт: Kotlin 2.x, Spring Boot 3, PostgreSQL 16 + Flyway, Redis, Testcontainers. Повні стандарти: [docs/PROJECT.md](../docs/PROJECT.md), розділ 9. Пише сюди лише `backend-dev`.

> Модуль ще не створено (фаза 2). Команди нижче запрацюють після скелета.

## Структура
`src/main/kotlin/<pkg>/common/` — помилки, безпека, конфіг · `feature/<name>/{api,domain,data}/`.

## Правила
- Реалізуй згенеровані інтерфейси з `contracts/openapi.yaml` (openapi-generator `kotlin-spring`, `interfaceOnly=true`); контракт не змінюй.
- Контролер лише мапить DTO і викликає сервіс; бізнес-логіка в `domain/`.
- Міграції Flyway лише нові, не редагуються після merge.
- Помилки — Problem Details (RFC 9457) з контракту; валідація на вході й у домені.
- Секрети тільки через env; у репо лише `.env.example`. Логи JSON без персональних даних.
- Інтеграційні тести через Testcontainers (не H2); контрактні тести відповідей vs `openapi.yaml`.
- `RoomModel` валідується за `contracts/room-model.schema.json`.
- Покриття `domain/` ≥ 80%; кожен ендпоінт — інтеграційний тест на успіх і на кожну задокументовану помилку.

## Команди
| Дія | Команда |
| --- | --- |
| Збірка | `./gradlew :backend:build` |
| Тести | `./gradlew :backend:test` |
| Лінт | `./gradlew :backend:ktlintCheck :backend:detekt` |
| Локальний запуск | `docker compose -f infra/docker/compose.dev.yml up` |
