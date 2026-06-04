# /commit - Context-Aware Smart Commit

Generate a well-crafted commit message by analyzing changes in context.

## When to Use

- Multi-file changes that need context understanding
- Need to follow project-specific commit conventions
- Want to link to issues or PRs
- Complex changes where `aicommit` (shell) isn't sufficient

## Workflow

### 1. Analyze Changes

```bash
git status
git diff --cached --stat
```

If nothing staged, suggest:

- Use `fga` (shell function) for interactive staging
- Or `git add <files>` for specific files

### 2. Understand Context

```bash
git log --oneline -5
git branch --show-current
```

Check for:

- Related issue numbers in branch name
- Recent commit message patterns
- Project conventions in CLAUDE.md

### 3. Generate Commit Message

Format: `type(scope): description`

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance

**Rules:**

- First line < 72 characters
- Focus on WHY, not WHAT
- No period at the end
- Reference issues: `fixes #123` or `relates to #456`

### 4. Execute

```bash
git commit -m "type(scope): description"
```

## vs aicommit (Shell)

| aicommit           | /commit                     |
| ------------------ | --------------------------- |
| Quick terminal use | Claude Code session         |
| No context         | Full project awareness      |
| Simple changes     | Complex multi-file changes  |
| Single provider    | Uses current Claude context |

## Examples

```
feat(auth): add OAuth2 support for GitHub login

fix(api): handle null response in user endpoint

refactor(core): extract validation logic to separate module

docs(readme): update installation instructions for v2
```
