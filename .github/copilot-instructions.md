# Solidity — Naming Conventions & Test Patterns

## 1. Naming Conventions

### 1.1 Contracts

| Category           | Convention                         | Examples                                                  |
| ------------------ | ---------------------------------- | --------------------------------------------------------- |
| Main contracts     | PascalCase, domain-prefixed        | `TokenVault`, `TokenVaultFactory`                         |
| Modules            | PascalCase, functional-role suffix | `VaultAdmin`, `VaultFundraise`, `VaultView`               |
| Abstract contracts | No special prefix/suffix           | `abstract contract VaultFundraise`, `abstract contract X` |
| Interfaces         | `I` prefix + PascalCase            | `ITokenVault`, `IVaultAdmin`, `IStaking`, `ILicense`      |
| Libraries          | PascalCase matching purpose        | `TokenVaultStorage`, `VaultStateChecker`, `Errors`        |

### 1.2 Files

| Type              | Pattern                                  | Examples                                             |
| ----------------- | ---------------------------------------- | ---------------------------------------------------- |
| Contracts         | `ContractName.sol`                       | `TokenVault.sol`, `Legal.sol`                        |
| Tests             | `ContractName.t.sol`                     | `TokenVault.t.sol`                                   |
| Sub-feature tests | `ContractName.feature.t.sol`             | `TokenVault.whitelist.claim.t.sol`                   |
| Deploy scripts    | `N_ContractName.deploy.s.sol` (numbered) | `1_TokenVaultFactory.deploy.s.sol`                   |
| Upgrade scripts   | `ContractName.upgrade.s.sol`             | `TokenVault.upgrade.s.sol`                           |
| Storage libs      | `ContractNameStorage.sol`                | `TokenVaultStorage.sol`, `VaultFundraiseStorage.sol` |
| Types             | `ContractNameTypes.sol`                  | `TokenVaultTypes.sol`                                |
| Errors            | `Errors.sol` (centralized)               | Single library for all domain errors                 |
| Mocks             | `ContractName_Mock.sol`                  | `TokenVault_Mock.sol`, `Legal_Mock.sol`              |
| Test setup        | `ContractName.setup.sol`                 | `Staking.setup.sol`                                  |
| Fuzzing           | No `.t.sol` suffix                       | `Fuzz.sol`, `FuzzSetup.sol`, `FuzzGuided.sol`        |

### 1.3 Import Ordering

Imports are separated into groups by blank lines, in this order:

1. **External dependencies** — grouped by publisher/package, alphabetical within each group
2. **Custom interfaces** — project-local `I`-prefixed interfaces
3. **Custom contracts** — project-local contracts and abstract contracts
4. **Custom libraries / types / errors** — storage libraries, struct definitions, error libraries

```solidity
// 1. External dependencies (grouped by publisher)
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IAccessManaged} from "openzeppelin-contracts/access/manager/IAccessManaged.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {Time} from "openzeppelin-contracts/utils/types/Time.sol";

// 2. Custom interfaces
import {IMyContract} from "./interfaces/IMyContract.sol";

// 3. Custom contracts (including abstract)
import {MyBase} from "./MyBase.sol";

// 4. Custom libraries, storage, types, errors
import {MyStorage} from "./lib/MyStorage.sol";
```

### 1.4 Functions

| Visibility       | Convention                                                     | Examples                                                   |
| ---------------- | -------------------------------------------------------------- | ---------------------------------------------------------- |
| External/public  | `camelCase`                                                    | `claimTokens()`, `depositFunds()`                          |
| Internal/private | `_camelCase` (underscore prefix)                               | `_checkAuth()`, `_authorizeUpgrade()`, `_setMerkleRoot()`  |
| View/getters     | `get` prefix                                                   | `getExpirationTime()`, `getState()`, `getTotalDeposited()` |
| Initializers     | `initialize()` top-level; `initX()` for sub-init               | `initialize()`, `initFundraise()`, `initWhitelist()`       |
| Storage load     | Always `load()`                                                | `MyStorage.load()`                                         |
| Script entry     | Always `run(string memory network, string memory environment)` | —                                                          |

