# MCP Shrimp Task Manager Guide

로컬에서 Shrimp Task Manager를 실행 가이드

## 🎨 설치

### mcp 로컬 프로젝트 클론

- 로컬로 작업하면 프로젝트별 작업 메모리를 관리할 수 있습니다.
- https://github.com/cjo4m06/mcp-shrimp-task-manager 접속 후 아래 가이드 수행

```bash
# Clone the repository
git clone https://github.com/cjo4m06/mcp-shrimp-task-manager.git
cd mcp-shrimp-task-manager

# Install dependencies
npm install

# Build the project
npm run build

```

### mcp 설치 확인

```json
{
  "mcpServers": {
    "shrimp-task-manager": {
      "command": "node",
      "args": ["/path/to/mcp-shrimp-task-manager/dist/index.js"],
      "env": {
        "DATA_DIR": "/path/to/your/shrimp_data",
        "TEMPLATES_USE": "en",
        "ENABLE_GUI": "false"
      }
    }
  }
}
```

## 🚀 한국어 템플릿 추가

### KO 템플릿 추가

아래 명령어를 수행하여 templates-ko 추가

```bash
npx github:junhoKims/shrimp-task-manager-ko-templates
```

- https://github.com/junhoKims/shrimp-task-manager-ko-templates

### 템플릿 적용 및 확인

```json
{
  "mcpServers": {
    "shrimp-task-manager": {
      "command": "node",
      "args": ["/path/to/mcp-shrimp-task-manager/dist/index.js"],
      "env": {
        "DATA_DIR": "/path/to/your/shrimp_data",
        "TEMPLATES_USE": "ko", <-- 이거
        "ENABLE_GUI": "false"
      }
    }
  }
}
```

