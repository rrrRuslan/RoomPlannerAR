#!/usr/bin/env bash
# PostToolUse hook для Edit|Write|NotebookEdit: швидка перевірка зміненого файлу.
# Визначає тип файлу за шляхом і запускає відповідний легкий лінт. Помилка → exit 2,
# і Claude бачить stderr як зворотний зв'язок. Інструменти, яких ще немає (модуль не
# створено, лінтер не встановлено), тихо пропускаються.
set -uo pipefail

input="$(cat)"
path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$input")"
cwd="$(jq -r '.cwd // ""' <<<"$input")"
[[ -z "$path" ]] && exit 0
[[ "$path" != /* ]] && path="${cwd:-$PWD}/$path"
[[ -f "$path" ]] || exit 0

root="$(git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -z "$root" ]] && exit 0
root="$(cd "$root" && pwd -P)"
path="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
rel="${path#"$root"/}"

fail() { echo "quick-check ($rel):" >&2; echo "$1" >&2; exit 2; }
have() { command -v "$1" >/dev/null 2>&1; }

case "$rel" in
  openspec/changes/archive/*) ;;
  openspec/changes/*/*)
    change="${rel#openspec/changes/}"; change="${change%%/*}"
    # Перевіряємо, лише коли зміна вже має proposal (під час генерації артефактів — пропуск).
    if have openspec && [[ -f "$root/openspec/changes/$change/proposal.md" && -f "$root/openspec/changes/$change/tasks.md" ]]; then
      out="$(cd "$root" && openspec validate "$change" --strict 2>&1)" || fail "$out"
    fi ;;
  openspec/specs/*)
    if have openspec; then out="$(cd "$root" && openspec validate --specs --strict 2>&1)" || fail "$out"; fi ;;
  *.dart)
    if have dart; then
      out="$(dart format --output=none --set-exit-if-changed "$path" 2>&1)" || fail "Потрібне форматування: dart format $rel"$'\n'"$out"
      if [[ -f "$root/flutter_app/pubspec.yaml" && "$rel" == flutter_app/* ]]; then
        out="$(cd "$root/flutter_app" && dart analyze --fatal-infos "$path" 2>&1)" || fail "$out"
      fi
    fi ;;
  *.kt|*.kts)
    if have ktlint; then out="$(ktlint --relative "$path" 2>&1)" || fail "$out"; fi ;;
  contracts/*.yaml|contracts/*.yml)
    if have spectral; then out="$(spectral lint "$path" 2>&1)" || fail "$out"; fi ;;
  *.json)
    out="$(jq empty "$path" 2>&1)" || fail "Невалідний JSON: $out" ;;
  .github/workflows/*.yml|.github/workflows/*.yaml)
    if have actionlint; then out="$(actionlint "$path" 2>&1)" || fail "$out"; fi ;;
  *.sh)
    out="$(bash -n "$path" 2>&1)" || fail "$out" ;;
esac
exit 0
