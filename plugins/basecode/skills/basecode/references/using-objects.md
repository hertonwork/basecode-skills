# Using Objects

## Why it matters

Primitives (strings, ints, arrays, plain objects/dicts) are the right starting point: keep using them for as long as they stay readable. The problem is *primitive obsession*: a codebase that keeps reaching for a primitive even when it has started to hurt, producing informal data structures, duplicated validation and duplicated logic everywhere the primitive travels.

Objects fix this in two ways: they group data into a formal structure, and they give shared logic a single home. The goal is readability, not "more classes". If there is no informal structure and no duplicated clump of data or logic, leave the primitives alone.

## Three signals and what to do

### 1. Formalize an informal structure

An "options array"/"config object" whose keys can be anything is an infinite, unmaintainable interface: nobody can list the valid keys, nobody can safely remove one.

```php
// before - what keys are allowed? which are used?
public function send(Message $message, array $options = []): void
{
    if ($options['retry'] ?? false) { ... }
    if (($options['priority'] ?? 'normal') === 'high') { ... }
}

// after - the options are explicit, typed, defaulted, and discoverable
final class SendOptions
{
    public function __construct(
        public readonly bool $retry = false,
        public readonly Priority $priority = Priority::Normal,
    ) {}
}

public function send(Message $message, SendOptions $options = new SendOptions()): void
```

The same applies to magic strings and ints: an enum or a small class names the valid values and gives them a place to grow (labels, helpers).

### 2. Couple a data clump into a value object

Two or more values that are always passed together, and that cannot sensibly change independently, are one concept. Give it a name.

```js
// before - amount and currency travel everywhere as a pair
function transfer(from, to, amount, currency) {
  from.debit(amount, currency);
  to.credit(amount, currency);
}

// after - one immutable value
class Money {
  constructor(amount, currency) {
    this.amount = amount;
    this.currency = currency;
    Object.freeze(this);
  }
}

function transfer(from, to, money) {
  from.debit(money);
  to.credit(money);
}
```

Value objects are immutable: once created they do not change, which removes a whole class of state bugs. They also make signatures symmetrical and closer to how the domain is spoken about (nobody says "debit the amount and the currency").

### 3. Encapsulate the logic that keeps following the data

When the same comparison or calculation appears wherever the clump is used, move it into the object.

```php
// before - the range check is repeated at every call site
function withinBudget(array $costs, int $min, int $max): array
{
    return array_filter($costs, fn ($cost) => $cost >= $min && $cost <= $max);
}

// after - the object owns the rule
final class Range
{
    public function __construct(private int $min, private int $max) {}

    public function includes(int $value): bool
    {
        return $value >= $this->min && $value <= $this->max;
    }
}

function withinBudget(array $costs, Range $range): array
{
    return array_filter($costs, fn ($cost) => $range->includes($cost));
}
```

Now `Range` is where validation (`min <= max`), formatting and other range logic live, instead of being re-derived at each use.

## How to apply as an agent

1. Look for open-ended `array $options`/`opts = {}` parameters, magic strings compared in several places, and pairs/triples of parameters that always travel together.
2. Introduce the smallest object that names the concept: constructor, the data, and only the logic that is already duplicated. No getters/setters for their own sake.
3. Make value objects immutable (`readonly` properties, `Object.freeze`, frozen dataclasses).
4. Replace call sites incrementally; keep the old signature working until the last caller is migrated, then delete it (see `dead-code.md`).
5. Stop if the object would have a single use and no duplicated logic - that is speculation, not refactoring.

## Pitfalls

- Creating a class for every parameter. Objects are for structure and shared logic, not ceremony.
- Anemic objects that are just a bag of getters: if the logic stays outside, you have not encapsulated anything.
- Mutable value objects. If it can change after construction, it is not a value.
