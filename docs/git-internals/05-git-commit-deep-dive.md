# 05. git commit 상세 과정

> `git commit`은 **인덱스(Staging Area)의 현재 상태를 영구 스냅샷으로 만드는 과정**이다.
> blob은 이미 `git add` 시점에 저장되어 있으므로, commit은 **tree 객체 생성 + commit 객체 생성 + 참조 업데이트**로 구성된다.

---

## 1. 전체 과정 요약

```
git commit -m "feat: 기능 추가"

  ① Index 읽기
       ↓
  ② Tree 객체 생성 (디렉토리 구조 → 중첩 tree)
       ↓
  ③ Commit 객체 생성 (tree + parent + author + message)
       ↓
  ④ 브랜치 참조 업데이트 (refs/heads/main → 새 commit hash)
       ↓
  ⑤ Reflog 기록
```

---

## 2. 단계별 상세

### Step 1: 인덱스 읽기

Git은 `.git/index` 파일을 읽어 현재 스테이징된 모든 파일 목록을 가져온다.

```
인덱스 내용:
  100644 blob a1b2c3d4...  README.md
  100644 blob d4e5f6a7...  package.json
  100644 blob 5f3a4b2c...  src/main.js
  100644 blob 7a8b9c0d...  src/utils/helper.js
  100644 blob f1e2d3c4...  src/utils/format.js
```

이 flat한 목록에서 디렉토리 구조를 복원해야 한다.

---

### Step 2: Tree 객체 생성

인덱스의 flat 목록을 **디렉토리 계층 구조**로 변환하여 tree 객체들을 생성한다.

#### 디렉토리 구조 파악

```
README.md           → 루트
package.json        → 루트
src/main.js         → src/
src/utils/helper.js → src/utils/
src/utils/format.js → src/utils/
```

#### 하위 tree부터 생성 (Bottom-Up)

**① `src/utils/` tree 생성:**

```
tree [size]\0
100644 blob 7a8b9c0d...  helper.js
100644 blob f1e2d3c4...  format.js
```

이 tree의 SHA-1: `aaaa1111...`

**② `src/` tree 생성:**

```
tree [size]\0
100644 blob 5f3a4b2c...  main.js
040000 tree aaaa1111...   utils        ← 위에서 만든 tree 참조
```

이 tree의 SHA-1: `bbbb2222...`

**③ root tree 생성:**

```
tree [size]\0
100644 blob a1b2c3d4...  README.md
100644 blob d4e5f6a7...  package.json
040000 tree bbbb2222...   src          ← 위에서 만든 tree 참조
```

이 root tree의 SHA-1: `cccc3333...`

#### 왜 Bottom-Up인가?

상위 tree는 하위 tree의 **해시**를 포함해야 한다.
해시는 내용이 결정된 후에야 계산할 수 있으므로, 반드시 가장 깊은 디렉토리부터 만들어야 한다.

```
src/utils/ tree (먼저)
     ↓ 해시 확정
src/ tree (다음)
     ↓ 해시 확정
root tree (마지막)
```

#### Tree 재사용 최적화

파일이 하나도 변경되지 않은 디렉토리의 tree는 **이전 커밋과 동일한 해시**를 갖는다.
Git은 이를 감지하여 새 tree 객체를 생성하지 않고 기존 해시를 그대로 재사용한다.

```
이전 커밋:  root tree → src/ tree → utils/ tree
                               ↕ (src/main.js만 변경됨)
새 커밋:    root tree → src/ tree → utils/ tree  ← 동일 해시, 재사용!
            (새 해시)   (새 해시)   (동일 해시)
```

---

### Step 3: Commit 객체 생성

root tree가 완성되면, commit 객체를 만든다.

```
commit [size]\0
tree cccc3333...                                        ← root tree의 SHA-1
parent a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0       ← 이전 commit의 SHA-1
author Junho Kim <junho@example.com> 1712100500 +0900   ← 코드 작성자
committer Junho Kim <junho@example.com> 1712100500 +0900 ← 커밋 실행자
                                                         ← 빈 줄 (메시지 구분)
feat: 기능 추가                                          ← 커밋 메시지
```

#### 각 필드 상세

