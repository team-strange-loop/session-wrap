#!/bin/bash
# find-session-files.sh - 세션 ID로 관련 파일 찾기
#
# 사용법: ./find-session-files.sh <session-id> [codex|claude|all]
#
# 검색 대상:
# - Codex history/session files
# - Claude Code session logs
# - Claude Code debug logs
# - Claude Code agent transcripts and TODO files

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <session-id> [codex|claude|all]"
    echo ""
    echo "Finds files related to a Codex or Claude Code session."
    echo ""
    echo "Session ID can be:"
    echo "  - Full UUID: 0d2c9ac7-e0ab-427c-a9bc-709886b749c5"
    echo "  - Partial: 0d2c9ac7"
    echo "  - A direct path to a log/session file"
    echo ""
    echo "Files searched:"
    echo "  - ~/.codex/               (Codex history/session files)"
    echo "  - ~/.claude/projects/*/     (session logs)"
    echo "  - ~/.claude/todos/          (todo files)"
    echo "  - ~/.claude/agent-transcripts/  (agent logs)"
    exit 1
fi

SESSION_ID="$1"
RUNTIME="${2:-all}"
CODEX_DIR="${HOME}/.codex"
CLAUDE_DIR="${HOME}/.claude"

echo "=== Searching for Session: $SESSION_ID ==="
echo ""

if [ -f "$SESSION_ID" ]; then
    echo "--- Direct File ---"
    echo "$SESSION_ID"
    echo ""
    exit 0
fi

if [ "$RUNTIME" = "codex" ] || [ "$RUNTIME" = "all" ]; then
    echo "--- Codex Files ---"
    if [ -d "$CODEX_DIR" ]; then
        find "$CODEX_DIR" -type f \( -name "*${SESSION_ID}*" -o -name "*.jsonl" \) 2>/dev/null | head -50 || echo "(none found)"
    else
        echo "(~/.codex directory not found)"
    fi
    echo ""
fi

if [ "$RUNTIME" = "claude" ] || [ "$RUNTIME" = "all" ]; then
    # 메인 세션 로그
    echo "--- Claude Code Session Logs (.jsonl) ---"
    find "$CLAUDE_DIR/projects" -name "*${SESSION_ID}*.jsonl" 2>/dev/null || echo "(none found)"
    echo ""

    # 디버그 로그
    echo "--- Claude Code Debug Logs ---"
    if [ -d "$CLAUDE_DIR/logs" ]; then
        find "$CLAUDE_DIR/logs" -name "*${SESSION_ID}*" 2>/dev/null || echo "(none found)"
    else
        echo "(logs directory not found)"
    fi
    echo ""

    # TODO 파일
    echo "--- Claude Code TODO Files ---"
    if [ -d "$CLAUDE_DIR/todos" ]; then
        find "$CLAUDE_DIR/todos" -name "*${SESSION_ID}*" 2>/dev/null || echo "(none found)"
    else
        echo "(todos directory not found)"
    fi
    echo ""

    # 에이전트 트랜스크립트
    echo "--- Claude Code Agent Transcripts ---"
    if [ -d "$CLAUDE_DIR/agent-transcripts" ]; then
        find "$CLAUDE_DIR/agent-transcripts" -name "*${SESSION_ID}*" 2>/dev/null || echo "(none found)"
    else
        echo "(agent-transcripts directory not found)"
    fi
    echo ""

    echo "=== Recent Claude Code Session Files (last 5) ==="
    find "$CLAUDE_DIR/projects" -name "*.jsonl" -type f 2>/dev/null | \
        xargs ls -lt 2>/dev/null | head -5 || echo "(none found)"

    echo ""
    echo "=== Claude Code Session File Details ==="
    SESSION_FILE=$(find "$CLAUDE_DIR/projects" -name "*${SESSION_ID}*.jsonl" 2>/dev/null | head -1)
    if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
        echo "File: $SESSION_FILE"
        echo "Size: $(ls -lh "$SESSION_FILE" | awk '{print $5}')"
        echo "Lines: $(wc -l < "$SESSION_FILE")"
        echo "Modified: $(ls -l "$SESSION_FILE" | awk '{print $6, $7, $8}')"

        if command -v jq &> /dev/null; then
            echo ""
            echo "Message Types:"
            jq -r '.type' "$SESSION_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10
        fi
    else
        echo "(session file not found)"
    fi
fi

if [ "$RUNTIME" = "codex" ] || [ "$RUNTIME" = "all" ]; then
    echo ""
    echo "=== Codex File Details ==="
    CODEX_FILE=$(find "$CODEX_DIR" -type f -name "*${SESSION_ID}*" 2>/dev/null | head -1)
    if [ -z "$CODEX_FILE" ] && [ -f "$CODEX_DIR/history.jsonl" ]; then
        CODEX_FILE="$CODEX_DIR/history.jsonl"
    fi
    if [ -n "$CODEX_FILE" ] && [ -f "$CODEX_FILE" ]; then
        echo "File: $CODEX_FILE"
        echo "Size: $(ls -lh "$CODEX_FILE" | awk '{print $5}')"
        echo "Lines: $(wc -l < "$CODEX_FILE")"
        echo "Modified: $(ls -l "$CODEX_FILE" | awk '{print $6, $7, $8}')"
    else
        echo "(codex file not found)"
    fi
fi
