# claude-hud Guide

로컬 세팅으로 작업되어 있는 plugin `claude-hud` 가이드

## 🎨 설치

```bash
/plugin marketplace add jarrodwatts/claude-hud
```

```bash
/plugin install claude-hud
```

```bash
/claude-hud:setup
```

## 🚀 설정 (configuration)

~/.claude/plugins/claude-hud/config.json에서 아래와 같이 설정

```json
{
  "display": {
    "sevenDayThreshold": 90,
    "showConfigCounts": true,
    "showTodos": true
  },
  "gitStatus": {
    "enabled": false,
    "showDirty": true,
    "showAheadBehind": false,
    "showFileStats": false
  },
  "lineLayout": "compact",
  "showSeparators": false
}

```
- sevenDayThreshold: 7일 내 세션의 usage가 N% 이상이면 노출
