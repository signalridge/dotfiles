# /plan-import - Import External Plan

Import and convert external planning documents into the standard plan format.

## Usage

```
/plan-import <source>
/plan-import --from-notion <url>
/plan-import --from-linear <id>
/plan-import --from-file <path>
```

## Arguments

- `source`: URL, file path, or issue reference
- `--from-notion <url>`: Import from Notion page
- `--from-linear <id>`: Import from Linear issue/project
- `--from-file <path>`: Import from local file

## Supported Sources

| Source       | Format   | Notes                               |
| ------------ | -------- | ----------------------------------- |
| GitHub Issue | Markdown | Extracts title, body, labels        |
| GitHub PR    | Markdown | Extracts description, linked issues |
| Notion Page  | Export   | Requires Notion export or MCP       |
| Linear Issue | API      | Requires Linear MCP or API          |
| Local File   | MD/TXT   | Any text format                     |
| Clipboard    | Text     | Paste content directly              |

## Workflow

### Step 1: Fetch Source Content

```bash
# From GitHub issue
gh issue view 123 --json title,body,labels

# From file
cat path/to/document.md
```

### Step 2: Extract Structure

Identify and map:

- Title → Plan title
- Description → Goal + Background
- Requirements → Definition of Done
- Tasks/Checklist → Implementation Steps
- Labels/Tags → Constraints or categories
- Links → References

### Step 3: Fill Gaps

Prompt for missing sections:

- Constraints (if not specified)
- Assumptions (usually missing)
- Decisions Required (if ambiguous)

### Step 4: Generate Plan

Convert to standard format:

```markdown
---
created: YYYY-MM-DD
imported_from: [source URL]
original_date: [if available]
---

# Plan: [Extracted Title]

## Goal

[Extracted/reformatted goal]

## Background

[Extracted context]

...
```

### Step 5: Review and Save

- Review converted plan
- Fill in any remaining gaps
- Save to `.claude/plans/`

## Examples

### From GitHub Issue

```
/plan-import --from-issue 123
→ Fetches issue #123 and converts to plan format
```

### From Notion

```
/plan-import --from-notion https://notion.so/page-id
→ Imports Notion page content (requires MCP)
```

### From Local File

```
/plan-import --from-file docs/feature-spec.md
→ Reads file and converts to plan
```

### From Clipboard

```
/plan-import
→ Prompts to paste content, then converts
```

## Conversion Rules

### GitHub Issue → Plan

| Issue Field            | Plan Field          |
| ---------------------- | ------------------- |
| Title                  | Plan title          |
| Body (first paragraph) | Goal                |
| Body (rest)            | Background + Steps  |
| Labels                 | Constraints hints   |
| Milestone              | Timeline constraint |
| Assignees              | Owner               |

### Notion → Plan

| Notion Element | Plan Field           |
| -------------- | -------------------- |
| Page title     | Plan title           |
| Callout blocks | Constraints/Notes    |
| Toggle lists   | Implementation Steps |
| Checkboxes     | Definition of Done   |
| Links          | References           |

## Notes

- Imported plans should be reviewed and refined
- Use `/plan-refine` after import to improve quality
- Original source is preserved in frontmatter for reference
