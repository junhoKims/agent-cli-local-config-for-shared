# SOLID 원칙 — 프론트엔드/백엔드 적용 가이드

> 출처: [SOLID Principle for Front-End](https://medium.com/@syazantri/solid-principle-for-front-end-85e2a2d2be40)

## SRP — 단일 책임 원칙

하나의 모듈/함수는 하나의 책임만 가진다. API 호출을 기능별로 분리한다.

```typescript
// Bad: 하나의 파일에 모든 API 호출
export const fetchSchedule = () => { /* ... */ };
export const fetchUsers = () => { /* ... */ };
export const login = () => { /* ... */ };

// Good: 관심사별 파일 분리
// api/schedule.ts
export const fetchSchedule = () => { /* ... */ };
// api/auth.ts
export const login = () => { /* ... */ };
```

## OCP — 개방-폐쇄 원칙

기존 코드를 수정하지 않고 기능을 확장할 수 있어야 한다.

```typescript
// Bad: 새 정렬 기준 추가 시 함수 내부 수정 필요
function sortRooms(rooms: Room[], type: string) {
  if (type === 'name') { /* ... */ }
  else if (type === 'date') { /* ... */ }
  // 새 정렬 기준마다 else if 추가...
}

// Good: 정렬 전략을 외부에서 주입
function sortRooms(rooms: Room[], compareFn: (a: Room, b: Room) => number) {
  return [...rooms].sort(compareFn);
}
```

## LSP — 리스코프 치환 원칙

하위 타입은 상위 타입을 대체할 수 있어야 한다. 컴포넌트 변형(variant)이 일관된 인터페이스를 유지한다.

```tsx
// Good: 모든 Button variant가 동일 인터페이스로 동작
<Button variant="primary" onClick={handleClick}>확인</Button>
<Button variant="danger" onClick={handleClick}>삭제</Button>
<Button variant="custom" color="#333" onClick={handleClick}>커스텀</Button>
```

## ISP — 인터페이스 분리 원칙

컴포넌트는 사용하지 않는 Props에 의존하지 않는다.

```typescript
// Bad: 불필요한 Props까지 포함
interface RoomFormProps {
  roomName: string;
  roomCapacity: number;
  buildingAddress: string;  // 이 컴포넌트에서 불필요
  buildingFloor: number;    // 이 컴포넌트에서 불필요
}

// Good: 필요한 Props만 수신
interface RoomFormProps {
  roomName: string;
  roomCapacity: number;
}
```

## DIP — 의존성 역전 원칙

구체 구현이 아닌 추상화에 의존한다.

```typescript
// Bad: axios에 직접 의존
import axios from 'axios';
const fetchData = () => axios.get('/api/data');

// Good: 추상화된 HTTP 클라이언트에 의존
import { httpClient } from '@/lib/httpClient';
const fetchData = () => httpClient.get('/api/data');
// httpClient 내부 구현(axios/fetch)은 교체 가능
```

## 적용 판단 기준

| 상황 | 적용 수준 |
| --- | --- |
| 여러 곳에서 재사용되는 모듈 | SOLID 적극 적용 |
| 한 곳에서만 쓰는 로직 | SRP 정도만. 과도한 추상화 불필요 |
| Props가 5개 이상 늘어나는 컴포넌트 | ISP 재검토, 컴포넌트 분리 고려 |
| 외부 라이브러리 직접 사용 | DIP로 래핑하여 교체 가능하게 |
