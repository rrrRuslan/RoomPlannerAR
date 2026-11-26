# flutter_app/ — правила для агентів

Flutter stable, Dart 3: Riverpod (codegen), go_router, dio + клієнт `dart-dio` з OpenAPI, freezed, drift. Основний клієнт на iOS і другий на Android. Повні стандарти: [docs/PROJECT.md](../docs/PROJECT.md), розділи 11 і 11.1.

> Модуль ще не створено (фаза 2). Команди нижче запрацюють після скелета.

## Хто куди пише
- `flutter-dev` — усе в `flutter_app/`, крім `packages/api_client` (генерується) і `packages/ar_bridge`.
- `ar-dev` — `packages/ar_bridge` (Android-частина використовує `android/core/ar`, iOS — ARKit/RoomPlan).

## Структура
`lib/app/` · `lib/core/{network,storage,platform,ui}/` · `lib/features/<name>/{data,domain,presentation}/`.

## Правила
- Стан екрана — `AsyncValue` або freezed-union зі станами зі специфікації (loading, content, empty, error, offline).
- Віджети без бізнес-логіки; провайдери не викликають dio напряму — лише репозиторії.
- `*.g.dart`, `*.freezed.dart`, `api_client` не редагуються; генерація `dart run build_runner build -d`.
- Локалізація `flutter gen-l10n` (ARB uk, en). Платформні відмінності — у `core/platform/` і в специфікації.
- Кожен стан екрана — golden-тест.
- Підписування й публікація iOS/Android — лише техлід.

## Команди
| Дія | Команда |
| --- | --- |
| Залежності і генерація | `flutter pub get && dart run build_runner build -d` |
| Аналіз | `dart analyze && dart format --set-exit-if-changed .` |
| Тести | `flutter test --coverage` |
| Збірка Android | `flutter build apk --debug` |
| Збірка iOS | `flutter build ios --debug --no-codesign` |
