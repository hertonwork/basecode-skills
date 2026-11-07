# Dead Code

## Why it matters

Dead code is the "broken window" of a codebase: once it is visible, the code looks uncared for, and everyone cares a little less. Its cost comes in three forms:

- **Apathy** - it signals nobody maintains this, so why should the next person.
- **Noise** - it has to be read, it pollutes searches and diffs, it weakens the signal of the live code.
- **Obscurity** - it raises questions ("was this used? why was it removed?") that usually have no answer.

Dead code is never written on purpose. It accumulates because we work in increments and rarely return to clean up. The fix is a habit: whenever you touch a file, leave it with less dead code than you found (boy-scout rule).

## The four kinds, easiest to hardest to spot

### 1. Commented-out code

The most common. Blocks that were commented "to keep them handy". Delete them. Version control already keeps them; a reader who needs the old code can look at history, and removing it in its own commit makes it trivially revertible.

```js
// before
const total = items.reduce((sum, item) => sum + item.price, 0);
// const total = items.map(i => i.price).reduce((a, b) => a + b);
// return { total, currency: 'USD' };
return { total };

// after
const total = items.reduce((sum, item) => sum + item.price, 0);
return { total };
```

If a block is toggled on and off regularly, that is a feature flag or a configuration value, not a comment.

### 2. Unused code

Parameters, variables, methods, imports, conditions and options that nothing uses. Often born from speculation about future needs. Easy to spot with static analysis (`phpstan`, `psalm`, `eslint no-unused-vars`, `ts-prune`, `knip`, `vulture`, IDE inspections), hard to spot by eye when the unused thing is an open-ended "options array" where you cannot tell which keys are consumed.

- As the author: review your own change before finishing and remove anything you added "in case".
- In an unfamiliar codebase: run the analysis tool the project has, remove in small chunks, run the tests after each chunk.

### 3. Unreachable code

Statements after a `return`/`throw`/`continue`, a `break` after a `return` inside `switch`, `if (false)`, loops whose condition can never be true, a `default:` that ends in `break`. Remove them.

```php
switch ($plan) {
    case 'free':
        return 0;
        break;        // unreachable - delete
    default:
        return 10;
        break;        // unreachable - delete
}
```

For hot paths where you are not sure a branch is dead, add a temporary log line ("tracer bullet"), check the logs after a few days, then remove the branch.

### 4. Abandoned code

Feature paths that still compile but can no longer run: a branch behind a config flag that is never enabled, a user preference that the UI no longer offers, an expired promotion, a retired API tier. Static analysis cannot see it; only domain knowledge can. Look for it whenever you touch config-driven or time-bound conditionals, and create a follow-up task to remove the feature when a flag is retired.

## How to apply as an agent

1. Run the project's static analysis or linter if one exists and act on "unused" findings in the files you touch.
2. Delete, do not comment out. Deletion goes in its own commit (or at least its own hunk) with a message that says what was removed and why.
3. When removing something you are not certain is dead, say so in the summary and keep the removal isolated so it can be reverted alone.
4. Do not "clean up" unrelated dead code in a PR that is about something else without mentioning it; if the cleanup is large, propose a separate change.

## Pitfalls

- Commenting code out "temporarily" during a refactor and forgetting it. Finish the refactor or revert.
- Keeping an unused parameter because "callers pass it". Fix the callers too.
- Treating `@deprecated` as a removal. Deprecation is a promise to remove; schedule the removal.
