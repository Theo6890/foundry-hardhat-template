# Git Workflow

> **Consumers:** All agents that commit or push. Master agents for PR planning.
> **Load when:** Creating commits, branches, or pull requests.

---

## GIT-01 · Commit Message Format [MUST]

All commits follow [Conventional Commits](https://www.conventionalcommits.org/) enforced by **commitlint**.

```
type(scope): concise imperative description
```

| Element     | Rule                                                                                            |
| ----------- | ----------------------------------------------------------------------------------------------- |
| `type`      | **Required.** One of the types below, lowercase.                                                |
| `scope`     | Optional. Module or area affected, e.g. `market`, `staking`, `ci`.                              |
| Description | Imperative mood ("add X", not "added X"), no trailing period, max ~72 characters.               |
| Body        | Optional. Separated by blank line. Explains **why**, not what.                                  |
| Breaking    | Append `!` after type/scope: `refactor(market)!: remove deprecated hook`.                       |

**Allowed types:**

| Type       | Purpose                                           |
| ---------- | ------------------------------------------------- |
| `feat`     | New feature or capability                         |
| `fix`      | Bug fix                                           |
| `refactor` | Code restructuring, no behavior change            |
| `test`     | Adding or updating tests                          |
| `style`    | Formatting, linting, whitespace — no logic change |
| `chore`    | Maintenance tasks (deps, configs, tooling)        |
| `ci`       | CI/CD pipeline changes                            |
| `docs`     | Documentation only                                |
| `perf`     | Performance improvement                           |
| `build`    | Build system or external dependency changes       |

## GIT-02 · Atomic Commits [MUST]

Each commit contains **exactly one logical change** matching its message.

| Rule                               | Violation Example                                                   |
| ---------------------------------- | ------------------------------------------------------------------- |
| No unrelated changes               | A `feat` commit that also fixes formatting in another file          |
| No bundling across types           | Tests + refactor + feature in a single commit                       |
| Commit must compile and tests pass | A `refactor` commit that breaks compilation, fixed in the next one  |
| Scope matches message              | Message says "add whitelist" but commit also modifies staking logic |

If a feature requires a preparatory refactor, that refactor is a **separate commit** (`refactor: ...`) before the feature (`feat: ...`).

## GIT-03 · Branching & Pull Requests [MUST]

| Rule                                 | Details                                                                      |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| One branch per work item             | Each feature, fix, or refactor gets its own branch                           |
| Branch naming                        | `type/short-kebab-description` — e.g. `feat/whitelist`, `fix/double-claim`  |
| Branch from `main`                   | Always branch off the latest `main`                                          |
| Multiple focused commits per branch  | A branch contains several atomic commits forming a reviewable unit           |
| PR for review                        | Every branch merged via PR — no direct pushes to `main`                      |
| Each commit independently reviewable | Reviewers can step through commits one by one                                |

## GIT-04 · Formatting & Pre-commit Hooks [MUST]

Husky pre-commit hooks enforce formatting on every commit.

**Pre-commit checks (`.husky/pre-commit`):**

```sh
forge fmt --check
npx prettier --check .
```

**Commit message lint (`.husky/commit-msg`):**

```sh
npx --no -- commitlint --edit "$1"
```

| Tool        | Scope                    | Config                  | Fix command              |
| ----------- | ------------------------ | ----------------------- | ------------------------ |
| `forge fmt` | Solidity (`*.sol`)       | `foundry.toml` `[fmt]` | `forge fmt`              |
| `prettier`  | Non-Solidity (JS, JSON…) | `.prettierrc`           | `npx prettier --write .` |
| `commitlint`| Commit messages          | `commitlint.config.js`  | Amend the message        |

**Rules:**

- Never commit with `--no-verify`.
- If `forge fmt --check` or `prettier --check` fails, fix and **include formatting in the same commit** — do not create a separate `style:` commit for code you are already touching.
- `style:` commits are reserved for standalone formatting sweeps on unrelated files.
- Run both checks locally before opening a PR.
