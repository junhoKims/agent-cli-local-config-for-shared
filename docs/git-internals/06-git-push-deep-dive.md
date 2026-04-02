# 06. git push 상세 과정

> `git push`는 **로컬 저장소의 객체와 참조를 리모트 저장소로 전송하는 과정**이다.
> add/commit이 로컬에서 완결되는 반면, push는 네트워크 통신이 필요한 유일한 핵심 작업이다.

---

## 1. 전체 과정 요약

```
git push origin main

  ① 리모트 연결 + 참조 목록 교환 (Reference Discovery)
       ↓
  ② 전송 필요 객체 계산 (Object Negotiation)
       ↓
  ③ Packfile 생성 (Delta Compression)
       ↓
  ④ 네트워크 전송 (Smart Protocol)
       ↓
  ⑤ 리모트 측 검증 + 참조 업데이트
       ↓
  ⑥ 로컬 리모트 추적 브랜치 업데이트
```

---

## 2. 단계별 상세

### Step 1: 참조 비교 (Reference Discovery)

Git 클라이언트가 리모트 서버에 연결하여 서로의 참조 상태를 교환한다.

```
[로컬]                              [리모트]
refs/heads/main = eeee5555          refs/heads/main = a1b2c3d4
refs/heads/feature = ffff6666       refs/heads/feature = ffff6666
```

**프로토콜 교환 과정:**

```
# 1. 클라이언트 → 서버: 연결 요청
GET /info/refs?service=git-receive-pack

# 2. 서버 → 클라이언트: 리모트의 모든 참조 목록 전송
a1b2c3d4... refs/heads/main
ffff6666... refs/heads/feature
(서버의 capabilities 목록도 함께 전송)

# 3. 클라이언트: 로컬과 리모트 참조 비교
main:    로컬(eeee5555) ≠ 리모트(a1b2c3d4) → 업데이트 필요
feature: 로컬(ffff6666) = 리모트(ffff6666) → 변경 없음
```

이 단계에서 **어떤 브랜치를 업데이트해야 하는지** 결정된다.

---

### Step 2: 전송할 객체 계산 (Object Negotiation)

리모트에 없는 객체만 골라내야 한다. 전체 저장소를 다시 보내면 비효율적이기 때문이다.

#### 필요한 객체 파악

```
로컬 main의 커밋 체인:
  eeee5555 (HEAD) → dddd4444 → cccc3333 → a1b2c3d4 (리모트가 이미 가지고 있는 커밋)

전송 필요:
  eeee5555 (commit)
  dddd4444 (commit)
  cccc3333 (commit)
  + 이 커밋들이 참조하는 tree와 blob 중 리모트에 없는 것들
```

#### "have / want" 프로토콜

```
클라이언트 → 서버:
  want eeee5555...    "이 커밋까지 업데이트하고 싶다"
  have a1b2c3d4...    "이 커밋은 이미 가지고 있을 것이다"
  done

서버 → 클라이언트:
  ACK a1b2c3d4...     "맞다, 그 커밋은 이미 있다"
```

**have/want 협상**의 핵심:
- `want`: 클라이언트가 전송하고 싶은 최신 커밋
- `have`: 리모트가 이미 보유하고 있을 것으로 예상되는 커밋
- `ACK`: 서버가 확인한 공통 조상 커밋

서버가 ACK한 커밋 이후의 모든 객체만 전송하면 된다.

#### 객체 그래프 순회

공통 조상이 확인되면, Git은 commit → tree → blob을 재귀적으로 순회한다:

```
전송 대상 계산:

commit eeee5555
  └─ tree cccc3333 (root)
       ├─ blob a1b2c3d4 (README.md)      ← 리모트에 이미 있음 → 제외
       ├─ blob d4e5f6a7 (package.json)    ← 리모트에 이미 있음 → 제외
       └─ tree bbbb2222 (src/)
            ├─ blob 5f3a4b2c (main.js)    ← 새로운 blob → 포함!
            └─ tree aaaa1111 (utils/)      ← 리모트에 이미 있음 → 제외

commit dddd4444
  └─ (같은 방식으로 순회)

최종 전송 목록:
  commit eeee5555, dddd4444, cccc3333
  tree   cccc3333, bbbb2222
  blob   5f3a4b2c, (기타 새로운 blob들)
```

