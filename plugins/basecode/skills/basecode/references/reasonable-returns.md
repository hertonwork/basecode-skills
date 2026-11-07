# Reasonable Returns

## Why it matters

A return value should pay for itself. `null` has a negative return: it communicates nothing except "no value", it is foreign to how humans think about absence, and every caller has to write code to handle it. That handling bubbles up through every level and interrupts the reader at each one. Exceptions carry a similar cost; use them for truly exceptional paths and decide deliberately at which level they are thrown and caught.

The biggest payoff comes from fixing the **lowest-level** functions and data structures first, because that is where the null checks start.

## Three techniques

### 1. Return the type's empty value instead of `null`

Every primitive has a natural "nothing": `0`, `0.0`, `''`, `[]`, an empty collection. Return it. The function's return type stays single (`array`, not `array|null`), and callers can chain or iterate without checks.

```php
// before - every caller must check for null
function vowelsIn(string $text): ?array
{
    $vowels = preg_replace('/[^aeiou]/', '', $text);

    if ($vowels === '') {
        return null;
    }

    return str_split($vowels);
}

function vowelHistogram(string $text): ?string
{
    $vowels = vowelsIn($text);

    if ($vowels === null) {
        return null;
    }

    return http_build_query(array_count_values($vowels), '', ', ');
}

// after - the empty array flows through
function vowelsIn(string $text): array
{
    $vowels = preg_replace('/[^aeiou]/', '', $text);

    return $vowels === '' ? [] : str_split($vowels);
}

function vowelHistogram(string $text): string
{
    return http_build_query(array_count_values(vowelsIn($text)), '', ', ');
}
```

### 2. Use expressive representations instead of magic values

`-1` for "not found", `0/1/-1` for comparisons, `false` that collides with `0`: readers must memorize these. Replace them with named constants, enums, or small result objects: `NOT_FOUND`, `Comparison::Less`, `Status::Pending`, `Result::failure($reason)`.

```js
// before
const index = items.indexOf(target);
if (index === -1) { ... }

// after (the language provides the expressive form)
if (!items.includes(target)) { ... }
```

Enums (PHP 8.1 `enum`, TypeScript `enum`/union literals) also give the values a home for labels and helper methods.

### 3. Null objects for the absence of an object

When a function returns an object, "nothing" has no primitive equivalent, so `null` creeps in. Instead return an object that implements the same interface and answers with sensible empty values. The handling of "absent" then lives in one class instead of at every call site.

```php
// before
function greeting(): string
{
    $user = Session::user();

    if ($user !== null) {
        return 'Welcome ' . $user->preferredName();
    }

    return 'Welcome Guest!';
}

// after - Session::user() returns a Guest when nobody is logged in
final class Guest implements Visitor
{
    public function preferredName(): string
    {
        return 'Guest';
    }
}

function greeting(): string
{
    return 'Welcome ' . Session::user()->preferredName();
}
```

Null objects are cheap to write and sit at the lowest level, so they remove null handling across the whole application.

## How to apply as an agent

1. In new code, declare non-nullable return types and return the empty value of the type. Use `?Type` only when absence is meaningful *and* no empty value or null object fits.
2. When you see `return null;`, ask what the primary action's type is and return its empty value.
3. Replace magic numbers and sentinel values with constants/enums; prefer the language's or framework's expressive method (`includes`, `isEmpty`, `firstOrFail`, `findOr`).
4. Introduce a null object when several call sites check the same `=== null` on an object.
5. Reserve exceptions for failures the caller cannot reasonably continue from; do not use them as a second kind of `null`.

## Pitfalls

- Returning `[]` where the empty value hides an error that should have been raised (for example a misconfigured lookup). Empty means "none", not "broken".
- Null objects that silently swallow writes. They should answer reads with empty values; writes on an absent object usually indicate a bug and should fail loudly.
- Leaving nullable types in the lowest layer and "handling it later"; later is every caller.
