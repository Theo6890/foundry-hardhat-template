# Solidity Style Guide

> **Consumers:** Contract-writing agents, refactoring agents, review agents.
> **Load when:** Writing, editing, or reviewing any `.sol` production file.

---

## STYLE-01 · Contract Naming [MUST]

| Category           | Convention                         | Examples                                    |
| ------------------ | ---------------------------------- | ------------------------------------------- |
| Main contracts     | PascalCase, domain-prefixed        | `MyContract`, `MyContractFactory`           |
| Modules            | PascalCase, functional-role suffix | `MyAdmin`, `MyLifecycle`, `MyView`          |
| Abstract contracts | No special prefix/suffix           | `abstract contract MyLifecycle`             |
| Interfaces         | `I` prefix + PascalCase            | `IMyContract`, `IMyAdmin`                   |
| Libraries          | PascalCase matching purpose        | `MyContractStorage`, `StateChecker`         |
| Errors library     | Service-prefixed PascalCase        | `MyContractErrors`, `VaultErrors`           |

## STYLE-02 · File Naming [MUST]

| Type              | Pattern                                  | Examples                              |
| ----------------- | ---------------------------------------- | ------------------------------------- |
| Contracts         | `ContractName.sol`                       | `MyContract.sol`                      |
| Tests             | `ContractName.t.sol`                     | `MyContract.t.sol`                    |
| Sub-feature tests | `ContractName.feature.t.sol`             | `MyContract.claims.t.sol`             |
| Deploy scripts    | `N_ContractName.deploy.s.sol` (numbered) | `1_MyContract.deploy.s.sol`           |
| Upgrade scripts   | `ContractName.upgrade.s.sol`             | `MyContract.upgrade.s.sol`            |
| Storage libs      | `ContractNameStorage.sol`                | `MyContractStorage.sol`               |
| Types             | `ContractNameTypes.sol`                  | `MyContractTypes.sol`                 |
| Errors            | `ContractNameErrors.sol`                 | `MyContractErrors.sol`                |
| Mocks             | `ContractName_Mock.sol`                  | `MyContract_Mock.sol`                 |
| Test setup        | `ContractName.setup.sol`                 | `MyContract.setup.sol`                |
| Storage tests     | `ContractName.storages.t.sol`            | `MyContract.storages.t.sol`           |
| Fuzzing           | No `.t.sol` suffix                       | `Fuzz.sol`, `FuzzSetup.sol`           |

## STYLE-03 · Import Ordering [SHOULD]

Separated by blank lines, in this order:

1. **External dependencies** — grouped by publisher/package, alphabetical within each group
2. **Custom interfaces** — project-local `I`-prefixed interfaces
3. **Custom contracts** — project-local contracts and abstract contracts
4. **Custom libraries / types / errors** — storage libraries, struct definitions, error libraries

```solidity
// 1. External dependencies (grouped by publisher)
import {Math} from "oz/utils/math/Math.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

// 2. Custom interfaces
import {IMyContract} from "./interfaces/IMyContract.sol";

// 3. Custom contracts (including abstract)
import {MyBase} from "./MyBase.sol";

// 4. Custom libraries, storage, types, errors
import {MyStorage} from "./libs/MyStorage.sol";
import {MyContractErrors} from "./libs/MyContractErrors.sol";
```

## STYLE-04 · Function Naming [MUST]

| Visibility       | Convention                                                     | Examples                                            |
| ---------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| External/public  | `camelCase`                                                    | `claimTokens()`, `depositFunds()`                   |
| Internal         | `_camelCase` (single underscore prefix)                        | `_checkAuth()`, `_setMerkleRoot()`                  |
| Private          | `_camelCase` (single underscore prefix preferred)              | `_validateInput()`, `_computeSlot()`                |
| View/getters     | `get` prefix                                                   | `getState()`, `getTotalDeposited()`                 |
| Initializers     | `initialize()` top-level; `initX()` for sub-init              | `initialize()`, `initFundraise()`                   |
| Storage load     | Always `load()`                                                | `MyStorage.load()`                                  |
| Script entry     | Always `run(string memory network, string memory environment)` | —                                                   |

## STYLE-05 · Variable Naming [MUST]

