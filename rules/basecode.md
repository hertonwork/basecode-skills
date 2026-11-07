# BaseCode rules (condensed)

Paste this block into `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/basecode.mdc`, `.github/copilot-instructions.md` or any agent instructions file. For the full practices with examples, use the `basecode` skill in this repo.

## Principles

- Code is read far more than it is written: optimize for the next reader. Readability breaks every tie.
- Most code is too complex: start simple, stay simple, don't build for a future that may not come (YAGNI).
- No hard numeric rules (line counts, single return). If a rule below makes code less readable, the rule loses. Fewer lines is never the goal.

## Ten practices (apply in this order)

1. **Formatting** - use the project's formatter/standard (PSR-12/Pint, Prettier, Black, gofmt). Never hand-format or fight the formatter. Reformat-only changes go in their own commit.
2. **Dead code** - delete commented-out code, unused parameters/variables/imports/methods, unreachable statements (`break` after `return`, code after `return`, `if (false)`), and abandoned feature paths. Git is the backup. Delete in its own commit.
3. **Nested code** - keep the primary action at the top level: remove empty blocks; `return` boolean conditions directly; convert nested `if`s into guard clauses (negate + early return); no `else` after `return`; prefer `if` over `switch` when cases are few or complex; prefer `filter/map/reduce` over index loops. Don't collapse into dense booleans or ternaries.
4. **Using objects** - when primitives hurt, formalize: an options object instead of an open-ended options array; a value object for data that always travels together (immutable); move logic that keeps following the data into the object. Don't create objects without duplicated structure or logic.
5. **Big blocks** - three steps: recognize the reading level of the block (entry point vs model vs helper), regroup into sub-blocks with temporary labels, then per sub-block ask "native alternative?" then "right level?" (inline / extract private method / move to the owning object). Code is moved, not removed.
6. **Naming** - no abbreviations (except `i`, `e`, `id`, `url`...); follow the language's official conventions; don't repeat scope or type in names (`users.name` not `users.user_name`, `$users` not `$userArray`); read like a sentence; use domain words over technical ones; leave long placeholder names and improve them later.
7. **Removing comments** - challenge every inline comment: delete "what" comments; turn variable comments into names; turn block comments into extracted methods; constants for magic numbers; tickets for TODOs. Keep only "why" comments that code cannot express. Docblocks that add types the language lacks are fine.
8. **Reasonable returns** - don't return `null` or magic sentinels (`-1`, `false`/`0`). Return the type's empty value (`[]`, `''`, `0`), an expressive constant/enum, or a null object. Fix the lowest-level functions first. Exceptions only for truly exceptional paths.
9. **Rule of three** - first occurrence: write it; second: duplicate anyway; third: extract. Defer abstractions until necessary - duplication is cheaper than the wrong abstraction. Never add flags to a shared helper to serve a new caller; inline it back and re-extract along the right seam.
10. **Symmetry** - the same idea the same way everywhere: consistent operators and structure; paired names (`on/off`, `attach/detach`); one term per concept; positive conditions; guards grouped (all `return false`, then all `return true`, then the action); one abstraction level per function; reuse the patterns the codebase already has instead of adding new ones. Apply last.

## When refactoring

Work through the practices in order, one small verifiable change at a time, tests after each, formatter before finishing. State any deliberate trade-off (e.g. duplication kept under the rule of three) in the summary or commit message.
