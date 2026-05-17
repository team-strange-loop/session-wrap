#!/bin/bash
# extract-hook-events.sh - 디버그 로그에서 Hook 이벤트 추출
#
# 사용법: ./extract-hook-events.sh <debug-log.txt>
#
# 추출 대상:
# - PreToolUse, PostToolUse, Stop, SubagentStop 이벤트
# - Prompt hook 결과 (met/not met)
# - Permission decisions

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <debug-log.txt>"
    echo ""
    echo "Extracts hook events from Claude Code debug logs."
    echo "Shows PreToolUse, PostToolUse, Stop, SubagentStop events."
    exit 1
fi

DEBUG_LOG="$1"

if [ ! -f "$DEBUG_LOG" ]; then
    echo "Error: File not found: $DEBUG_LOG"
    exit 1
fi

echo "=== Hook Events from: $DEBUG_LOG ==="
echo ""

# PreToolUse 이벤트
echo "--- PreToolUse Events ---"
grep -E "PreToolUse|preToolUse" "$DEBUG_LOG" 2>/dev/null | head -50 || echo "(none found)"
echo ""

# PostToolUse 이벤트
echo "--- PostToolUse Events ---"
grep -E "PostToolUse|postToolUse" "$DEBUG_LOG" 2>/dev/null | head -50 || echo "(none found)"
echo ""

# Stop 이벤트
echo "--- Stop Events ---"
grep -E "Stop hook|StopHook|onStop" "$DEBUG_LOG" 2>/dev/null | head -20 || echo "(none found)"
echo ""

# SubagentStop 이벤트
echo "--- SubagentStop Events ---"
grep -E "SubagentStop|subagentStop" "$DEBUG_LOG" 2>/dev/null | head -20 || echo "(none found)"
echo ""

# Prompt hook 결과
echo "--- Prompt Hook Results ---"
grep -E "prompt.*met|condition.*met|hook.*result" -i "$DEBUG_LOG" 2>/dev/null | head -30 || echo "(none found)"
echo ""

# Permission decisions
echo "--- Permission Decisions ---"
grep -E "permission|allowed|denied|blocked" -i "$DEBUG_LOG" 2>/dev/null | head -30 || echo "(none found)"
echo ""

# Hook 실행 통계
echo "=== Hook Statistics ==="
echo "PreToolUse:   $(grep -c -E "PreToolUse|preToolUse" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "PostToolUse:  $(grep -c -E "PostToolUse|postToolUse" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "Stop:         $(grep -c -E "Stop hook|StopHook|onStop" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "SubagentStop: $(grep -c -E "SubagentStop|subagentStop" "$DEBUG_LOG" 2>/dev/null || echo "0")"
