#!/bin/bash
###############################################
# PreToolUse(ExitPlanMode) hook:
#   Plan Mode 완료 시 macOS 알림을 보내는 스크립트
###############################################

# stdin 소비 (matcher가 ExitPlanMode로 한정되므로 분기 불필요)
cat > /dev/null

osascript -e 'display notification "📋 Plan ready for approval" with title "Plan Ready" sound name "Submarine"'
