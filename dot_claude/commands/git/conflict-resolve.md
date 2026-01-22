# /conflict-resolve - Intelligent Merge Conflict Resolution

Systematically resolve git merge conflicts with smart categorization.

## Usage

```
/conflict-resolve [file]
/conflict-resolve --auto
/conflict-resolve --list
```

## Arguments

- `file`: Specific file to resolve (optional, resolves all if omitted)
- `--auto`: Only resolve auto-resolvable conflicts
- `--list`: List conflicts without resolving

## Workflow

### Step 1: Detect Conflicts

```bash
# List all conflicted files
git diff --name-only --diff-filter=U

# Show conflict details
git status
```

### Step 2: Categorize Each Conflict

| Category                     | Description                      | Resolution                |
| ---------------------------- | -------------------------------- | ------------------------- |
| **Simple Addition**          | Both sides add different content | Usually keep both         |
| **Import Duplicate**         | Same import added twice          | Keep one                  |
| **Semantic Collision**       | Same area, different logic       | Manual review required    |
| **Deletion vs Modification** | One deletes, one modifies        | Choose based on intent    |
| **Formatting Only**          | Whitespace/style differences     | Use formatter to resolve  |
| **Version Bump**             | Package version conflicts        | Choose higher or intended |

### Step 3: Auto-Resolvable Conflicts

These can often be resolved automatically:

```bash
# For simple additions (keep both)
git checkout --ours FILE   # Keep current branch version
git checkout --theirs FILE # Keep incoming version

# For formatting conflicts
ruff format FILE           # Python
prettier --write FILE      # JS/TS
```

### Step 4: Manual Resolution

For semantic conflicts:

1. **Open the file** and find conflict markers:

   ```
   <<<<<<< HEAD
   current branch code
   =======
   incoming branch code
   >>>>>>> branch-name
   ```

2. **Understand both changes**:
   - What does HEAD (current) change do?
   - What does incoming change do?
   - Are they compatible?

3. **Resolve**:
   - Keep one version
   - Keep both (combine)
   - Write new code that satisfies both intents

4. **Remove conflict markers** completely

5. **Test the result**

### Step 5: Mark as Resolved

```bash
# After manually fixing
git add FILE

# Verify no conflicts remain
git diff --check

# Continue merge/rebase
git merge --continue
# or
git rebase --continue
```

## Resolution Strategies

### Keep Ours (Current Branch)

```bash
git checkout --ours path/to/file
git add path/to/file
```

### Keep Theirs (Incoming Branch)

```bash
git checkout --theirs path/to/file
git add path/to/file
```

### Interactive Merge Tool

```bash
git mergetool
```

### Abort If Needed

```bash
git merge --abort
# or
git rebase --abort
```

## Common Conflict Patterns

### Lock Files (package-lock.json, uv.lock)

```bash
# Regenerate from scratch
rm package-lock.json
npm install
git add package-lock.json
```

### Import Statements

Usually safe to keep both, then remove duplicates:

```python
# Before
<<<<<<< HEAD
from module import foo
=======
from module import bar
>>>>>>> feature

# After
from module import foo, bar
```

### Configuration Files

Compare carefully - often need manual merge:

```bash
# View both versions
git show :2:config.json > config.ours.json
git show :3:config.json > config.theirs.json
diff config.ours.json config.theirs.json
```

## Output

After resolution:

```markdown
## Conflict Resolution Summary

### Resolved (Auto)

- `src/utils.py` - Import duplicate (kept both, deduped)
- `package.json` - Version bump (used higher version)

### Resolved (Manual)

- `src/api.py:45-67` - Semantic collision (combined logic)

### Verification

- [ ] All conflicts resolved
- [ ] Tests pass
- [ ] No conflict markers remaining
```

## Notes

- Always understand both sides before resolving
- Run tests after resolving conflicts
- If unsure, ask the author of the conflicting change
- Use `git log --merge` to see commits causing conflicts