### 1.5 Variables

| Type                   | Convention                            | Examples                                              |
| ---------------------- | ------------------------------------- | ----------------------------------------------------- |
| Constants              | `UPPER_CASE`                          | `ADMIN_ROLE`, `PUBLIC_ROLE`, `MAX_REALISTIC_AMOUNT`   |
| Storage slot constants | `STORAGE_SLOT` or `_UPPER_CASE`       | `_VAULT_STORAGE_LOCATION`, `STORAGE_SLOT`             |
| State variables        | `camelCase`                           | `rewardToken`, `totalDeposited`                       |
| Storage layout ref     | `$` (single) or `$$` (secondary)      | `VaultLayout storage $`, `FundraiseLayout storage $$` |
| Function params        | `camelCase` (optionally `_camelCase`) | `amount`, `staker` or `_amount`, `_staker`            |
| Local variables        | `camelCase`                           | `aliceBalance`, `expectedRatio`                       |

### 1.6 Events

- **PascalCase, past-tense or descriptive.**
- Declared in **interfaces**, not implementations.

```
TokenClaimed, DepositReceived, RefundClaimed, VaultCanceled
Staked, Unstaked, RoyaltiesDeposited, LicenseSigned
MintInitiated, MintExecuted, TimelockDurationUpdateInitiated
RoleGranted, RoleRevoked, AdminTransferScheduled
```

### 1.7 Errors

- **Centralized** in an `Errors` library for related contract groups.
- Pattern: `ContractName__PascalCaseDescription` with double-underscore separator.

```solidity
Errors.TokenVault__ZeroAmount()
Errors.TokenVault__VaultNotOpen(FundraiseState)
Errors.TokenVaultFactory__ZeroAdminAddress()
```

- Standalone module errors may be declared in interfaces or contracts directly.
- Access manager errors follow OZ style: `AccessManagerUnauthorizedAccount(address, uint64)`.

### 1.8 Storage (ERC-7201 Namespaced)

| Element          | Convention                                                                             |
| ---------------- | -------------------------------------------------------------------------------------- |
| Namespace        | `"my-protocol.ContractName"` or `"myorg.module.Name"`                                  |
| Slot computation | `keccak256(abi.encode(uint256(keccak256("namespace")) - 1)) & ~bytes32(uint256(0xff))` |
| Layout struct    | `VaultLayout`, `FundraiseLayout`, `Layout`                                             |
| Accessor         | `function load() internal pure returns (Layout storage $)`                             |

### 1.9 NatSpec Comments

#### Line length

All comments — NatSpec (`/// @dev`, `/** ... */`), inline (`//`), and banner headers — must respect the **same line-length limit as code** (Foundry `[fmt].line_length`, default **120 characters**). When a `/// @dev` one-liner exceeds the limit, convert it to a multi-line `/** @dev ... */` block.

```solidity
// ✅ Good — wraps at 120 chars (content fills up to column 120)
/**
 * @dev Sets the admin role for `roleId`. The admin role's members can grant/revoke `roleId`. Cannot be
 * PUBLIC_ROLE or `roleId` itself.
 */
function setRoleAdmin(uint64 roleId, uint64 admin) external;

// ❌ Bad — single-line comment exceeds 120 chars
/// @dev Sets the admin role for `roleId`. The admin role's members can grant/revoke `roleId`. Cannot be PUBLIC_ROLE or `roleId` itself.
function setRoleAdmin(uint64 roleId, uint64 admin) external;

// ❌ Bad — wraps too early (~85 chars) when 120 are available
/**
 * @dev Sets the admin role for `roleId`. The admin role's members can
 * grant/revoke `roleId`. Cannot be PUBLIC_ROLE or `roleId` itself.
 */
function setRoleAdmin(uint64 roleId, uint64 admin) external;
```

#### Contract-level

Every contract/abstract/library (not interfaces) has a `@title` + `@notice` block. Add `@custom:audit` when the contract deviates from upstream code:

