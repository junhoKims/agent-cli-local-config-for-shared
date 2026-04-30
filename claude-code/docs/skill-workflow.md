# 스킬 워크플로 가이드

이 문서는 작업 유형별로 사용할 스킬과 순서를 정의한다.

## 기능 구현 워크플로

```
1. @brainstorming    → 요구사항 파악, 모호한 부분 질문
2. @writing-plans    → 구현 계획 수립
3. @test-driven-development → 테스트 먼저 작성
4. @executing-plans  → 계획 기반 구현
5. 구현 중간마다 타입 검사(check:type) 실행
6. @requesting-code-review → 구현 후 자체 리뷰
7. @receiving-code-review  → 피드백 반영
8. @verification-before-completion → 완료 전 검증
9. @finishing-a-development-branch → 브랜치 마무리 옵션 제시
```

## 버그 수정 워크플로

```
1. @systematic-debugging → 근본 원인 분석
2. @test-driven-development → 회귀 테스트 먼저 작성
3. 수정 구현
4. @verification-before-completion → 수정 검증
```

## UI/프론트엔드 워크플로

```
1. @brainstorming → 디자인 요구사항 파악
2. @ui-ux-pro-max, @web-design-guidelines → 디자인 가이드 참조
3. React 작업: @vercel-react-best-practices
4. Next.js 작업: @next-best-practices
5. @webapp-testing 또는 @agent-browser → 브라우저 테스트
```

## 워크트리 사용

- @using-git-worktrees 스킬을 사용하여 생성
- 워크트리 경로: 프로젝트의 `.claude/worktrees`에 생성
- 생성 후 아래 명령어로 환경 초기화:

```bash
pnpm clean && pnpm --filter balcony config:platform -- --platform bom-kr --env local && pnpm --filter beltoon-jp config:platform -- --env local
```

## 테스트 도구 선택

| 상황 | 스킬 |
| --- | --- |
| 단위/통합 테스트 | @test-driven-development |
| 웹앱 E2E 테스트 | @webapp-testing |
| 브라우저 자동화 | @agent-browser (@playwright-cli) |
