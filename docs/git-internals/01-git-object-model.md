# 01. Git 객체 모델 (Object Model)

> Git의 핵심은 **Content-Addressable Filesystem**(내용 주소 지정 파일 시스템)이다.
> 모든 데이터는 "내용의 해시"를 키로 사용하는 key-value 저장소에 보관된다.

---

## 1. Content-Addressable Filesystem이란?

일반 파일 시스템은 **경로**(path)로 파일을 찾는다:

```
/home/user/project/hello.txt  →  파일 내용
```

Git은 **내용의 해시**(hash)로 데이터를 찾는다:

```
sha1("blob 13\0Hello, World!") = "943e5b3..."  →  데이터
```

이것이 의미하는 바:
- **동일한 내용은 항상 동일한 해시**를 생성한다 → 자연스러운 중복 제거
- **파일명이 달라도 내용이 같으면** 하나의 객체만 저장된다
- **데이터 무결성이 보장**된다: 내용이 1비트라도 바뀌면 해시가 완전히 달라진다

---

## 2. SHA-1 해싱 과정

Git이 객체를 저장하는 정확한 과정:

### Step 1: 헤더 생성

```
"{객체타입} {내용바이트수}\0"
```

예시: `hello.txt` 파일에 `Hello, World!` (13바이트)가 있다면:

```
"blob 13\0"
```

### Step 2: 해시 계산

```
SHA-1(헤더 + 내용) = SHA-1("blob 13\0Hello, World!")
```

결과: `943e5b3ea8b877b258fca1252a0e3b1bab5cf53e` (40자 hex 문자열)

### Step 3: 저장 경로 결정

40자 해시를 두 부분으로 분리:
- **앞 2자** → 디렉토리명: `94`
- **나머지 38자** → 파일명: `3e5b3ea8b877b258fca1252a0e3b1bab5cf53e`

```
.git/objects/94/3e5b3ea8b877b258fca1252a0e3b1bab5cf53e
```

### Step 4: zlib 압축 후 저장

내용을 zlib으로 압축하여 위 경로에 바이너리 파일로 저장한다.

> **왜 앞 2자로 디렉토리를 나누는가?**
> 하나의 디렉토리에 수십만 개의 파일이 있으면 파일 시스템 성능이 저하된다.
> 256개(00~ff)의 하위 디렉토리로 분산하여 이 문제를 해결한다.

---

## 3. 4가지 객체 유형

Git에는 정확히 4가지 유형의 객체가 존재한다.

### 3-1. Blob (Binary Large Object)

**파일 내용**만 저장한다. 파일명, 경로, 권한 등 메타데이터는 포함하지 않는다.

```
blob 13\0Hello, World!
```

핵심 특성:
- **파일명을 모른다**: blob 자체는 어떤 파일인지 알 수 없다
- **중복 제거**: `a.txt`와 `b.txt`의 내용이 같으면 blob은 하나만 존재
- **불변(immutable)**: 한번 생성되면 절대 변경되지 않는다

### 3-2. Tree

**디렉토리 구조**를 표현한다. blob이나 하위 tree에 대한 참조 목록을 저장한다.

```
tree [size]\0
100644 blob a1b2c3...  hello.txt
100644 blob d4e5f6...  README.md
040000 tree 7a8b9c...  src
```

각 엔트리의 구성:
| 필드 | 설명 | 예시 |
|------|------|------|
| mode | 파일 모드 (권한) | `100644` (일반 파일), `100755` (실행 파일), `040000` (디렉토리) |
| type | 객체 유형 | `blob` 또는 `tree` |
| hash | SHA-1 해시 | `a1b2c3d4e5f6...` |
| name | 파일/디렉토리명 | `hello.txt`, `src` |

핵심 특성:
- **파일명은 tree가 관리**한다 (blob이 아님)
- **중첩 구조**: tree가 하위 tree를 참조하여 디렉토리 계층을 표현
- **스냅샷**: 특정 시점의 전체 디렉토리 구조를 캡처

### 3-3. Commit

**스냅샷의 메타데이터**를 저장한다. "누가, 언제, 왜" 이 스냅샷을 만들었는지 기록한다.