```solidity
/**
 * @title MyCore
 * @notice Abstract base providing internal machinery shared across modules:
 *         authorisation checks, role/target/schedule internals, and virtual hooks.
 *
 * @custom:audit Same code as OZ's AccessManager, except:
 *          - _grantRole(...) => return false if already has role,
 *          - minSetback()    => 2 days (io 5d) safety buffer but more flexible.
 */
```

Interfaces have **no** `@title` / `@notice` block — the `interface` keyword is self-documenting.

#### Events

- **No NatSpec** for self-documenting events (name + params tell the story).
- `/// @dev` one-liner when extra context is needed (e.g., what `since` means).
- `/** @dev ... */` multi-line block for complex events.

```solidity
event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

/// @dev `newAdmin` can call {acceptAdminTransfer} after `acceptSchedule`.
event AdminTransferScheduled(address indexed newAdmin, uint48 acceptSchedule);
```

#### Errors

- **No NatSpec** when the error name + params are self-explanatory.
- `/// @dev` one-liner when the revert condition isn't obvious from the name.

```solidity
error NotScheduled(bytes32 operationId);

/// @dev The pending delay change has already taken effect; call {finalizeDelay} instead.
error DelayChangeAlreadyEffective();
```

#### Functions — Interfaces

- **No NatSpec** when the function signature is self-documenting.
- `/// @dev` one-liner for quick clarifications.
- `/** @dev ... */` multi-line block for complex behavior, reentrancy notes, or non-obvious side effects.

```solidity
function revokeRole(uint64 roleId, address account) external;

/// @dev Grants `account` membership in `roleId` with the role's current grant delay. Blocked for ADMIN_ROLE.
function grantRole(uint64 roleId, address account) external;

/**
 * @dev Executes a call on `target` with `data`. If the caller has an execution delay, the matching schedule
 * is consumed. Duplicate `(target, data)` pairs cannot be concurrently scheduled; append a salt byte to
 * `data` if needed.
 *
 * Re-entrancy safe: permissions are checked on `msg.sender` and {_consumeScheduledOp} guarantees one-time
 * consumption.
 */
function execute(address target, bytes calldata data) external payable returns (uint32);
```

#### Functions — Implementations

- **`/// @inheritdoc IInterfaceName`** only when the interface function actually has NatSpec documentation (`/// @dev`, `/** @dev ... */`, etc.). If the interface declares the function without any NatSpec, **omit** `@inheritdoc` — there is nothing to inherit.
- `/// @dev` one-liner for internal functions with non-obvious logic.
- **No NatSpec** for trivial internals whose name is self-documenting.

```solidity
// Interface has `/// @dev Sets the execution delay...` → inherit
/// @inheritdoc IMyContract
function setExecutionDelay(uint64 roleId, uint32 newDelay) external override onlyAuthorized { ... }

// Interface has NO NatSpec for revokeRole → omit @inheritdoc
function revokeRole(uint64 roleId, address account) external override onlyAuthorized {
    if (roleId == ADMIN_ROLE) revert EnforcedAdminRules();
    _revokeRole(roleId, account);
}

/// @dev Grants `account` membership in `roleId` with a `grantDelay`. Returns true if new member.
function _grantRole(uint64 roleId, address account, uint32 grantDelay) internal virtual returns (bool) { ... }

function _getRoleAdmin(uint64 roleId) internal view returns (uint64) {
    return MyStorage.load().roles[roleId].admin;
}
```

### 1.10 Visibility & Mutability

Every function must use the **strictest visibility and mutability** it needs based on actual usage:

| Principle       | Rule                                                                                                                                                                                                                        |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Visibility      | Prefer `external` over `public` when the function is never called internally (only via the ABI). Prefer `private` over `internal` when the function is only called within the declaring contract.                           |
| Mutability      | Use `pure` when the function does not access state. Use `view` when it only reads state. Leave unmarked only when the function writes state.                                                                                |
| `virtual` hooks | Even `virtual` functions use the strictest mutability for the **current** implementation. A `pure virtual` base allows only `pure` overrides; a `view virtual` base allows `view` or `pure` overrides. Choose deliberately. |

```solidity
// Returns a literal → pure (not view)
function expiration() public pure virtual returns (uint32) { return 1 weeks; }

