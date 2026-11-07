# Controllers

Controllers hold the most lines per method and the fewest private methods of any Laravel class, so this is where streamlining pays off most. Six practices, in the order to apply them.

## 1. Temporary variables

Most temporaries in controllers exist to feed `compact()` or to hold something an object already exposes. Apply the **proximity rule**: move each assignment to the line before its first use. If it is used once, inline it. If it stays, it now sits where its context is obvious, which also lowers the pressure to find a perfect name.

```php
// before
public function update(Request $request, Account $account)
{
    $data = $request->except(['_method', '_token']);
    $message = 'Your account details have been updated.';
    $accountId = $account->id;

    $account->update($data);

    return redirect()->route('account.edit', compact('accountId', 'message'));
}

// after
public function update(Request $request, Account $account)
{
    $account->update($request->except(['_method', '_token']));

    return redirect()->route('account.edit', [
        'accountId' => $account->id,
        'message' => 'Your account details have been updated.',
    ]);
}
```

Dropping `compact()` also decouples controller variable names from view variable names, so each can use the name that reads best in its own context.

Access data from its owner rather than copying it:

```php
// before
$user = Auth::user();
$data = $request->all();

return Todo::create([
    'user_id' => $user->id,
    'title' => $data['title'],
    'completed' => $data['completed'] ?? false,
]);

// after
return Todo::create([
    'user_id' => Auth::id(),
    'title' => $request->input('title'),
    'completed' => $request->boolean('completed'),
]);
```

Inlining is a discovery tool, too: inline everything, and the overlapping or redundant conditions become visible; then recompose only what is needed. What survives are complex or expensive expressions; wrap those in a small private method (Laravel's own classes are full of tiny private helpers). Memoize with a `static` local if the same expensive call is needed twice in one action.

Do not inline into nested ternaries or one-liners; density is the opposite of the goal.

## 2. The request object

Laravel injects `Request` into every action. Use it instead of the `Request`, `Auth` and `Validator` facades: it is shorter, keeps the action cohesive, and stops the controller from reaching across boundaries through globals.

```php
public function update(Request $request, Post $post)
{
    $request->validate([
        'title' => ['required', 'max:255'],
        'body' => ['required'],
    ]);

    $post->update($request->validated());
    $post->user()->associate($request->user());
    $post->save();

    return $post;
}
```

If you prefer an explicit user variable, inject `Authenticatable $user` into the action.

## 3. Form requests

Validation blocks (and often the authorization check) are the biggest blocks in controllers. A form request moves both out and halves the action. This is a shell game - the lines move, they do not vanish - but each piece now sits at the right level.

```php
// before
public function store(Request $request)
{
    abort_unless($request->user(), 401);

    $request->validate([
        'order_id' => ['required', 'exists:orders,id'],
        'billing_details' => ['required', 'string'],
    ]);

    $order = Order::find($request->input('order_id'));
    abort_unless($order->user->is($request->user()), 403);

    $invoice = Invoice::create($request->only(['order_id', 'billing_details']));

    return redirect()->route('invoice.show', $invoice);
}

// after
public function store(CreateInvoiceRequest $request)
{
    $invoice = Invoice::createFromRequest($request);

    return redirect()->route('invoice.show', $invoice);
}
```

Where should the creation logic go?

- `$request->createInvoice()` on the form request: shortest, but the request now changes for two reasons.
- `Invoice::createWithData($request->validated())` on the model: honors MVC, but accepts any array.
- `Invoice::createFromRequest(CreateInvoiceRequest $request)`: the type hint documents exactly which data the model may read, which makes boundary violations easy to spot. Preferred.

Don't reuse one form request across `store` and `update` if it needs to inspect the route to vary rules; two small declarative classes are simpler.

## 4. Authorization: middleware, gates, policies

- A form request's `authorize()` is fine when the check is about this request.
- Otherwise default to **middleware** - it is the most generic place and where everyone looks first.
- Use a **policy** when the rules are coupled to a model's CRUD operations; Laravel wires policies automatically.
- Use **gates** for custom logic not tied to a model; they work in middleware (`can:`), controllers (`$this->authorize()`/`Gate::allows()`) and Blade (`@can`), with the least code.

Follow the convention your codebase already uses; discipline beats "a newer way".

## 5. Dispatching jobs, events, notifications, mail

```php
// before
$job = new RunImport($file);
$this->dispatch($job);

event(new OrderShipped($order));

if ($user->wantsUpdates()) {
    event(new AccountUpdated($user));
}

// after
RunImport::dispatch($file);

OrderShipped::dispatch($order);

AccountUpdated::dispatchIf($user->wantsUpdates(), $user);
```

The static `dispatch`, `dispatchIf`, `dispatchUnless`, `dispatchSync`, `dispatchAfterResponse` come from the `Dispatchable` traits on jobs and events. Same shape for both, which gives the controller syntactic symmetry.

## 6. Responding with resources

Use the expressive response helpers (`response()->noContent()` instead of `response(null, 204)`). Return a model or collection directly when plain JSON is enough; control the shape with `$hidden`/`$appends`.

Once the response depends on the request (conditional fields, headers), move it to an **API Resource**: it has access to both the model and the request, so neither the model nor the controller has to.

```php
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'name' => $this->full_name,
            'title' => $this->title,
            'age' => $this->when($request->has('show-age'), fn () => $this->birthdate->age),
        ];
    }

    public function withResponse($request, $response): void
    {
        $response->header('X-RateLimit-UserLimit', $this->limit);
    }
}

public function show(User $user)
{
    return new UserResource($user);
}
```

Prefer this to a formatting package unless the package does exactly what you need.

## Checklist for a controller action

- Does it read at one level (orchestration only)?
- No `compact()`, no facade where `$request` would do, no validation rules inline when a form request fits.
- Authorization in middleware/gate/policy, not inline `if`s.
- Static `dispatch`.
- Response via helper or resource; no array shaping inline.
- Usually under ten lines; if not, run the Big Blocks process from `basecode`.
