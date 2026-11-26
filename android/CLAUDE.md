# android/ — правила для агентів

Нативний Android за підходом Now in Android: Compose + Material 3, Hilt, Retrofit (клієнт з OpenAPI), Room, Coroutines/Flow. Повні стандарти: [docs/PROJECT.md](../docs/PROJECT.md), розділи 10 і 11.1.

> Модуль ще не створено (фаза 2). Команди нижче запрацюють після скелета.

## Хто куди пише
- `android-dev` — усе в `android/`, крім `core/ar` і `feature/room-scan`.
- `ar-dev` — `core/ar`, `feature/room-scan`.
- Згенерований клієнт (`core/network/build/generated/`) вручну не редагується.

## Модулі
`app` · `core:{network,data,database,designsystem,ui,ar,testing}` · `feature:<name>`. Конвенції в `build-logic`, версії в `gradle/libs.versions.toml`.

## Правила
- Екран: `XxxRoute` (ViewModel) + stateless `XxxScreen(uiState, onAction)` + `@Preview` для кожного стану.
- `UiState` — sealed interface або immutable data class; ViewModel віддає `StateFlow`.
- Жодної логіки в Composable, жодних мережевих викликів з ViewModel — лише через репозиторій / use case.
- Рядки лише в `strings.xml` (uk, en). Доступність: `contentDescription`, 48dp, великий шрифт.
- Кожен стан екрана — Roborazzi-тест; ViewModel — JUnit + MockK + Turbine.
- AR не працює в емуляторі: позначай сценарії для фізичного пристрою.

## Команди
| Дія | Команда |
| --- | --- |
| Збірка debug | `./gradlew :app:assembleDebug` |
| Юніт-тести | `./gradlew testDebugUnitTest` |
| Скріншот-тести | `./gradlew verifyRoborazziDebug` |
| Лінт | `./gradlew ktlintCheck detekt lintDebug` |
| Покриття | `./gradlew jacocoTestReport` |

Для емулятора й падінь — skills плагіна adb-mcp: `build-and-test`, `driving`, `crash-triage`.
