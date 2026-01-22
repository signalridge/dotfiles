# Git Workflow

Best practices for Git version control and GitHub collaboration.

## Branch Strategy

### Naming Convention

```
{type}/{description}

Types:
- feat/     New feature
- fix/      Bug fix
- refactor/ Code restructuring
- docs/     Documentation
- test/     Test additions/changes
- chore/    Maintenance tasks
```

Examples:

- `feat/user-authentication`
- `fix/login-redirect-loop`
- `refactor/extract-validation`

### Protected Branches

Never commit directly to:

- `main` / `master`
- `develop`
- `release/*`

Always use feature branches and pull requests.

## Commit Messages

### Format

```
type(scope): description

[optional body]

[optional footer]
```

### Types

| Type     | Use For                      |
| -------- | ---------------------------- |
| feat     | New feature                  |
| fix      | Bug fix                      |
| docs     | Documentation only           |
| style    | Formatting (no logic change) |
| refactor | Code restructuring           |
| perf     | Performance improvement      |
| test     | Adding/fixing tests          |
| chore    | Maintenance, dependencies    |

### Examples

```
feat(auth): add OAuth2 support for GitHub

fix(api): handle null response in user endpoint

refactor(core): extract validation to separate module

docs(readme): update installation instructions
```

### Rules

- First line ≤ 72 characters
- Use imperative mood ("add" not "added")
- No period at the end
- Focus on WHY, not WHAT

## Common Operations

### Start New Feature

```bash
git checkout main
git pull origin main
git checkout -b feat/new-feature
```

### Save Work in Progress

```bash
git add -A
git commit -m "wip: work in progress"
# Or use stash
git stash push -m "description"
```

### Sync with Main

```bash
git fetch origin main
git rebase origin/main
# Or merge if rebasing is problematic
git merge origin/main
```

### Create Pull Request

```bash
git push -u origin feat/new-feature
gh pr create --fill
```

## Shell Functions Available

| Function       | Purpose                             |
| -------------- | ----------------------------------- |
| `fgc`          | Fuzzy branch checkout               |
| `fga`          | Fuzzy git add (interactive staging) |
| `fgl`          | Fuzzy git log                       |
| `git-root`     | Jump to repository root             |
| `git-undo`     | Undo last commit (keep changes)     |
| `git-branches` | List branches by date               |
| `git-cleanup`  | Delete merged branches              |
| `aicommit`     | AI-generated commit message         |

## Safety Rules

### Never Do (Blocked by Hooks)

- Force push to protected branches
- Interactive rebase (requires manual input)
- Delete protected branches

### Ask First (Hook Prompts)

- `git commit --amend` - Only if not pushed
- `git reset --hard` - Loses uncommitted work
- `git clean -fd` - Deletes untracked files
- Force push to feature branches

## GitHub CLI (`gh`)

```bash
# Create PR
gh pr create --title "Title" --body "Description"

# View PR
gh pr view

# Check PR status
gh pr checks

# Merge PR
gh pr merge --squash

# Create issue
gh issue create --title "Bug: ..."
```
