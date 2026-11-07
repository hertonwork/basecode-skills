# Additional Streamlines

Framework-level practices applied whenever a Laravel codebase is modernized. Each one removes code by using something Laravel already provides.

## 1. Maintaining config files

Laravel's `config/*.php` files change every release. If you edit them, every upgrade becomes a line-by-line diff, and a single stale option can halt development for days.

- **Don't edit Laravel's config files.** Set the values they expose through `.env` variables; nearly every commonly customized option already reads `env()`.
- **Put your own options in your own file**: `config/shift.php` -> `config('shift.latest_sku')`. Back them with `env()` where the value differs per environment. Keep static lists (SKUs, feature tables) there too.
- When a package or Laravel requires options inside a core file (`database.connections`, `filesystems.disks`), add a clearly separate block so customizations are easy to spot when diffing against the stock file.

With this discipline, upgrading config is "copy the new stock files over".

**`config()` over `env()`.** Config loading is expensive and happens per request; `php artisan config:cache` fixes that, but only if the app never calls `env()` outside `config/`. Replace `env('X')` in application code with `config('myapp.x')` and declare `x` in your config file.

## 2. Fluent routes

Array options (`['as' => ..., 'uses' => ...]`) are legacy. Chain methods, and collapse CRUD sets with `resource`/`apiResource` + `only`/`except`:

```php
Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::resource('billing', BillingController::class)->only(['create', 'store']);
    Route::resource('invoices', InvoiceController::class)->only(['index', 'show']);
});
```

Adopt small conventions and keep them: a fixed chain order (verb -> middleware -> name -> constraints), middleware declared in route files rather than controller constructors, `apiResource` for APIs.

## 3. Container

- **No binding for auto-resolvable classes.** `$this->app->bind(Foo::class, fn () => new Foo())` does nothing the container doesn't already do, even when `Foo` has typed constructor dependencies.
- **No interface for a single implementation.** Laravel's own contracts exist because several classes implement them. If only one class ever will, type-hint the class and delete the interface.
- When a binding is truly needed, declare it declaratively:

```php
class AppServiceProvider extends ServiceProvider
{
    public $bindings = [
        PaymentGatewayContract::class => StripeGateway::class,
    ];

    public $singletons = [
        RateLimiterRegistry::class => RateLimiterRegistry::class,
    ];
}
```

Closure bindings remain for genuinely complex construction, which should be rare.

## 4. Macros

Nearly every facade and support class is `Macroable` (`Str`, `Collection`, `Request`, `Response`, `Redirect`, `Route`, `Builder`, ...). A macro attaches behavior to the framework class where it reads most naturally, without a new class, a binding or a helper that takes awkward arguments.

```php
// before: a global helper that needs the request passed around
return redirect_to_checkout($request, $order);

// after: a macro registered once (AppServiceProvider or a dedicated MacroServiceProvider)
Redirect::macro('checkout', function (Order $order) {
    return $order->runsForFree()
        ? $this->route('run.create', $order)
        : $this->route('checkout.create', $order);
});

return redirect()->checkout($order);
```

Because macros look native, register them all in one `MacroServiceProvider` so new developers can find them.

## 5. Exception handling

Try/catch blocks with several `catch` arms, each logging and redirecting, bury the happy path. Laravel calls `report()` and `render($request)` on any exception that defines them, so the handling moves into the exception class:

```php
class PaymentChargeFailed extends RuntimeException
{
    public function __construct(string $message, private array $data) { parent::__construct($message); }

    public function report(): void
    {
        Log::error('Card failed', $this->data);
    }

    public function render(Request $request)
    {
        return back()->withInput()->with('error', [
            'template' => 'partials.errors.charge_failed',
            'data' => $this->data['error'] ?? [],
        ]);
    }
}
```

The service throws `PaymentChargeFailed`; the controller contains only the happy path. On Laravel 11+ app-wide handling lives in `bootstrap/app.php` (`->withExceptions(...)`), but per-exception `report`/`render` methods still work and keep the logic next to the exception.

## 6. Real-time facades

A custom facade normally needs the class, an accessor class and a binding - too much ceremony for a lightweight service used in one or two places. Dependency injection works in controllers but not everywhere. Real-time facades need nothing: prefix the class's namespace with `Facades\`:

```php
use Facades\App\Services\Geocoder;

$country = Geocoder::countryForIp($ip);
```

Still fully testable (`Geocoder::shouldReceive(...)`).

## 7. Events and observers

Events decouple side effects (send verification mail, resize avatar, tag the newsletter subscriber) from the primary action, and remove the human burden of remembering to trigger them from every entry point. The cost is a paradigm shift: behavior now happens somewhere else, which can confuse readers and complicate debugging. Adopt events only when the pain of shared side effects is real, and tell the team (README, onboarding) that the app uses them.

Guidelines:

- Perform the primary action inline; put secondary actions in listeners. Queue listeners (`ShouldQueue`) for slow or fire-and-forget work.
- Jobs vs events: jobs for single, repeatable, on-demand actions; events for shared or asynchronous reactions to something that happened.
- Dispatch statically: `VideoWatched::dispatch($user, $videoId)`.
- **Streamline simple cases**: a string event with an inline closure listener avoids two lazy classes:

```php
event('video.watched', [$request->user(), $videoId]);

// AppServiceProvider::boot (Laravel 11+ has no EventServiceProvider by default; listeners are auto-discovered)
Event::listen('video.watched', fn (User $user, int $videoId) => Newsletter::tag($user, "Video-$videoId"));
```

- **Model lifecycle**, from most to least visible:
  1. `$dispatchesEvents = ['created' => VideoWatched::class]` - reuses an existing event, visible at the top of the model.
  2. An **observer** class (`#[ObservedBy(WatchObserver::class)]` on the model, or `Watch::observe(...)` in a provider) when several lifecycle hooks or big blocks are involved. Observers run synchronously and are tightly coupled to the model event.
  3. Closures in `booted()` (`static::created(fn ($watch) => ...)`) when an observer would be a lazy class.
  Returning `false` from a `saving`/`deleting` handler cancels the operation.

Observers fire invisibly, so prefer explicit event dispatching unless the model hook is the obvious home.

## Checklist

- No edits to stock config files; own options in own config; no `env()` outside `config/`.
- Fluent routes, `resource()->only()`.
- No redundant bindings or single-implementation interfaces.
- Shared behavior on framework classes as macros, registered in one place.
- Exceptions carry their own `report`/`render`; controllers keep the happy path.
- Lightweight services via real-time facades.
- Events only when justified; dispatch explicitly; queue slow listeners.
