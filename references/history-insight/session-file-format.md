# Session File Format

Codex 및 Claude Code 세션 파일(.jsonl) 구조 문서.

## 파일 위치

```
~/.codex/history.jsonl
~/.claude/projects/<project-hash>/<session-id>.jsonl
```

## JSONL Type 분류

### 주요 타입과 크기 분포

| Type | 설명 | 크기 비중 |
|------|------|----------|
| `user` | 사용자 메시지 | ~1% |
| `assistant` | Claude 응답 | ~5-10% |
| `file-history-snapshot` | 파일 상태 스냅샷 | ~60-70% |
| `queue-operation` | 큐 작업 기록 | ~15-20% |
| `summary` | 대화 요약 | ~1% |

Codex의 `~/.codex/history.jsonl`은 버전과 환경에 따라 필드가 다를 수
있으므로, 먼저 `jq -r 'keys'` 또는 샘플 라인으로 구조를 확인한다.

### 타입별 구조

#### user
```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": "메시지 내용"
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

#### assistant
```json
{
  "type": "assistant",
  "message": {
    "role": "assistant",
    "content": [
      {"type": "thinking", "thinking": "..."},
      {"type": "text", "text": "..."},
      {"type": "tool_use", "id": "...", "name": "Bash", "input": {...}}
    ]
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

#### file-history-snapshot
```json
{
  "type": "file-history-snapshot",
  "files": {
    "/path/to/file.js": {
      "content": "파일 전체 내용...",
      "hash": "abc123"
    }
  }
}
```

## assistant 메시지 내부 구조

`assistant.message.content`는 배열로 여러 블록 포함:

### thinking
- Claude의 내부 사고 과정
- 분석에 불필요, 크기가 큼
- 추출 시 제외 권장

### text
- 사용자에게 보여지는 실제 응답
- 분석의 핵심 데이터

### tool_use
- 도구 호출 기록
- `name`: 도구 이름 (Bash, Read, Write, Edit, Task 등)
- `input`: 도구 입력 파라미터
- `id`: 결과 매칭용 ID

### tool_result
- 도구 실행 결과
- `tool_use_id`로 호출과 매칭

## jq 파싱 명령어 예시

### 메시지 타입 분포 확인
```bash
jq -r '.type' session.jsonl | sort | uniq -c | sort -rn
```

### user 메시지만 추출
```bash
jq -c 'select(.type == "user")' session.jsonl
```

### assistant 텍스트만 추출
```bash
jq -r 'select(.type == "assistant") |
  .message.content[] |
  select(.type == "text") |
  .text' session.jsonl
```

### 사용된 도구 목록
```bash
jq -r 'select(.type == "assistant") |
  .message.content[] |
  select(.type == "tool_use") |
  .name' session.jsonl | sort | uniq -c
```

### thinking 제외한 assistant 메시지
```bash
jq -c 'select(.type == "assistant") |
  .message.content = [.message.content[] |
  select(.type != "thinking")]' session.jsonl
```

### 파일 크기 기여도 분석
```bash
jq -c 'select(.type == "file-history-snapshot")' session.jsonl | wc -c
jq -c 'select(.type != "file-history-snapshot")' session.jsonl | wc -c
```

## 최적화 팁

1. **대화 분석 시**: `file-history-snapshot`, `queue-operation` 제외
2. **파일 변경 추적 시**: `file-history-snapshot` 활용
3. **도구 사용 패턴 분석 시**: `tool_use` 블록 집중
4. **컨텍스트 크기 최소화**: `thinking` 블록 제외
5. **대화 내용만 추출 시**: assistant `text` 블록만 보존하고
   `tool_use`/`tool_result`는 제외
