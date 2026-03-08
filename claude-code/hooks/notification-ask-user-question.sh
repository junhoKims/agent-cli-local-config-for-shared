#!/bin/bash
###############################################
# Notification(elicitation_dialog) hook:
#   사용자 입력이 필요한 다이얼로그 표시 시
#   macOS 알림을 보내는 스크립트
###############################################

# stdin 소비 (matcher가 elicitation_dialog으로 한정되므로 분기 불필요)
cat > /dev/null

osascript -e 'display notification "❓ Question needs your answer" with title "Question Ready" sound name "Submarine"'
