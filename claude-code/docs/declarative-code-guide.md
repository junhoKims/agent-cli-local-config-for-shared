# 선언적 코드 작성 가이드

> 출처: [토스 기술 블로그 — 선언적인 코드 작성하기](https://toss.tech/article/frontend-declarative-code)

## 핵심 정의

선언적 코드란 **추상화 레벨이 높아진 코드**이다. 내부 구현(how)을 숨기고 **무엇을 하는지(what)**에 집중하게 만든다.

## 제1원칙: 수정하기 쉬운 코드

토스가 코드 품질의 최상위 기준으로 삼는 원칙이다. 선언적 코드의 목적은 "멋진 코드"가 아니라 **수정하기 쉬운 코드**를 만드는 것이다.

## 핵심 교훈: 선언적 코드가 항상 좋은 것은 아니다

과도한 추상화는 prop 폭발을 일으키고 오히려 수정을 어렵게 만든다. **적절한 추상화 레벨을 선택**하는 것이 핵심이다.

---

## 패턴 1: 커스텀 훅으로 상태 관리 추상화

### 명령형 (before)

```tsx
const [isSheetOpen, setIsSheetOpen] = useState(false);

<button onClick={() => setIsSheetOpen(true)}>
  바텀시트 열기
</button>
<BottomSheet open={isSheetOpen} onClose={() => setIsSheetOpen(false)}>
  나는 바텀시트야
</BottomSheet>
```

### 선언적 (after) — useOverlay

```tsx
const overlay = useOverlay();

<button
  onClick={() => {
    overlay.open(({ isOpen, close }) => {
      return (
        <BottomSheet open={isOpen} onClose={close}>
          나는 바텀시트야
        </BottomSheet>
      );
    });
  }}
>
  바텀시트 열기
</button>
```

**효과**: 열기/닫기 상태(useState, setState)를 훅 내부로 추상화. 호출부는 "무엇을 열 것인가"만 선언한다.

---

## 패턴 2: 래퍼 컴포넌트로 횡단 관심사 분리

### 뷰포트 노출 감지 — ImpressionArea

```tsx
<ImpressionArea onImpressionStart={() => { /* 보여졌을 때 실행 */ }}>
  <div>내가 보여졌으면 onImpressionStart가 실행돼</div>
</ImpressionArea>
```

내부적으로 `IntersectionObserver` API의 복잡한 설정을 추상화한다.

### 클릭 로깅 — LoggingClick

**명령형 (before):**

```tsx
<button
  onClick={() => {
    log({ title: '사기', price });
    buy();
  }}
>
  사기
</button>
```

**선언적 (after):**

```tsx
<LoggingClick params={{ price }}>
  <button onClick={buy}>사기</button>
</LoggingClick>
```

**효과**: 로깅 로직과 비즈니스 로직이 분리되어 관심사가 명확하게 나뉜다.

---

## 패턴 3: 추상화 레벨 선택 (반면교사)

### 적절한 추상화

```tsx
<SignUpForm
  onSubmit={result => {
    /* 회원가입 결과에 따라서 특정 동작 수행 */
  }}
/>
```

### 과도한 추상화 (prop 폭발)

```tsx
<SignUpForm
  signUpOrder={['sns', 'normal']}
  title="사이트에 어서 오세요"
  subtitle="먼저 회원가입을 해주세요."
  primaryButtonColor={colors.blue}
  secondaryButtonColor={colors.grey}
  /* 많은 Props ... */
  onCancel={/* ... */}
  onSubmit={result => { /* ... */ }}
/>
```

**교훈**: 요구사항이 늘어나면서 prop이 폭발한다면, 추상화 레벨을 재고해야 한다. 이 경우 컴포넌트를 분리하거나 Composition Pattern으로 전환하는 것이 적합하다.

---

## 적용 판단 기준

| 상황 | 접근 방식 |
| --- | --- |
| 반복되는 상태 관리 패턴 (열기/닫기, 로딩) | 커스텀 훅으로 추상화 |
| 횡단 관심사 (로깅, 권한, 노출 감지) | 래퍼 컴포넌트로 분리 |
| Props가 5개 이상 늘어나는 컴포넌트 | 추상화 레벨 재검토, Composition으로 전환 |
| 한 곳에서만 사용하는 로직 | 추상화하지 않음. 명령형이 더 명확 |
| 내부 구현을 알아야 디버깅 가능한 추상화 | 추상화 제거 고려 |
