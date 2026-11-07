# basecode-skills

Agent skills that make coding agents (Claude Code and anything else that reads `SKILL.md` folders) write and refactor code the way the **BaseCode** and **BaseLaravel** field guides by Jason McCreary teach: readable first, as simple as possible, and - in Laravel - the way the framework itself does it.

The skills are original write-ups of the practices with our own examples. The books are not included; buy them at [basecodefieldguide.com](https://basecodefieldguide.com).

## What's inside

```
.claude-plugin/marketplace.json      Claude Code marketplace (two plugins)
plugins/
  basecode/                          plugin: language-agnostic practices
    skills/basecode/                 the ten practices (SKILL.md + references/<practice>.md)
    skills/basecode-review/          /basecode-review - findings report on a file, diff or PR
  base-laravel/                      plugin: Laravel streamlines
    skills/base-laravel/             controllers, models, views, additional streamlines
rules/
  basecode.md                        one-page checklist to paste into CLAUDE.md / AGENTS.md / Cursor rules
  base-laravel.md                    same, for Laravel projects
scripts/install-skills.sh            symlink the skills into any skills directory
```

| Skill | Triggers on | Covers |
|-------|-------------|--------|
| `basecode` | writing/refactoring code in any language; "make it readable", "clean up", "less nested", "remove dead code", "fix naming"... | Formatting, Dead Code, Nested Code, Using Objects, Big Blocks, Naming, Removing Comments, Reasonable Returns, Rule of Three, Symmetry |
| `basecode-review` | "review this for readability", "basecode review", "what would you clean up", PR reviews | Walks the ten practices over a file/diff/PR and reports findings (Fix / Suggest / Consider) with before/after snippets; applies fixes only on request |
| `base-laravel` | any PHP work in a Laravel project; "the Laravel way", "where should this go", "fat controller" | Temporary variables, request object, form requests, authorization, dispatching, API resources; traits vs inheritance, member order, creation methods, casts/accessors, scopes, collections; Blade directives, hierarchy, stacks, dumb views, presenters, components; config, routes, container, macros, exceptions, real-time facades, events |

## Install

### Claude Code - as plugins (recommended)

From this folder on your machine:

```bash
claude plugin marketplace add ~/agent-tools/basecode-skills
claude plugin install basecode@basecode-skills
claude plugin install base-laravel@basecode-skills      # Laravel projects
```

Or inside a session: `/plugin marketplace add ~/agent-tools/basecode-skills`, then `/plugin install basecode@basecode-skills`.

Once the repo is pushed to GitHub, teammates use `claude plugin marketplace add <owner>/basecode-skills` instead of the local path. Edits to a locally added marketplace take effect on the next session or `/reload-plugins`.

Plugin skills are namespaced: the review command is `/basecode:basecode-review [file|diff|PR] [--apply]`.

### Claude Code - without plugins

```bash
scripts/install-skills.sh                 # personal: ~/.claude/skills
scripts/install-skills.sh .claude/skills  # project-level, run inside the project
```

Or try a plugin for one session: `claude --plugin-dir ~/agent-tools/basecode-skills/plugins/basecode`.

### Other agents (Codex, Cursor, Copilot, Aider...)

- If the agent supports the Agent Skills format, point `scripts/install-skills.sh` at its skills directory (for example `~/.codex/skills`).
- Otherwise paste `rules/basecode.md` (and `rules/base-laravel.md` for Laravel) into the project's `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*.mdc` or `.github/copilot-instructions.md`.

## Using the skills

- They load automatically when the task matches their description. To force one: "use the basecode skill" / `/basecode:basecode`.
- `basecode` and `base-laravel` are meant to run together on Laravel code: BaseLaravel decides *where* code goes and *which framework feature* to use, BaseCode decides *how it reads*.
- `basecode-review` reports by default; add `--apply` (or say so) to have it fix the Fix-level items in separate commits.

## Maintaining

- One practice per reference file; keep `SKILL.md` as the index and workflow (under ~150 lines).
- Change a rule only when something went wrong (a bad refactor, a missed trigger, a correction). Record the reason in the commit message and bump `metadata.version` in the skill.
- Validate before pushing: `claude plugin validate .` (marketplace) and `claude plugin validate plugins/<name>` (each plugin).

## Credits

Practices adapted from *BaseCode* (2019) and *BaseLaravel* (2020) by Jason McCreary. This repo contains independent write-ups of those practices for use by coding agents; it does not reproduce the books.
