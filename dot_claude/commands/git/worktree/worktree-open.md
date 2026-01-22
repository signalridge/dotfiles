# /worktree-open - Open Worktree Directory

Open a worktree in file manager, terminal, or editor.

## Usage

```
/worktree-open <worktree>
/worktree-open <worktree> --editor
/worktree-open <worktree> --terminal
```

## Arguments

- `worktree`: Worktree name, branch name, or path
- `--editor, -e`: Open in default editor (VS Code, Neovim)
- `--terminal, -t`: Open new terminal at worktree
- `--finder, -f`: Open in Finder (macOS)

## Workflow

### Step 1: Locate Worktree

```bash
# Find worktree path from name
git worktree list | grep "worktree-name"

# Or from branch name
git worktree list | grep "branch-name"
```

### Step 2: Open in Desired Application

#### Open in Finder (macOS)

```bash
open /path/to/worktree
```

#### Open in VS Code

```bash
code /path/to/worktree
```

#### Open in Neovim (new terminal)

```bash
# Using tmux
tmux new-window -c /path/to/worktree -n "worktree-name" "nvim ."

# Or in new iTerm tab
osascript -e 'tell application "iTerm2" to create window with default profile command "cd /path/to/worktree && nvim ."'
```

#### Open Terminal at Path

```bash
# New tmux window
tmux new-window -c /path/to/worktree -n "worktree-name"

# Or new iTerm tab
open -a iTerm /path/to/worktree
```

## Examples

### Open PR review worktree

```
/worktree-open pr-123
→ Opens /project-worktrees/pr-123 in Finder
```

### Open in VS Code

```
/worktree-open feature/auth --editor
→ code /project-worktrees/feature-auth
```

### Open terminal

```
/worktree-open hotfix --terminal
→ New tmux window at worktree path
```

## Integration with Tmux

If using tmux, create named windows for each worktree:

```bash
# Create window for worktree
tmux new-window -c "$worktree_path" -n "$branch_name"

# Or split current pane
tmux split-window -c "$worktree_path"
```

## Integration with Aerospace (macOS)

If using aerospace window manager:

```bash
# Open in new workspace
aerospace workspace next
open -a "Terminal" "$worktree_path"
```

## Output

```markdown
## Worktree Opened

- **Name**: feature/add-auth
- **Path**: /Users/you/project-worktrees/feature-auth
- **Opened in**: VS Code

### Quick Actions

- Terminal: `cd /Users/you/project-worktrees/feature-auth`
- Status: `git -C /Users/you/project-worktrees/feature-auth status`
```

## Related Commands

- `/worktree-list` - Find worktree paths
- `/worktree-create` - Create new worktree
