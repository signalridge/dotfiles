# /command-create - Create New Command

Create a new slash command with proper structure.

## Usage

```
/command-create <name>
/command-create <name> --template <type>
```

## Arguments

- `name`: Command name (kebab-case, no slash)
- `--template <type>`: Base template (workflow, tool, query)
- `--category <cat>`: Category for organization

## Command Structure

```markdown
# /<command-name> - Short Description

[One-line description of what this command does]

## Usage

\`\`\`
/<command-name> [required-arg] [optional-arg]
/<command-name> --flag <value>
\`\`\`

## Arguments

- `required-arg`: Description (required)
- `optional-arg`: Description (optional, default: X)
- `--flag <value>`: Description

## Workflow

### Step 1: [First Step]

[Description and commands]

### Step 2: [Second Step]

[Description and commands]

## Examples

### Basic Usage

\`\`\`
/<command-name> value
→ [Expected output]
\`\`\`

### With Options

\`\`\`
/<command-name> --flag option
→ [Expected output]
\`\`\`

## Notes

- [Important consideration 1]
- [Important consideration 2]

## Related Commands

- `/related-command` - Description
```

## Templates

### Workflow Template

For multi-step processes:

- Clear step-by-step workflow
- Checkpoints and verification
- Error handling guidance

### Tool Template

For single-action commands:

- Focused functionality
- Input/output specification
- Quick reference

### Query Template

For information retrieval:

- What information is gathered
- How it's presented
- Filtering options

## Workflow

### Step 1: Define Purpose

Answer:

- What problem does this solve?
- Who uses this command?
- When is it invoked?
- What's the expected outcome?

### Step 2: Design Interface

Determine:

- Required arguments
- Optional flags
- Default behaviors
- Output format

### Step 3: Write Content

Follow structure:

1. Title and description
2. Usage syntax
3. Arguments documentation
4. Step-by-step workflow
5. Examples
6. Notes and caveats
7. Related commands

### Step 4: Save Command

```bash
# Save to commands directory
# File: ~/.claude/commands/<name>.md
```

### Step 5: Test Command

- Invoke with various arguments
- Check edge cases
- Verify output format

## Best Practices

1. **Clear naming**: Command name should indicate action
2. **Consistent style**: Follow existing command patterns
3. **Practical examples**: Show real-world usage
4. **Error guidance**: Help users recover from mistakes
5. **Cross-references**: Link to related commands

## Example Creation

### Creating a "deploy" command:

```
/command-create deploy --template workflow --category ops
```

Generated template:

```markdown
# /deploy - Deploy Application

Deploy the application to specified environment.

## Usage

\`\`\`
/deploy <environment>
/deploy <environment> --dry-run
\`\`\`

## Arguments

- `environment`: Target environment (staging, production)
- `--dry-run`: Preview without executing

## Workflow

### Step 1: Pre-deployment Checks

...

### Step 2: Deploy

...

### Step 3: Verify

...
```

## Output

```markdown
## Command Created

- Name: /deploy
- File: ~/.claude/commands/deploy.md
- Category: ops
- Template: workflow

### Next Steps

1. Edit command file to customize
2. Test with `/deploy --help`
3. Add to cheatsheet: `/command-cheatsheet --update`
```

## Related Commands

- `/command-cheatsheet` - View all commands
- `/command-suggest` - Get command suggestions
