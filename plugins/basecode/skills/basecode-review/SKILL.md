---
name: basecode-review
description: Produce a readability review of a file, diff, branch or PR against the ten BaseCode practices (formatting, dead code, nested code, using objects, big blocks, naming, removing comments, reasonable returns, rule of three, symmetry), as a findings report with before/after snippets, optionally applying the fixes. Use when asked to "review this for readability", "basecode review", "code review for clean code", "what would you clean up here", "readability audit", "is this too nested/complex", or before merging a PR when style and maintainability matter. Do not use for security, performance or correctness review (use a dedicated code-review skill) or when writing new code (use basecode).
argument-hint: "[file | directory | diff | branch | PR url] [--apply]"
metadata:
  version: "1.0.0"
---

# BaseCode Review

Review code for readability and complexity using the BaseCode practices, and report what to change and why. This skill *reports*; it only edits when the user asks for fixes (`--apply` or an explicit request). The practice details live in the `basecode` skill's `references/` folder; read the relevant file when a finding needs more than a one-line explanation.

## 1. Scope the target

- A file or directory: read it (use `git diff` against the default branch if the user says "my changes").
- A branch or PR: `git diff <base>...<head>` or `gh pr diff <number>`; also read the surrounding code of changed functions, since readability depends on context.
- No target given: review the uncommitted changes (`git diff` and `git diff --staged`). Say what you reviewed.

Note the project's formatter and static-analysis tools (see `basecode/references/formatting.md`) and run them first if available; report their output under Formatting and Dead Code instead of re-deriving it by eye.

## 2. Walk the practices in order

For each block of code (function, method, template section), check the practices in this sequence and record findings:

1. **Formatting** - deviates from the project formatter or language standard; hand alignment; mixed styles.
2. **Dead code** - commented-out code, unused parameters/variables/imports/methods, unreachable statements (`break` after `return`, code after `return`), abandoned feature paths.
3. **Nested code** - primary action buried under conditionals; empty blocks; `if/else` returning booleans; `else` after `return`; `switch` with few or complex cases; index loops that are a `filter`/`map`/`reduce`.
4. **Using objects** - open-ended options arrays; data clumps passed together; logic duplicated around the same primitives.
5. **Big blocks** - long methods mixing abstraction levels; low-level details in entry points (controllers, handlers, CLI commands); code that could be a native framework/language feature.
6. **Naming** - abbreviations; convention violations; repeated context or type words; technical names where domain words exist; inconsistent terms.
7. **Comments** - comments that describe *what*; stale or wrong comments; `TODO`s without tickets; missing *why* for non-obvious decisions.
8. **Reasonable returns** - `return null` where an empty value/null object fits; magic sentinels (`-1`, `false`/`0` ambiguity); nullable return types in low-level code.
9. **Rule of three** - premature abstractions with flags/parameters to serve two callers; third+ duplicates that should now be extracted.
10. **Symmetry** - mixed operators, mixed naming pairs, negative and positive conditions interleaved, several patterns for one job, one-off low-level expressions among high-level calls.

## 3. Rate each finding

- **Fix** - clear win, low risk, mechanical (dead code, formatting, empty blocks, `else` after `return`, 1:1 comments).
- **Suggest** - improves readability but involves judgment or touches more than one place (guard clauses, extraction, value object, rename).
- **Consider** - a trade-off worth a conversation (introducing a null object, un-DRYing, moving code to another layer).

Do not report nitpicks the formatter will handle. Do not pad the report: if a practice has no findings, omit it.

## 4. Report format

```
## BaseCode review: <target> (<n> files, <n> findings)

### Summary
One or two sentences: overall readability, the biggest wins, anything blocking.

### Findings

#### <path>:<line>  <practice>  <Fix|Suggest|Consider>
What: one sentence.
Why: one sentence tied to the practice.
Before:
<minimal snippet>
After:
<minimal snippet>

(repeat)

### Not changed on purpose
Asymmetries or duplication deliberately left (e.g. second copy, Rule of Three) and why.
```

Group findings by file, in file order. Keep snippets to the lines that change. Prefer one combined finding when several practices point at the same lines (for example "nested code + symmetry").

## 5. Apply fixes only when asked

If the user asks to apply (`--apply`, "fix these", "go ahead"):

1. Apply **Fix** items first, one practice at a time, running the formatter and tests after each group.
2. Apply **Suggest** items next; stop and ask before any **Consider** item or anything that changes a public signature.
3. Keep each practice's changes in a separate commit (`refactor(<area>): <practice> - <what>`), never mixed with behavior changes.
4. Re-run the review on the result and report what remains.

## Trigger test

Given a prompt like "can you look at this controller and tell me how to make it cleaner?", this skill loads, scopes to the file, runs the ten-step walk, and returns the report above without editing.