---

### Step 3: Packfile 생성

전송할 객체 목록이 확정되면, 이를 하나의 **Packfile**로 묶는다.

#### Packfile의 구조

```
┌──────────────────────────────────────┐
│ PACK header (12 bytes)               │
│   - Signature: "PACK"               │
│   - Version: 2                       │
│   - Object count: N                  │
├──────────────────────────────────────┤
│ Object Entry #1                      │
│   - Type + Size (variable length)    │
│   - Compressed data (zlib)           │
├──────────────────────────────────────┤
│ Object Entry #2                      │
│   - Type: OFS_DELTA or REF_DELTA    │
│   - Base object reference            │
│   - Delta data (zlib compressed)     │
├──────────────────────────────────────┤
│ ...                                  │
├──────────────────────────────────────┤
│ Checksum (20 bytes SHA-1)            │
└──────────────────────────────────────┘
```

#### Delta Compression

Packfile의 핵심 최적화 기법. 유사한 객체 간의 차이분만 저장한다.

```
예시: main.js가 1000줄이고, 5줄만 변경했다면

일반 저장:  1000줄 전체 (이전 버전) + 1000줄 전체 (새 버전) = ~2000줄

Delta 저장: 1000줄 전체 (base 객체) + 5줄 차이분 (delta)     = ~1005줄
```

Delta 객체의 구조:
```
OFS_DELTA 또는 REF_DELTA
  ├─ base 객체 참조 (offset 또는 SHA-1)
  └─ delta instructions:
       COPY offset=0, size=500     "base의 0~500 바이트를 그대로 복사"
       INSERT data="새로운 내용"    "이 데이터를 삽입"
       COPY offset=510, size=490   "base의 510~1000 바이트를 복사"
```

> **Delta 체인**: delta가 다른 delta를 base로 참조할 수 있다 (A → B → C).
> 성능을 위해 기본 체인 깊이 제한은 50이다 (`pack.depth`).

#### Thin Pack

`git push` 시에는 **thin pack**이 사용될 수 있다:
- Delta의 base 객체가 리모트에 이미 있는 경우, base를 포함하지 않음
- 전송 데이터를 더 줄일 수 있음
- 리모트가 수신 후 base를 자체적으로 연결하여 pack을 "fix up"

---

### Step 4: 네트워크 전송

#### 전송 프로토콜

Git은 두 가지 주요 프로토콜을 사용한다:

**Smart HTTP Protocol:**
```
POST /git-receive-pack HTTP/1.1
Content-Type: application/x-git-receive-pack-request

[packfile 데이터 스트리밍]
```

**SSH Protocol:**
```
ssh git@github.com "git-receive-pack 'user/repo.git'"
[packfile 데이터 스트리밍]
```