// Only called from external wrappers in the same contract → private (not internal)
function _setRoleAdmin(uint64 roleId, uint64 admin) private { ... }

// Only satisfies an interface, never called internally → external (not public)
function canCall(...) external view virtual override returns (...) { ... }
```

### 1.11 Function & Declaration Ordering

#### Section Headers

Major visibility groups are separated by **banner-style comments** at a consistent ~78-char width:

```solidity
//////////////////////////////////////////////////////////////////////////////
////////////////////////////////// EXTERNAL //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
```

Sub-sections within a visibility group use **lightweight inline headers**:

```solidity
//////////////// VIEW (internal) ////////////////

// ---- Role config ---- //
```

#### Order within a Contract

##### Top-Level Order

1. `using` directives
2. Type declarations (structs, enums)
3. State variables (contract only)
4. Constants
5. Events
6. Errors
7. Modifiers (contract only)
8. Constructor / Initializer (contract only)

##### For Interfaces

9. Mutative functions (A → Z)
10. Getters — view (A → Z)
11. Getters — pure (A → Z)

##### For Contracts (including abstract)

12. **External — mutative** (A → Z)
13. **External — view** (A → Z)
14. **External — pure** (A → Z)
15. **Public — mutative** (A → Z)
16. **Public — view** (A → Z)
17. **Public — pure** (A → Z)
18. **Internal — mutative** (A → Z)
19. **Internal — view** (A → Z)
20. **Internal — pure** (A → Z)
21. **Private — mutative** (A → Z)
22. **Private — view** (A → Z)
23. **Private — pure** (A → Z)

Within each group, functions are sorted **alphabetically (A → Z)** by name.

**Sub-categories** (e.g., `// ---- Role config ---- //`, `// ---- Schedule ---- //`) are allowed inside a group for semantic clarity. When present, each sub-category is ordered internally A → Z, and the sub-categories themselves appear in a logical domain order.

#### Order within an Interface

Interfaces follow a four-section structure, each with a matching banner:

1. **EVENTS** — A → Z by event name
2. **ERRORS** — A → Z by error name
3. **MUTATIVE** — A → Z within optional sub-categories
4. **GETTERS** — A → Z within optional sub-categories

```solidity
interface IMyContract {
    //////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// EVENTS ///////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    event OperationCanceled(...);
    event OperationExecuted(...);

    //////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// ERRORS ///////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    error AlreadyScheduled(...);
    error BadConfirmation();

    //////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// MUTATIVE //////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    // ---- Role config ---- //
    function grantRole(...) external;
    function labelRole(...) external;

    // ---- Delay config ---- //
    function setExecutionDelay(...) external;
    function setGrantDelay(...) external;

    //////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// GETTERS //////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    // ---- Role queries ---- //
    function getAccess(...) external view returns (...);
    function getRoleAdmin(...) external view returns (...);

    // ---- Target queries ---- //
    function canCall(...) external view returns (...);
}
```

---

## 2. Test Patterns

### 2.1 Directory Structure

Tests mirror `contracts/` hierarchy:

```
test/
├── access/          → contracts/access/
├── claim/           → contracts/claim/
├── core/
│   ├── fuzzing/     → stateful fuzzing suite
│   ├── integration/ → end-to-end tests
│   ├── mocks/       → mock contracts
│   ├── staking/     → staking tests + utils/
│   ├── utils/       → BaseTest.t.sol
│   └── vault/       → vault tests + timelock/ + upgrade-safety/
├── legal/           → contracts/legal/
├── token/           → contracts/token/
└── utils/           → shared mocks (ERC20Mock, etc.)
```

### 2.2 Test Contract Inheritance

Four patterns coexist:

