# Rule of Three

## Why it matters

Don't Repeat Yourself (DRY) feels like tidiness, so it gets applied the moment a second copy appears. But removing duplication early is a bet that you already understand the pattern. Usually you don't. One or two data points are not enough to see a pattern (given the sequence `2`, almost anything comes next; given `2, 4, 16` the pattern is clear). Code is the same: a shared abstraction built from one or two uses is often the wrong one, and a wrong abstraction is far more expensive to live with than duplicated code.

Repetition is also how code grows. Fighting all duplication fights growth.

## The rule

- First occurrence: just write it.
- Second occurrence: notice the duplication, wince, and duplicate anyway.
- Third occurrence: now you have enough information - refactor.

Said differently: **Defer Until Necessary.** You will be smarter later; postpone decisions about abstraction until the pain is real and the shape of the duplication is clear. The number three is a heuristic, not a law.

## Why waiting works

- Time reveals which parts are truly shared and which only looked alike. The abstraction you write at the third copy fits reality; the one you would have written at the first copy fits your guess.
- Duplication is explicit; a premature abstraction hides differences behind parameters and flags, which later grow into the real complexity.
- When the duplication is finally removed, it is usually a small, obvious change.
- Once an abstraction is in place and a *new* kind of problem appears, the counter resets: wait for that new pain to repeat before abstracting again.

## How to apply as an agent

1. When implementing a feature that resembles existing code, copy it rather than generalizing the existing code on the spot. Note the duplication in your summary ("second copy of X; refactor when a third appears").
2. When you encounter the third copy, extract: a method, a class, a value object, or a framework feature (trait, macro, scope). Base the abstraction on what the three copies actually share, not on what they might share later.
3. Do not add parameters, flags, or callbacks to an abstraction to make it serve a case it was not built for. If a shared method needs a boolean to behave two ways, you likely have two methods.
4. If an existing abstraction already fights its callers (many flags, special cases), prefer inlining it back into the callers and letting the duplication reappear ("un-DRY"), then re-extract later along the right seams.
5. Keep extraction commits separate from feature commits.

## Example progression

```js
// 1st time: an email is sent after checkout
await mailer.send(user.email, 'Order confirmed', renderOrderConfirmed(order));

// 2nd time (refund flow): similar, but not identical - keep the duplication
await mailer.send(user.email, 'Refund issued', renderRefundIssued(refund));

// 3rd time (shipping flow): the shape is now clear - extract
await notifyCustomer(user, new ShippingUpdate(shipment));
```

Only at the third use was it obvious that the abstraction was "notify a customer with a typed message", not "a helper that builds subject strings".

## Pitfalls

- Extracting a "shared" helper on the second occurrence and then adding `if ($mode === 'refund')` branches to it on the third.
- Treating similar-looking code as duplication when it serves different domain concepts; it may diverge later.
- Letting a third, fourth and fifth copy accumulate because the refactor "can wait". Three is when the pain is supposed to trigger action.
