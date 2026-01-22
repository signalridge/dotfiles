# /design-review-live - Live Design Review

Conduct a comprehensive design review with live environment testing.

## Usage

```
/design-review-live [url]
/design-review-live --pr <number>
```

## Philosophy

**Live Environment First**: Always assess the interactive experience before static analysis.

## Workflow

### Step 1: Gather Context

```bash
git status
git diff --name-only origin/HEAD...
git log --no-decorate origin/HEAD...
git diff --merge-base origin/HEAD
```

### Step 2: Seven-Phase Review

---

## Phase 0: Preparation

- [ ] Analyze PR description for motivation, changes, testing notes
- [ ] Review code diff to understand implementation scope
- [ ] Set up live preview environment (Playwright if available)
- [ ] Configure initial viewport (1440x900 for desktop)

## Phase 1: Interaction and User Flow

- [ ] Execute the primary user flow following testing notes
- [ ] Test all interactive states (hover, active, disabled, focus)
- [ ] Verify destructive action confirmations
- [ ] Assess perceived performance and responsiveness

## Phase 2: Responsiveness Testing

- [ ] Desktop viewport (1440px) - capture screenshot
- [ ] Tablet viewport (768px) - verify layout adaptation
- [ ] Mobile viewport (375px) - ensure touch optimization
- [ ] Verify no horizontal scrolling or element overlap

## Phase 3: Visual Polish

- [ ] Layout alignment and spacing consistency
- [ ] Typography hierarchy and legibility
- [ ] Color palette consistency and image quality
- [ ] Visual hierarchy guides user attention

## Phase 4: Accessibility (WCAG 2.1 AA)

- [ ] Complete keyboard navigation (Tab order)
- [ ] Visible focus states on all interactive elements
- [ ] Keyboard operability (Enter/Space activation)
- [ ] Semantic HTML usage
- [ ] Form labels and associations
- [ ] Image alt text
- [ ] Color contrast ratios (4.5:1 minimum)

## Phase 5: Robustness Testing

- [ ] Form validation with invalid inputs
- [ ] Content overflow scenarios
- [ ] Loading, empty, and error states
- [ ] Edge case handling

## Phase 6: Code Health

- [ ] Component reuse over duplication
- [ ] Design token usage (no magic numbers)
- [ ] Adherence to established patterns

## Phase 7: Content and Console

- [ ] Grammar and clarity of all text
- [ ] Browser console for errors/warnings

---

## Communication Principles

1. **Problems Over Prescriptions**: Describe problems and impact, not solutions
   - Bad: "Change margin to 16px"
   - Good: "The spacing feels inconsistent with adjacent elements, creating visual clutter"

2. **Evidence-Based**: Provide screenshots for visual issues

3. **Start Positive**: Acknowledge what works well before issues

---

## Severity Levels

| Level               | Description                                  |
| ------------------- | -------------------------------------------- |
| `[Blocker]`         | Critical failures requiring immediate fix    |
| `[High-Priority]`   | Significant issues to fix before merge       |
| `[Medium-Priority]` | Improvements for follow-up                   |
| `[Nitpick]`         | Minor aesthetic details (prefix with "Nit:") |

---

## Output Format

```markdown
### Design Review Summary

[Positive opening and overall assessment]

### Findings

#### Blockers

- [Problem + Screenshot if applicable]

#### High-Priority

- [Problem + Screenshot if applicable]

#### Medium-Priority / Suggestions

- [Problem]

#### Nitpicks

- Nit: [Minor detail]
```

---

## Playwright Commands (if MCP available)

```
mcp__playwright__browser_navigate      # Navigate to URL
mcp__playwright__browser_click         # Click elements
mcp__playwright__browser_type          # Type text
mcp__playwright__browser_take_screenshot  # Capture screenshot
mcp__playwright__browser_resize        # Change viewport
mcp__playwright__browser_snapshot      # DOM analysis
mcp__playwright__browser_console_messages  # Check console
```

## Related Files

- `.claude/context/design-principles.md` - Design standards
- `.claude/context/style-guide.md` - Style guidelines