| Pattern                      | When to use                       | Example                                                                |
| ---------------------------- | --------------------------------- | ---------------------------------------------------------------------- |
| `BaseTest` (→ protocol base) | Tests needing full protocol stack | `TokenVaultTest is BaseTest`                                           |
| Standalone setup contract    | Self-contained tests              | `Staking_Test is Staking_Setup`                                        |
| Shared abstract base         | Multiple related test contracts   | `AccessManager_Base` → `_AdminRoleBlocked_Test`, `_NonAdminRoles_Test` |
| Plain `Test`                 | Simple contracts                  | `Token_Test is Test`                                                   |

### 2.3 Test Function Naming

| Pattern                             | Usage                   | Examples                                                                      |
| ----------------------------------- | ----------------------- | ----------------------------------------------------------------------------- |
| `test_feature_Description`          | Happy path tests        | `test_grantRole_MultipleUsers`, `test_revokeRole_RemovesMember`               |
| `test_RevertWhen_function_Scenario` | Revert on condition     | `test_RevertWhen_grantRole_AdminRole`, `test_RevertWhen_claim_DeadlinePassed` |
| `test_RevertIf_function_Scenario`   | Revert if guard fails   | `test_RevertIf_beginAdminTransfer_NotAdmin`                                   |
| `testDifferential_description`      | Differential tests      | `testDifferential_signLicense_SolidityVsTypescript`                           |
| `testFuzz_function`                 | Fuzz tests              | `testFuzz_staking(uint256, uint256, uint256, uint256)`                        |
| `testFuzzDifferential_description`  | Fuzz differential tests | `testFuzzDifferential_claim_withWhitelist`                                    |
| `testFork_description`              | Fork tests              | `testFork_redeem_User`                                                        |

> **Note:** Naming may not be fully uniform in legacy tests. The conventions above must be followed for any new or updated tests.

### 2.4 Setup Patterns

All test contracts override `setUp()` and call `super.setUp()`:

```solidity
function setUp() public override {
    super.setUp();
    // Additional test-specific setup
}
```

`BaseTest.setUp()` orchestrates via sub-functions:

1. `super.setUp()` — deploys base protocol stack
2. `_createUsersWallets()` — deterministic wallets via `vm.createWallet`
3. `_setUpTestParams()` — mock tokens, config parameters
4. `_deployContracts()` — core protocol contracts
5. `_createVaultInstance()` — instance via factory

### 2.5 Helper Functions

- Internal helpers: `_camelCase` — `_aliceDeposits()`, `_bobDeposits()`, `_deployContracts()`
- Per-user repeatable actions extracted into named helpers: `_aliceDeposits(uint128 amount)`
- Defined in both base test contracts and individual test contracts

### 2.6 Section Organization

