# /doc-compact - Compact Documentation

Reduce documentation redundancy while preserving meaning.

## Usage

```
/doc-compact <file>
/doc-compact <directory>
/doc-compact --preview
```

## Arguments

- `file`: Documentation file to compact
- `directory`: Process all docs in directory
- `--preview`: Show changes without applying
- `--aggressive`: More aggressive reduction

## What Gets Compacted

| Redundancy Type              | Example                         | Compacted                     |
| ---------------------------- | ------------------------------- | ----------------------------- |
| Duplicate expressions        | "very unique"                   | "unique"                      |
| Excessive modifiers          | "extremely important critical"  | "critical"                    |
| Verbose explanations         | "In order to be able to..."     | "To..."                       |
| Repeated information         | Same concept in multiple places | Single mention with reference |
| Filler phrases               | "It should be noted that..."    | (removed)                     |
| Passive voice (when clearer) | "X is used by Y"                | "Y uses X"                    |

## What to Preserve

- **Technical accuracy**: Never sacrifice correctness
- **Important context**: Background that aids understanding
- **Code examples**: Keep working examples intact
- **Links and references**: Maintain all external references
- **Warnings and notes**: Critical information stays

## Workflow

### Step 1: Analyze Document

```bash
# Count current words/characters
wc -w documentation.md

# Identify redundancy patterns
# Claude analyzes document structure
```

### Step 2: Propose Changes

Present changes in diff format:

```diff
## Before
- In order to be able to install the application, you will first
- need to make sure that you have properly installed and configured
- the required dependencies that are listed below.

## After
+ To install, first configure these dependencies:
```

### Step 3: Review Changes

For each proposed change, verify:

- [ ] Meaning preserved?
- [ ] Context maintained?
- [ ] Tone appropriate?
- [ ] Important info kept?

### Step 4: Apply Changes

```bash
# With confirmation
/doc-compact README.md --preview
# Review output
/doc-compact README.md  # Apply
```

## Examples

### Verbose → Concise

Before:

```markdown
## Getting Started

In order to get started with using this application, you will
need to first make sure that you have all of the necessary
prerequisites installed on your system. The prerequisites that
are required include Node.js version 18 or higher, as well as
npm which usually comes bundled together with Node.js.
```

After:

```markdown
## Getting Started

Prerequisites:

- Node.js 18+
- npm (included with Node.js)
```

### Remove Filler

Before:

```markdown
It should be noted that the configuration file is very important
and it is absolutely essential that you do not forget to update
it before running the application.
```

After:

```markdown
Update the configuration file before running the application.
```

### Deduplicate

Before:

```markdown
## Installation

Install dependencies with `npm install`.

## Setup

After installation, run `npm install` to get all dependencies.
```

After:

```markdown
## Installation

Run `npm install` to install dependencies.

## Setup

(Refer to Installation above for dependencies)
```

## Verification Checklist

After compacting:

- [ ] All commands still work
- [ ] All links still valid
- [ ] Technical instructions complete
- [ ] No meaning lost
- [ ] Appropriate reading level
- [ ] Consistent style

## Output

```markdown
## Compaction Report: README.md

### Statistics

- Before: 1,245 words
- After: 823 words
- Reduction: 34%

### Changes Made

1. Line 15-20: Simplified installation instructions
2. Line 45: Removed redundant explanation
3. Line 78-85: Consolidated duplicate sections
4. Line 102: Replaced verbose phrase

### Preserved

- All code examples
- API reference section
- Warning notes
- External links
```

## Related Commands

- `/doc-update` - Update documentation
- `/doc-generate` - Generate documentation
