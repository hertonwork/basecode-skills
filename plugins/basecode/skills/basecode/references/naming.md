# Naming

## Why it matters

Names carry most of the human signal in code; everything else is syntax the reader's brain parses automatically. Naming is hard mainly when it is forced. Two things make it easy: **context** (the surrounding code, the domain vocabulary) and **time** (names improve over iterations).

## Hard rules

### 1. No abbreviations

Modern editors autocomplete; there is nothing to save. `$perm`, `$cfg`, `$usr`, `$e`, `$cb`, `tmpl`, `resp` all force the reader to expand them. Write `$permissions`, `$config`, `$user`, `$exception`, `$callback`, `template`, `response`.

Exceptions are only the universal conventions below.

### 2. Follow the language's official conventions

A convention is something documented by the language or shared across languages, not a habit of one codebase:

- `i` as a `for` loop index; `$e` in a `catch`; `id`; `url`; `html`; `json`.
- Case conventions: `camelCase` methods in PHP/JS, `snake_case` in Python, `PascalCase` classes, `SCREAMING_CASE` constants.
- Framework conventions: controller/model/job suffixes, test naming, `Interface`/`Trait` suffixes if the ecosystem uses them.

Honor them even when you dislike them; they let readers move between codebases. Do not stretch them: `i, j, k, l` for four nested loops means the loop needs a different structure (see `nested-code.md`, `big-blocks.md`).

### 3. Leverage context instead of repeating it

Every word in a name costs; spend the budget on words that add information. Do not repeat what the scope, the parent, or the type already says:

- Table `users` with columns `user_name`, `user_email` -> `name`, `email`.
- `components[].component` -> `components[].type` or `.name`.
- `$userArray`, `strToUpper`, `$countInt`, `ICustomerRepository` -> drop the type: `$users`, `uppercase`, `$count` (unless the ecosystem's convention mandates the prefix).
- `EventHandler::handleEvent()` -> `EventHandler::handle()` or better, a verb that adds meaning.

The characters you save go to richer words: `name` -> `legalName`, `date` -> `publishedAt`.

## Guidelines

### Human readable

Names should read like a sentence to a technical reader: `$invoice->markPaid()`, `if ($subscription->isExpired())`, `Route::middleware('auth')`. Let the reader infer technical facts from the code (types, signatures); use the words for the human meaning.

### Express the domain

Use the words the team uses when talking about the product. `Zookeeper::feed()` beats `Employee::work()`. `Operator::connect($call)` beats `EventHandler::bind($event)`. When a method name needs filler words to be read aloud, the vocabulary is probably too technical. A dictionary or thesaurus is a legitimate tool here.

### Let it run in the background

Do not force the perfect name on the first try. Use a long, descriptive placeholder (even a full phrase: `createUserIfNotAuthenticated`) and keep going. The right name tends to appear after the surrounding code exists, or after the domain term shows up in conversation. Revisit names when the context changes; renaming is cheap with an IDE.

## Worked example

```php
// before
class EvtHandler
{
    public function handle($e, $fn) { ... }
    public function rm($e) { ... }
}

// expand abbreviations
class EventHandler
{
    public function handle($event, $function) { ... }
    public function remove($event) { ... }
}

// follow conventions ($callback), stop repeating context (handle in EventHandler)
class EventHandler
{
    public function bind($event, $callback) { ... }
    public function unbind($event) { ... }
}

// express the domain (this is a telephony app)
class Operator
{
    public function connect(Call $call, Endpoint $endpoint) { ... }
    public function disconnect(Call $call) { ... }
}
```

Each step is small; the last one requires knowing what the code is for.

## How to apply as an agent

1. Expand every abbreviation in code you write or touch, except conventional ones.
2. Match case and suffix conventions of the language and framework in use; check neighbouring files.
3. Remove type words and repeated parent/scope words from names.
4. Pair names symmetrically (`open/close`, `attach/detach`, `enable/disable`); see `symmetry.md`.
5. Prefer domain verbs and nouns; ask the user for the domain term when unsure rather than inventing a technical one.
6. When renaming public API, keep a deprecated alias for one release only if external callers exist; otherwise rename everywhere.

## Pitfalls

- Over-long names that restate every condition: `getActiveUsersWhoHaveNotLoggedInSinceLastMonth()` -> `dormantUsers()` with the rule inside.
- Hungarian notation and type suffixes.
- Generic nouns: `data`, `info`, `item`, `manager`, `helper`, `util` as the whole name.
