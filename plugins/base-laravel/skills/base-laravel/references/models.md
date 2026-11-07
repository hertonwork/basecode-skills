# Models

Models bloat over time, either from "fat models, skinny controllers" taken literally or from being the catch-all for whatever has no home. The practices here keep them organized and push each piece of logic to the framework feature built for it.

## 1. Traits, not a base model

A `BaseModel` that every model extends is one of the most regretted choices in Laravel projects. It trades "not repeating yourself" for forcing behavior on every child, which creates a hard-to-see form of dead code (behavior no child uses) and, worse, tends to override core Eloquent methods, so nobody can tell how the app diverges from the framework.

Laravel itself decorates models with traits (`SoftDeletes`, `Notifiable`, `HasFactory`). Do the same: a trait per behavior, applied only where needed.

```php
// before: every model is unguarded whether it wants to be or not
class BaseModel extends Model
{
    protected $guarded = [];
    public function fill(array $attributes) { /* custom override of core behavior */ }
}

// after: opt in per model
trait Unguarded
{
    public function initializeUnguarded(): void
    {
        $this->guarded = [];
    }
}

class Post extends Model
{
    use Unguarded;
}
```

Eloquent calls `boot{TraitName}()` (static, once) and `initialize{TraitName}()` (per instance) on every trait a model uses - this is how a trait can set properties PHP would not otherwise let it override. Grokking the framework uncovers these hooks.

## 2. The order of things

Uniform ordering means readers know where to look as a model grows. Suggested order (adjust, but apply consistently - a linter such as TLint can enforce it):

1. **Properties**: connection, table, primary key, fillable/guarded, hidden, casts, dates, timestamps, other Laravel properties, custom properties.
2. **Initialization**: constructor, `boot`/`booted`, `initialize*`.
3. **Relationships** (alphabetical is fine). They are closest to properties and the most used methods; keep them near the top.
4. **Query methods**: scopes first, then custom finders.
5. **Accessors, mutators, casts** - alphabetical by attribute so getter and setter sit together.
6. **Creation methods** (named constructors).
7. **Everything else**.

Creation and custom methods go at the bottom because many models have none; keeping relationships in a fixed place matters more than putting statics near the constructor.

## 3. Creation methods

Persistence detail in a controller is "inappropriate intimacy": a high-level class knowing low-level facts (which columns to set, how to hash, which status to start with). Move it to a static method on the model that owns the concept.

```php
// controller before
$product = Product::findOrFail($request->input('product_id'));
$user = User::where('email', $request->input('email'))->first();
if ($user === null) {
    $user = User::create([
        'email' => $request->input('email'),
        'password' => Hash::make(Str::random(32)),
    ]);
}
$order = Order::create([
    'user_id' => $user->id,
    'product_id' => $product->id,
    'total' => $product->price,
    'status' => OrderStatus::Pending,
]);

// controller after
$order = Order::createFromPurchase($request);

// model
public static function createFromPurchase(CreatePurchaseRequest $request): self
{
    $product = Product::findOrFail($request->input('product_id'));
    $user = User::findOrDefault($request->input('email'));

    return static::create([
        'user_id' => $user->id,
        'product_id' => $product->id,
        'total' => $product->price,
        'status' => OrderStatus::Pending,
    ]);
}
```

It is acceptable for `Order::createFromPurchase` to create the user it belongs to; split into two creation methods if you prefer models to only create themselves. Creation methods also cover "build up" logic that sets a complex field or several relationships. A repository layer may hold this instead, but a repository that only wraps Eloquent rarely carries its weight.

Relate models with the expressive relationship API rather than raw foreign keys:

```php
$order->user_id = $user->id;          // technical
$order->user()->associate($user);     // expressive
$user->orders()->create([...]);
$post->tags()->sync($tagIds);
```

## 4. Accessors, mutators, casts

Incremental ladder - stop at the first rung that is readable:

1. **Cast** for type conversion: `'admin' => 'boolean'`, `'settings' => 'array'`, `'status' => OrderStatus::class`, `'price' => MoneyCast::class`. Laravel 11+: a `casts()` method; older: `$casts` property. Custom cast classes (`get`/`set`) replace accessor/mutator pairs that only convert a storage format.
2. **Accessor/mutator** when logic is involved: `Attribute::make(get: fn ($value) => ..., set: fn ($value) => ...)` (Laravel 9+), or `getXAttribute`/`setXAttribute` on older versions. Always pair them so reads and writes stay symmetric.
3. **Helper method** (`isAdmin()`, `expired()`) when it reads better at the call site than an attribute.

Never be afraid to abandon a legacy storage format (a delimited string) for a native one (`array`/`json` cast) when the cost of carrying it exceeds the cost of the migration.

## 5. Query methods

- Repeated query fragments become **local scopes**: `scopeRan(Builder $query)` (any version) or a method tagged `#[Scope]` (Laravel 12+), used as `->ran()`.
- A rule that always applies becomes a **global scope**, best shipped in a trait with a `boot{Trait}` that calls `static::addGlobalScope(...)`, so the model just `use`s it. Opt out with `withoutGlobalScope()`.
- Queries wrapped in extra logic become **static finders** (`Subscription::findByRepository(...)`, `User::invoicesFor(...)`) on the model with the most ownership. They look like Eloquent and keep higher levels free of query detail.

```php
trait SortedByOrdinal
{
    public static function bootSortedByOrdinal(): void
    {
        static::addGlobalScope('ordinal', fn (Builder $query) => $query->orderBy('ordinal'));
    }
}
```

## 6. Collections

Everything Eloquent returns is a `Collection`. Use it.

```php
// before
if (count($orders->toArray()) === 0) { ... }

$next = [];
foreach ($orders as $order) {
    if ($order->hasRerun()) {
        $next[] = $order;
    }
}

// after
if ($orders->isEmpty()) { ... }

$next = $orders->filter->hasRerun();
```

`isEmpty`/`isNotEmpty`, `filter`, `map`, `pluck`, `sum`, `groupBy`, `keyBy`, `first`, `firstWhere`, higher-order messages (`->filter->method()`, `->map->property`) and custom collection classes (`newCollection()`) cover nearly every hand-written loop.

## Checklist for a model

- No base model; shared behavior in traits.
- Members in the fixed order.
- No request/session/auth access inside the model (pass typed data in).
- Casts before accessors; accessor and mutator always paired.
- Repeated query fragments are scopes; always-on rules are global scopes.
- Creation methods for multi-step persistence; relationship methods instead of `_id` assignment.
