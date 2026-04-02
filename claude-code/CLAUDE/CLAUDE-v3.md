## 언어 및 커뮤니케이션 규칙

- 🗺 기본 응답 언어: 한국어
- 📋 코드 주석: 한국어로 작성
- ✨ 커밋 메시지: 컨벤션 규칙 링크를 참고하여 한국어로 작성 (https://www.conventionalcommits.org/en/v1.0.0/#summary)
- 🎨 문서화: 한국어로 작성
- 🧩 변수명/함수명: 영어 (코드 표준 준수)

## 코드 스타일

- 🗺 ES 모듈(import/export) 구문을 사용하고, CommonJS(require)는 사용하지 마십시오
- 📋 가능하면 import를 구조 분해하십시오 (예: import { foo } from 'bar')
- ✨ react 코드의 작업 시 @react-best-practices 스킬을 사용하세요
- 🎨 nextjs 코드의 작업 시 @nextjs-best-practices 스킬을 사용하세요
- 🧩 UI 작업 시 @ui-ux-pro-max, @web-design-guidelines 스킬을 사용하세요

## 워크플로우 (IMPORTANT)

- 🗺 계획 수립 및 코드 작성 시 @brainstorming 스킬을 사용하세요. 또한 모호한 부분을 질문하세요
- 📋 계획 작성 및 실행 시 @writing-plans, @executing-plans 스킬을 사용하세요
- ✨ 작업(구현) 사이에 타입 검사를 수행하고 @requesting-code-review 스킬을 사용하여 문제를 보고하세요
- 🎨 작업(구현)이 완료되면 @receiving-code-review 스킬을 사용하여 피드백하세요
- 🧩 모든 작업(구현)이 완료되면 finishing-a-development-branch 스킬을 사용하여 브랜치의 옵션 여부, 작업 트리를 질문하세요

## 문제(원인) 디버깅 및 수정

- 🗺 @systematic-debugging 스킬을 사용하여 디버깅하세요
- 📋 @verification-before-completion 스킬을 사용하여 문제가 실제로 해결되었는지 확인하세요

## 테스트

- 🗺 작업(구현) 시 @test-driven-development 스킬을 사용하여 개발하세요
- 📋 playwright-cli를 사용 시 @agent-browser
- 🧩 웹앱(webapp)을 테스트해야할 시 @webapp-testing 스킬을 사용하세요


## 워크트리(worktree) 사용

- 🗺 워크트리를 사용한다면 @using-git-worktrees 스킬을 사용하세요
- 📋 워크트리를 생성 시 아래 명령어를 실행하여 환경을 초기화하세요.

```bash
pnpm clean && pnpm --filter balcony config:platform -- --platform bom-kr --env local && pnpm --filter beltoon-jp config:platform -- --env local
```

## 자주 사용하는 명령어

```bash
npm run dev         # 개발 서버 실행 (일반적으로 http://localhost:3000)
npm run build       # 프로덕션 빌드 실행
npm run check:lint  # 린트 검사 실행
npm run check:type  # 타입 검사 실행 (권장)
```

## 작업 완료 체크리스트

```bash
npm run check:type  # 모든 검사 통과 확인
npm run build       # 빌드 성공 확인
```

@RTK.md
