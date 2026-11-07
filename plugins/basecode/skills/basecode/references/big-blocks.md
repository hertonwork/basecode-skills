# Big Blocks

## Why it matters

Length correlates with readability but is not the same thing: a dense one-liner is short and unreadable; a codebase of one-line methods is tidy and exhausting to follow. Use the urge to shorten as fuel, but aim at reading effort, not line count.

Remember the conservation law: unless you find a native replacement, code is never removed, only moved. Extracting five lines from one method adds five lines to another. That is fine - the win is that each reader now sees only the lines that belong to the level they are reading at.

## The three-step process

Most people jump to step 3. Steps 1 and 2 are what make step 3 easy.

### 1. Recognize the level

Decide what "reading level" this code is at, from its location and role: a controller action is a high-level entry point; a model method is lower; a helper deep in a library is lower still. A reader at a given level expects to see code at that level - not lower-level details (hashing a password, parsing a header, mapping role IDs to paths) and not higher-level orchestration.

For callbacks and closures, use the level of whatever invokes them.

### 2. Regroup into sub-blocks

Insert blank lines between groups of related statements and put a **temporary** one-line comment above each group saying what it does ("validate input", "find the course", "pick the dashboard", "redirect"). This is an outline. Two things usually jump out:

- the *primary action* of the block (the reason it exists),
- duplicated actions across sub-blocks.

Focusing on *what each group does* is far less subjective than arguing about "responsibilities".

### 3. Refactor each sub-block

For every sub-block, ask two questions in order:

1. **Is there a native way to do this?** Search the codebase, framework and language for an existing helper using the words from your temporary comment (for example "detect ajax request", "find model from route parameter", "validate request"). If one exists, use it and delete the sub-block.
2. **Does this action belong at the current level?**
   - Yes, and it is short: leave it inline.
   - Yes, but it is long or repeated: extract a private method named after the comment.
   - No: move it to the level where it belongs (a model, a value object, a service, a form request, a presenter) and call it from here.

Remove the temporary comments as you go; the names you created replace them.

When stuck, write the ideal flow as pseudo-code using only the primary actions ("enroll the user", "redirect to the course") and then fill in the gaps.

## Worked example (PHP, framework-agnostic)

```php
// before
public function completeOrder(Request $request, Order $order)
{
    $isAjax = $request->headers->get('X-Requested-With') === 'XMLHttpRequest';

    if ($order->total < 5000) {
        $fee = 0;
    } else {
        $fee = (int) round($order->total * 0.029 + 30);
    }

    $order->fee = $fee;
    $order->status = 'completed';
    $order->completed_at = now();
    $order->save();

    if ($isAjax) {
        return response()->json(['url' => '/orders/' . $order->id]);
    }
    return redirect('/orders/' . $order->id);
}
```

Step 1: this is a controller action - high level. Step 2 (temporary comments): "detect ajax", "calculate processing fee", "mark the order completed", "respond". Step 3:

- "detect ajax": the framework already has `$request->ajax()` - native, delete the sub-block.
- "calculate processing fee": too low-level for a controller, and the rule belongs with the order. Move to `Order::processingFee()`.
- "mark the order completed": belongs with the order. Move to `Order::complete()`.
- "respond": correct level, but likely repeated across actions. Extract `redirectToOrder()`.

```php
// after
public function completeOrder(Request $request, Order $order)
{
    $order->complete();

    return $this->redirectToOrder($request, $order);
}

private function redirectToOrder(Request $request, Order $order)
{
    if ($request->ajax()) {
        return response()->json(['url' => $order->path()]);
    }

    return redirect($order->path());
}
```

The controller now reads at one level. The fee rule has a home where it can be tested on its own.

## How to apply as an agent

1. Never start by extracting. Do steps 1 and 2 first, even mentally; for long blocks, actually add the temporary comments in the file, then remove them.
2. Search before writing: the framework or language probably already has the helper.
3. Move code *down* to the object that owns the data (model, value object) and *out* to a dedicated class only when a concept exists (presenter, form request, job).
4. Name extracted methods after the temporary comment, then improve the name (see `naming.md`).
5. Keep each extraction in its own small commit; run tests between.

## Pitfalls

- Extracting to a private method just to hit a line count; if the sub-block is at the right level and used once, it may stay inline.
- Moving low-level details into a controller or entry point because "it is only three lines".
- Inappropriate intimacy: a high-level class reaching through two or three relationships to read a low-level detail. That is a signal the logic belongs lower.
