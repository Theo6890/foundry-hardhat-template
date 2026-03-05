# Test Patterns

> **Consumers:** Test-writing agents, fuzz agents, review agents.
> **Load when:** Writing, editing, or reviewing any test file. Also load `solidity-style.md` for naming rules.

---

## TEST-01 · Directory Structure [SHOULD]

Tests mirror the `src/` hierarchy. For single-domain projects a flat `test/` layout is acceptable. For multi-domain projects, use subdirectories mirroring `src/`:

```
test/
├── ContractName.setup.sol         # Shared test setup
├── ContractName.t.sol             # Core lifecycle tests
├── ContractName.feature.t.sol     # Per-feature test files
├── ContractName.storages.t.sol    # ERC-7201 slot verification
├── ContractName.fuzz.t.sol        # Fuzz tests
└── mocks/
    └── ERC20Mock.sol              # Shared utility mocks
```

## TEST-02 · Test Contract Inheritance [SHOULD]

| Pattern                  | When to Use                       | Example                                               |
| ------------------------ | --------------------------------- | ----------------------------------------------------- |
| Standalone setup         | Self-contained test suites        | `MyContract_Test is MyContract_Setup`                 |
| Shared abstract base     | Multiple related test contracts   | `MyContract_Base` → `MyContract_Feature_Test`         |
| Plain `Test`             | Simple contracts, storage tests   | `MyContract_Storages_Test is Test`                    |

## TEST-03 · Test Function Naming [MUST]

| Pattern                             | Usage                   | Examples                                                              |
| ----------------------------------- | ----------------------- | --------------------------------------------------------------------- |
| `test_feature_Description`          | Happy path              | `test_createMarket_SetsState`, `test_claim_ProRataPayout`            |
| `test_RevertWhen_function_Scenario` | Revert on condition     | `test_RevertWhen_claim_DeadlinePassed`                                |
| `test_RevertIf_function_Scenario`   | Revert if guard fails   | `test_RevertIf_deposit_NotAuthorized`                                 |
| `testDifferential_description`      | Differential tests      | `testDifferential_payout_SolidityVsTypescript`                        |
| `testFuzz_function`                 | Fuzz tests              | `testFuzz_claim(uint256, uint256)`                                    |
| `testFuzzDifferential_description`  | Fuzz differential       | `testFuzzDifferential_claim_withWhitelist`                            |
| `testFork_description`              | Fork tests              | `testFork_redeem_User`                                                |

> Legacy tests may not follow these patterns. All new or updated tests **must** comply.

## TEST-04 · Setup Patterns [SHOULD]

All test contracts override `setUp()` and call `super.setUp()`:

```solidity
function setUp() public override {
    super.setUp();
    // Additional test-specific setup
}
```

Decompose setup into named internal helpers for readability:

```solidity
function setUp() public override {
    super.setUp();
    _createUserWallets();
    _setUpTestParams();
    _deployContracts();
}
```

## TEST-05 · Helper Functions [SHOULD]

- Internal helpers: `_camelCase` — `_deployContracts()`, `_fundUser(address, uint256)`
- Per-user repeatable actions extracted into named helpers: `_aliceDeposits(uint128 amount)`
- Defined in both base test contracts and individual test contracts

## TEST-06 · Section Organization [SHOULD]

Tests within a contract are grouped by visual separator comments:

```solidity
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// REVERT ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// HAPPY ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
```

No `givenX`/`whenY` modifier pattern — use separate test contracts per feature instead.

## TEST-07 · Mock Patterns [SHOULD]

- Named `ContractName_Mock`
- `exposed_functionName()` to surface internal functions
- Direct state setters allowed for test convenience

```solidity
contract MyContract_Mock is MyContract {
    function exposed_computeLeaf(...) external view returns (bytes32) { ... }
    function setToken(address t_) external { ... }
}
```

## TEST-08 · Event Testing [MUST]

Always use `vm.expectEmit(true, true, true, true)` to assert **all** event parameters (indexed and non-indexed). Only omit a parameter check (by setting the corresponding bool to `false`) when the value cannot be controlled or predicted in the test context (e.g., depends on third-party logic, block-level randomness, or is prohibitively complex to reproduce).

Reference events via their **interface**:

```solidity
// ✅ Default — check all params
vm.expectEmit(true, true, true, true);
emit IMyContract.ActionCompleted(user, amount);
myContract.doAction(amount);

// ✅ Named parameter syntax is acceptable
vm.expectEmit(true, true, true, true);
emit IMyContract.ActionCompleted({user: alice, amount: 100});
myContract.doAction(100);

// ✅ Skipping a param — only when justified (e.g., third-party-generated value)
vm.expectEmit(true, true, false, true);
emit IMyContract.ActionCompleted(user, 0 /* unknown amount from oracle */);
myContract.doAction(oracleData);
```

## TEST-09 · Error/Revert Testing [MUST]

**Selector only (no args):**

```solidity
vm.expectRevert(Errors.MyContract__NothingToRecover.selector);
```

**Encoded with args:**

```solidity
vm.expectRevert(abi.encodeWithSelector(Errors.MyContract__InvalidState.selector, CurrentState.Open));
```

**Bare revert:**

```solidity
vm.expectRevert();
```

## TEST-10 · Fuzzing [SHOULD]

**`bound()` over `assume()`** [MUST]: `bound()` clamps the value into range; `assume()` discards the run. Use `assume()` only when the valid set cannot be expressed as a contiguous range.

```solidity
function testFuzz_claim(uint256 amount, uint256 shares) public {
    amount = bound(amount, 1, MAX_REALISTIC_AMOUNT);
    shares = bound(shares, 1, amount);
    // ...
}
```

**Stateful fuzzing suite (Guardian Audits pattern):**

- Inheritance chain: `FuzzSetup → FunctionCalls → ... → FuzzGuided → Fuzz`
- Functions: `fuzz_functionName(...)` with `invariant_NAME()` checks
- Named invariants: `INV_01`, `INV_02`, etc.
- Actor-based: maps `address → uint256` private keys
- Run: `forge test --mc Fuzz --show-progress`

## TEST-11 · Fork Testing [SHOULD]

- Test function prefix: `testFork_`
- Use `vm.createSelectFork()` with a target chain RPC
- Load real deployment addresses from JSON configs

## TEST-12 · Test Contract Naming [MUST]

```
ContractName_featureOrScope_Test
```

Examples: `MyContract_Claims_Test`, `MyContract_Fuzz_Test`, `MyContract_Fork_Test`

## TEST-13 · Assertion Reason Strings [SHOULD]

When a test has **more than one or two assertions**, add short reason strings (2–4 words):

```solidity
assertEq(pendingAdmin, user1, "pending admin");
assertEq(pendingSchedule, expected, "pending schedule");
```

Single-assertion test functions do not need a reason string.

## TEST-14 · ERC-7201 Storage Slot Verification [MUST]

Every ERC-7201 storage library must have a test re-deriving the slot from the namespace string. A wrong slot silently reads/writes to wrong storage.

```solidity
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

- One test per storage library — file named `ContractName.storages.t.sol`.
- Namespace in test must match the `@custom:storage-location erc7201:<namespace>` annotation.
