# Agent Delivery Workflow

> **Consumers:** Master agents, orchestration agents.
> **Load when:** Planning iterations, decomposing features into PRs, delegating tasks to subagents, or validating delivery compliance.

---

## AGENT-01 · Documentation Tier System [MUST]

This org uses a three-tier documentation hierarchy. Agents must load context in this order:

| Tier | File | Purpose | Loaded By |
|------|------|---------|-----------|
| 1 | `.github/copilot-instructions.md` | Routing index to all instruction modules | All agents (auto-loaded) |
| 1 | `.github/instructions/*.md` | Org-wide conventions (style, testing, git, architecture) | Per-task (see AGENT-03) |
| 2 | `docs/v1/PLAN.md` *(if exists)* | Project-wide architecture, design decisions, glossary | Master agents, architecture subagents |
| 3 | `docs/v1/ITERATION_N_PLAN.md` *(if exists)* | Scope, tasks, acceptance criteria for current iteration | Master agents, executing subagents |

**Rules:**
- Never duplicate content from a higher tier into a lower tier — reference by filename.
- Completed iteration files are historical context; only the active iteration file is the operative execution plan.
- If a convention conflicts with a project-specific decision in PLAN.md, the project-specific decision takes precedence within that project.
- **Tier 2/3 files may not exist** in newly initialised repos or repos not bootstrapped by AI agents. When absent, rely solely on Tier 1 conventions and the codebase itself for context. Do not create these files unless explicitly requested.

## AGENT-02 · PR Decomposition [MUST]

Plan implementation as dependency-ordered, atomic pull requests where each PR compiles and tests independently.

- Follow the build order in `ARCH-01` (architecture.md) for sequencing.
- Each PR should contain one logical unit of work (e.g., "add types + storage + interfaces", "add core module X", "add tests for module X").
- Shared dependencies (types, storage, interfaces, test setup) must be merged before PRs that consume them.
- Independent PRs (e.g., separate test files for separate modules) may be parallelized only after shared dependencies are merged.

## AGENT-03 · Context Loading per Task Type [SHOULD]

Load **only** the instruction files relevant to the task. This minimizes context-window waste and improves agent focus.

| Task Type | Instruction Files to Load |
|---|---|
| **Planning / orchestration** | `architecture.md` + `agent-delivery.md` + `git-workflow.md` |
| **Writing Solidity contracts** | `solidity-style.md` + `architecture.md` |
| **Writing tests** | `testing.md` + `solidity-style.md` |
| **Committing / branching** | `git-workflow.md` |
| **Full review / audit** | All instruction files |

When delegating to a subagent, include only the relevant files in the subagent's prompt context.

## AGENT-04 · Commit Discipline [MUST]

- One logical change per commit (see `GIT-02` in git-workflow.md).
- Align commit scope with touched modules — a commit that modifies `MarketBetting.sol` should not also modify `MarketAdmin.sol` unless the change is inherently cross-cutting.
- Every commit must compile (`forge build`) and pass tests (`forge test`).
- Run `forge fmt` and `npx prettier --check .` before each commit.

## AGENT-05 · Convention Compliance Validation [SHOULD]

Before finalizing any PR, verify:

1. **Naming:** Contracts, functions, variables, errors, events follow `solidity-style.md` rules.
2. **Ordering:** Function/declaration ordering per `STYLE-12`.
3. **NatSpec:** Contract-level + function-level documentation per `STYLE-10`.
4. **Tests:** Naming, setup, section organization per `testing.md`.
5. **Formatting:** `forge fmt --check` passes. `npx prettier --check .` passes.
6. **Commits:** Each commit message follows `GIT-01`. Each commit is atomic per `GIT-02`.
7. **Storage slots:** Any new ERC-7201 storage library has a corresponding `TEST-14` verification test.

## AGENT-06 · Handling Ambiguity [SHOULD]

When conventions are unclear or conflicting:

1. Check whether the project's `PLAN.md` documents a project-specific decision that resolves the ambiguity (skip if the file does not exist).
2. If not (or no PLAN.md exists), prefer the stricter interpretation (e.g., `private` over `internal`, `external` over `public`).
3. If genuine ambiguity remains, ask one narrow question and proceed with minimal assumptions.
4. Never invent conventions — if a pattern is not documented, flag the gap rather than guessing.

## AGENT-07 · Rule Severity Guide [MUST]

All rules across instruction files are tagged with severity:

| Tag | Meaning | Agent Behavior |
|-----|---------|----------------|
| `[MUST]` | Correctness, security, or hard constraint. Violation causes bugs or blocks review. | Always comply. Never skip or defer. |
| `[SHOULD]` | Strong convention. Deviation requires explicit justification. | Comply by default. Deviate only with stated reason. |
| `[MAY]` | Preference or stylistic option. Either choice is acceptable. | Follow when practical. No justification needed to deviate. |
