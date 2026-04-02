# 03. Git 참조 시스템 (References)

> SHA-1 해시 `a1b2c3d4e5f6...`를 매번 기억할 수는 없다.
> Git의 **참조(reference)**는 해시에 사람이 읽을 수 있는 이름을 부여하는 메커니즘이다.

---

## 1. 참조란 무엇인가?

참조는 본질적으로 **커밋 해시를 담고 있는 텍스트 파일**이다.

```bash
$ cat .git/refs/heads/main
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

이 단순한 메커니즘 위에 브랜치, 태그, HEAD 등 Git의 모든 "이름 붙은 포인터"가 구축된다.

---

## 2. 브랜치 (Branch)

### 브랜치의 실체

브랜치는 `refs/heads/` 디렉토리 아래의 파일이다.

```
.git/refs/heads/
├── main          ← "a1b2c3d4..." (커밋 해시)
├── feature/login ← "d4e5f6a7..." (커밋 해시)
└── hotfix/bug-42 ← "7a8b9c0d..." (커밋 해시)
```

**브랜치 = 특정 커밋을 가리키는 움직이는 포인터**

### 브랜치의 동작

```
               main
                ↓
C1 ← C2 ← C3 ← C4
```

`git commit` 실행 시:
1. 새 commit 객체 `C5` 생성 (parent = C4)
2. `refs/heads/main` 파일의 내용을 C5의 해시로 교체

```
                    main
                      ↓
C1 ← C2 ← C3 ← C4 ← C5
```

**브랜치는 이동한다. 커밋이 이동하는 것이 아니다.**

### 브랜치 생성의 비용

```bash
# 브랜치 생성 = 41바이트 파일 하나 생성 (해시 40자 + 줄바꿈)
$ git branch feature
# .git/refs/heads/feature 파일이 생기고, 현재 커밋 해시가 기록됨
```

SVN 같은 시스템은 브랜치 생성 시 전체 디렉토리를 복사한다.
Git은 **41바이트 파일 하나** 만들면 끝이다. 이것이 Git에서 브랜치가 "가벼운" 이유다.

---

## 3. HEAD — "지금 어디에 있는가"

### 일반 상태: 심볼릭 참조

```bash
$ cat .git/HEAD
ref: refs/heads/main
```

HEAD는 **브랜치를 가리키는 포인터** (포인터의 포인터)다.

```
HEAD → refs/heads/main → commit C5
```

`git commit` 시, Git은:
1. HEAD를 읽어 현재 브랜치(main)를 파악
2. 해당 브랜치가 가리키는 커밋을 새 커밋의 parent로 설정
3. 새 커밋 생성 후, 해당 브랜치의 참조를 업데이트

### Detached HEAD 상태

```bash
$ git checkout a1b2c3d4
$ cat .git/HEAD
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

HEAD가 브랜치가 아닌 **커밋을 직접 가리킨다**.

```
HEAD (detached)
  ↓
  C3
```

이 상태에서 커밋하면:
- 새 커밋은 생성되지만, 어떤 브랜치에도 속하지 않는다
- 다른 브랜치로 이동하면 이 커밋에 접근할 수 없게 된다 (reflog에는 남음)
- gc가 실행되면 도달 불가능한 커밋은 삭제될 수 있다

### HEAD 해석 체인

Git이 실제 커밋을 찾는 과정:

```
HEAD
 ↓ (심볼릭 참조 해석)
refs/heads/main
 ↓ (파일 내용 읽기)
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
 ↓ (객체 저장소에서 조회)
commit 객체
 ↓ (tree 필드)
root tree 객체
 ↓ (엔트리 순회)
blob/tree 객체들 → Working Directory 파일들
```

---

## 4. 태그 (Tag)

### Lightweight Tag

**단순히 커밋 해시를 담은 참조 파일.** 브랜치와 유일한 차이는 자동으로 이동하지 않는다는 것.

```bash
$ git tag v0.1
$ cat .git/refs/tags/v0.1
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

### Annotated Tag

**별도의 tag 객체를 생성한다.** 작성자, 날짜, 메시지, GPG 서명을 포함할 수 있다.

```bash
$ git tag -a v1.0.0 -m "첫 번째 릴리즈"

# refs에는 tag 객체의 해시가 저장됨
$ cat .git/refs/tags/v1.0.0
f1e2d3c4b5a6978869574030211fedcba9876543

# tag 객체 → commit 객체를 가리킴
$ git cat-file -p f1e2d3c4
object a1b2c3d4...   ← 커밋 해시
type commit
tag v1.0.0
tagger Junho Kim <...> 1712100000 +0900

