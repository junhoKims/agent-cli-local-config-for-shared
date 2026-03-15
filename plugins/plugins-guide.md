# 🔌 Plugins 가이드

Plugins의 설치 및 제거, 사용 방법에 대한 가이드

---

## 📦 Plugin 리스트

| 플러그인명 | 설명 |
|-----------|------|
| 🦸 `superpowers` | AI 에이전트의 워크플로우를 강화하는 Skills 모음 — 브레인스토밍, 디버깅, TDD, 코드 리뷰, 계획 수립 등 |

---

## 🦸 superpowers Skills 리스트

| 스킬명 | 설명 |
|--------|------|
| 🧠 `brainstorming` | 구현 전 창의적 작업(기능 생성·컴포넌트 구축·동작 수정) 시 사용자 의도와 요구사항 탐색 |
| 🚀 `dispatching-parallel-agents` | 공유 상태나 순차 의존성 없이 독립적으로 처리 가능한 2개 이상의 작업을 병렬로 처리 |
| 📋 `executing-plans` | 리뷰 체크포인트를 포함한 별도 세션에서 작성된 구현 계획 실행 |
| 🏁 `finishing-a-development-branch` | 구현 완료 후 merge·PR·정리 등 개발 브랜치 통합 방식 결정 및 완료 |
| 👀 `receiving-code-review` | 코드 리뷰 피드백 수신 시 기술적 엄밀성과 검증을 기반으로 제안 구현 |
| 🔍 `requesting-code-review` | 작업 완료·주요 기능 구현·병합 전 요구사항 충족 여부 검증 |
| 🤖 `subagent-driven-development` | 현재 세션에서 독립적인 태스크를 포함한 구현 계획을 서브에이전트로 실행 |
| 🐛 `systematic-debugging` | 버그·테스트 실패·예상치 못한 동작 발생 시 수정 제안 전 체계적 원인 분석 |
| 🧪 `test-driven-development` | 기능 구현 또는 버그 수정 시 구현 코드 작성 전 TDD 워크플로우 적용 |
| 🌿 `using-git-worktrees` | 현재 워크스페이스에서 격리가 필요한 기능 작업 시작 또는 구현 계획 실행 전 사용 |
| ⚡ `using-superpowers` | 모든 대화 시작 시 사용 — Skills 탐색 및 사용 방법 확립 |
| ✅ `verification-before-completion` | 작업 완료·수정·통과를 선언하기 전 검증 명령 실행 및 결과 확인 |
| 📝 `writing-plans` | 다단계 작업의 명세·요구사항이 있을 때 코드 수정 전 구현 계획 수립 |
| 🛠️ `writing-skills` | 새 스킬 생성·기존 스킬 편집·배포 전 스킬 동작 검증 |

---

## 🔗 의존성 (중요)

Global(User scope)의 Plugin은 아래 링크에 크게 의존

> <https://github.com/obra/superpowers>

---

## 🚀 설치

마켓플레이스를 설치한다

```bash
/plugin marketplace add obra/superpowers-marketplace
```

### 🗑️ 제거

- claude-code 안에서 제거
