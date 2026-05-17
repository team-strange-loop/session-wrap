# Session Analysis Patterns

디버그 로그 분석을 위한 패턴과 grep 명령어 모음.

## SubAgent 분석 패턴

### 에이전트 실행 흐름
```bash
# SubAgent 시작/종료 이벤트
grep -E "Subagent(Start|Stop)" debug.log

# 특정 에이전트 타입 추적
grep -E "Explore|Plan|Bash" debug.log | grep -i agent

# 에이전트 실행 시간
grep -E "subagent.*duration|agent.*ms" debug.log
```

### 에이전트 결과 분석
```bash
# 에이전트 출력
grep -A 5 "SubagentStop" debug.log

# 에이전트 오류
grep -E "subagent.*error|agent.*failed" -i debug.log
```

## Hook 분석 패턴

### Hook 실행 추적
```bash
# 모든 Hook 이벤트
grep -E "Hook|hook" debug.log

# 특정 Hook 타입
grep -E "PreToolUse|PostToolUse|Stop|SubagentStop" debug.log

# Hook 조건 평가
grep -E "condition.*met|prompt.*result" debug.log
```

### Hook 성능 분석
```bash
# Hook 실행 시간
grep -E "hook.*ms|hook.*duration" debug.log

# Hook 실패
grep -E "hook.*error|hook.*failed" -i debug.log
```

## Tool Usage 패턴

### 도구 호출 통계
```bash
# 도구별 호출 횟수
grep -E "tool_use|ToolUse" debug.log | \
  grep -oE "name\":\"[^\"]+\"" | sort | uniq -c | sort -rn

# Bash 명령어 목록
grep -E "Bash.*command" debug.log | head -20

# 파일 읽기/쓰기
grep -E "Read|Write|Edit" debug.log | head -20
```

### 도구 실행 결과
```bash
# 도구 성공/실패
grep -E "tool_result|ToolResult" debug.log | \
  grep -E "success|error|failed" | head -20

# 도구 실행 시간
grep -E "tool.*duration|tool.*ms" debug.log
```

## Timeline 재구성 방법

### 시간순 이벤트 정렬
```bash
# 타임스탬프가 있는 로그
grep -E "^\d{4}-\d{2}-\d{2}|^\[\d{2}:" debug.log | head -50

# 주요 이벤트만 추출
grep -E "Start|Stop|Complete|Error" debug.log | head -50
```

### 이벤트 시퀀스 분석
```bash
# user → assistant → tool_use 흐름
grep -E "user|assistant|tool_use" debug.log | head -100

# 세션 시작부터 종료까지
grep -E "session.*start|session.*end|SessionStart|SessionEnd" debug.log
```

## 복합 분석 예시

### 세션 요약 생성
```bash
# 1. 기본 통계
echo "=== Session Stats ==="
wc -l debug.log
grep -c "user" debug.log
grep -c "assistant" debug.log
grep -c "tool_use" debug.log

# 2. 에이전트 사용량
echo "=== Agent Usage ==="
grep -E "Subagent" debug.log | grep -oE "type\":\"[^\"]+\"" | sort | uniq -c

# 3. 오류 요약
echo "=== Errors ==="
grep -i "error" debug.log | head -10
```

### 성능 병목 찾기
```bash
# 긴 실행 시간
grep -E "\d{4,}ms" debug.log

# 반복되는 도구 호출
grep -E "tool_use" debug.log | sort | uniq -d

# 실패 후 재시도 패턴
grep -B 2 -A 2 "retry|failed.*retry" debug.log
```

## 유용한 One-liner

```bash
# 세션 파일에서 대화 요약
jq -r 'select(.type == "user") | .message.content' session.jsonl | head -20

# 가장 많이 사용된 도구 Top 5
jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "tool_use") | .name' session.jsonl | sort | uniq -c | sort -rn | head -5

# 에러가 발생한 도구 호출
grep -B 5 "error" session.jsonl | grep "tool_use"
```
