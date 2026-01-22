# /branch-create - Smart Branch Creation

Create a git branch with auto-generated name based on context.

## Usage

```
/branch-create [description]
/branch-create --base <branch> [description]
```

## Arguments

- `description` (optional): Brief description of the work
- `--base <branch>`: Base branch to create from (default: auto-detect main/master)

## Workflow

### Step 1: Analyze Context

```bash
# Check current state
git status
git diff --stat
git diff --cached --stat
```

Identify:

- What type of work (feature, fix, refactor, etc.)
- Key files or components affected
- Any related issue numbers

### Step 2: Determine Branch Type

| Type        | When to Use           | Example                       |
| ----------- | --------------------- | ----------------------------- |
| `feat/`     | New functionality     | `feat/user-authentication`    |
| `fix/`      | Bug fixes             | `fix/login-redirect-loop`     |
| `refactor/` | Code restructuring    | `refactor/extract-validation` |
| `docs/`     | Documentation only    | `docs/api-reference`          |
| `test/`     | Test additions        | `test/auth-integration`       |
| `chore/`    | Maintenance tasks     | `chore/update-dependencies`   |
| `hotfix/`   | Urgent production fix | `hotfix/security-patch`       |

### Step 3: Generate Branch Name

Format: `type/kebab-case-description`

Rules:

- Use lowercase letters, numbers, and hyphens only
- Keep it concise but descriptive (3-5 words)
- Include issue number if available: `fix/123-null-pointer`

### Step 4: Create Branch

```bash
# Fetch latest
git fetch origin

# Determine base branch
base=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

# Create and switch to new branch
git checkout -b <branch-name> origin/$base
```

### Step 5: Confirm

```bash
git branch --show-current
git log --oneline -1
```

## Examples

### From description

```
/branch-create add user profile page
→ feat/add-user-profile-page
```

### With issue number

```
/branch-create fix the login bug #42
→ fix/42-login-bug
```

### From different base

```
/branch-create --base develop add caching layer
→ feat/add-caching-layer (from develop)
```

### Auto-detect from staged changes

```
/branch-create
→ Analyzes staged files and suggests appropriate branch name
```

## Notes

- Always fetch before creating to ensure you have latest remote state
- If uncommitted changes exist, they will be carried to the new branch
- Use `git stash` first if you want a clean branch