```
tree 7a8b9c0d1e2f...
parent 1a2b3c4d5e6f...
author Junho Kim <junho@example.com> 1712100000 +0900
committer Junho Kim <junho@example.com> 1712100000 +0900

feat: 로그인 기능 추가
```

각 필드:
| 필드 | 설명 |
|------|------|
| `tree` | 이 커밋이 가리키는 root tree의 SHA-1 (프로젝트 전체 스냅샷) |
| `parent` | 이전 커밋의 SHA-1. 첫 커밋이면 없음, merge 커밋이면 2개 이상 |
| `author` | 코드를 작성한 사람 + 타임스탬프 |
| `committer` | 커밋을 생성한 사람 + 타임스탬프 (cherry-pick/rebase 시 author와 다를 수 있음) |
| 메시지 | 빈 줄 이후 커밋 메시지 |

핵심 특성:
- **diff를 저장하지 않는다**: 전체 tree 스냅샷을 참조할 뿐, 변경분을 저장하지 않음
- **parent 링크로 이력 형성**: commit → parent → parent → ... 로 히스토리 체인 생성
- **불변**: 메시지 한 글자만 바꿔도 완전히 새로운 commit 객체가 됨

### 3-4. Tag (Annotated Tag)

**커밋에 대한 영구 레이블**이다. lightweight tag와 달리 별도의 객체로 존재한다.

```
object 1a2b3c4d5e6f...
type commit
tag v1.0.0
tagger Junho Kim <junho@example.com> 1712100000 +0900

첫 번째 정식 릴리즈
```

핵심 특성:
- commit 객체를 가리키며, tagger 정보와 메시지를 포함
- GPG 서명 가능 (릴리즈 검증용)

---

## 4. DAG (Directed Acyclic Graph)

commit들이 parent를 통해 형성하는 구조가 **방향성 비순환 그래프(DAG)**이다.

```
C1 ← C2 ← C3 ← C4    (main)
           ↖
            C5 ← C6   (feature)
```

- **방향성(Directed)**: parent에서 child로의 단방향 참조
- **비순환(Acyclic)**: 순환 참조 불가능 (A→B→C→A 같은 구조 불가)
- **그래프(Graph)**: merge 시 하나의 commit이 여러 parent를 가질 수 있음

이 DAG 구조가 Git의 브랜치, merge, rebase 등 모든 이력 조작의 기반이 된다.

---

## 5. 실습: 직접 객체 확인하기

```bash
# 객체의 타입 확인
git cat-file -t HEAD
# 출력: commit

# 객체의 내용 확인
git cat-file -p HEAD
# 출력: tree, parent, author, committer, message

# commit이 가리키는 tree 확인
git cat-file -p HEAD^{tree}
# 출력: tree 엔트리 목록 (mode, type, hash, name)

# 특정 blob 내용 확인
git cat-file -p <blob-hash>
# 출력: 파일 내용 그대로

# 파일 내용으로 해시 계산 (저장하지 않음)
echo -n "Hello, World!" | git hash-object --stdin
# 출력: SHA-1 해시

# 수동으로 blob 객체 저장
echo -n "Hello, World!" | git hash-object -w --stdin
# 출력: SHA-1 해시 (이제 .git/objects/에 저장됨)
```

---

## 6. 객체 모델의 핵심 통찰

1. **Git은 파일 시스템 위의 파일 시스템이다**: `.git/objects/`가 Git 자체의 파일 시스템
2. **모든 것은 불변(immutable)**: 객체는 한번 생성되면 절대 수정되지 않는다. "수정"은 항상 새 객체 생성을 의미
3. **해시가 곧 주소이자 무결성 검증**: 내용이 변조되면 해시가 달라지므로 즉시 감지 가능
4. **Blob은 이름을 모르고, Tree는 내용을 모른다**: 관심사의 분리(Separation of Concerns)
5. **Commit은 스냅샷이지 diff가 아니다**: `git diff`는 두 스냅샷을 비교하여 런타임에 계산하는 것

---

> **다음 문서**: [02. .git 디렉토리 구조](./02-git-directory-structure.md) — 이 객체들이 실제로 어디에, 어떻게 저장되는지 살펴본다.
