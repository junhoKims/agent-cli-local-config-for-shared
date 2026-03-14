# `settings.json` Guide [Pro Plan]

Pro Plan에서의 `settings.json` 설정 가이드

## Configuration

각 설정의 의미, 종류, 이유에 대해서 나열

### model

`sonnet`

- 기본적인 코딩 작업으로 충분
- opus는 Pro Plan에서 지나친 토큰 소모

### effortLevel

`medium`

- 깊은 추론의 레벨
- high는 Pro Plan에서 지나친 토큰 소모
- https://code.claude.com/docs/en/model-config#adjust-effort-level

### env - ENABLE_TOOL_SEARCH

`true`

- Tool Search를 활성화하여 더 빠른 문제 해결 가능
- https://code.claude.com/docs/en/mcp#configure-tool-search

### env - MAX_THINKING_TOKENS

`10000`

- Pro Plan에서 지나친 토큰 소모를 방지하기 위한 설정
- 기본값은 31999으로 설정되어 있으며, 이는 Pro Plan에서 지나친 토큰 소모
- https://code.claude.com/docs/en/costs#adjust-extended-thinking

### permissions - allow

`["mcp__serena", "mcp__shrimp-task-manager"]`

- MCP 서버에 대한 접근 권한 설정
- 기본적으로 허락없이 수행하도록 설정
- https://code.claude.com/docs/en/mcp#configure-mcp-servers