첫 번째 릴리즈
```

```
refs/tags/v1.0.0 → tag 객체 → commit 객체 → tree → blob
```

### 비교

| 특성 | Lightweight Tag | Annotated Tag |
|------|----------------|---------------|
| 참조 대상 | 직접 커밋 | tag 객체 → 커밋 |
| 작성자 정보 | 없음 | 있음 |
| 메시지 | 없음 | 있음 |
| GPG 서명 | 불가 | 가능 |
| 권장 용도 | 임시 마킹 | 릴리즈 태깅 |

---

## 5. 리모트 추적 브랜치 (Remote-Tracking Branch)

**마지막으로 리모트와 통신한 시점의 리모트 브랜치 상태를 기록한다.**

```
.git/refs/remotes/origin/
├── main        ← 마지막 fetch/push 시점의 origin/main 커밋 해시
├── develop     ← 마지막 fetch/push 시점의 origin/develop 커밋 해시
└── HEAD        ← origin의 기본 브랜치 정보
```

핵심 특성:
- **읽기 전용**: 사용자가 직접 수정하지 않음
- **자동 업데이트**: `git fetch`, `git pull`, `git push` 시 갱신
- **로컬 브랜치와 독립**: `origin/main`과 `main`은 별개의 참조

```
로컬 main:   C1 ← C2 ← C3 ← C4 ← C5    (내가 작업한 커밋)
origin/main: C1 ← C2 ← C3               (마지막 fetch 시점)
```

`git fetch` 후:

```
로컬 main:   C1 ← C2 ← C3 ← C4 ← C5
origin/main: C1 ← C2 ← C3 ← C6 ← C7    (리모트에 새 커밋이 있었음)
```

---

## 6. Reflog — 참조 변경 이력

**참조가 가리킨 모든 커밋의 이력을 시간순으로 기록한다.**

```bash
$ git reflog
a1b2c3d HEAD@{0}: commit: feat: 새 기능
d4e5f6a HEAD@{1}: checkout: moving from feature to main
7a8b9c0 HEAD@{2}: commit: fix: 버그 수정
f1e2d3c HEAD@{3}: commit (initial): init
```

### Reflog이 기록되는 시점

| 동작 | reflog 기록 |
|------|------------|
| `git commit` | HEAD + 현재 브랜치 |
| `git checkout` | HEAD |
| `git merge` | HEAD + 현재 브랜치 |
| `git rebase` | HEAD + 현재 브랜치 |
| `git reset` | HEAD + 현재 브랜치 |
| `git pull` | HEAD + 현재 브랜치 + 리모트 추적 |

### Reflog의 생명 주기

- **도달 가능한 엔트리**: 기본 90일 보관 (`gc.reflogExpire`)
- **도달 불가능한 엔트리**: 기본 30일 보관 (`gc.reflogExpireUnreachable`)
- `git reflog expire --expire=now --all`: 즉시 만료

### 복구 시나리오

```bash
# 실수로 reset --hard로 커밋을 날렸을 때
$ git reset --hard HEAD~3    # 3개 커밋 삭제!

# reflog에서 이전 상태 확인
$ git reflog
a1b2c3d HEAD@{0}: reset: moving to HEAD~3
f1e2d3c HEAD@{1}: commit: 중요한 작업

# 복구
$ git reset --hard f1e2d3c   # 또는 HEAD@{1}
```

---

## 7. Packed-refs 최적화

참조가 수백 개 이상 쌓이면, 각각의 파일을 열어보는 것이 비효율적이다.

```bash
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0 refs/heads/main
d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3 refs/heads/develop
f1e2d3c4b5a6978869574030211fedcba9876543 refs/tags/v1.0.0
```

탐색 우선순위:
1. `refs/heads/<name>` 파일이 있으면 그것을 사용 (loose ref)
2. 없으면 `packed-refs`에서 검색

`git pack-refs --all`: 모든 loose ref를 packed-refs로 통합

---

## 8. 참조 해석 규칙 (Ref Resolution)

`git show main`이라고 입력하면 Git은 다음 순서로 참조를 찾는다:

1. `.git/main` (직접 파일)
2. `.git/refs/main`
3. `.git/refs/tags/main`
4. `.git/refs/heads/main` ← **보통 여기서 찾음**
5. `.git/refs/remotes/main`
6. `.git/refs/remotes/main/HEAD`

이 순서 때문에 태그와 브랜치 이름이 겹치면 태그가 우선한다.

---

## 9. 실습

```bash
# 모든 참조 목록
$ git show-ref

# 특정 참조가 가리키는 커밋
$ git rev-parse main
$ git rev-parse HEAD

# 심볼릭 참조 확인
$ git symbolic-ref HEAD

# reflog 전체 확인
$ git reflog show --all

# 참조 간 관계
$ git log --oneline --graph --all
```

---

## 10. 핵심 통찰

1. **브랜치는 41바이트 텍스트 파일이다**: "무거운 브랜치"라는 것은 Git에 존재하지 않는다
2. **HEAD는 이중 포인터다**: HEAD → 브랜치 → 커밋. 이 체인이 Git의 "현재 위치" 시스템
3. **태그는 움직이지 않는 브랜치다**: 구조적으로 동일하지만, 커밋 시 자동 이동하지 않음
4. **Reflog은 로컬 전용 안전망이다**: `git push`로 전송되지 않으며, clone에도 포함되지 않음
5. **모든 참조 조작은 파일 I/O다**: `git branch`, `git tag` 등은 결국 텍스트 파일을 읽고 쓰는 것

---

> **다음 문서**: [04. git add 상세 과정](./04-git-add-deep-dive.md) — Working Directory에서 Staging Area로 변경을 기록하는 과정을 단계별로 분석한다.