**tree**: 이 커밋이 나타내는 프로젝트의 전체 스냅샷. root tree 하나만 참조하면 전체 파일 구조에 접근 가능.

**parent**: 이 커밋의 직전 커밋.
- 첫 커밋 (initial commit): parent 없음
- 일반 커밋: parent 1개
- merge 커밋: parent 2개 이상

```
# 일반 커밋
parent a1b2c3d4...

# merge 커밋
parent a1b2c3d4...    ← 첫 번째 부모 (현재 브랜치)
parent d4e5f6a7...    ← 두 번째 부모 (merge 대상 브랜치)
```

**author vs committer**: 보통 동일인이지만, 다를 수 있다.
- `git cherry-pick`: 원 작성자(author)는 유지, committer는 cherry-pick 실행자
- `git rebase`: author 유지, committer는 rebase 실행자
- `git commit --amend`: author 유지 가능 (옵션), committer는 amend 실행자

**타임스탬프 형식**: `Unix timestamp` + `timezone offset`
- `1712100500 +0900` → 2024년 4월 3일 12:28:20 KST

#### SHA-1 계산

commit 객체 전체 내용을 해싱:

```
SHA-1("commit [size]\0tree cccc3333...\nparent a1b2c3d4...\nauthor...\n\nfeat: 기능 추가\n")
= "eeee5555..."
```

이것이 이 커밋의 고유 식별자가 된다.

> **커밋 해시의 의미**: 커밋 해시는 메시지, 작성자, 시간, 전체 파일 트리, 부모 커밋 등
> **모든 것**의 해시다. 어느 하나라도 바뀌면 완전히 다른 해시가 된다.
> 이것이 `git rebase`가 커밋 해시를 변경하는 이유다.

---

### Step 4: 브랜치 참조 업데이트

새 commit 객체가 저장되면, 현재 브랜치가 이 커밋을 가리키도록 업데이트한다.

```bash
# Git이 내부적으로 수행하는 작업:

# 1. HEAD 읽기
$ cat .git/HEAD
ref: refs/heads/main

# 2. 해당 브랜치 파일의 내용을 새 커밋 해시로 교체
$ echo "eeee5555..." > .git/refs/heads/main
```

**Detached HEAD인 경우:**

```bash
# HEAD 파일 자체를 새 커밋 해시로 교체
$ echo "eeee5555..." > .git/HEAD
```

#### 안전한 업데이트 (Atomic Write)

Git은 참조 업데이트 시 **compare-and-swap** 방식을 사용한다:

1. 현재 `refs/heads/main`의 값을 읽음 (expected = `a1b2c3d4...`)
2. 새 값 `eeee5555...`를 임시 파일에 기록
3. expected 값이 여전히 동일한지 확인
4. 동일하면 임시 파일을 `refs/heads/main`으로 rename (atomic)
5. 다르면 → 실패 (다른 프로세스가 동시에 변경한 경우)

이 메커니즘이 동시 commit 시 데이터 손실을 방지한다.

---

### Step 5: Reflog 기록

참조가 업데이트될 때마다 reflog에 이력을 남긴다.

```
# .git/logs/HEAD에 추가되는 줄:
a1b2c3d4... eeee5555... Junho Kim <junho@example.com> 1712100500 +0900  commit: feat: 기능 추가

# .git/logs/refs/heads/main에도 동일한 줄 추가
```

---

## 3. 생성되는 객체 정리

하나의 `git commit` 명령으로 생성되는 모든 객체:

```
기존 (git add 시 생성):
  blob 5f3a4b2c... (수정된 src/main.js의 내용)

새로 생성 (git commit 시):
  tree aaaa1111... (src/utils/ 디렉토리)  ← 변경 없으면 재사용
  tree bbbb2222... (src/ 디렉토리)        ← src/main.js 변경으로 새로 생성
  tree cccc3333... (root 디렉토리)        ← 하위 tree 변경으로 새로 생성
  commit eeee5555... (커밋 메타데이터)

업데이트:
  .git/refs/heads/main → eeee5555...
  .git/logs/HEAD → 이력 추가
  .git/logs/refs/heads/main → 이력 추가
```

---

## 4. 특수 케이스

### 4-1. 최초 커밋 (Initial Commit)

