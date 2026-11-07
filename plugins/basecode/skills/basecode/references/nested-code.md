# Nested Code

## Why it matters

Every level of nesting costs the reader twice: more eye travel, and one more condition to hold in working memory while reading the inner block. Conditionals are unavoidable, so the goal is not "no conditionals" but **keep the primary action at the top level** and keep each block shallow. "Avoid `else`" is a useful stepping stone, not the goal.

## Techniques, in the order to try them

### 1. Remove empty blocks

An `if` with an empty body paired with a real `else`, or a real `if` with an empty `else`, is dead code. Invert the condition if needed and delete the empty block.

```js
// before
if (process.env.NODE_ENV === 'development') {
  // nothing
} else {
  enforceHttps(req, res);
}

// after
if (process.env.NODE_ENV !== 'development') {
  enforceHttps(req, res);
}
```

### 2. Return the condition itself

When both branches only return a boolean, return the expression.

```php
// before
public function isOverdue(): bool
{
    if ($this->dueDate->isPast()) {
        return true;
    } else {
        return false;
    }
}

// after
public function isOverdue(): bool
{
    return $this->dueDate->isPast();
}
```

Only for booleans. Casting a condition to an int, or collapsing into a ternary, condenses without reducing complexity; use a guard clause instead.

### 3. Guard clauses

Nested conditionals usually mirror the author's reasoning ("if we have an item, and if it's not already there, then add it"). Flip it: handle the exceptional paths first with an early `return`/`throw`, then the primary action sits unindented at the bottom. Mechanically: negate the condition (De Morgan) and return.

```php
// before
public function add(Tag $tag): void
{
    if ($tag !== null) {
        if (! $this->tags->contains($tag)) {
            $this->tags->push($tag);
        }
    }
}

// after
public function add(Tag $tag): void
{
    if ($tag === null || $this->tags->contains($tag)) {
        return;
    }

    $this->tags->push($tag);
}
```

Guard clauses also make the exceptional paths explicit and individually testable. They may appear anywhere in a function, not only at the top.

### 4. Switch to `if`

`switch` carries a lot of syntax (four keywords, three indentation levels). It reads well only when each `case` maps to roughly one line. Prefer a series of `if`s (often guard clauses) when:

- there are only two or three cases,
- any case contains nested logic,
- the value must be cast or computed to fit the `switch`,
- the surrounding code already uses `if`, so mixing the two breaks symmetry.

```js
// before
switch (true) {
  case user.isAdmin:
    return true;
  case visibility === 'public':
    return true;
  case visibility === 'private' && user.id === ownerId:
    return true;
  default:
    return false;
}

// after
if (user.isAdmin) return true;
if (visibility === 'public') return true;
if (visibility === 'private' && user.id === ownerId) return true;

return false;
```

A lookup map or polymorphism is a further option for large, uniform switches, but each adds its own complexity; a tidy `switch` is often good enough.

### 5. Simplify loops

Most loops either accumulate or invoke. Prefer the language's collection helpers (`filter`/`map`/`reduce`, `array_filter`/`array_map`, Laravel collections, list comprehensions) over hand-written index loops with conditionals inside. Extract the body of a complex loop into a named function so the loop reads as a sentence.

```js
// before
const active = [];
for (let i = 0; i < users.length; i++) {
  if (users[i].status === 'active' && !users[i].banned) {
    active.push(users[i].email);
  }
}

// after
const active = users
  .filter((user) => user.status === 'active' && !user.banned)
  .map((user) => user.email);
```

## How to apply as an agent

1. Find the primary action of the function (the thing it exists to do). If it is indented more than one level, unravel the conditions around it with guard clauses until it sits at the top level.
2. Delete `else` after a branch that returns/throws.
3. Convert `switch` to `if` when it fails the "roughly one line per case" test.
4. Replace index loops with collection helpers when the loop is a filter/map/reduce in disguise.
5. Stop collapsing when the next step would create a dense compound expression. Several short guard clauses read better than one long boolean.

## Pitfalls

- Merging all guard clauses into one giant `return a || (b && c) || ...`. Lines of code are not the metric.
- Ternaries nested in ternaries.
- Guard clauses that return `null`; see `reasonable-returns.md`.
