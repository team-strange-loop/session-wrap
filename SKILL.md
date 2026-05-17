---
name: wrap
description: This skill should be used when the user asks to "wrap up", "wrap", "세션 마무리", "마무리해줘", "end session", "finish coding", "commit changes", "summarize session", "analyze session", "세션 분석", "validate skill", "check session logs", "debug skill", or wants to conclude or analyze a Codex or Claude Code coding session. Supports session wrap-up, follow-up planning, and post-hoc skill/session validation.
version: 1.0.0
user-invocable: true
---

# Session Wrap Skill

Conclude or analyze coding sessions for Codex and Claude Code.

Use this skill in two modes:

- **Wrap Mode**: summarize current work, identify documentation updates,
  automation opportunities, learnings, and follow-up tasks.
- **Analysis Mode**: inspect saved session logs and validate behavior against a
  `SKILL.md` or explicit acceptance criteria.

## Trigger

- `/wrap`
- "세션 마무리해줘"
- "wrap up this session"
- "analyze session"
- "validate this session against a skill"

## Runtime Detection

Detect the active agent runtime from available tools and files:

- **Codex**: use `spawn_agent` for delegated analysis when available,
  `multi_tool_use.parallel` for parallel file reads/commands, and normal chat
  for user decisions. Codex history is commonly in `~/.codex/history.jsonl`.
- **Claude Code**: use `Task` for delegated analysis, `AskUserQuestion` for
  explicit options, and inspect `~/.claude/projects/**/*.jsonl` plus debug logs
  when analyzing sessions.
- **Fallback**: if delegation tools are unavailable, do the analysis locally and
  clearly say which checks were skipped.

Do not assume Claude Code-specific paths or tools when running in Codex.

## Wrap Mode Workflow

### Step 1: Git Status Check

```bash
git status --short
git diff --stat
```

Assess current changes before analysis.

### Step 2: Phase 1 - Parallel Analysis

Launch four independent analyses in parallel when the runtime supports it.

| Workstream | Purpose |
|------------|---------|
| documentation | Project memory updates such as `AGENT.md`, `AGENTS.md`, `CLAUDE.md`, or local context docs |
| automation | Repeated workflows that could become scripts, skills, commands, or agents |
| learning | Lessons, gotchas, and discoveries worth preserving |
| follow-up | Next tasks, risks, and priorities |

Runtime guidance:

- In Codex, use separate `spawn_agent` calls only if the user explicitly asked
  for delegation or parallel agents; otherwise run the workstreams locally.
- In Claude Code, use `Task` agents if available.
- Without delegation, produce the same four sections from local analysis.

### Step 3: Phase 2 - Validation

Validate proposals before presenting them:

- Check whether suggested docs or automations already exist.
- Check whether current git changes support the summary.
- Remove low-confidence or duplicate suggestions.

### Step 4: Result Integration

Synthesize all agent findings into comprehensive wrap analysis:

```markdown
## Session Wrap Analysis

### Documentation Updates
[Validated proposals]

### Automation Opportunities
[Validated proposals]

### Learnings
[Notable discoveries]

### Follow-up Tasks
[Prioritized tasks]
```

### Step 5: User Action Selection

Present options using the runtime's user input mechanism or plain chat:

- **Create commit** (Recommended) - Commit current changes with generated message
- **Update project memory** - Apply documentation proposals
- **Create automation** - Generate proposed skill/command/agent
- **Skip** - End without action

### Step 6: Execute Selected Actions

#### If "Create commit" selected:
1. Generate commit message from session analysis
2. Stage relevant files with `git add`
3. Create commit with generated message

#### If "Update project memory" selected:
1. Find the active project memory file, preferring `AGENT.md`, `AGENTS.md`,
   `CLAUDE.md`, or the file the user names.
2. Apply validated documentation proposals.
3. Show diff to user for confirmation

#### If "Create automation" selected:

**6a. Parse Proposals**
Extract from automation-scout output:
- Type (skill/command/agent)
- Name (kebab-case)
- Path (target file location)
- File content (between `<file-content>` and `</file-content>` tags)

**6b. Present Selection**
If multiple proposals exist, use AskUserQuestion to let user select which to create.