| 프로토콜 | 장점 | 단점 |
|----------|------|------|
| SSH | 인증이 강력, 암호화 기본 | 방화벽 제한 가능 |
| Smart HTTP | 방화벽 친화적, 프록시 지원 | 인증 토큰 관리 필요 |
| Git Protocol (git://) | 빠름 | 인증/암호화 없음 (읽기 전용 권장) |

#### 전송 진행률

```bash
$ git push origin main
Enumerating objects: 10, done.           ← 전송 대상 객체 수
Counting objects: 100% (10/10), done.    ← 객체 수 확인
Delta compression using up to 8 threads. ← 병렬 delta 계산
Compressing objects: 100% (6/6), done.   ← zlib 압축
Writing objects: 100% (7/7), 1.23 KiB | 1.23 MiB/s, done. ← 전송
Total 7 (delta 3), reused 0 (delta 0)   ← 통계
```

---

### Step 5: 리모트 측 검증 + 참조 업데이트

서버가 packfile을 수신한 후 수행하는 과정:

#### 1) Packfile 검증

```
- 체크섬 확인: pack의 SHA-1이 일치하는가
- 객체 무결성: 모든 객체가 정상적으로 압축 해제되는가
- thin pack fix-up: 누락된 base 객체 연결
```

#### 2) Fast-Forward 검증

```
리모트의 현재 main: a1b2c3d4
push하려는 main:    eeee5555

질문: a1b2c3d4가 eeee5555의 조상(ancestor)인가?
```

```
eeee5555 → dddd4444 → cccc3333 → a1b2c3d4 ✓ (조상이 맞음)
                                    ↑
                              리모트의 현재 위치
```

- **조상이면 (Fast-Forward)**: 안전하게 업데이트 가능
- **조상이 아니면 (Non-Fast-Forward)**: 거부

```
# Non-Fast-Forward 예시
로컬:   C1 ← C2 ← C4 (main)
리모트: C1 ← C2 ← C3 (main)    ← C3는 로컬에 없는 커밋

C3가 C4의 조상이 아니므로 → 거부!

$ git push origin main
! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs
hint: Updates were rejected because the tip of your current branch is behind
```

해결 방법:
- `git pull` 후 merge/rebase 후 재시도
- `git push --force` (위험: 리모트의 C3를 잃을 수 있음)
- `git push --force-with-lease` (안전: 리모트가 예상한 상태일 때만 강제 push)

#### 3) Git Hooks 실행

서버 측에서 순서대로 실행되는 hook:

```
① pre-receive    ← 모든 참조 업데이트 전. 하나라도 거부하면 전체 push 실패
                    용도: 권한 검사, 브랜치 보호 규칙, 코드 서명 검증

② update         ← 각 참조별로 실행. 개별 참조를 선택적으로 거부 가능
                    용도: 브랜치별 세밀한 접근 제어

③ post-receive   ← 모든 참조 업데이트 후. 거부 불가 (이미 업데이트됨)
                    용도: 알림 전송, CI/CD 트리거, 배포 시작
```

#### 4) 참조 업데이트

모든 검증을 통과하면:

```bash
# 리모트 서버에서 수행됨
refs/heads/main: a1b2c3d4 → eeee5555
```

---

### Step 6: 로컬 리모트 추적 브랜치 업데이트

push가 성공하면, 로컬의 리모트 추적 브랜치도 갱신된다.

```bash
# 로컬에서 수행됨
.git/refs/remotes/origin/main: a1b2c3d4 → eeee5555
```

```
push 전:
  main:        eeee5555
  origin/main: a1b2c3d4   ← 뒤처져 있음

push 후:
  main:        eeee5555
  origin/main: eeee5555   ← 동기화됨
```

---

## 3. Push 거부 상황과 대응

### 3-1. Non-Fast-Forward

```bash
$ git push origin main
! [rejected]        main -> main (non-fast-forward)
```

원인: 리모트에 로컬에 없는 커밋이 있음

```bash
# 해결 1: fetch + merge
$ git fetch origin
$ git merge origin/main
$ git push origin main

# 해결 2: fetch + rebase (더 깔끔한 이력)
$ git fetch origin
$ git rebase origin/main
$ git push origin main

# 해결 3: force push (주의!)
$ git push --force-with-lease origin main
```

### 3-2. pre-receive hook 거부

```bash
$ git push origin main
remote: error: 이 브랜치는 보호되어 있습니다
! [remote rejected] main -> main (pre-receive hook declined)
```

원인: 서버의 브랜치 보호 규칙, 코드 리뷰 필수 정책 등

해결: PR(Pull Request)을 통해 merge하거나, 관리자에게 권한 요청

### 3-3. 용량 초과

```bash
$ git push origin main
remote: error: File large-file.zip is 150 MB; this exceeds the file size limit of 100 MB
```

해결:
- `git rm --cached large-file.zip` 후 `.gitignore`에 추가
- Git LFS (Large File Storage) 사용
- 이미 커밋된 경우 `git filter-branch` 또는 `BFG Repo-Cleaner`로 이력에서 제거

---

## 4. Push와 관련된 설정

```bash
# push 기본 동작 설정
$ git config push.default current    # 현재 브랜치만 push

# push 시 태그도 함께 전송
$ git push --tags

# 특정 리모트의 특정 브랜치로 push
$ git push origin local-branch:remote-branch

# 리모트 브랜치 삭제
$ git push origin --delete feature-branch
# (실제로는 리모트의 refs/heads/feature-branch를 삭제)
```

### push.default 옵션

| 값 | 동작 |
|----|------|
| `nothing` | 명시적으로 지정하지 않으면 push 거부 |
| `current` | 현재 브랜치와 같은 이름의 리모트 브랜치로 push |
| `upstream` | 현재 브랜치의 upstream으로 설정된 리모트 브랜치로 push |
| `simple` (기본값) | upstream과 이름이 같을 때만 push |
| `matching` | 이름이 같은 모든 브랜치를 push |

---

## 5. 실습: push 과정 관찰하기

```bash
# 1. 리모트 참조 상태 확인
$ git ls-remote origin

# 2. 전송될 커밋 확인 (push 전 미리보기)
$ git log origin/main..main --oneline

# 3. 전송될 객체 수 확인
$ git rev-list --objects origin/main..main | wc -l

# 4. dry-run으로 push 시뮬레이션
$ git push --dry-run origin main

# 5. verbose 모드로 push (프로토콜 상세 출력)
$ GIT_TRACE=1 git push origin main

# 6. push 후 리모트 추적 브랜치 확인
$ git branch -vv
* main eeee555 [origin/main] feat: 기능 추가

# 7. reflog에서 push 이력 확인
$ git reflog show origin/main
```

---

## 6. Push vs Fetch: 대칭적 이해

| | Push | Fetch |
|--|------|-------|
| **방향** | 로컬 → 리모트 | 리모트 → 로컬 |
| **참조 비교** | 로컬이 리모트보다 앞서야 함 | 제한 없음 |
| **객체 전송** | 로컬의 새 객체 → 리모트 | 리모트의 새 객체 → 로컬 |
| **참조 업데이트** | 리모트의 refs/heads/ | 로컬의 refs/remotes/ |
| **Fast-Forward 검증** | 필수 (거부 가능) | 불필요 (항상 허용) |
| **Hooks** | pre-receive, update, post-receive | 없음 (서버 측에서 실행) |

---

## 7. 핵심 통찰

1. **Push는 필요한 객체만 전송한다**: have/want 협상으로 최소한의 데이터만 전송
2. **Packfile + Delta = 효율적 전송**: 유사 객체의 차이분만 압축하여 전송 크기 최소화
3. **Fast-Forward는 안전 장치다**: 리모트의 이력이 덮어씌워지는 것을 방지
4. **서버 Hook이 접근 제어의 핵심**: pre-receive hook으로 push 정책 강제
5. **Push는 "보내기"일 뿐, "적용"은 서버가 결정**: 서버가 검증 후 거부할 수 있음
6. **리모트 추적 브랜치는 캐시다**: 마지막 통신 시점의 리모트 상태를 로컬에 기록

---

> **시리즈 완료!**
> - [01. Git 객체 모델](./01-git-object-model.md)
> - [02. .git 디렉토리 구조](./02-git-directory-structure.md)
> - [03. Git 참조 시스템](./03-git-references.md)
> - [04. git add 상세 과정](./04-git-add-deep-dive.md)
> - [05. git commit 상세 과정](./05-git-commit-deep-dive.md)
> - [06. git push 상세 과정](./06-git-push-deep-dive.md) ← 현재 문서
