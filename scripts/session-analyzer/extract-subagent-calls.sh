#!/bin/bash
# extract-subagent-calls.sh - 디버그 로그에서 SubAgent 호출 추출
#
# 사용법: ./extract-subagent-calls.sh <debug-log.txt>
#
# 추출 대상:
# - SubagentStart/SubagentStop 이벤트
# - 에이전트별 카운트 (Explore, gap-analyzer, reviewer, worker 등)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <debug-log.txt>"
    echo ""
    echo "Extracts SubAgent calls from Claude Code debug logs."
    echo "Shows agent types and execution counts."
    exit 1
fi

DEBUG_LOG="$1"

if [ ! -f "$DEBUG_LOG" ]; then
    echo "Error: File not found: $DEBUG_LOG"
    exit 1
fi

echo "=== SubAgent Calls from: $DEBUG_LOG ==="
echo ""

# SubagentStart 이벤트
echo "--- SubagentStart Events ---"
grep -E "SubagentStart|subagent.*start|Task.*agent" -i "$DEBUG_LOG" 2>/dev/null | head -50 || echo "(none found)"
echo ""

# SubagentStop 이벤트
echo "--- SubagentStop Events ---"
grep -E "SubagentStop|subagent.*stop|subagent.*complete" -i "$DEBUG_LOG" 2>/dev/null | head -50 || echo "(none found)"
echo ""

# 에이전트 타입별 호출
echo "=== Agent Type Breakdown ==="

echo ""
echo "Built-in Agents:"
echo "  Explore:         $(grep -c -E "Explore|explore.*agent" -i "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  Plan:            $(grep -c -E "Plan.*agent|planning" -i "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  Bash:            $(grep -c -E "Bash.*agent" -i "$DEBUG_LOG" 2>/dev/null || echo "0")"

echo ""
echo "Plugin Agents (session-wrap):"
echo "  doc-updater:       $(grep -c -E "doc-updater" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  automation-scout:  $(grep -c -E "automation-scout" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  learning-extractor: $(grep -c -E "learning-extractor" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  followup-suggester: $(grep -c -E "followup-suggester" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  duplicate-checker: $(grep -c -E "duplicate-checker" "$DEBUG_LOG" 2>/dev/null || echo "0")"

echo ""
echo "Plugin Agents (plugin-dev):"
echo "  gap-analyzer:    $(grep -c -E "gap-analyzer" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  reviewer:        $(grep -c -E "reviewer" "$DEBUG_LOG" 2>/dev/null || echo "0")"
echo "  worker:          $(grep -c -E "worker" "$DEBUG_LOG" 2>/dev/null || echo "0")"

echo ""
echo "=== Timeline (first 20 agent events) ==="
grep -E "Subagent|Task.*agent|agent.*start|agent.*stop" -i "$DEBUG_LOG" 2>/dev/null | head -20 || echo "(none found)"
