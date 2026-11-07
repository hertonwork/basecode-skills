---
name: basecode
description: Readability-first coding practices for writing and refactoring code in any language (PHP, JavaScript, TypeScript, Python, Go, etc.). Use whenever writing new functions or classes, refactoring, cleaning up, simplifying, or when asked to make code "readable", "clean", "simpler", "less nested", "less complex", to "remove dead code", "fix naming", "remove comments", "avoid null returns", "DRY this up", "extract a method" or "split this up". Covers ten practices - formatting, dead code, nested code, using objects, big blocks, naming, removing comments, reasonable returns, rule of three, symmetry. Do not use for Laravel-specific streamlining (use base-laravel) or for producing a findings report on a diff or PR (use basecode-review).
metadata:
  version: "1.0.0"
  source: "Practices adapted from Jason McCreary's BaseCode field guide (original wording and examples)"
---

# BaseCode: write code that lasts

Two truths drive every rule here:

1. **Code is read far more often than it is written.** Optimize for the next reader, not for the author. Readability is the tie-breaker whenever two implementations are otherwise equal.
2. **Most code is more complex than it needs to be.** Start simple and stay simple as long as possible. Do not pre-architect, do not force patterns, do not build for a future that may never come (YAGNI).

There are no hard numeric rules (no "max 15 lines", no "single return"). When a rule below would make the code *less* readable, the rule loses. Reducing line count is never the goal; reducing the reader's effort is.

## The ten practices

Apply them in this order. The first ones are mechanical and cheap; the last ones need judgment and time. Read the matching file in `references/` when you actually apply a practice to non-trivial code.

| # | Practice | The rule in one line | Read |
|---|----------|----------------------|------|
| 1 | Formatting | Choose the language's standard style, automate it, then never think about it again. Never hand-format. | `references/formatting.md` |
| 2 | Dead Code | Delete commented-out code, unused code, unreachable code and abandoned feature paths. Version control is the backup. | `references/dead-code.md` |
| 3 | Nested Code | Bring the primary action to the top level: remove empty blocks, return boolean conditions directly, convert nested ifs to guard clauses, prefer `if` over `switch` for a few cases, prefer `filter/map/reduce` over hand-rolled loops. | `references/nested-code.md` |
| 4 | Using Objects | When primitives (arrays, options maps, paired scalars) make code awkward, formalize them into a small object: options objects, value objects, and objects that encapsulate the logic that keeps getting duplicated. | `references/using-objects.md` |
| 5 | Big Blocks | Shrink a long block in three steps: recognize the reading level of the code, regroup it into labeled sub-blocks, then refactor each sub-block (native alternative? right level? extract or move). | `references/big-blocks.md` |
| 6 | Naming | No abbreviations; follow the language's official conventions; don't repeat context already given by the scope or type; prefer human, domain words over technical ones; let names improve over time. | `references/naming.md` |
| 7 | Removing Comments | Challenge every inline comment: can the code be rewritten (name, extract, reorder) so the comment is unnecessary? Keep only comments that explain *why* and cannot be expressed in code. | `references/removing-comments.md` |
| 8 | Reasonable Returns | Avoid returning `null` and magic values. Return the type's empty value (`[]`, `""`, `0`), an expressive constant/enum, or a null object. Fix the lowest-level functions first. | `references/reasonable-returns.md` |
| 9 | Rule of Three | Tolerate duplication until the third occurrence; only then extract. Defer abstractions until they are necessary - duplication is cheaper than the wrong abstraction. | `references/rule-of-three.md` |
| 10 | Symmetry | Express the same idea the same way everywhere: consistent syntax, paired names (on/off, add/remove), one tone (positive conditions), one set of patterns per codebase. Apply last. | `references/symmetry.md` |

## Workflow when writing new code

1. Detect the project's formatter/linter (`.php-cs-fixer*`, `phpcs.xml`, `pint.json`, `.prettierrc`, `eslint.config.*`, `.editorconfig`, `pyproject.toml`, etc.) and match it. Run it on files you touch if a command exists in the project.
2. Write the simplest thing that works, with primitives, no speculative parameters, no speculative abstractions.
3. Put the primary action at the top level of each function; guard the exceptional paths first.
4. Name with full words from the domain. Don't inject types or repeated context into names.
5. Do not write a comment that describes *what* the next line does. If you feel the need to, rename or extract instead.
6. Never return `null` from code you control when an empty value or null object fits.
7. If you copy a block for the second time, leave it. On the third copy, extract.
8. Before finishing, reread for symmetry: same operators, same naming pairs, same abstraction level within each function.

## Workflow when refactoring existing code

Go through the practices in table order on the target block. Each pass should be small and separately verifiable (run the tests after each). Do not combine a mass reformat with behavior changes in one commit. Stop when the next pass would reduce readability instead of improving it.

## Non-negotiables

- Never hand-align or hand-format code when an automated formatter exists in the project; never fight the formatter with style exceptions.
- Never leave commented-out code behind "just in case".
- Never add a `break` after a `return`, an empty `else`, or an `if (x) { return true; } else { return false; }`.
- Never pack logic into a ternary or a one-liner to save lines; density is not readability.
- Never abstract on the first or second duplicate.
- Never add a comment to explain code you could rename or extract instead.

## Trade-offs to state out loud

When a practice conflicts with another (for example, a guard clause that returns `null`, or an object that would only have one use), say which practice wins and why in one sentence in your reply or commit message. Readability is the deciding factor.
