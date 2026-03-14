# `settings.json` Guide [Max Plan]

Max Plan에서의 `settings.json` 설정 가이드

## Configuration

각 설정의 의미, 종류, 이유에 대해서 나열

### model

`opusplan`

- Max Plan에서 설계는 opus로 진행
- 구현 작업은 sonnet으로 진행

### effortLevel

`high`

- 깊은 추론의 레벨
- high는 Max Plan에서 토큰 소모 거뜬
- https://code.claude.com/docs/en/model-config#adjust-effort-level

### env - ENABLE_TOOL_SEARCH

`true`

- Tool Search를 활성화하여 더 빠른 문제 해결 가능
- https://code.claude.com/docs/en/mcp#configure-tool-search

### env - MAX_THINKING_TOKENS

`31999`

- Max Plan에서 깊은 추론을 위해 기본값 설정
- 그 이상은 시간 소요가 더 크다고 판단
- https://code.claude.com/docs/en/costs#adjust-extended-thinking

### permissions - allow

`["mcp__serena", "mcp__shrimp-task-manager"]`

- MCP 서버에 대한 접근 권한 설정
- 기본적으로 허락없이 수행하도록 설정
- https://code.claude.com/docs/en/mcp#configure-mcp-servers