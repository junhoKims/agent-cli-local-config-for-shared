# rtk-guide

`rtk`에 대해서, 그리고 설치 및 사용법

## rtk

LLM에 컨텍스트가 가기 전, 가로채서 토큰소모량을 줄여주는 Proxy

https://github.com/rtk-ai/rtk

## 설치

### Homebrew (recommended)

```bash
brew install rtk
```

## Quick Start

```bash
# 1. Install hook for Claude Code (recommended)
rtk init --global
# Follow instructions to register in ~/.claude/settings.json

# 2. Restart Claude Code, then test
git status  # Automatically rewritten to rtk git status
rtk gain
```

## 확인

아래 명령어를 통해서 사용했는지, 사용량을 확인할 수 있다

```bash
rtk gain
```

## 직접 설치 후 각 설정파일 확인하기

rtk에서 쓰이는 sha256 고유파일이 있어서 해당 레포에 설정을 작성해놓기가 애매하다 (혼선 가능)

때문에 사이트에서 직접 설치 필요