```
commit [size]\0
tree cccc3333...
author Junho Kim <...> 1712100000 +0900
committer Junho Kim <...> 1712100000 +0900

init
```

- `parent` 필드가 **없다**
- 이것이 DAG의 루트 노드가 된다

### 4-2. Merge 커밋

```bash
$ git merge feature
```

```
commit [size]\0
tree dddd4444...
parent eeee5555...    ← main의 최신 커밋
parent ffff6666...    ← feature의 최신 커밋
author Junho Kim <...> 1712100800 +0900
committer Junho Kim <...> 1712100800 +0900

Merge branch 'feature'
```

- `parent`가 **2개**
- tree는 merge 결과를 반영한 새로운 스냅샷

### 4-3. --amend

```bash
$ git commit --amend -m "새 메시지"
```

동작:
1. 현재 HEAD 커밋과 **같은 parent**를 가진 새 커밋 생성
2. 인덱스의 현재 상태로 새 tree 생성
3. 브랜치 참조를 새 커밋으로 업데이트
4. **이전 커밋 객체는 삭제되지 않음** (reflog에서 참조, gc가 나중에 정리)

```
amend 전: C1 ← C2 ← C3(main)
amend 후: C1 ← C2 ← C3'(main)     C3는 orphaned (gc 대상)
```

### 4-4. 빈 커밋

```bash
$ git commit --allow-empty -m "빈 커밋"
```

- tree가 이전 커밋과 **동일**
- commit 객체만 새로 생성됨 (새 tree 객체 생성 불필요)
- CI 트리거, 태그용 등으로 사용

---

## 5. Commit이 diff를 저장하지 않는다는 것의 의미

많은 개발자가 "커밋 = 변경분(diff)의 저장"이라고 생각하지만, 이는 오해다.

```
Commit C3:
  tree → root tree → 모든 파일의 blob    ← 전체 스냅샷

"git diff C2 C3"은:
  C2의 root tree vs C3의 root tree 비교  ← 런타임 계산
```

**장점:**
- 임의의 두 커밋 간 diff가 O(변경 파일 수) 시간에 가능
- 특정 커밋 시점의 전체 파일 조회가 O(1)
- 브랜치 전환(checkout)이 빠름

**공간 효율:**
- blob 중복 제거: 변경되지 않은 파일은 동일 blob 재사용
- Pack file: delta compression으로 유사 blob 간 차이분만 저장

---

## 6. 실습: commit 과정 관찰하기

```bash
# 1. 커밋 전 인덱스 상태
$ git ls-files --stage

# 2. 커밋 실행
$ git commit -m "feat: 기능 추가"

# 3. 새 커밋 객체 확인
$ git cat-file -p HEAD
tree cccc3333...
parent a1b2c3d4...
author Junho Kim <...>
committer Junho Kim <...>

feat: 기능 추가

# 4. root tree 내용 확인
$ git cat-file -p HEAD^{tree}
100644 blob a1b2c3d4...  README.md
100644 blob d4e5f6a7...  package.json
040000 tree bbbb2222...  src

# 5. 커밋 시 생성된 객체 수 확인
$ git rev-list --objects HEAD | head -20

# 6. reflog 확인
$ git reflog -1
eeee555 HEAD@{0}: commit: feat: 기능 추가

# 7. 브랜치 참조 확인
$ cat .git/refs/heads/main
eeee5555...
```

---

## 7. 핵심 통찰

1. **Commit은 스냅샷이다**: diff가 아닌 전체 프로젝트의 tree를 참조한다
2. **Tree 생성은 Bottom-Up**: 가장 깊은 디렉토리부터 만들어 올라간다
3. **변경되지 않은 tree는 재사용**: 해시가 같으므로 새 객체 생성이 불필요하다
4. **커밋 해시 = 전체의 해시**: 메시지, 시간, 작성자, 트리, 부모 모두 포함
5. **참조 업데이트는 atomic**: 파일 rename으로 동시성 문제를 방지한다
6. **Amend는 수정이 아닌 교체**: 이전 커밋은 orphaned 되고 새 커밋이 생성된다

---

> **다음 문서**: [06. git push 상세 과정](./06-git-push-deep-dive.md) — 로컬 커밋을 리모트 저장소로 전송하는 과정을 분석한다.