| Type                   | Convention                                           | Examples                                               |
| ---------------------- | ---------------------------------------------------- | ------------------------------------------------------ |
| Constants              | `UPPER_CASE`                                         | `ADMIN_ROLE`, `MAX_AMOUNT`                             |
| Storage slot constants | `STORAGE_SLOT` or `_UPPER_CASE`                      | `STORAGE_SLOT`, `_STORAGE_LOCATION`                    |
| State variables        | `camelCase` (internal: `_camelCase`, private: `__camelCase`) | `rewardToken`, `_rewardToken`, `__rewardToken` |
| Storage layout ref     | `$` (single) or `$$` (secondary)                     | `Layout storage $`, `SubLayout storage $$`             |
| Function params        | `camelCase` when no state-var name conflict; `camelCase_` when a same-name state variable exists | `amount`, `staker` or `amount_`, `staker_` |
| Local variables        | `camelCase`                                          | `totalBalance`, `expectedRatio`                        |

## STYLE-06 · Events [MUST]

- PascalCase, past-tense or descriptive.
- Declared in **interfaces**, not implementations.

## STYLE-07 · Errors [MUST]

- Errors must be scoped per service, not shared across unrelated services.
- Use a dedicated `ContractNameErrors` library for each top-level service or contract family.
- Pattern: `ContractName__PascalCaseDescription` with double-underscore separator.

```solidity
MyContractErrors.MyContract__ZeroAmount()
MyContractErrors.MyContract__InvalidState(CurrentState)
MyFactoryErrors.MyFactory__ZeroAdminAddress()
```

- Storage and types follow the same service boundary rule: prefer `MyContractStorage.sol` and `MyContractTypes.sol` over cross-service shared files unless the shared type is intentionally cross-domain.
- Cross-references are allowed when logically needed, but ownership remains service-local.
- Standalone module errors may be declared in interfaces or contracts directly.
- OZ-inherited errors follow OZ style: `AccessManagerUnauthorizedAccount(address, uint64)`.

## STYLE-08 · Error Handling [MUST]

| Pattern | When to Use |
| --- | --- |
| `require(condition, CustomError())` | When the error is immediately obvious without application context (e.g., zero-address, zero-amount, simple access checks). |
| `if (!condition) revert CustomError()` | When the revert condition involves domain logic, multiple parameters, or benefits from the explicit `if` block for readability. |
| `try/catch` | Rarely used. No established best practices yet — avoid unless handling external-call failures where silent failure is unacceptable. |

```solidity
// ✅ require — self-explanatory error
require(amount > 0, Errors.MyContract__ZeroAmount());

// ✅ if...revert — domain logic with context
if (getEffectiveState(id) != EffectiveState.Open) {
    revert Errors.MyContract__InvalidState(getEffectiveState(id));
}
```

## STYLE-09 · Storage — ERC-7201 Namespaced [MUST]

| Element          | Convention                                                                             |
| ---------------- | -------------------------------------------------------------------------------------- |
| Namespace        | `"my-protocol.ContractName"` or `"myorg.module.Name"`                                  |
| Slot computation | `keccak256(abi.encode(uint256(keccak256("namespace")) - 1)) & ~bytes32(uint256(0xff))` |
| Layout struct    | `Layout` (or `XLayout` when multiple exist, e.g. `FundraiseLayout`)                   |
| Accessor         | `function load() internal pure returns (Layout storage $)`                             |

## STYLE-10 · NatSpec Comments [SHOULD]

**Line length:** All comments must respect the same line-length limit as code (`foundry.toml` `[fmt]` settings; Foundry default is 120). When a `/// @dev` one-liner exceeds the limit, convert to a `/** @dev ... */` block.

**Multi-line NatSpec:** Always use collapsible block NatSpec for multi-line comments:

```solidity
/**
 * @title MyContract
 * @notice Short description.
 */
```

Do not use stacked multi-line `///` comments for contract-, library-, struct-, or function-level multi-line NatSpec.

**Tag grouping order:** When a NatSpec block contains multiple tag categories, keep them in this order:

1. `@title`
2. `@notice` and `@dev` together
3. `@param` entries together
4. `@return` entries together
5. `@custom:*` entries together

Leave exactly one blank line between each populated group.

```solidity
/**
 * @title MyContract
 *
 * @notice Short description.
 * @dev Extra implementation context.
 *
 * @param account Account being updated.
 * @param amount Amount in asset units.
 *
 * @return success Whether the update succeeded.
 *
 * @custom:audit Uses pull-based settlement.
 */
```

