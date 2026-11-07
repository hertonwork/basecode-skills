---
name: base-laravel
description: Laravel-specific practices for writing less complex, more readable Laravel applications - skinny controllers (temporary variables, request object, form requests, middleware/policies/gates, job and event dispatching, API resources), organized models (traits over inheritance, member ordering, creation methods, accessors/casts, scopes, collections), dumb views (modern Blade directives, template hierarchies, stacks, presenters, components) and framework streamlines (config over env, fluent routes, container bindings, macros, renderable exceptions, real-time facades, events/observers). Use when creating or refactoring any PHP file in a Laravel project (controllers, models, Blade views, routes, providers, jobs, events, exceptions), when asked "the Laravel way", "streamline this", "where should this go", "fat controller", "fat model", or when reviewing Laravel code. Apply together with the basecode skill. Do not use for non-Laravel PHP or for frontend-only work.
metadata:
  version: "1.0.0"
  source: "Practices adapted from Jason McCreary's BaseLaravel field guide (original wording and examples), updated for current Laravel idioms"
---

# BaseLaravel: streamline Laravel applications

Two principles decide every choice. When they disagree with a personal preference, the principles win.

1. **Write readable code.** The ten BaseCode practices apply (load the `basecode` skill). Three of them matter even more inside a framework:
   - *Follow conventions.* Adopt Laravel's style, naming and folder structure as-is. Personal customizations cost forever: every doc snippet needs tweaking, every upgrade gets harder, onboarding slows.
   - *Where things go.* A class close to a core Laravel concept goes in that concept's folder (`app/Http/Controllers`, `app/Models`, `app/Mail`, `app/Events`, `app/Exceptions`, `app/Http/Requests`, `app/Http/Resources`, `app/Jobs`, `app/Policies`, `app/Observers`). Plain classes that relate to a model live with the models. Everything else starts in `app/Services`; when three similar classes accumulate there (Rule of Three), give them their own folder - this surfaces the patterns your app actually uses. Separate `Api` controllers under `app/Http/Controllers/Api`.
   - *Big blocks are tolerated even less.* A long method inside a core Laravel component (controller, model, provider) almost always means a framework feature is being reimplemented.
2. **Grok the framework.** When unsure how to write something, look at how Laravel itself does it and follow that. Two corollaries:
   - *Use what's available.* Before adding a package or writing a helper, check whether the framework already has it (request helpers, response helpers, collection methods, Blade directives, casts, scopes, macros). Prefer a few lines of your own over a package that does ten things you don't need.
   - *Honor MVC.* Views don't query or reach into the request/session/auth; models don't read the request; controllers orchestrate, they don't persist, format or compute. Helpers and facades make crossing boundaries easy - notice when you do.

Everything is a trade-off. When you deliberately go against a practice, state the reason in one sentence (commit message or reply).

## Quick reference

### Controllers (where most code - and most waste - lives)

- **Collapse temporary variables.** Move each assignment next to its use (proximity rule); if it is used once, inline it. Access data from the owning object (`$request->input()`, `$request->user()`, `Auth::id()`) instead of copying it into locals. Drop `compact()`; pass an explicit array to `view()`. Wrap only complex or expensive expressions in a tiny private method (memoize with `static` if needed). Never inline into a ternary soup.
- **Use the injected `$request`.** Type-hint `Request $request` (or a form request) and use `$request->validate()`, `->validated()`, `->boolean()`, `->user()`, `->ajax()` instead of the `Request`/`Auth`/`Validator` facades.
- **Form requests** own validation and request authorization. Pass the whole request to a model creation method (`Invoice::createFromRequest($request)`) so the coupling is typed and MVC-safe. Don't share one form request between `store` and `update` if that needs route sniffing.
- **Authorization** goes to middleware (generic), gates (generic custom logic, usable in routes, controllers and Blade via `can`), or policies (coupled to a model's CRUD). Pick the most generic option that fits so it is found where everyone expects.
- **Dispatch statically**: `SendInvoice::dispatch($order)`, `OrderShipped::dispatch($order)`, `OrderShipped::dispatchIf($condition, $order)`; not `$this->dispatch(new Job(...))` or `event(new ...)`.
- **Respond expressively**: `response()->noContent()`, return the model/collection directly for plain JSON, and use an API Resource (`toArray`, `when()`, `withResponse()`) once the response needs request-aware shaping or headers.

### Models

- **Traits, not a base model.** Shared behavior goes in a trait with `boot{Trait}`/`initialize{Trait}` hooks and is applied only to models that need it. Never override core Eloquent methods in a parent class.
- **Fixed member order**: properties -> initialization (`__construct`, `boot`/`booted`, `initialize`) -> relationships -> query methods (scopes, then custom finders) -> accessors/mutators/casts -> creation methods -> other methods. Alphabetical inside a group when it has no natural order.
- **Creation methods** (`Order::createFromPurchase(...)`, `User::findOrDefault(...)`) pull persistence detail out of controllers. Relate models with `associate`, `attach`, `sync`, `->orders()->create()`, not by assigning `_id` columns by hand.
- **Casts first, then accessors.** `casts()`/`$casts` for type conversion (including enums and custom cast classes), `Attribute::make(get:, set:)` for real logic, a helper method only when it reads better.
- **Query scopes** (`scopeRan()` or `#[Scope]`) for repeated query fragments; a trait with a global scope when the rule always applies.
- **Collections**: `isEmpty()`, `filter->method()`, `map`, `pluck`, `sum` instead of `toArray()` + `foreach`.

### Views

- **Modern directives**: `@unless`, `@isset`, `@empty`, `@auth`/`@guest`, `@can`/`@cannot`, `@production`, `@env`, `@forelse ... @empty`, `@includeWhen`, `@each`, `@class`, `@checked`/`@selected`/`@disabled`, `@push`/`@stack`. Avoid double negatives.
- **Hierarchy**: layouts -> views -> partials (and components). Shared fragments (errors, form bodies, headers) become partials or anonymous components.
- **Be dumb**: no `@php` assignments, no facades for request/session/auth/db. The controller passes simple data; display logic that remains goes to a presenter class or a model helper (`$order->hasRun()`).
- **Components** (`<x-quote ...>` with `$attributes->merge()` and `$slot`) for repeated markup with varying data.

### Additional streamlines

Config over `env()`, custom config files instead of editing Laravel's, fluent routes (`->name()`, `Route::middleware()->group()`, `Route::resource()->only()`), no container bindings for auto-resolvable classes (`$bindings`/`$singletons` when you must), macros on macroable classes (registered in one `MacroServiceProvider`), renderable/reportable exceptions so controllers keep only the happy path, real-time facades (`Facades\App\Services\...`) for lightweight services, and events only when the pain of shared side effects is real.

## Workflow

1. Identify which component you are in (controller, model, view, route file, provider, job) and read the matching reference: `references/controllers.md`, `references/models.md`, `references/views.md`, `references/streamlines.md`.
2. Check the Laravel version in `composer.json` and use that version's idiom (for example `casts()` method and `#[Scope]` on Laravel 11/12, `$casts` and `scopeX()` on older versions).
3. Search the framework (`vendor/laravel/framework`) and the project for an existing way to do the thing before writing a helper or adding a package.
4. Apply the BaseCode practices to the result (nested code, naming, comments, symmetry).
5. Run the project's formatter (`vendor/bin/pint`) and tests on what you touched.
