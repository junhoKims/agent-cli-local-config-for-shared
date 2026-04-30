# 응집도는 높이고 결합도는 낮추기

> 출처: [Frontend Fundamentals — Code Quality](https://frontend-fundamentals.com/code-quality/)

## 응집도 (Cohesion) — 함께 변경되는 코드를 함께 두라

### 1. 도메인 기반 디렉토리 구조

파일을 타입별(components, hooks, utils)이 아닌 **도메인(기능) 단위**로 묶는다.

```
# Bad: 타입 기반 — 의존 관계 불명확, 기능 삭제 시 고아 파일 발생
└─ src
   ├─ components/
   ├─ hooks/
   └─ utils/

# Good: 도메인 기반 — 관련 코드가 한 곳에, 삭제 시 디렉토리 통째로 제거
└─ src
   ├─ components/  (공용)
   └─ domains/
      ├─ Order/
      │   ├─ components/
      │   ├─ hooks/
      │   └─ utils/
      └─ Auth/
          ├─ components/
          └─ hooks/
```

### 2. 매직 넘버 제거

```typescript
// Bad: 300이 무엇인지 알 수 없음. 애니메이션 시간 변경 시 사일런트 버그 발생
await delay(300);

// Good: 이름이 있는 상수로 관련 값을 한 곳에서 관리
const ANIMATION_DELAY_MS = 300;
await delay(ANIMATION_DELAY_MS);
```

### 3. 폼 응집도 선택

| 상황 | 접근 방식 |
| --- | --- |
| 필드별 독립 검증, 여러 폼에서 재사용 | **필드 단위** — 각 필드가 자체 validate 로직 보유 |
| 필드 간 상호 의존, 단일 비즈니스 기능 | **폼 단위** — Zod 스키마로 중앙 집중 검증 |

```tsx
// 폼 단위 응집도 — 검증 로직이 한 곳에 모여 전체 흐름 파악 용이
const schema = z.object({
  name: z.string().min(1, "이름을 입력해주세요."),
  email: z.string().min(1, "이메일을 입력해주세요.").email("유효한 이메일 주소를 입력해주세요.")
});

const { register, handleSubmit } = useForm({ resolver: zodResolver(schema) });
```

---

## 결합도 (Coupling) — 변경의 영향 범위를 최소화하라

### 1. 공유 Hook 분리 — usePageState

모든 URL 쿼리 파라미터를 하나의 Hook으로 관리하면 결합도가 높아진다.

```typescript
// Bad: 모든 파라미터가 하나의 Hook에 결합
function usePageState() {
  const [query, setQuery] = useQueryParams({
    cardId: NumberParam,
    statementId: NumberParam,
    dateFrom: DateParam,
    dateTo: DateParam,
    statusList: ArrayParam
  });
  // 모든 setter를 하나의 객체로 반환...
}

// Good: 파라미터별 독립 Hook — 수정 영향 범위가 좁아짐
function useCardIdQueryParam() {
  const [cardId, setCardId] = useQueryParam("cardId", NumberParam);
  return [cardId ?? undefined, setCardId] as const;
}
```

### 2. 중복 코드 허용 — useBottomSheet

비슷해 보이는 로직을 공유 Hook으로 통합하면, 페이지별 요구사항이 달라질 때 공유 코드가 복잡해진다.

```typescript
// Bad: 공유 Hook — 페이지별 로깅 값, 닫기 동작이 달라지면 분기 폭발
export const useOpenMaintenanceBottomSheet = () => {
  const logger = useLogger();
  return async (info) => {
    logger.log("점검 바텀시트 열림");  // 페이지마다 다른 로그가 필요하다면?
    const result = await bottomSheet.open(info);
    closeView();  // 일부 페이지에서는 닫지 않아야 한다면?
  };
};

// Good: 각 페이지에서 직접 작성 — 독립적으로 변경 가능
// 동작이 완전히 동일하고 분기 가능성이 없을 때만 통합
```

### 3. Props Drilling 해소 — Composition 우선

```tsx
// Bad: Props가 중간 컴포넌트를 그대로 통과 (drilling)
<ItemEditBody items={items} recommendedItems={recommendedItems}
  onConfirm={onConfirm} onClose={onClose} keyword={keyword} />

// Good: children으로 drilling 제거 — 중간 계층이 불필요한 props를 알 필요 없음
<ItemEditBody keyword={keyword} onKeywordChange={setKeyword} onClose={onClose}>
  <ItemEditList items={items} recommendedItems={recommendedItems}
    onConfirm={onConfirm} />
</ItemEditBody>
```

**Props Drilling 해소 우선순위:**
1. props 자체는 나쁘지 않다 — 데이터 흐름을 명확히 표현
2. **children(Composition)을 먼저 시도** — 중간 계층 제거
3. Context API는 최후의 수단 — Composition만으로 불충분할 때만 사용
