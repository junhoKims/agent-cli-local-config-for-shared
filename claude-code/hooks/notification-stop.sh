#!/bin/bash
###############################################
# Stop hook: 세션 종료 시 macOS 알림을 보내는 스크립트
#
# 분류 기준:
#   - token_limit → 토큰 리밋 초과로 중지
#   - normal      → 정상 완료
###############################################

INPUT=$(cat)

###############################################
# macOS 알림을 발송한다
# @param $1 - 알림 제목
# @param $2 - 알림 본문
# @param $3 - 알림 사운드 이름
###############################################
send_notification() {
    local title="$1"
    local desc="$2"
    local sound="$3"

    osascript -e "display notification \"$desc\" with title \"$title\" sound name \"$sound\""
}

###############################################
# transcript JSONL 파일을 분석하여 중지 사유를 분류한다.
# stdout으로 분류 결과 문자열을 출력한다.
#
# 분류 로직:
#   1. JSONL 파싱
#   2. 마지막 20개 엔트리에서 에러 확인
#   3. 에러 내용에 토큰/리밋 관련 키워드 매칭
#   4. 결과: "token_limit" 또는 "normal"
#
# @param $1 - JSONL 파일 경로
# @output token_limit | normal
###############################################
classify_stop_reason() {
    TRANSCRIPT_PATH="$1" python3 - << 'PYEOF'
import json, sys, os

path = os.environ['TRANSCRIPT_PATH']

entries = []
try:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except:
                    pass
except Exception:
    print('normal')
    sys.exit()

# 마지막 20개 엔트리에서 에러 확인
token_keywords = ['token', 'limit', 'context', 'capacity', 'too long']

for entry in entries[-20:]:
    is_error = entry.get('isApiErrorMessage') or entry.get('error')
    if not is_error:
        continue

    # 에러 내용을 문자열로 변환하여 키워드 매칭
    error_str = json.dumps(entry, ensure_ascii=False).lower()
    for keyword in token_keywords:
        if keyword in error_str:
            print('token_limit')
            sys.exit()

print('normal')
PYEOF
}

###############################################
# 메인
# 1. stdin JSON에서 transcript_path 추출
# 2. classify_stop_reason()으로 분류
# 3. 분류 결과에 따라 알림 발송
###############################################
main() {
    local transcript_path
    transcript_path=$(echo "$INPUT" | python3 -c "import json,sys; hook_input=json.load(sys.stdin); print(hook_input.get('transcript_path',''))" 2>/dev/null)

    local reason="normal"

    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
        reason=$(classify_stop_reason "$transcript_path")
    fi

    case "$reason" in
        "token_limit")
            send_notification "Task Stop" "Limit Token" "Hero"
            ;;
        *)
            send_notification "Task Complete" "Main task completed" "Hero"
            ;;
    esac
}

main
