# Formatting

## Why it matters

Reading is not subjective. Readers rely on visual cues (indentation, paired blocks, line breaks) to recognize structures like assignments, conditionals and method bodies before they read a single token. Consistent formatting makes the visual shape of the code match what the code does ("visual honesty"). Inconsistent formatting forces the reader to parse syntax instead of recognizing shapes.

The details (tabs vs spaces, brace placement) do not matter. Consistency does. Formatting is a team concern, even when the team is you and future-you.

## The rule: choose it, automate it, forget it

1. **Choose** the language's standard, widely used style. Do not invent one, do not customize it beyond a line or two.
   - PHP: PSR-12 (via Laravel Pint, PHP-CS-Fixer or PHP_CodeSniffer)
   - JavaScript / TypeScript: Prettier (plus ESLint for lint rules, not style)
   - Python: Black / Ruff format
   - Go: gofmt
   - CSS / HTML / Blade / Markdown: Prettier where supported
2. **Automate** it. The format must be applicable by a tool, on save and in CI. If the chosen style cannot be enforced automatically, choose another.
3. **Forget** it. Treat formatting violations like syntax errors: unformatted code does not merge. Nobody discusses formatting in review because the tool already settled it.

## How to apply as an agent

- Before editing, find the project's formatter config: `pint.json`, `.php-cs-fixer.php`, `phpcs.xml`, `.prettierrc*`, `eslint.config.*`, `.editorconfig`, `pyproject.toml` (`[tool.black]`/`[tool.ruff]`), `Makefile` or `composer.json`/`package.json` scripts. Match it exactly.
- If the project exposes a format command (`composer lint`, `vendor/bin/pint`, `npm run format`, `npx prettier --write`), run it on the files you touched before finishing.
- If no formatter is configured, follow the language standard above and mention in your summary that no formatter is set up; offer to add one as a separate change.
- When a whole codebase needs reformatting, do it in **one dedicated commit** with no logic changes, so blame and review stay useful. Add that commit's hash to `.git-blame-ignore-revs` so `git blame` skips it.
- Never mix a reformat with a behavior change in the same commit.

## Before / after

Unformatted (the shape hides a simple structure):

```php
function canView($visibility,$ownerId){
  if (currentUser()->isAdmin()){
    return true;}
  else {
  if ($visibility=='public') return true;
    if($visibility=='private'&&currentUser()->id===$ownerId)
       return true;
  return false;}
}
```

After running the formatter (nothing else changed, yet the structure is now visible, and other practices become obvious to apply):

```php
function canView($visibility, $ownerId)
{
    if (currentUser()->isAdmin()) {
        return true;
    } else {
        if ($visibility == 'public') {
            return true;
        }
        if ($visibility == 'private' && currentUser()->id === $ownerId) {
            return true;
        }
        return false;
    }
}
```

The `else` and the nesting are the next things to fix - see `nested-code.md`.

## Pitfalls

- Arguing about brace style or tabs in a review. The answer is "whatever the tool says".
- Manually aligning `=` signs or array arrows. Alignment drifts on the next edit and creates noisy diffs.
- Disabling the formatter for a block "because it looks better". Readers learn one shape per codebase; exceptions break that.
