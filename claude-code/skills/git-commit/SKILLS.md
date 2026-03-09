---
name: git-commit
description: 'Conventional commit 메시지 분석, 지능형 staging, 메시지 생성을 통한 git commit 실행. 사용자가 변경사항 커밋, git commit 생성, 또는 "/commit"을 언급할 때 사용. 지원 기능: (1) 변경사항에서 type과 scope 자동 감지, (2) diff에서 conventional commit 메시지 생성, (3) type/scope/description 재정의 가능한 대화형 commit, (4) 논리적 그룹핑을 위한 지능형 파일 staging'
allowed-tools: Bash
---

# Conventional Commits 기반 Git Commit

## 개요

Conventional Commits 규격을 사용하여 표준화된 의미론적 git commit을 생성합니다. 실제 diff를 분석하여 적절한 type, scope, 메시지를 결정합니다.

## Conventional Commit 형식

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type       | 용도                 |
|------------|--------------------|
| `feat`     | 새로운 기능             |
| `fix`      | 버그 수정              |
| `docs`     | 문서 변경만 해당          |
| `style`    | 포맷/스타일 (로직 변경 없음)  |
| `refactor` | 코드 리팩토링 (기능/수정 아님) |
| `perf`     | 성능 개선              |
| `test`     | 테스트 추가/수정          |
| `build`    | 빌드 시스템/의존성         |
| `ci`       | CI/설정 변경           |
| `chore`    | 유지보수/기타            |
| `revert`   | commit 되돌리기        |

## 워크플로우

### 1. Diff 분석

```bash
# staged된 파일이 있으면 staged diff 사용
git diff --staged

# staged된 것이 없으면 working tree diff 사용
git diff

# 상태도 확인
git status --porcelain
```

### 2. 파일 Stage (필요시)

staged된 것이 없거나 변경사항을 다르게 그룹핑하고 싶을 때:

```bash
# 특정 파일 stage
git add path/to/file1 path/to/file2

# 패턴으로 stage
git add *.test.*
git add src/components/*

# 대화형 staging
git add -p
```

**절대 시크릿을 커밋하지 마세요** (.env, credentials.json, 개인 키).

### 3. Commit 메시지 생성

diff를 분석하여 다음을 결정:

- **Type**: 어떤 종류의 변경인가?
- **Scope**: 어떤 영역/모듈이 영향을 받는가?
- **Description**: 변경 내용의 한 줄 요약 (현재 시제, 명령형, 72자 미만)

### 4. Commit 실행

```bash
# 한 줄
git commit -m "<type>[scope]: <description>"

# body/footer 포함 여러 줄
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<optional body>

<optional footer>
EOF
)"
```

## 모범 사례

- commit 당 하나의 논리적 변경
- 현재 시제 사용: "추가" ("추가함" 아님)
- 명령형 사용: "버그 수정" ("버그 수정함" 아님)
- 이슈 참조: `Closes #123`, `Refs #456`
- description은 72자 미만 유지

## Git 안전 규칙

- 절대 git config를 수정하지 않음
- 명시적 요청 없이 절대 파괴적 명령어 (--force, hard reset) 실행하지 않음
- 사용자 요청 없이 절대 hook을 건너뛰지 않음 (--no-verify)
- 절대 main/master에 force push하지 않음
- hook으로 인해 commit이 실패하면, 문제를 수정하고 새로운 commit을 생성 (amend 하지 않음)

## Description에 특정 메세지 제거

- "Co-Authored-By: Claude [model] [version] <noreply@anthropic.com>" 절대 노출하지 말것