# 02. .git 디렉토리 구조

> `.git` 디렉토리가 **Git 저장소의 실체**다.
> 프로젝트 루트에서 `.git`을 삭제하면 모든 Git 이력이 사라진다. 반대로, `.git`만 있으면 전체 이력을 복원할 수 있다.

---

## 1. 전체 구조 개요

```
.git/
├── HEAD                    ← 현재 체크아웃된 브랜치 포인터
├── index                   ← 스테이징 영역 (바이너리)
├── config                  ← 이 저장소의 로컬 설정
├── description             ← GitWeb용 설명 (거의 사용 안 함)
├── objects/                ← 모든 Git 객체 저장소
│   ├── 94/                 ← SHA-1 앞 2자
│   │   └── 3e5b3ea8b...   ← SHA-1 나머지 38자
│   ├── pack/               ← Packfile (압축된 객체 묶음)
│   │   ├── pack-abc123.pack
│   │   └── pack-abc123.idx
│   └── info/               ← 보조 정보
├── refs/                   ← 참조(포인터) 저장
│   ├── heads/              ← 로컬 브랜치
│   │   └── main            ← main 브랜치의 최신 커밋 해시
│   ├── tags/               ← 태그
│   └── remotes/            ← 리모트 추적 브랜치
│       └── origin/
│           └── main
├── logs/                   ← Reflog (참조 변경 이력)
│   ├── HEAD
│   └── refs/
│       └── heads/
│           └── main
├── hooks/                  ← Git 훅 스크립트
│   ├── pre-commit.sample
│   └── post-commit.sample
└── info/
    └── exclude             ← 로컬 전용 .gitignore
```

---

## 2. 핵심 파일/디렉토리 상세

### 2-1. `HEAD` — 현재 위치 포인터

**Git이 "지금 어디에 있는지"를 아는 방법.**

```bash
$ cat .git/HEAD
ref: refs/heads/main
```

- 일반 상태: `ref: refs/heads/<branch-name>` 형태의 **심볼릭 참조**
- detached HEAD 상태: 커밋 해시가 직접 기록됨 (예: `a1b2c3d4e5f6...`)

`git checkout`, `git switch`, `git commit` 등이 이 파일을 업데이트한다.

### 2-2. `index` — 스테이징 영역

**다음 커밋에 포함될 파일 목록과 상태를 기록하는 바이너리 파일.**

직접 읽을 수는 없지만, 명령어로 확인할 수 있다:

```bash
# 인덱스에 등록된 모든 파일 확인
$ git ls-files --stage
100644 a1b2c3d4... 0  README.md
100644 d4e5f6a7... 0  src/main.js

# 인덱스의 바이너리 구조 (참고용)
$ hexdump -C .git/index | head -5
```

인덱스 파일의 내부 구조:

| 영역 | 내용 |
|------|------|
| 헤더 (12바이트) | 시그니처 `DIRC` + 버전 + 엔트리 수 |
| 엔트리 (반복) | ctime, mtime, dev, ino, mode, uid, gid, size, SHA-1, flags, 파일경로 |
| 확장 | tree cache, resolve-undo 등 (선택적) |
| 체크섬 (20바이트) | 전체 인덱스의 SHA-1 |

핵심 특성:
- **정렬 상태 유지**: 파일 경로 기준으로 항상 정렬되어 빠른 탐색 가능
- **stat cache**: 파일의 타임스탬프/크기로 변경 여부를 빠르게 판단 (내용 비교 없이)
- **하나의 flat 파일**: 디렉토리 구조가 아닌 단일 파일에 모든 엔트리 기록

### 2-3. `objects/` — 객체 저장소

**Git의 모든 데이터가 저장되는 핵심 디렉토리.**

두 가지 저장 형태가 있다:

#### Loose Objects (개별 객체)

```
objects/94/3e5b3ea8b877b258fca1252a0e3b1bab5cf53e
```

- 각 객체가 개별 파일로 존재
- `git add`, `git commit` 시 생성
- zlib 압축된 바이너리

#### Pack Files (묶음 객체)

```
objects/pack/pack-abc123def456.pack    ← 객체 데이터
objects/pack/pack-abc123def456.idx     ← 인덱스 (빠른 탐색용)
```

- `git gc` (garbage collection) 또는 `git push`/`git fetch` 시 생성
- 유사한 객체끼리 **delta compression** 적용 → 저장 공간 대폭 절감
- `.pack`: 실제 객체 데이터 묶음
- `.idx`: pack 내 객체를 빠르게 찾기 위한 인덱스

