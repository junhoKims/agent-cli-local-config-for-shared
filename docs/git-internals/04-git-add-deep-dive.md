# 04. git add 상세 과정

> `git add`는 단순히 "파일을 스테이징한다"가 아니다.
> **파일 내용을 blob 객체로 영구 저장하고, 인덱스를 업데이트하는 과정**이다.
> 즉, `git add` 시점에 이미 데이터가 `.git/objects/`에 저장된다.

---

## 1. Git의 3영역 모델

`git add`를 이해하려면 먼저 Git의 3영역을 명확히 알아야 한다.

```
┌─────────────────┐    git add     ┌─────────────────┐   git commit   ┌─────────────────┐
│                 │  ──────────→  │                 │  ──────────→  │                 │
│   Working       │               │   Staging Area  │               │   Repository    │
│   Directory     │  ←──────────  │   (Index)       │               │   (.git)        │
│                 │   git restore │                 │               │                 │
└─────────────────┘               └─────────────────┘               └─────────────────┘
   파일 편집 공간                    다음 커밋 준비 공간                 영구 저장소
```

| 영역 | 물리적 위치 | 역할 |
|------|------------|------|
| Working Directory | 프로젝트 루트 | 실제 파일을 편집하는 공간 |
| Staging Area (Index) | `.git/index` | 다음 커밋에 포함될 스냅샷을 조립하는 공간 |
| Repository | `.git/objects/` | 커밋된 스냅샷이 영구 보관되는 공간 |

---

## 2. git add의 전체 과정 (단계별)

### 예시 시나리오

`hello.txt` 파일의 내용을 `Hello, World!`에서 `Hello, Git!`으로 수정한 후 `git add hello.txt`를 실행한다고 가정한다.

---

### Step 1: 변경 감지

Git은 먼저 해당 파일이 실제로 변경되었는지 확인한다.

```
인덱스 기록:
  hello.txt → mtime: 1712100000, size: 13, sha1: 943e5b3...

현재 파일:
  hello.txt → mtime: 1712100500, size: 10
```

**비교 과정:**
1. 인덱스에 기록된 `mtime`(수정 시간)과 `size`(파일 크기)를 현재 파일과 비교
2. 둘 중 하나라도 다르면 → 변경된 것으로 판단
3. 둘 다 같으면 → 변경 없음으로 판단 (**내용을 읽지 않음!**)

> **stat cache 최적화**: 파일 시스템의 메타데이터(stat)만으로 변경 여부를 판단한다.
> 수만 개 파일이 있어도 밀리초 내에 변경 파일을 식별할 수 있는 이유다.
> 단, 타임스탬프가 같은데 내용이 다른 극히 드문 경우를 위해 `core.trustctime` 등의 옵션이 있다.

---

### Step 2: 파일 내용 읽기 + 헤더 생성

변경이 확인되면, Git은 파일 전체 내용을 읽고 blob 객체의 헤더를 생성한다.

```
파일 내용: "Hello, Git!" (10바이트)

헤더: "blob 10\0"

전체 데이터: "blob 10\0Hello, Git!"
```

헤더 구성:
- `blob` : 객체 유형
- ` ` : 공백 구분자
- `10` : 내용의 바이트 수 (문자 수가 아님!)
- `\0` : null byte (헤더와 내용의 구분자)

---

### Step 3: SHA-1 해시 계산

```
SHA-1("blob 10\0Hello, Git!") = "5f3a4b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a"
```

이 해시가 이 blob의 **고유 식별자**이자 **저장 경로**가 된다.

> **동일 내용 = 동일 해시**: 프로젝트 내 다른 파일이 이미 같은 내용을 가지고 있다면,
> 해시가 같으므로 새로운 객체를 생성하지 않는다. 자연스러운 중복 제거.

---

### Step 4: zlib 압축 + 객체 저장

```python
# 의사 코드로 표현한 저장 과정
data = b"blob 10\0Hello, Git!"
compressed = zlib.compress(data)

path = ".git/objects/5f/3a4b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a"
#                      ↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
#                   디렉토리          파일명

os.makedirs(".git/objects/5f/", exist_ok=True)
write_file(path, compressed)
```

저장 전 확인:
- `.git/objects/5f/3a4b2c...` 파일이 이미 존재하면 → **저장 생략** (내용이 동일하므로)
- 존재하지 않으면 → 새 파일 생성

이 시점에서 **파일 내용은 이미 Git 저장소에 영구 저장되었다**.
아직 커밋하지 않았지만, blob 객체는 존재한다.

---

### Step 5: 인덱스 업데이트

blob이 저장되면, `.git/index` 파일을 업데이트한다.

**변경 전 인덱스:**
```
[Entry #1]
  ctime:  1712100000.123456789
  mtime:  1712100000.123456789
  dev:    16777234
  ino:    12345678
  mode:   100644          ← 일반 파일
  uid:    501
  gid:    20
  size:   13              ← 이전 파일 크기
  sha1:   943e5b3ea8b...  ← 이전 blob 해시
  flags:  0x000C          ← 파일명 길이 등
  path:   hello.txt
```

