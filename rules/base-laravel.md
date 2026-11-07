# BaseLaravel rules (condensed)

Paste into the agent instructions file of a Laravel project, together with `basecode.md`. For the full practices with examples, use the `base-laravel` skill in this repo.

## Principles

- **Write readable code** (BaseCode) and **grok the framework**: when unsure, do it the way Laravel itself does.
- **Follow conventions** - Laravel's style, naming and folders, unmodified. Personal customizations cost on every upgrade and every onboarding.
- **Where things go** - a class near a core concept goes in that concept's folder (`app/Http/Controllers`, `app/Models`, `app/Mail`, `app/Events`, `app/Exceptions`, `app/Http/Requests`, `app/Http/Resources`, `app/Jobs`, `app/Policies`, `app/Observers`); model-adjacent plain classes live with models; anything else starts in `app/Services` and gets its own folder once three similar classes exist. API controllers under `app/Http/Controllers/Api`.
- **Use what's available** - check the framework (and `vendor/laravel/framework`) before writing a helper or adding a package.
- **Honor MVC** - views don't touch request/session/auth/db; models don't read the request; controllers orchestrate only.
- A big block inside a core Laravel component almost always means a framework feature is being reimplemented.
- Every deviation is a trade-off: state the reason in one sentence.

## Controllers

- Collapse temporary variables: move assignments next to use, inline single-use ones, read from the owning object (`$request->input()`, `$request->user()`, `Auth::id()`, `$request->boolean()`). No `compact()`; pass explicit arrays to `view()`. Small private methods for complex/expensive expressions only.
- Use the injected `Request` (or a form request), not `Request::`/`Auth::`/`Validator::` facades.
- Validation and request authorization in **form requests**; persistence via a typed model creation method (`Invoice::createFromRequest($request)`). Don't share one form request between `store` and `update` if it needs route sniffing.
- Authorization in middleware (default), gates (custom generic logic), or policies (model CRUD) - not inline `if`s.
- Dispatch statically: `Job::dispatch($x)`, `Event::dispatch($x)`, `Event::dispatchIf($cond, $x)`.
- Respond with helpers (`response()->noContent()`), return models for plain JSON, use **API Resources** (`toArray`, `when()`, `withResponse()`) when the response is request-aware or sets headers.

## Models

- Traits over a base model; never override core Eloquent methods in a parent. Use `boot{Trait}`/`initialize{Trait}` hooks.
- Member order: properties -> initialization -> relationships -> query methods (scopes, finders) -> accessors/mutators/casts -> creation methods -> other methods. Alphabetical within a group.
- Creation methods (`Model::createFromX()`) for multi-step persistence; relationship API (`associate`, `attach`, `sync`, `->relation()->create()`) instead of assigning `_id` columns.
- Casts (`casts()`/`$casts`, enums, custom cast classes) before accessors (`Attribute::make(get:, set:)`, always paired) before helper methods.
- Repeated query fragments are local scopes (`scopeX`/`#[Scope]`); always-on rules are global scopes in a trait; wrapped queries are static finders.
- Use collections (`isEmpty`, `filter->method()`, `map`, `pluck`, `sum`) instead of `toArray()` + `foreach`.

## Views

- Modern directives: `@unless`, `@isset`, `@empty`, `@auth`/`@guest`, `@can`/`@cannot`, `@production`/`@env`, `@forelse/@empty`, `@includeWhen`, `@each`, `@class`, `@checked`/`@selected`/`@disabled`, `@push`/`@stack`, `$loop`. No double negatives.
- Hierarchy: layouts -> views -> partials/components. Page assets via stacks.
- Views are dumb: no `@php`, no request/session/auth/db access; the controller passes simple data.
- Remaining display logic (icons, labels, classes per state) goes in a presenter class or a model helper; repeated markup becomes a Blade component with `@props`, `$attributes->merge()` and `$slot`.

## Streamlines

- Never edit stock `config/*.php`; use `.env` for their values and your own `config/<app>.php` for custom options. `config()` everywhere, `env()` only inside `config/`.
- Fluent routes: `->name()`, `Route::middleware()->group()`, `Route::resource()->only()`, `apiResource`; fixed chain order; middleware in route files.
- No container bindings for auto-resolvable classes; no interfaces with one implementation; use `$bindings`/`$singletons` when a binding is needed.
- Macros on macroable classes for framework-shaped helpers, all registered in one `MacroServiceProvider`.
- Exceptions define `report()`/`render()`; controllers keep only the happy path.
- Lightweight services as real-time facades (`use Facades\App\Services\X`).
- Events only when shared side effects hurt; primary action inline, secondary in (queued) listeners; prefer explicit dispatch over observers; string events + closure listeners for trivial cases.
