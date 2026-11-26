#!/usr/bin/env bash
# PreToolUse hook для Edit|Write|NotebookEdit.
# Блокує (exit 2) запис у згенерований код і запис субагента поза каталогами його ролі
# (docs/PROJECT.md, розділ 6). Роль береться з поля agent_type вхідного JSON:
# воно є, лише коли виклик робить субагент. Основна сесія (техлід) і вбудовані
# агенти (Explore, Plan, general-purpose) обмежуються лише забороною згенерованого коду.
#
# Обмеження: hook бачить тільки інструменти Edit/Write/NotebookEdit. Запис через Bash
# він не ловить — тому dev-агентам Bash дається лише для збірок і тестів (див. файли агентів).
set -euo pipefail

input="$(cat)"
agent="$(jq -r '.agent_type // ""' <<<"$input")"
path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$input")"
cwd="$(jq -r '.cwd // ""' <<<"$input")"

[[ -z "$path" ]] && exit 0
[[ "$path" != /* ]] && path="${cwd:-$PWD}/$path"

# Корінь git-репозиторію (або worktree), до якого належить файл. Для нового файлу
# піднімаємось до першого наявного каталогу.
dir="$(dirname "$path")"
while [[ ! -d "$dir" && "$dir" != "/" ]]; do dir="$(dirname "$dir")"; done
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
root="$(cd "$root" 2>/dev/null && pwd -P || true)"
dir_real="$(cd "$dir" && pwd -P)"
path="$dir_real/${path#"$dir"/}"

# Поза репозиторієм (scratchpad, /tmp) — не наша зона відповідальності.
[[ -z "$root" || "$path" != "$root"/* ]] && exit 0
rel="${path#"$root"/}"

deny() {
  echo "guard-paths: запис у '$rel' заборонено${agent:+ для агента '$agent'}. $1" >&2
  exit 2
}

# 1. Згенерований код — нікому.
case "$rel" in
  flutter_app/packages/api_client/*|*.g.dart|*.freezed.dart|*/build/generated/*|build/generated/*)
    deny "Це згенерований код: змініть contracts/ або генератор і перегенеруйте." ;;
esac

# 2. Основна сесія і вбудовані агенти — без обмежень за ролями.
[[ -z "$agent" ]] && exit 0

# Відмітка виконаних задач у tasks.md активної зміни дозволена всім виконавцям.
tasks_md() { [[ "$rel" == openspec/changes/*/tasks.md ]]; }
# Тестові каталоги (для qa).
test_path() {
  case "$rel" in
    */test/*|*/tests/*|*/testing/*|*/androidTest/*|*/testDebug/*|*/integration_test/*|*/patrol_test/*|*/test_driver/*|.maestro/*|*/.maestro/*|docs/qa/*) return 0 ;;
  esac
  return 1
}
ar_path() {
  case "$rel" in
    android/core/ar/*|android/feature/room-scan/*|flutter_app/packages/ar_bridge/*) return 0 ;;
  esac
  return 1
}

case "$agent" in
  spec-analyst)
    case "$rel" in openspec/changes/*|docs/qa/parity-matrix.md|docs/qa/parity/*) exit 0 ;; esac ;;
  architect)
    case "$rel" in contracts/*|docs/adr/*|openspec/changes/*|docs/qa/parity-matrix.md|CLAUDE.md|*/CLAUDE.md) exit 0 ;; esac ;;
  backend-dev)
    tasks_md && exit 0
    case "$rel" in backend/*) exit 0 ;; esac ;;
  android-dev)
    tasks_md && exit 0
    ar_path && deny "AR-модулі належать ar-dev."
    case "$rel" in android/*) exit 0 ;; esac ;;
  flutter-dev)
    tasks_md && exit 0
    ar_path && deny "AR-плагін належить ar-dev."
    case "$rel" in flutter_app/*) exit 0 ;; esac ;;
  ar-dev)
    tasks_md && exit 0
    ar_path && exit 0 ;;
  ui-designer)
    case "$rel" in docs/design/*) exit 0 ;; esac ;;
  qa)
    tasks_md && exit 0
    test_path && exit 0 ;;
  docs-writer)
    case "$rel" in docs/adr/*) deny "ADR пише architect." ;; esac
    case "$rel" in docs/*|openspec/*|README.md|*/README.md|CHANGELOG.md) exit 0 ;; esac ;;
  devops)
    case "$rel" in infra/*|.github/*|docs/runbooks/*) exit 0 ;; esac ;;
  reviewer|security-reviewer)
    deny "Рецензенти лише звітують і не змінюють файли." ;;
  *)
    # Невідомий або вбудований агент (Explore, Plan, general-purpose) — як основна сесія.
    exit 0 ;;
esac

deny "Дозволені каталоги ролі — docs/PROJECT.md, розділ 6. Якщо зміна потрібна, поверни запит основній сесії або відповідному агенту."
