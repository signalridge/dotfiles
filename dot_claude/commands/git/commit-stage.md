# /commit-stage - Stage Changes in Logical Units

Stage changes interactively, organizing them into logical commit units.

## Usage

```
/commit-stage [files...]
/commit-stage --patch
/commit-stage --all
```

## Arguments

- `files`: Specific files to stage
- `--patch, -p`: Interactive patch mode (stage parts of files)
- `--all, -a`: Stage all changes (use with caution)

## Workflow

### Step 1: Review All Changes

```bash
# Overview of changes
git status

# Detailed diff of unstaged changes
git diff

# List modified files
git diff --name-only
```

### Step 2: Identify Logical Units

Group changes by:

1. **Single responsibility**: Each commit should do one thing
2. **Related changes**: Files that work together
3. **Atomic changes**: Should compile/run after each commit

Examples of good groupings:

- Model + migration + test for new field
- Component + styles + unit test
- Bug fix + regression test
- Refactor across multiple files (same change type)

### Step 3: Stage Files

#### Stage specific files

```bash
git add path/to/file1.py path/to/file2.py
```

#### Stage by pattern

```bash
git add "*.py"           # All Python files
git add src/             # All files in src/
git add "src/**/*.ts"    # TypeScript files in src/
```

#### Interactive patch mode

```bash
git add -p [file]
```

Patch mode commands:

- `y` - stage this hunk
- `n` - don't stage this hunk
- `s` - split into smaller hunks
- `e` - manually edit the hunk
- `q` - quit

### Step 4: Verify Staged Changes

```bash
# Review what's staged
git diff --cached

# Summary view
git diff --cached --stat

# Verify nothing unintended
git status
```

### Step 5: Ready for Commit

Once satisfied:

```bash
# Option 1: Use /commit command
/commit

# Option 2: Manual commit
git commit -m "type(scope): description"
```

## Undo Staging

```bash
# Unstage specific file
git reset HEAD path/to/file

# Unstage everything
git reset HEAD

# Unstage last hunk (after git add -p)
git reset -p
```

## Best Practices

1. **Review before staging**: Always `git diff` first
2. **Stage in logical units**: Don't mix unrelated changes
3. **Use patch mode**: When a file has multiple logical changes
4. **Verify staged content**: `git diff --cached` before committing
5. **Small commits**: Easier to review, revert, and cherry-pick

## Examples

### Stage related test and implementation

```
/commit-stage src/user.py tests/test_user.py
```

### Stage part of a file

```
/commit-stage --patch src/api.py
→ Interactive mode to select specific hunks
```

### Stage all Python files

```
/commit-stage "**/*.py"
```

## Notes

- Don't stage generated files (build artifacts, .pyc, etc.)
- Check `.gitignore` if files aren't showing up
- Use `git stash` to temporarily hide unrelated changes
