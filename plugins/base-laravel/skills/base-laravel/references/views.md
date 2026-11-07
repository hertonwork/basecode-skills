# Views

Views force a context switch (PHP to HTML/Blade), so lazy view code costs more than lazy backend code. The aims are the least code and a predictable structure.

## 1. Modern Blade directives

Blade syntax has been stable for years, so many templates still use Laravel 3-era `@if` for everything. Replace them with the purpose-built directives:

| Old | Modern |
|-----|--------|
| `@if(! $condition)` | `@unless($condition)` |
| `@if(isset($records))` | `@isset($records)` |
| `@if(empty($records))` | `@empty($records)` |
| `@if(Auth::check())` / `@if(! Auth::check())` | `@auth` / `@guest` |
| `@if(Gate::allows('edit', $post))` / `denies` | `@can('edit', $post)` / `@cannot(...)` |
| `@if(App::environment('production'))` | `@production` / `@env('local', 'testing')` |
| `@if($items->isNotEmpty()) @foreach ... @else ... @endif` | `@forelse($items as $item) ... @empty ... @endforelse` |
| `@if($x) @include('a') @endif` stacked | `@includeWhen($x, 'a')` / `@includeUnless` / `@includeFirst` |
| `@foreach` that only includes a partial | `@each('partials.item', $items, 'item', 'partials.empty')` |
| `class="{{ $active ? 'is-active' : '' }}"` | `@class(['is-active' => $active])` |
| `{{ $checked ? 'checked' : '' }}` | `@checked($checked)`, `@selected(...)`, `@disabled(...)`, `@readonly(...)`, `@required(...)` |

Avoid double negatives (`@if(! $items->isNotEmpty())`): `@unless($items->isEmpty())` or, better, `@forelse`. Inside loops, use `$loop->first/last/index/iteration` instead of your own counters.

## 2. Template hierarchy

Three levels:

1. **Layouts** - the `<html>` shell. Pages extend or wrap them.
2. **Views** - one per page or screen.
3. **Partials / components** - shared fragments (error lists, form bodies shared by create and edit, header pieces). Partials may include partials.

```blade
<x-layouts.app>
    @include('partials.errors')

    <form method="POST" action="{{ route('location.update', $location) }}">
        @method('PUT')
        @csrf

        @include('partials.location.form')

        <button type="submit">{{ __('Save Location') }}</button>
    </form>
</x-layouts.app>
```

## 3. Stacks

Page-specific assets or scripts belong to the page, not to conditionals in the layout:

```blade
{{-- page --}}
@push('scripts')
    <script src="https://js.stripe.com/v3/"></script>
@endpush

{{-- layout --}}
@vite('resources/js/app.js')
@stack('scripts')
```

## 4. Be dumb

Views should not be smart. Smart views reach into the request, session, auth or database, do arithmetic, or massage data. Signs: `@php` blocks, `Request::`/`Session::`/`Auth::` inside templates, `->where()` in a loop.

Move that logic to the controller (or presenter) and pass simple data. The view becomes flexible (the same template renders for any user/account/display mode) and testable.

```blade
{{-- before --}}
@php $display = Request::input('type', 'full'); @endphp
@if(Auth::user() && Session::get('account') != $list->account_id) ... @endif

{{-- after: controller passes $display, $user, $currentAccountId --}}
@if($user && $currentAccountId != $list->account_id) ... @endif
```

Exception: directives that *are* the framework's blessed view access (`@auth`, `@can`) are fine.

## 5. Presenters (view classes)

Even dumb views accumulate display logic: which icon for which status, which label, which CSS class, which wording per variant. Each new state means hunting through every template. Put that logic in a **presenter** - a small class (static methods or an object wrapping the model) called from the view:

```blade
{{-- before --}}
@if($order->status === OrderStatus::Hold)
    @if($order->ranTwice()) {{-- failed button --}} @else {{-- rerun button --}} @endif
@elseif($order->status === OrderStatus::Pending)
    {{-- run button --}}
@endif
<a title="View {{ Str::lower(pr_name($order->connection->service)) }}">...</a>

{{-- after --}}
<x-order.action :order="$order" />
<a title="{{ OrderPresenter::prLinkTitle($order) }}">...</a>
```

"Presenter" rather than "view model": it does not change the controller contract, it only answers display questions, and it may emit HTML. Simple predicates (`$order->hasRun()`, `$order->isPending()`) can stay on the model when other layers use them too.

## 6. Components

For repeated markup with varying data, use Blade components (Laravel 7+), anonymous when there is no logic:

```blade
<x-quote class="mt-24" name="Taylor Otwell" title="Creator - Laravel" handle="taylorotwell">
    If you're running an old version, this is the fastest way to upgrade.
</x-quote>

{{-- resources/views/components/quote.blade.php --}}
@props(['name', 'title', 'handle'])
<blockquote {{ $attributes->merge(['class' => 'px-6']) }}>
    <p>{{ $slot }}</p>
    <footer>
        <img src="{{ asset("images/avatar-$handle.jpg") }}" alt="{{ $name }}">
        <cite>{{ $name }} <span>{{ $title }}</span></cite>
    </footer>
</blockquote>
```

Refactor incrementally: inline markup -> partial/`@component` -> `<x-component>`. Trade-off: going all-in on components (including layouts) gives up the classic `@extends/@section` hierarchy; choose one approach per project and state why.

## Checklist for a view

- Modern directives, no double negatives, no `@php`.
- No request/session/db access; everything arrives as data.
- Repeated markup is a partial or component; page assets use stacks.
- Display logic lives in a presenter or model helper, not in nested `@if`s.
