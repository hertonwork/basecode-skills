# Symmetry

## Why it matters

Symmetry is the principle that the same idea is expressed the same way everywhere it appears. Readers recognize symmetrical code as consistent and intuitive, and they start to predict what comes next. It underlies all the other practices (format, naming, structure) and is the one that takes longest to master, so apply it **last**, after the other practices have shaped the code.

A classic illustration: a method whose body is `input(); count++; output();` mixes two high-level calls with one low-level statement. `input(); tally(); output();` has the same behavior, one level of abstraction, and names of the same kind.

## Three levels, apply in order

### 1. Syntactic symmetry

Same syntax for the same thing:

- One formatter settles brace placement, spacing and quotes (see `formatting.md`).
- Consistent structure: declarations at the top, methods grouped by visibility, the same parameter order across related functions (`(callback, items)` vs `(items, callback)` in one codebase is asymmetric).
- Consistent operators: `&&` or `and`, strict `===` everywhere, one way to check emptiness.
- Guard clauses grouped: all the `return false` guards together, then all the `return true` early returns, then the primary action.

### 2. Semantic symmetry

Same meaning, same words:

- Pair names with their true opposites: `on/off`, `open/close`, `attach/detach`, `enable/disable`, `start/stop`. Not `on/stop` or `enable/remove`.
- Once a prefix convention is chosen (`is`/`has`/`can` for booleans, `get`/`set` or bare property names), use it everywhere in the scope.
- One term per concept: `last`, `latest` and `previous` for the same thing in one class is three terms too many. Pick one.
- One tone: prefer positive conditions. `if ($this->disabled())` reads better than `if (! $this->enabled())`; mixing negated and positive guards forces the reader to flip logic on every line.
- Trim words the context already provides: `Check::alreadyScheduledOrRunning()` instead of `Check::checkHasAlreadyBeenScheduledOrIsRunning()`.

### 3. Systemic symmetry

Same patterns across the codebase:

- Pick one way to do a thing (one validation approach, one way to dispatch background work, one way to format responses) and use it everywhere. Design-pattern bingo prevents readers from ever getting a feel for the application.
- When choosing between adopting a new pattern and reusing one already in the codebase, symmetry favors reuse.
- Keep each function at one abstraction level; a single low-level expression among high-level calls is a signal to extract it (see `big-blocks.md`), which also tends to remove hidden temporal dependencies between conditions.

## Worked example

```php
// before - mixed tone, mixed terms (latest/previous), one raw implementation detail
public function needsToRun(): bool
{
    if (! $this->enabled) {
        return false;
    }
    if ($this->type === CheckType::Uptime && $this->latestRun()?->failed()) {
        return true;
    }
    if ($this->latestRun() === null) {
        return true;
    }
    if ($this->previousRunCrashed()) {
        return true;
    }
    if ($this->alreadyScheduledOrRunning()) {
        return false;
    }

    return $this->latestRun()->endedMoreThanMinutesAgo($this->minutesBetweenRuns());
}

// after - negatives first, then positives; one term; one tone; one abstraction level
public function needsToRun(): bool
{
    if ($this->disabled()) {
        return false;
    }
    if ($this->alreadyScheduledOrRunning()) {
        return false;
    }

    if ($this->firstRun()) {
        return true;
    }
    if ($this->retryUptimeCheck()) {
        return true;
    }
    if ($this->lastRunCrashed()) {
        return true;
    }

    return $this->readyToRerun();
}
```

Each line now has the same shape: a positively-named, parameterless query. Improving symmetry in one spot made the remaining asymmetries (the compound uptime condition, the chained call with an argument) obvious; that positive feedback loop is normal.

## How to apply as an agent

1. After applying the other practices, reread the block and look for one-offs: a different operator, a negated condition among positives, a lower-level expression among method calls, a term that does not match its siblings.
2. Reorder guards so negative outcomes are grouped, then positive outcomes, then the primary action.
3. Rename for pairs and single terms; check the whole class, not just the method.
4. Before introducing a new library, pattern or helper style, search the codebase for how the same problem is already solved and follow that.
5. Note remaining asymmetries you chose not to fix (and why) in your summary.

## Pitfalls

- Forcing symmetry where the domain really differs (two things that look alike but behave differently).
- Renaming for symmetry across public APIs without a migration plan.
- Treating symmetry as cosmetic; it is the practice that lets a reader understand the application from any file.