> **Production code** section headers and function ordering are defined in [§1.11 Function & Declaration Ordering](#111-function--declaration-ordering).

Tests within a contract are grouped by visual separator comments:

```solidity
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// REVERT ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// ... revert tests ...

/////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// HAPPY /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
// ... happy path tests ...
```

Or simpler delimiters: `// ===== REVERT TESTS =====` / `// ===== HAPPY PATH TESTS =====`

No `givenX`/`whenY` modifier pattern — scenario branching is handled via separate test contracts per feature instead.

### 2.7 Mock Patterns

**Thin mocks (expose internals):**

```solidity
contract TokenVault_Mock is TokenVault {
    function exposed_computeLeaf(...) external view returns (bytes32) { ... }
    function setToken(address _t) external { ... } // direct storage setter
}
```

- Named `ContractName_Mock`
- `exposed_functionName` to surface internal functions
- Sometimes include direct state setters for test convenience

### 2.8 Event Testing

Use `vm.expectEmit()` then emit the expected event, then call the function:

```solidity
vm.expectEmit();
emit IVaultAdmin.TokenWithdrawn(fundReceiver, address(mockUsdc), expectedAmount);
vaultInstance.withdraw();
```

Named parameter syntax is also used:

```solidity
vm.expectEmit();
emit IVaultAdmin.LostTokensRecovered({
    token: address(mockLostToken), to: recoverToAddress, amount: extraTokenAmount
});
```

Events are referenced via their **interface**: `IVaultUser.DepositReceived(...)`.

### 2.9 Error/Revert Testing

**Selector only (no args):**

```solidity
vm.expectRevert(Errors.TokenVault__NothingToRecover.selector);
```

**Encoded with args:**

```solidity
vm.expectRevert(abi.encodeWithSelector(
    Errors.TokenVault__VaultNotCanceled.selector, FundraiseState.Open
));
```

**Bare revert:**

```solidity
vm.expectRevert(); // Just asserts it reverts
```

### 2.10 Fuzzing

**Simple fuzz (Foundry built-in):**

```solidity
function testFuzz_staking(uint256 a, uint256 b, uint256 c, uint256 d) public {
    a = bound(a, 1, MAX_REALISTIC_AMOUNT);
    // ...
}
```

> **Prefer `bound()` over `assume()`** to constrain fuzz inputs. `bound()` clamps the value into the desired range, while `assume()` discards the entire run, wasting fuzzer iterations. Use `assume()` only when the valid set cannot be expressed as a contiguous range.

**Stateful fuzzing suite (Guardian Audits pattern):**

- Inheritance chain: `FuzzSetup → FunctionCalls → ... → FuzzGuided → Fuzz`
- Functions named `fuzz_functionName(...)` with `invariant_NAME()` checks
- Named invariants: `INV_01`, `INV_02`, etc.
- Actor-based: maps `address → uint256` private keys for signing
- Runs via: `forge test --mc Fuzz --show-progress`

### 2.11 Fork Testing

```solidity
function setUp() public {
    loadSetup("testnet_1315");
    loadDeployed("testnet_1315", "dev");
    vm.createSelectFork("https://rpc.example.io");
    address staking_ = vm.parseJsonAddress(jsonDeployed, ...);
}
```

- Inherits `LoadSetup, LoadDeployed` to read real deployment addresses
- Uses `vm.createSelectFork()` with a target chain RPC
- Test function prefix: `testFork_`

### 2.12 Test Contract Naming

```
ContractName_featureOrScope_Test
```

Examples:

- `TokenVault_recoverLostTokens_Test`
- `TokenVault_whitelist_claim`
- `Staking_Test`, `Staking_FuzzTest`, `Staking_Fork_Test`
- `Legal_Revert_Test`
- `AccessManager_AdminRoleBlocked_Test`

### 2.13 Assertion Reason Strings

When a test function contains **more than one or two assertions**, add a concise reason string so the developer immediately knows which check failed:

```solidity
// ✅ Good — reason strings identify which assertion failed
(address pendingAdmin, uint48 pendingSchedule) = access.pendingAdmin();
assertEq(pendingAdmin, user1, "pending admin");
assertEq(pendingSchedule, expectedSchedule, "pending schedule");

// ❌ Bad — when either fails, you must read the stack trace to identify which
assertEq(pendingAdmin, user1);
assertEq(pendingSchedule, expectedSchedule);
```

Keep reason strings **short (2–4 words)**. They should name **what** is being checked, not re-state the assertion logic. Single-assertion test functions do not need a reason string.

### 2.14 ERC-7201 Storage Slot Verification

Every ERC-7201 namespaced storage library **must** have a corresponding test that re-derives the slot from the namespace string and asserts it matches the hardcoded constant. A wrong slot silently reads/writes to the wrong storage, causing catastrophic bugs that are invisible at compile time.

```solidity
/// @dev Validates that ERC-7201 namespaced storage slots are correctly computed.
contract MyContract_Storages_Test is Test {
    function test_myStorage_CorrectlyComputed() public pure {
        bytes32 expected = _computeStorageLocation("my-protocol.MyContract");
        bytes32 actual = MyStorage.STORAGE_SLOT;
        assertEq(actual, expected);
    }

    function _computeStorageLocation(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encode(uint256(keccak256(bytes(name))) - 1)) & ~bytes32(uint256(0xff));
    }
}
```

- **One test per storage library** — file named `ContractName.storages.t.sol`.
- The namespace string in the test must match the `@custom:storage-location erc7201:<namespace>` NatSpec annotation.
- Tests are `pure` (no state needed) and run near-instantly.
