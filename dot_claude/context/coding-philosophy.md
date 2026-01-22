# Coding Philosophy

Detailed principles referenced by CLAUDE.md. For execution rules, see CLAUDE.md directly.

## Core Beliefs

- **Pursue good taste** - Eliminate edge cases to make code logic natural
- **Embrace extreme simplicity** - Complexity is the root of all evil
- **Be pragmatic** - Solve real problems, not hypothetical ones
- **Data structures first** - Good programmers worry about data structures
- **Never break backward compatibility** - Existing functionality is sacred
- **Incremental progress** - Small changes that compile and pass tests
- **Learn from existing code** - Study before implementing
- **Clear intent over clever code** - Be boring and obvious

## Simplicity Means

- Single responsibility per function/class
- Avoid premature abstractions
- No clever tricks - choose the boring solution
- If you need to explain it, it's too complex

## Fix, Don't Hide

**Solve problems, don't silence symptoms:**

❌ `@ts-ignore`, `skip`, `ignore`, empty catch, `as any`, excessive timeouts

✅ Fix the root cause

## Tooling Rules

- Use project's existing build system
- Use project's test framework
- Use project's formatter/linter settings
- Don't introduce new tools without strong justification

## Content Uniqueness

- Each layer owns its abstraction level
- Reference, don't duplicate
- Maintain perspective at appropriate scale
- Higher layers stay architectural

## Edit Fallback

When Edit tool fails 2+ times → try sed/awk → then Write
