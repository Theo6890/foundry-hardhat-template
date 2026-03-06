# Copilot Instructions — Org-Wide Conventions

> This is the **routing index** for all instruction modules. It is automatically loaded as Tier 1 context.
> Detailed rules live in the module files under `.github/instructions/`.

---

## Instruction Modules

| File | Scope | Rule IDs | Primary Consumers |
|------|-------|----------|-------------------|
| [instructions/solidity-style.md](instructions/solidity-style.md) | Naming, formatting, NatSpec, NatSpec tag grouping, struct field documentation, ordering, visibility, error handling, service boundaries | `STYLE-01` – `STYLE-13` | Contract agents, refactoring agents |
| [instructions/testing.md](instructions/testing.md) | Test patterns, setup, mocks, fuzz, fork, assertions | `TEST-01` – `TEST-14` | Test agents, fuzz agents |
| [instructions/git-workflow.md](instructions/git-workflow.md) | Commits, branches, PRs, formatting hooks | `GIT-01` – `GIT-04` | All agents that commit/push |
| [instructions/architecture.md](instructions/architecture.md) | Design principles: composition, state machines, accounting, auth | `ARCH-01` – `ARCH-07` | Master agents, architecture agents |
| [instructions/agent-delivery.md](instructions/agent-delivery.md) | Agent planning, delegation, compliance, context loading | `AGENT-01` – `AGENT-07` | Master agents, orchestration agents |

## Documentation Tiers

| Tier | File | Purpose |
|------|------|---------|
| 1 | This file + `instructions/*.md` | Org-wide conventions (style, testing, git, architecture, delivery) |
| 2 | `docs/v1/PLAN.md` *(if exists)* | Project-wide architecture, design decisions, glossary |
| 3 | `docs/v1/ITERATION_N_PLAN.md` *(if exists)* | Scope, tasks, acceptance criteria for current iteration |

Load context in tier order. Never duplicate higher-tier content into lower tiers — reference by filename.

Tier 2 and Tier 3 files may not exist in newly initialised repos or repos that were not bootstrapped by AI agents. When absent, rely solely on Tier 1 conventions and the codebase itself for context. Do not create these files unless explicitly requested.

## Context Loading Quick Reference

| Task | Load These Modules |
|------|-------------------|
| Planning / orchestration | `architecture.md` + `agent-delivery.md` + `git-workflow.md` |
| Writing Solidity contracts | `solidity-style.md` + `architecture.md` |
| Writing tests | `testing.md` + `solidity-style.md` |
| Committing / branching | `git-workflow.md` |
| Full review / audit | All modules |

## Rule Severity Tags

All rules use severity tags. See `AGENT-07` in `agent-delivery.md` for definitions.

| Tag | Meaning |
|-----|---------|
| `[MUST]` | Correctness/security. Never skip. |
| `[SHOULD]` | Strong convention. Deviate only with justification. |
| `[MAY]` | Preference. Either choice acceptable. |

## Universal Rules

These apply to all agents regardless of task:

- All Solidity files must pass `forge fmt --check` before commit.
- All non-Solidity files must pass `npx prettier --check .` before commit.
- Every commit must compile (`forge build`) and pass tests (`forge test`).
