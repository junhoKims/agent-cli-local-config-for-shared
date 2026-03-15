# 🧰 Skills 가이드

Skills의 설치 및 제거, 사용 방법에 대한 가이드

---

## 📦 Skill 리스트

| 스킬명 | 설명 |
|--------|------|
| 🌐 `agent-browser` | AI 에이전트용 브라우저 자동화 CLI — 웹 탐색, 폼 입력, 스크린샷, 데이터 추출 등 |
| 🎨 `canvas-design` | .png/.pdf 형식의 포스터·아트·디자인 결과물을 디자인 철학 기반으로 생성 |
| ⚡ `next-best-practices` | Next.js 모범 사례 — 파일 컨벤션, RSC 경계, 데이터 패턴, 이미지·폰트 최적화 등 |
| 🎭 `playwright-cli` | Playwright CLI로 웹 브라우저 상호작용·테스트·폼 입력·스크린샷 자동화 |
| 📈 `seo-audit` | 사이트 SEO 감사·진단 — 기술적 SEO, Core Web Vitals, 크롤링·인덱싱 이슈 분석 |
| 💅 `styled-components-best-practices` | React CSS-in-JS 개발을 위한 styled-components 모범 사례 |
| 🎨 `tailwind-design-system` | Tailwind CSS v4 기반 확장 가능한 디자인 시스템·컴포넌트 라이브러리 구축 |
| 🖼️ `ui-ux-pro-max` | UI/UX 설계 지원 — 161개 컬러 팔레트, 57개 폰트 페어링, 99개 UX 가이드라인 등 |
| 🧩 `vercel-composition-patterns` | Boolean prop 남발 없는 확장 가능한 React 컴포지션 패턴 (React 19 포함) |
| 🚀 `vercel-react-best-practices` | Vercel Engineering의 React·Next.js 성능 최적화 가이드라인 |
| 🖥️ `web-design-guidelines` | Web Interface Guidelines 준수 여부 — 접근성·UX·디자인 코드 리뷰 |
| 🧑‍💻 `webapp-testing` | Playwright로 로컬 웹 앱 기능 검증·UI 디버깅·스크린샷 캡처·로그 확인 |

---

## 🔗 의존성 (중요)

Global(User scope)의 Skill은 아래 링크에 크게 의존

> <https://skills.sh/>

---

## 🚀 설치

```bash
npx skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices
```

### 🗑️ 제거

```bash
npx skills remove https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices
```

---

## 🌍 User scope에 적용하기

1. `.agents` 디렉토리를 그대로 `~/`로 복사
2. 아래 명령어를 수행하여 `.claude/skills` 디렉토리에 심링크 복사

> `HOME`은 `~`의 주소 변수

### Claude Code에 적용

```bash
ls ${HOME}/.agents/skills/ | xargs -I{} ln -s ${HOME}/.agents/skills/{} ${HOME}/.claude/skills/{}
```

### Codex에 적용

```bash
ls ${HOME}/.agents/skills/ | xargs -I{} ln -s ${HOME}/.agents/skills/{} ${HOME}/.codex/skills/.system/{}
```
