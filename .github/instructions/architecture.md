# Architecture & Design Principles

> **Consumers:** Master agents, planning agents, architecture-review agents.
> **Load when:** Planning new systems, designing modules, reviewing architectural decisions, or making any design choice that affects state, storage, accounting, or authorization.

These are **durable design principles** that govern all implementation decisions across iterations. They are not project-specific — they apply to any Solidity system built under this org's standards.

---

## ARCH-01 · Build Order for New Systems [MUST]

When implementing a new protocol or module family, follow this dependency order:

1. Shared domain types + centralized errors + storage layout + interfaces
2. Minimal reusable primitives (e.g., token/adapter/mock implementations)
3. Core modules grouped by responsibility
4. Main composition/orchestrator contract
5. Test setup + mocks
6. Feature tests (lifecycle, settlement, claims, access)
7. Fuzz/invariant tests
8. Deployment script

This sequencing minimizes refactors and keeps each step independently reviewable.

## ARCH-02 · Modular Composition [MUST]

- Decompose behavior into focused modules (admin, lifecycle, execution, claims, view) and compose them in a thin orchestrator.
- Keep shared cross-module logic in one base module/library to avoid drift and duplicate validation.
- Interfaces are the canonical location for events and externally visible errors.
- Storage libraries (namespaced via ERC-7201) are the single source of truth for shared state access.

## ARCH-03 · State Machine Design [MUST]

- Separate **stored state** (persisted lifecycle checkpoints) from **effective state** (runtime-derived from stored state + `block.timestamp`).
- Compute time-dependent transitions at read/validation time — do not require maintenance transactions to advance state.
- Gate each mutative function by the strict state required for that action.
- For optional delay/grace mechanisms, support both paths explicitly:
  - Zero-delay path: single-step transition to final state.
  - Delayed path: pending state + explicit finalization step.

## ARCH-04 · Accounting & Parameter Safety [MUST]

- Use a single canonical internal unit for accounting; convert only at external transfer boundaries.
- Snapshot mutable config (fees, rates, signer-dependent params) at irreversible state transitions — later admin updates must not retroactively affect settled outcomes.
- Persist original aggregate accounting values when derivative balances may decrease over time (e.g., burn-on-claim). Do not derive final accounting from mutable balances.
- Define deterministic fallback behavior for terminal edge cases (e.g., no valid winner → cancel/refund path).

## ARCH-05 · Off-chain Authorization & Finality [MUST]

- For signed reports/actions, require EIP-712 typed structured data with domain separation, nonce, and expiry deadline.
- Reject stale signatures and enforce monotonic/non-reusable nonces per context.
- If corrections are allowed, confine them to an explicit pending window and reset pending timers/versions on update.

## ARCH-06 · Test Strategy for Lifecycle Systems [MUST]

- Use setup contracts with deterministic actors and helper functions for repeatable scenario construction.
- Validate full lifecycle transitions (including timestamp-driven) without relying on implicit/manual steps.
- Cover both revert and happy-path cases for every mutative function.
- Add invariant/fuzz tests for conservation properties (e.g., payouts + fees never exceed pool; refunds match pool).
- Include storage-slot correctness tests for all namespaced storage libraries.

## ARCH-07 · Deployment & Environment [SHOULD]

<!-- TODO: Document deployment conventions — environment naming, secrets management (`secrets.json` pattern), deployment verification, and post-deploy validation steps. -->

Deploy scripts use `run(string memory network, string memory environment)` as the entry point. See `STYLE-04` in `solidity-style.md` for the function signature convention. Further deployment conventions are pending documentation.