**6c. Scaffold Files**
For each selected proposal:

```
# For skills in Claude Code-style projects
mkdir -p .claude/skills/{name}
# Write SKILL.md with the generated content

# For commands in Claude Code-style projects
mkdir -p .claude/commands
# Write {name}.md with the generated content

# For agents in Claude Code-style projects
mkdir -p .claude/agents
# Write {name}.md with the generated content

# For Codex-style reusable skills
mkdir -p skills/{name}
# Write SKILL.md at the skill root
```

**6d. Verify Creation**
```bash
# Confirm files were created
ls -la .claude/skills/{name}/ 2>/dev/null || \
ls -la .claude/commands/{name}.md 2>/dev/null || \
ls -la .claude/agents/{name}.md 2>/dev/null
```

**6e. Report Success**
```markdown
✅ Automation created successfully!

**Type**: {type}
**Name**: {name}
**Path**: {path}

You can now invoke this automation according to the active runtime.
```

#### If "Skip" selected:
End session wrap without performing any actions.

## Analysis Mode Workflow

Use Analysis Mode when the user asks to analyze logs, validate a skill, debug a
session, or compare observed behavior with `SKILL.md`.

### Inputs

| Input | Description | Required |
|-------|-------------|----------|
| sessionId | Session UUID, partial ID, or path to a session/log file | Yes |
| targetSkill | Path to `SKILL.md` or explicit expected behavior | Usually |
| runtime | `codex`, `claude-code`, or auto-detected | No |

### Step 1: Locate Session Evidence

If the user provides a path, use it directly. Otherwise search likely runtime
locations:

```bash
# Codex
find ~/.codex -name "*.jsonl" -o -name "history.jsonl"

# Claude Code
find ~/.claude -name "*${sessionId}*" -type f
```

For Claude Code session discovery, use:

```bash
scripts/session-analyzer/find-session-files.sh <session-id>
```

### Step 2: Parse Expected Behavior

Read the target `SKILL.md` and extract:

- required workflow steps
- expected tool usage
- expected delegated agents or subagents
- expected hooks or runtime events
- expected files or artifacts
- explicit user acceptance criteria

### Step 3: Parse Actual Behavior

Inspect logs for:

- user requests and assistant responses
- tool calls and command results
- delegated agent/subagent calls
- hook events, when the runtime supports hooks
- file operations and final artifacts

Helpful references:

- `references/session-analyzer/analysis-patterns.md`
- `references/session-analyzer/common-issues.md`

Helpful scripts:

- `scripts/session-analyzer/extract-subagent-calls.sh`
- `scripts/session-analyzer/extract-hook-events.sh`
- `scripts/session-analyzer/find-session-files.sh`

### Step 4: Compare and Report

Use this output shape:

```markdown
## Session Analysis Report

### Summary
- Runtime: Codex | Claude Code | Unknown
- Session: <id-or-path>
- Target: <skill-or-requirements>
- Overall: PASS | PARTIAL | FAIL

### Verification Details

| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
| Workflow step | <expected> | <observed> | PASS/PARTIAL/FAIL |

### Issues Found
1. <issue>
   - Expected: <expected>
   - Actual: <actual>
   - Impact: <impact>

### Recommendations
- <specific fix>
```

## Runtime-Specific Notes

### Codex

- Prefer `AGENT.md` or `AGENTS.md` for project memory updates.
- Use `spawn_agent` only when the user explicitly authorizes subagents or
  parallel agent work.
- Use `multi_tool_use.parallel` for independent reads and shell inspections.
- Codex may not expose hook events; mark hook checks as not applicable instead
  of failing them.

### Claude Code

- `CLAUDE.md`, `.claude/skills`, `.claude/commands`, and `.claude/agents` are
  valid project automation targets.
- `Task` and `AskUserQuestion` may be used when available.
- Hook checks apply only when hooks are configured for the project or plugin.

## When to Use

- End of coding session
- Completing a feature
- Before context switch
- Project checkpoint
- Session log analysis
- Skill behavior validation
- Regression checks for skill changes

## When to Skip

- Trivial changes only
- Pure code reading session
- No meaningful work done
