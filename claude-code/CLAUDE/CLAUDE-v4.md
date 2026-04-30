## 언어 및 커뮤니케이션

- 기본 응답/주석/문서/커밋 메시지: 한국어로 작성
- 변수명/함수명: 영어 (코드 표준 준수)
- 커밋 메시지: Conventional Commits 규격 준수 (https://www.conventionalcommits.org/en/v1.0.0/#summary)
- 응답은 간결하게. 코드 변경은 diff로 확인 가능하므로 변경 요약 생략

## 워크플로 (IMPORTANT)

모든 구현 작업은 아래 순서를 따르세요 ( @docs/skill-workflow.md )

1. **계획 단계**: @brainstorming으로 요구사항 파악 후, @writing-plans로 계획 수립. 모호한 부분은 반드시 질문
2. **구현 단계**: @test-driven-development로 테스트 먼저 작성, @executing-plans로 구현
3. **검증 단계**: @requesting-code-review로 자체 리뷰 → @receiving-code-review로 피드백 반영
4. **완료 단계**: @verification-before-completion으로 최종 검증 → @finishing-a-development-branch로 브랜치 마무리

## 디버깅

1. **분석 단계**: @systematic-debugging으로 근본 원인 분석. 이유: 추측 기반 수정은 새로운 버그를 만들기 때문에 반드시 코드를 읽고 분석
2. **구현 단계**: 회귀 테스트를 먼저 작성한 후 수정 구현
3. **완료 단계**: @verification-before-completion으로 수정 검증. 실패 시 로그를 포함하여 보고

## 코드 설계 원칙

- SOLID 원칙을 준수하되 적절한 수준으로 적용 ( @docs/solid-principle-guide.md )
- 프론트엔드는 Composition Pattern으로 유연한 UI 구성 ( @vercel-composition-patterns 스킬 )
- 프론트엔드는 선언적 코드 작성을 준수 ( @docs/declarative-code-guide.md )
- 응집도 높고 결합도 낮은 코드를 작성 ( @docs/cohesion-coupling-guide.md )

## 코드 변경 원칙

- 구현 전 관련 파일을 반드시 읽고, 기존 패턴을 참조하여 동일 패턴으로 구현
- 요청된 범위 내에서만 변경. 이유: 의도하지 않은 사이드 이펙트 방지
- 변경한 코드에 대해서만 주석과 타입을 작성
- 단일 PR에서 신규 파일 3개 이상 생성이 필요하면 작업 분할 여부를 질문
