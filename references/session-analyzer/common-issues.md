# Common Issues in Session Analysis

세션 분석 시 자주 발생하는 문제와 해결책.

## 세션 파일 이슈

### 세션 파일을 찾을 수 없음

**증상**: 세션 ID로 파일을 찾을 수 없음

**원인**:
- 잘못된 세션 ID
- 세션이 아직 저장되지 않음
- 다른 프로젝트 디렉토리에 저장됨

**해결책**:
```bash
# 최근 세션 파일 확인
ls -lt ~/.claude/projects/*/  | head -20

# 모든 프로젝트에서 검색
find ~/.claude/projects -name "*.jsonl" -mmin -60

# 부분 ID로 검색
find ~/.claude/projects -name "*abc123*"
```

### 세션 파일이 너무 큼

**증상**: jq 처리 시 메모리 부족 또는 느림

**원인**: `file-history-snapshot`이 대부분의 용량 차지

**해결책**:
```bash
# 대화만 추출 (extract-session.sh 사용)
./extract-session.sh large-session.jsonl

# 또는 수동으로 스냅샷 제외
jq -c 'select(.type != "file-history-snapshot")' session.jsonl > filtered.jsonl
```

### JSONL 파싱 오류

**증상**: `jq: parse error`

**원인**:
- 잘린 JSON 라인
- 인코딩 문제

**해결책**:
```bash
# 문제 라인 찾기
cat -n session.jsonl | while read line; do
  echo "$line" | jq . > /dev/null 2>&1 || echo "Error at: $line"
done

# 유효한 라인만 추출
while read line; do
  echo "$line" | jq . > /dev/null 2>&1 && echo "$line"
done < session.jsonl > valid.jsonl
```

## SubAgent 분석 이슈

### SubAgent 로그가 없음

**증상**: 디버그 로그에서 SubAgent 이벤트 없음

**원인**:
- 디버그 모드 미활성화
- 에이전트가 사용되지 않음
- 다른 로그 레벨 설정

**해결책**:
```bash
# 디버그 모드로 Claude Code 실행
CLAUDE_DEBUG=1 claude

# 또는 세션 파일에서 Task 도구 사용 확인
jq 'select(.type == "assistant") | .message.content[] | select(.name == "Task")' session.jsonl
```

### 에이전트 실행 순서 불명확

**증상**: 어떤 에이전트가 먼저 실행됐는지 모름

**해결책**:
```bash
# 타임스탬프로 정렬
grep -E "Subagent" debug.log | sort -t'T' -k1

# 세션 파일에서 순서 확인
jq -c 'select(.type == "assistant") |
  {ts: .timestamp, tools: [.message.content[] | select(.type == "tool_use") | .name]}' session.jsonl
```

## Hook 분석 이슈

### Hook이 실행되지 않음

**증상**: Hook 이벤트가 로그에 없음

**원인**:
- hooks.json 구문 오류
- 잘못된 이벤트 이름
- 조건이 충족되지 않음

**해결책**:
```bash
# hooks.json 유효성 검사
jq . plugins/*/hooks/hooks.json

# 이벤트 이름 확인 (대소문자 구분)
# 올바른 이름: PreToolUse, PostToolUse, Stop, SubagentStop

# 조건 확인
grep -E "condition|when|if" hooks.json
```

### Hook 실행은 되지만 효과 없음

**증상**: Hook 로그는 있지만 결과가 없음

**원인**:
- Hook 스크립트 오류
- 권한 문제
- 경로 문제 (${CLAUDE_PLUGIN_ROOT} vs ${pluginDir})

**해결책**:
```bash
# 스크립트 직접 실행 테스트
cd ~/.claude/plugins/cache/...
./scripts/my-hook.sh

# 실행 권한 확인
ls -la scripts/*.sh

# 환경 변수 확인
env | grep CLAUDE
```

## Reviewer 관련 이슈

### Reviewer가 잘못된 판단

**증상**: 안전한 코드를 위험으로 판단

**원인**:
- 컨텍스트 부족
- 과도한 보안 정책

**해결책**:
- Reviewer 프롬프트 조정
- 허용 패턴 명시
- 컨텍스트 추가 제공

### Reviewer 병목

**증상**: Reviewer에서 시간이 오래 걸림

**해결책**:
```bash
# Reviewer 호출 횟수 확인
grep -c "reviewer" debug.log

# 불필요한 Reviewer 호출 식별
grep -B 5 "reviewer" debug.log | grep "tool_use"
```

## 일반적인 디버깅 팁

### 1. 로그 레벨 확인
```bash
# 상세 로그 활성화
CLAUDE_DEBUG=1 CLAUDE_LOG_LEVEL=debug claude
```

### 2. 캐시 문제
```bash
# 플러그인 캐시 초기화
rm -rf ~/.claude/plugins/cache/*
```

### 3. 권한 문제
```bash
# 스크립트 실행 권한
chmod +x scripts/*.sh

# 디렉토리 권한
ls -la ~/.claude/
```

### 4. 환경 변수 확인
```bash
# Hook에서 사용 가능한 변수
echo "CLAUDE_PLUGIN_ROOT: $CLAUDE_PLUGIN_ROOT"
echo "Current dir: $(pwd)"
```
