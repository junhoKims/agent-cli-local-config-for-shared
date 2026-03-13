## 언어 및 커뮤니케이션 규칙 (IMPORTANT)

- 🗺 기본 응답 언어: 한국어
- 📋 코드 주석: 한국어로 작성
- 📁 커밋 메시지: 컨벤션 규칙 링크를 참고하여 한국어로 작성 (https://www.conventionalcommits.org/en/v1.0.0/#summary)
- 🎨 문서화: 한국어로 작성
- 🧩 변수명/함수명: 영어 (코드 표준 준수)

## 코드 스타일

- 🗺 ES 모듈(import/export) 구문을 사용하고, CommonJS(require)는 사용하지 마십시오
- 📋 가능하면 import를 구조 분해하십시오 (예: import { foo } from 'bar')

## 워크플로우

- 🗺 일련의 코드 변경을 완료할 때 반드시 타입 체크를 하십시오
- 📋 성능상 이유로 전체 테스트 스위트가 아닌 단일 테스트 실행을 선호하십시오

## 자주 사용하는 명령어

```bash
npm run dev         # 개발 서버 실행 (일반적으로 http://localhost:3000)
npm run build       # 프로덕션 빌드 실행
npm run check:lint  # 린트 검사 실행
npm run check:type  # 타입 검사 실행 (권장)
```

## 작업 완료 체크리스트

```bash
npm run check:type  # 모든 검사 통과 확인
npm run build       # 빌드 성공 확인
```

@RTK.md
