# /doc-update - Update Documentation

Update documentation to reflect code changes.

## Usage

```
/doc-update [file]
/doc-update --check
/doc-update --since <commit>
```

## Arguments

- `file`: Specific doc file to update (auto-detect if omitted)
- `--check`: Check if docs need updating without changing
- `--since <commit>`: Update based on changes since commit
- `--all`: Update all documentation

## What Gets Updated

| Doc Type    | Trigger          | Update Action               |
| ----------- | ---------------- | --------------------------- |
| README      | New features     | Add to Features section     |
| API docs    | Endpoint changes | Update signatures, examples |
| CHANGELOG   | Any changes      | Add entry                   |
| Config docs | Config changes   | Update options              |
| CLI help    | Command changes  | Update usage                |

## Workflow

### Step 1: Identify Changes

```bash
# Changes since last doc update
git diff HEAD~5 --name-only

# Or since specific commit
git diff abc123..HEAD --name-only
```

Focus on:

- New files (new features)
- Modified public APIs
- Changed configuration
- Updated dependencies

### Step 2: Map Changes to Docs

| Changed File       | Affected Docs         |
| ------------------ | --------------------- |
| `src/api/*.py`     | API reference, README |
| `config.py`        | Configuration docs    |
| `cli.py`           | CLI usage, README     |
| `requirements.txt` | Installation docs     |
| Any `.py`          | CHANGELOG             |

### Step 3: Generate Updates

For each affected doc:

#### README Updates

```markdown
## Features

- **NEW:** [Feature name] - [Brief description]
```

#### API Docs

````markdown
### `function_name(param1, param2)`

**NEW in v1.2.0**

Parameters:

- `param1` (str): Description
- `param2` (int, optional): Description. Default: 10

Returns:

- `dict`: Description of return value

Example:

```python
result = function_name("value", param2=20)
```
````

````

#### CHANGELOG
```markdown
## [Unreleased]

### Added
- New feature X for Y functionality

### Changed
- Updated Z to improve performance

### Fixed
- Bug in W that caused Q
````

### Step 4: Verify Accuracy

For each update:

- [ ] Matches actual code behavior
- [ ] Examples are runnable
- [ ] Links are valid
- [ ] Version numbers correct

### Step 5: Apply Updates

```bash
# Preview changes
/doc-update --check

# Apply updates
/doc-update
```

## Check Mode Output

````markdown
## Documentation Status

### Needs Update

| Doc          | Reason                     | Priority |
| ------------ | -------------------------- | -------- |
| README.md    | New feature not documented | High     |
| API.md       | 3 functions changed        | High     |
| CHANGELOG.md | Missing entries            | Medium   |

### Up to Date

- CONTRIBUTING.md
- LICENSE

### Suggested Updates

#### README.md

Add to Features section:

> - **User Profiles**: New profile management system

#### API.md

Update function signature:

```diff
- def get_user(id: int) -> User:
+ def get_user(id: int, include_metadata: bool = False) -> User:
```
````

````

## Automatic Sync

Configure auto-update on certain actions:

```yaml
# In settings or hooks
triggers:
  - on: "git commit"
    check: "doc-update --check"
    warn: true

  - on: "pre-push"
    run: "doc-update CHANGELOG.md"
````

## Output

```markdown
## Documentation Updated

### Files Modified

- README.md: Added 2 features
- API.md: Updated 3 functions
- CHANGELOG.md: Added 5 entries

### Summary

- New features: 2
- Updated APIs: 3
- Bug fixes documented: 1

### Next Steps

- [ ] Review changes: `git diff docs/`
- [ ] Commit: `git add docs/ && git commit -m "docs: update for v1.2"`
```

## Related Commands

- `/doc-compact` - Reduce documentation size
- `/doc-generate` - Generate new documentation
