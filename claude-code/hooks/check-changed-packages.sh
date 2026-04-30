#!/bin/bash
# Stop - 변경된 패키지에 대해 lint/type/test 검증 실행

set -uo pipefail

cd "$CLAUDE_PROJECT_DIR"

# pnpm 모노레포가 아니면 스킵
if [ ! -f "pnpm-workspace.yaml" ] || [ ! -d "packages" ]; then
  exit 0
fi

# 변경된 파일 목록에서 패키지 디렉토리 추출 (중복 제거)
CHANGED_PKGS=$(git diff --name-only HEAD 2>/dev/null | sed -n 's|^packages/\([^/]*\)/.*|\1|p' | sort -u)

# unstaged 변경사항도 포함
UNSTAGED_PKGS=$(git diff --name-only 2>/dev/null | sed -n 's|^packages/\([^/]*\)/.*|\1|p' | sort -u)

# untracked 파일도 포함
UNTRACKED_PKGS=$(git ls-files --others --exclude-standard 2>/dev/null | sed -n 's|^packages/\([^/]*\)/.*|\1|p' | sort -u)

# 모든 변경된 패키지 병합
ALL_PKGS=$(echo -e "${CHANGED_PKGS}\n${UNSTAGED_PKGS}\n${UNTRACKED_PKGS}" | sort -u | grep -v '^$')

if [ -z "$ALL_PKGS" ]; then
  exit 0
fi

HAS_ERROR=0

for PKG_DIR in $ALL_PKGS; do
  PKG_JSON="packages/$PKG_DIR/package.json"

  if [ ! -f "$PKG_JSON" ]; then
    continue
  fi

  # package.json에서 패키지명 추출
  PKG_NAME=$(node -e "console.log(require('./$PKG_JSON').name)" 2>/dev/null)

  if [ -z "$PKG_NAME" ]; then
    continue
  fi

  # 각 검증 스크립트를 존재 여부 확인 후 실행
  for CHECK in check:lint check:type check:test; do
    # package.json에 해당 스크립트가 있는지 확인
    HAS_SCRIPT=$(node -e "const p = require('./$PKG_JSON'); console.log(p.scripts && p.scripts['$CHECK'] ? 'yes' : 'no')" 2>/dev/null)

    if [ "$HAS_SCRIPT" = "yes" ]; then
      echo "[$PKG_NAME] $CHECK 실행 중..."
      if ! pnpm --filter "$PKG_NAME" "$CHECK" 2>&1; then
        echo "[$PKG_NAME] $CHECK 실패" >&2
        HAS_ERROR=1
      fi
    fi
  done
done

if [ "$HAS_ERROR" -ne 0 ]; then
  echo "검증 실패: 위 오류를 확인하고 수정해주세요." >&2
  exit 1
fi
