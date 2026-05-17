---
name: wrap
description: This skill should be used when the user asks to "wrap up", "wrap", "세션 마무리", "마무리해줘", "end session", "finish coding", "commit changes", "summarize session", or wants to conclude a coding session. Multi-agent analysis for documentation updates, automation opportunities, learnings, and follow-up tasks.
version: 1.0.0
user-invocable: true
---

# Session Wrap Skill

멀티에이전트 분석을 통한 코딩 세션 마무리 종합 워크플로우.

## Trigger

- `/wrap` 커맨드
- "세션 마무리해줘"
- "wrap up this session"

## Allowed Tools

Bash(git:*), Read, Write, Edit, Glob, Grep, Task, AskUserQuestion

## Workflow

### Step 1: Git 상태 확인

```bash
git status --short
git diff --stat
```

분석 전 현재 변경사항을 평가한다.

### Step 2: Phase 1 - 병렬 분석

Task 도구를 사용하여 4개 에이전트를 **동시에** 실행:

| 에이전트 | 모델 | 목적 |
|---------|------|------|
| doc-updater | sonnet | CLAUDE.md/context.md 업데이트 |
| automation-scout | sonnet | 자동화 기회 탐색 |
| learning-extractor | sonnet | 교훈 및 발견사항 |
| followup-suggester | sonnet | 다음 단계 및 우선순위 |

### Step 3: Phase 2 - 검증

Phase 1 완료 후 실행:

| 에이전트 | 모델 | 목적 |
|---------|------|------|
| duplicate-checker | haiku | 제안 검증, 중복 방지 |

### Step 4: 결과 통합

모든 에이전트 결과를 종합 분석으로 합성:

```markdown
## 세션 마무리 분석

### 문서 업데이트
[doc-updater에서, duplicate-checker로 검증됨]

### 자동화 기회
[automation-scout에서, 검증됨]

### 교훈
[learning-extractor에서]

### 후속 작업
[followup-suggester에서]
```

### Step 5: 사용자 액션 선택

AskUserQuestion으로 옵션 제시:

- **커밋 생성** (권장) - 생성된 메시지로 현재 변경사항 커밋
- **CLAUDE.md 업데이트** - 문서 제안 적용
- **자동화 생성** - 제안된 skill/command/agent 생성
- **건너뛰기** - 액션 없이 종료

### Step 6: 선택된 액션 실행

#### "커밋 생성" 선택 시:
1. 세션 분석에서 커밋 메시지 생성
2. `git add`로 관련 파일 스테이징
3. 생성된 메시지로 커밋 생성

#### "CLAUDE.md 업데이트" 선택 시:
1. 현재 CLAUDE.md 읽기
2. doc-updater 제안 적용 (duplicate-checker로 검증됨)
3. 사용자 확인을 위해 diff 표시

#### "자동화 생성" 선택 시:

**6a. 제안 파싱**
automation-scout 출력에서 추출:
- 타입 (skill/command/agent)
- 이름 (kebab-case)
- 경로 (대상 파일 위치)
- 파일 내용 (`<file-content>`와 `</file-content>` 태그 사이)

**6b. 선택 제시**
여러 제안이 있는 경우, AskUserQuestion으로 사용자가 생성할 항목 선택.

**6c. 파일 스캐폴딩**
선택된 각 제안에 대해:

```
# Skills용
mkdir -p .claude/skills/{name}
# 생성된 내용으로 SKILL.md 작성

# Commands용
mkdir -p .claude/commands
# 생성된 내용으로 {name}.md 작성

# Agents용
mkdir -p .claude/agents
# 생성된 내용으로 {name}.md 작성
```

**6d. 생성 확인**
```bash
# 파일 생성 확인
ls -la .claude/skills/{name}/ 2>/dev/null || \
ls -la .claude/commands/{name}.md 2>/dev/null || \
ls -la .claude/agents/{name}.md 2>/dev/null
```

**6e. 성공 보고**
```markdown
자동화가 성공적으로 생성되었습니다!

**타입**: {type}
**이름**: {name}
**경로**: {path}

이제 `/{name}`으로 이 자동화를 호출할 수 있습니다.
```

#### "건너뛰기" 선택 시:
액션 없이 세션 마무리 종료.

## When to Use

- 코딩 세션 종료 시
- 기능 완료 시
- 컨텍스트 전환 전
- 프로젝트 체크포인트

## When to Skip

- 사소한 변경만 있을 때
- 순수 코드 읽기 세션
- 의미 있는 작업이 없을 때
