#!/bin/bash
# PostToolUse (Edit|Write) - 수정된 파일에 prettier 적용

set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

# prettier가 설치되어 있지 않으면 스킵
if ! npx prettier --version >/dev/null 2>&1; then
  exit 0
fi

# tool input에서 파일 경로 추출
FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 프로젝트 루트 기준 상대 경로로 변환
REL_PATH="${FILE_PATH#$CLAUDE_PROJECT_DIR/}"

# prettier 지원 확장자만 처리
case "$REL_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md|*.yaml|*.yml)
    npx prettier --write --experimental-cli --cache-location .prettiercache/prettier "$REL_PATH" 2>/dev/null || true
    ;;
esac
