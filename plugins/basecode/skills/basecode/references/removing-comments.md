# Removing Comments

## Why it matters

Three reasons inline comments are usually a liability:

1. **Clear code explains itself.** Code is our primary medium; if the code cannot say it, a comment is a weaker substitute. A comment describing *what* the next line does is a sign the line needs a better name or structure.
2. **Comments are never checked.** The compiler and tests verify code, not comments. Comments rot the moment the code changes and then actively mislead.
3. **Comments are noise.** They are extra reading with no execution. They lower the signal.

The target is inline code comments. API documentation (docblocks on public methods of a shared library), license headers, and references to tickets are documentation, a different thing. The goal is not zero comments; it is to **challenge every comment's right to exist** and to write code instead when the code can carry the meaning.

## The challenge, comment by comment

Ask: "What would I change in the code so this comment is unnecessary?"

| Comment says | Fix in code |
|--------------|-------------|
| What the next line does (`// return the result`) | Delete the comment. It is condescending to the reader. |
| What a variable holds (`// date for yesterday`) | Rename the variable (`$yesterday`). |
| What a block of lines does (`// filter tweets by day`) | Extract the block into a method with that name (see `big-blocks.md`). |
| Which part of the function a section is (`// --- validation ---`) | Extract sections into methods, or split the function. |
| Why a value is what it is (`// 86400 = seconds per day`) | Named constant: `SECONDS_PER_DAY`. |
| That something is temporary / hacky (`// TODO fix later`) | Fix it, or create a tracked ticket and reference it; do not leave the note alone. |
| **Why** the code is written this unusual way (a vendor quirk, a performance measurement, a legal rule) | This one survives. Make it accurate and well written. |

Also use proximity: declare variables right before use. A comment often exists because a declaration sits far from the lines that need it.

## Worked example

```php
// before
// get orders from the last week for the customer
public function recent($customerId)
{
    // date for one week ago
    $date = now()->subWeek();

    // array of orders to return
    $retval = [];

    // use the search endpoint because it supports
    // a date filter, the list endpoint does not
    $orders = $this->client->get('orders/search', ['customer' => $customerId]);

    // loop over orders and keep the ones after the date
    foreach ($orders as $order) {
        if ($order->placedAt >= $date) {
            $retval[] = $order;
        }
    }

    // return the orders
    return $retval;
}
```

Apply the table: delete the 1:1 comments, rename from the information in the variable comments, extract the loop, move declarations next to use, keep and polish the one *why* comment.

```php
// after
public function ordersSinceLastWeek($customerId)
{
    // The search endpoint accepts a date filter and returns a much
    // smaller payload than the list endpoint.
    $orders = $this->client->get('orders/search', ['customer' => $customerId]);

    $oneWeekAgo = now()->subWeek();

    return $this->placedAfter($orders, $oneWeekAgo);
}
```

Do not inline `$oneWeekAgo` just to reach a one-liner: a well-named temporary variable adds context; density does not.

## How to apply as an agent

1. In code you write, do not add a comment that restates the code. If you are about to, rename or extract instead.
2. In code you touch, remove 1:1 comments, convert "what" comments into names or extracted methods, and keep "why" comments (rewrite them for clarity and correct grammar).
3. Keep docblocks that generate documentation or that provide types the language cannot express (generics in PHP, `@param array<int, User>`), and remove docblocks that merely repeat a typed signature.
4. Convert `TODO`/`FIXME` into tracked work and mention it in your summary; do not accumulate them.

## Pitfalls

- Deleting a "why" comment because it is a comment. Those are the valuable ones.
- Replacing a comment with a method whose name is as vague as the comment was (`processData()`).
- Writing a commit message or PR description that explains the code instead of improving the code.