**Contract-level:** Every contract/abstract/library (not interfaces) has `@title` + `@notice`. Add `@custom:audit` when deviating from upstream.

**Structs:** Put the NatSpec block immediately before the `struct` keyword.

- Do not place routine field-by-field NatSpec comments inside the struct body.
- When a field is not obvious without broader protocol context, document it in the struct-level NatSpec block.
- Prefer an explicit field list in the block comment for non-obvious members, for example:

```solidity
/**
 * @dev Persisted market data.
 *
 * @param state Stored lifecycle checkpoint used to derive the effective state.
 * @param pendingReportedAt Timestamp of the latest pending report inside the correction window.
 * @param feeAmount Fee amount snapshotted when the market resolves.
 */
struct MarketData {
    MarketState state;
    uint40 pendingReportedAt;
    uint256 feeAmount;
}
```

- Use `@param` entries selectively for the fields that need extra context; obvious fields do not need redundant explanations.

**Interfaces:** No `@title`/`@notice` — the `interface` keyword is self-documenting.

**Events / Errors:** No NatSpec when self-documenting. `/// @dev` one-liner when extra context is needed.

**Functions — Interfaces:** No NatSpec when self-documenting. `/// @dev` for quick clarifications. `/** @dev ... */` for complex behavior, reentrancy notes, or non-obvious side effects.

**Functions — Implementations:**
- `/// @inheritdoc IInterfaceName` only when the interface function has NatSpec. Omit if there is nothing to inherit.
- `/// @dev` one-liner for internal/private functions with non-obvious logic.
- No NatSpec for trivial internals whose name is self-documenting.

## STYLE-11 · Visibility & Mutability [MUST]

| Principle       | Rule                                                                                                         |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| Visibility      | `external` > `public` (if never called internally). `private` > `internal` (if only used in declaring contract). |
| Mutability      | `pure` if no state access. `view` if read-only. Unmarked only when writing state.                            |
| `virtual` hooks | Use strictest mutability for the current implementation.                                                     |

**Modifiers:** Keep modifiers as thin wrappers — call a private helper, then `_;`.

```solidity
modifier restricted() {
    __restricted();
    _;
}

function __restricted() private view {
    if (msg.sender != authority) revert Unauthorized(msg.sender);
}
```

## STYLE-12 · Function & Declaration Ordering [SHOULD]

### Section Headers

Major visibility groups use **banner-style comments**:

```solidity
//////////////////////////////////////////////////////////////////////////////
////////////////////////////////// EXTERNAL //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
```

Sub-sections use **lightweight inline headers**:

```solidity
//////////////// VIEW (internal) ////////////////

// ---- Config ---- //
```

### Top-Level Order

1. `using` directives
2. Type declarations (structs, enums)
3. State variables (contract only)
4. Constants
5. Events
6. Errors
7. Modifiers (contract only)
8. Constructor / Initializer (contract only)

### Contract Function Order

Functions ordered by visibility → mutability → alphabetical (A → Z):

| # | Group |
|---|---|
| 1 | External — mutative (A → Z) |
| 2 | External — view (A → Z) |
| 3 | External — pure (A → Z) |
| 4 | Public — mutative (A → Z) |
| 5 | Public — view (A → Z) |
| 6 | Public — pure (A → Z) |
| 7 | Internal — mutative (A → Z) |
| 8 | Internal — view (A → Z) |
| 9 | Internal — pure (A → Z) |
| 10 | Private — mutative (A → Z) |
| 11 | Private — view (A → Z) |
| 12 | Private — pure (A → Z) |

Sub-categories (e.g., `// ---- Config ---- //`) are allowed within a group. Each sub-category is ordered A → Z internally.

### Interface Order

Four-section structure with matching banners:

1. **EVENTS** — A → Z
2. **ERRORS** — A → Z
3. **MUTATIVE** — A → Z within optional sub-categories
4. **GETTERS** — A → Z within optional sub-categories

## STYLE-13 · Foundry Formatter Configuration [SHOULD]

`forge fmt` uses Foundry default settings unless explicitly overridden in `foundry.toml` `[fmt]`. Only settings present in `[fmt]` are non-default. Common defaults (not repeated in config):

- `line_length = 120`
- `tab_width = 4`
- `bracket_spacing = false`

Check the project's `foundry.toml` for active overrides. Always run `forge fmt --check` before committing.