**변경 후 인덱스:**
```
[Entry #1]
  ctime:  1712100500.987654321    ← 업데이트
  mtime:  1712100500.987654321    ← 업데이트
  dev:    16777234
  ino:    12345678
  mode:   100644
  uid:    501
  gid:    20
  size:   10                      ← 새 파일 크기
  sha1:   5f3a4b2c1d0...          ← 새 blob 해시
  flags:  0x000C
  path:   hello.txt
```

인덱스 업데이트 규칙:
- **기존 파일 수정**: 해당 엔트리의 sha1, size, mtime 등을 갱신
- **새 파일 추가**: 새 엔트리를 경로 순서에 맞게 삽입
- **파일 삭제** (`git rm`): 해당 엔트리를 제거

> **인덱스는 항상 정렬 상태**: 파일 경로 기준 사전순 정렬을 유지한다.
> 이진 탐색으로 O(log n) 시간에 특정 파일을 찾을 수 있다.

---

## 3. 특수 케이스

### 3-1. 새 파일 추가 (untracked → staged)

```bash
$ echo "new file" > new.txt
$ git add new.txt
```

1. blob 객체 생성 + 저장 (위와 동일)
2. 인덱스에 **새 엔트리 추가** (기존 엔트리 수정이 아님)
3. 정렬 위치에 삽입

### 3-2. 부분 스테이징 (git add -p)

```bash
$ git add -p hello.txt
```

파일의 일부 변경분(hunk)만 스테이징:
1. 원본 파일과 수정된 파일의 diff를 계산
2. 사용자가 선택한 hunk만 적용한 **임시 버전** 생성
3. 이 임시 버전으로 blob 객체 생성
4. 인덱스 업데이트

결과: Working Directory의 파일과 인덱스의 내용이 **서로 다른 상태**가 된다.

```
Working Directory:  전체 수정 내용
Index:              선택한 hunk만 반영된 내용
Repository:         이전 커밋 상태
```

### 3-3. 디렉토리 추가 (git add src/)

Git은 디렉토리 자체를 추적하지 않는다. `git add src/`는:

1. `src/` 내 모든 파일을 재귀적으로 탐색
2. 각 파일에 대해 개별적으로 blob 생성 + 인덱스 업데이트
3. **빈 디렉토리는 추가되지 않는다** (추적할 파일이 없으므로)

### 3-4. .gitignore에 해당하는 파일

```bash
$ echo "*.log" >> .gitignore
$ git add debug.log
# error: The following paths are ignored by one of your .gitignore files
```

- `.gitignore`에 패턴이 일치하면 `git add` 거부
- 강제 추가: `git add -f debug.log`
- 이미 추적 중인 파일은 `.gitignore`에 추가해도 계속 추적됨

---

## 4. git add 이후의 상태

```bash
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   hello.txt
```

이 시점의 상태:
- `.git/objects/5f/3a4b2c...` : 새 blob 객체 존재 ✓
- `.git/index` : 새 blob 해시를 참조 ✓
- Working Directory : 수정된 파일 존재 ✓
- 커밋은 아직 생성되지 않음

---

## 5. git add의 되돌리기

### 스테이징 취소 (인덱스만 원복)

```bash
$ git restore --staged hello.txt
# 또는
$ git reset HEAD hello.txt
```

동작:
1. 현재 HEAD 커밋의 tree에서 `hello.txt`의 blob 해시를 찾음
2. 인덱스의 해당 엔트리를 이 해시로 되돌림
3. **Working Directory의 파일은 변경하지 않음**
4. **이미 생성된 blob 객체(`5f3a4b2c...`)는 삭제되지 않음** (gc가 나중에 정리)

---

## 6. 실습: add 과정 관찰하기

```bash
# 1. 현재 인덱스 상태 확인
$ git ls-files --stage
100644 943e5b3... 0  hello.txt

# 2. 파일 수정
$ echo "Hello, Git!" > hello.txt

# 3. 수정 후 아직 add 전 — 인덱스는 변경 없음
$ git ls-files --stage
100644 943e5b3... 0  hello.txt    ← 여전히 이전 해시

# 4. git add 실행
$ git add hello.txt

# 5. 인덱스 변경 확인
$ git ls-files --stage
100644 5f3a4b2... 0  hello.txt    ← 새 해시!

# 6. 새 blob 객체가 생성되었는지 확인
$ git cat-file -t 5f3a4b2
blob

$ git cat-file -p 5f3a4b2
Hello, Git!

# 7. 객체 파일 직접 확인
$ ls .git/objects/5f/
3a4b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a    ← 존재!
```

---

## 7. 핵심 통찰

1. **`git add`는 이미 데이터를 저장한다**: commit이 아닌 add 시점에 blob 객체가 `.git/objects/`에 생성된다
2. **인덱스는 "다음 커밋의 초안"이다**: `git commit`은 인덱스의 현재 상태를 그대로 스냅샷으로 만든다
3. **stat cache가 성능의 비결이다**: 수만 개 파일의 변경 여부를 파일 메타데이터만으로 판단한다
4. **중복 저장은 없다**: 동일한 내용의 파일은 하나의 blob만 존재한다
5. **add와 commit은 분리된 과정이다**: add = blob 생성 + 인덱스 갱신, commit = tree + commit 객체 생성 + 참조 이동

---

> **다음 문서**: [05. git commit 상세 과정](./05-git-commit-deep-dive.md) — 인덱스의 스냅샷을 영구 커밋으로 만드는 과정을 분석한다.