> **왜 Pack이 필요한가?**
> 1000개의 커밋이 있고, 각 커밋마다 큰 파일이 1바이트씩 수정되었다면,
> loose objects는 1000개의 전체 파일 복사본을 저장한다.
> Pack은 기준 객체 1개 + 999개의 delta(차이분)만 저장하여 공간을 절약한다.

### 2-4. `refs/` — 참조 저장소

**SHA-1 해시에 사람이 읽을 수 있는 이름을 부여하는 메커니즘.**

```bash
# 브랜치: 커밋 해시 40자가 기록된 단순 텍스트 파일
$ cat .git/refs/heads/main
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0

# 태그
$ cat .git/refs/tags/v1.0.0
f1e2d3c4b5a6978869574030211fedcba9876543

# 리모트 추적 브랜치
$ cat .git/refs/remotes/origin/main
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

각 파일은 단순히 **커밋 해시 40자 + 줄바꿈** 만 포함하는 텍스트 파일이다.

> **packed-refs**: 참조가 많아지면 `.git/packed-refs` 파일 하나에 모든 참조를 모아 성능을 최적화한다. loose ref가 우선하며, packed-refs는 fallback으로 사용된다.

### 2-5. `logs/` — Reflog

**참조가 변경된 모든 이력을 기록한다.**

```bash
$ cat .git/logs/HEAD
0000000... a1b2c3d... Junho Kim <junho@example.com> 1712100000 +0900  commit (initial): init
a1b2c3d... d4e5f6a... Junho Kim <junho@example.com> 1712100100 +0900  commit: feat: 기능 추가
```

각 줄의 구성: `이전해시 새해시 작성자 타임스탬프 동작설명`

용도:
- `git reflog`: 삭제된 커밋도 여기서 찾을 수 있다
- `git reset --hard`로 날린 작업을 복구할 때 핵심 도구
- 기본 90일간 보관 (설정 변경 가능)

### 2-6. `config` — 로컬 설정

**이 저장소에만 적용되는 Git 설정.**

```ini
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
[remote "origin"]
    url = git@github.com:user/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
    remote = origin
    merge = refs/heads/main
```

Git 설정의 우선순위:
1. **로컬** (`.git/config`) — 최우선
2. **글로벌** (`~/.gitconfig`)
3. **시스템** (`/etc/gitconfig`) — 최하위

### 2-7. `hooks/` — Git 훅

**특정 Git 이벤트 발생 시 자동 실행되는 스크립트.**

| 훅 | 실행 시점 | 용도 |
|----|----------|------|
| `pre-commit` | commit 직전 | 린트, 포맷 검사 |
| `commit-msg` | 메시지 작성 후 | 커밋 메시지 규칙 검증 |
| `pre-push` | push 직전 | 테스트 실행 |
| `post-merge` | merge 완료 후 | 의존성 설치 |

`.sample` 확장자를 제거하면 활성화된다.

---

## 3. 실습: 직접 .git 내부 탐험

```bash
# .git 디렉토리 구조 확인
$ tree .git -L 2

# HEAD가 가리키는 곳
$ cat .git/HEAD

# 현재 브랜치의 커밋 해시
$ cat .git/refs/heads/main

# 인덱스에 등록된 파일들
$ git ls-files --stage

# 객체 저장소의 실제 파일들
$ find .git/objects -type f | head -10

# loose 객체 수
$ find .git/objects -type f | grep -v pack | grep -v info | wc -l

# pack 파일 확인
$ ls -la .git/objects/pack/

# reflog 확인
$ git reflog --all | head -10
```

---

## 4. 핵심 통찰

1. **`.git`이 저장소의 전부다**: Working Directory의 파일은 `.git`에서 체크아웃된 복사본에 불과하다
2. **대부분의 내용은 단순 텍스트**: refs, HEAD, config 등은 사람이 직접 읽고 수정할 수 있는 텍스트 파일이다
3. **index는 성능의 핵심**: stat cache를 통해 수만 개 파일의 변경 여부를 밀리초 단위로 판단한다
4. **Loose → Pack 전환**: 개별 객체(loose)가 쌓이면 gc가 packfile로 묶어 공간과 성능을 최적화한다
5. **Reflog은 안전망**: 실수로 날린 커밋도 `logs/`에 기록이 남아있어 복구할 수 있다

---

> **다음 문서**: [03. Git 참조 시스템](./03-git-references.md) — refs/ 디렉토리의 참조들이 어떻게 동작하는지 깊이 파고든다.
