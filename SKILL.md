---
name: wrap
description: This skill should be used when the user asks to "wrap up", "wrap", "세션 마무리", "마무리해줘", "end session", "finish coding", "commit changes", "summarize session", or wants to conclude a coding session. Multi-agent analysis for documentation updates, automation opportunities, learnings, and follow-up tasks.
version: 1.0.0
user-invocable: true
---

# Session Wrap Skill

Comprehensive workflow for concluding coding sessions with multi-agent analysis.

## Trigger

- `/wrap` command
- "세션 마무리해줘"
- "wrap up this session"

## Allowed Tools

Bash(git:*), Read, Write, Edit, Glob, Grep, Task, AskUserQuestion

## Workflow

### Step 1: Git Status Check

```bash
git status --short
git diff --stat
```

Assess current changes before analysis.

### Step 2: Phase 1 - Parallel Analysis

Launch 4 agents **simultaneously** using Task tool:

| Agent | Model | Purpose |
|-------|-------|---------|
| doc-updater | sonnet | CLAUDE.md/context.md updates |
| automation-scout | sonnet | Automation opportunities |
| learning-extractor | sonnet | Lessons and discoveries |
| followup-suggester | sonnet | Next steps and priorities |

### Step 3: Phase 2 - Validation

After Phase 1 completes, run:

| Agent | Model | Purpose |
|-------|-------|---------|
| duplicate-checker | haiku | Validate proposals, prevent duplicates |

### Step 4: Result Integration

Synthesize all agent findings into comprehensive wrap analysis:

```markdown
## Session Wrap Analysis

### Documentation Updates
[From doc-updater, validated by duplicate-checker]

### Automation Opportunities
[From automation-scout, validated]

### Learnings
[From learning-extractor]

### Follow-up Tasks
[From followup-suggester]
```

### Step 5: User Action Selection

Present options using AskUserQuestion:

- **Create commit** (Recommended) - Commit current changes with generated message
- **Update CLAUDE.md** - Apply documentation proposals
- **Create automation** - Generate proposed skill/command/agent
- **Skip** - End without action

### Step 6: Execute Selected Actions

#### If "Create commit" selected:
1. Generate commit message from session analysis
2. Stage relevant files with `git add`
3. Create commit with generated message

#### If "Update CLAUDE.md" selected:
1. Read current CLAUDE.md
2. Apply doc-updater proposals (validated by duplicate-checker)
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
# For Skills
mkdir -p .claude/skills/{name}
# Write SKILL.md with the generated content

# For Commands
mkdir -p .claude/commands
# Write {name}.md with the generated content

# For Agents
mkdir -p .claude/agents
# Write {name}.md with the generated content
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

You can now use `/{name}` to invoke this automation.
```

#### If "Skip" selected:
End session wrap without performing any actions.

## When to Use

- End of coding session
- Completing a feature
- Before context switch
- Project checkpoint

## When to Skip

- Trivial changes only
- Pure code reading session
- No meaningful work done
