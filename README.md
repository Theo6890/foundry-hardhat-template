# <h1 align="center"> DeFi </h1>

A DeFi project.

## Install

```bash
yarn install && forge install
```

Each time a new dependency is added in `lib/` run `forge install`.

## Architecture

Follow's Solidstate architecture (diamond pattern based).

| **folder**   | **layer**              | **description**                                                                                                             | **example**                                                                    |
| ------------ | ---------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **-**        | internal - `interface` | contains custom `error`, `enum`, `struct`& `event`                                                                          | `IRandomnessWritableInternal.sol`, `IRandomnessReadableInternal.sol`           |
| **-**        | external - `interface` | common interfaces which define external and public function's prototypes                                                    | `IRandomnessFallback.sol`, `IRandomnessReadble.sol`, `IRandomnessWritable.sol` |
| **readable** | external               | set of functions which only read the storage                                                                                | `RandomnessReadable.sol`                                                       |
| **writable** | external & internal    | set of functions which update storage; internal function always declares in `xyzWritableInternal.sol` & contains `modifier` | `RandomnessInternalWritable.sol`, `RandomnessWritable.sol`                     |
| **./**       | storage                | library for to map, access and modify storage                                                                               | `RandomnessStorage.sol`                                                        |

## Tests

-   Run without fuzz testing, use `forge test -vvv`

### Generate Coverage Report

If `lcov` is not installed, run `brew install lcov`.
Then run: `forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage`

### Coverage Screenshot

TBD

### Run GitHub Actions Locally

1. Install [act](https://github.com/nektos/act)
2. Load env var `source .env`
3. Run a job: `act -j foundry -s SEED` (hit ENTER when asked `Provide value for 'SEED':`)

## Run Advanced Tests

### Slither

`slither .`

Note: Slither has been added to GitHub actions, so it will run automatically on every **push and pull requests**.

### Mythril

`myth a src/Vault.sol --solc-json mythril.config.json` (you can use both `myth a` and `mythril analyze`)

### Manticore

1. Run Docker container:

```
docker run --rm -it --platform linux/amd64 \
-v $(pwd):/home/vault \
baolean/manticore:latest
```

2. Go to mounted volume location: `cd /home/vault`

3. Select Solidity version

```
solc-select install 0.8.17 && solc-select use 0.8.17
```

4. Run manticore:

```
manticore src/Vault.sol --contract Vault --solc-remaps="openzeppelin-contracts/=lib/openzeppelin-contracts/contracts/"
```

### SuMo

After install yarn dependencies, run `yarn sumo test` to run mutation testing.

_Note: there are issues when forge needs to compile with `--ffi`_

### Gambit

1. Install it locally, [see GitHub](https://github.com/Certora/gambit?utm_campaign=Gambit%20Release&utm_source=Medium&utm_medium=Blog#installation)

2. Run: `gambit mutate --json gambit-conf.json`

_Note: gambit does not take into account specified remappings_

## Best Practices to Follow

### Generics

-   Code formatter & linter: prettier, solhint, husky, lint-staged & husky
-   [Foundry](https://book.getfoundry.sh/tutorials/best-practices)

### Security

-   [Solidity Patterns](https://github.com/fravoll/solidity-patterns)
-   [Solcurity Codes](https://github.com/transmissions11/solcurity)
-   Secureum posts _([101](https://secureum.substack.com/p/security-pitfalls-and-best-practices-101) & [101](https://secureum.substack.com/p/security-pitfalls-and-best-practices-201): Security Pitfalls & Best Practice)_
-   [Smart Contract Security Verification Standard](https://github.com/securing/SCSVS)
-   [SWC](https://swcregistry.io)

## Be Prepared For Audits

Must Do Checklist:

-   [ ] Unit ([TDD](https://r-code.notion.site/TDDs-steps-cecba0a82ee6466f9f479ca553949be2)) & integration (BDD) tests (green)
-   [ ] Well refactored & commented code
    -   _Use where needed: NatSpec comment, [PlantUML](https://plantuml.com/starting), [Sol2UML](https://github.com/naddison36/sol2uml) (UML for Solidity)_
-   Internal Audit - Tool Suite
    -   [ ] Secureum articles
        -   [Audit Techniques & Tools 101](https://secureum.substack.com/p/audit-techniques-and-tools-101)
        -   [Audit Findings 101](https://secureum.substack.com/p/audit-findings-101)
        -   [Audit Findings 201](https://secureum.substack.com/p/audit-findings-201)
    -   [ ] Built in Foundry:
        -   [ ] fuzz testing: generate (semi-)random inputs
            -   _There is also echidna which can be used_
        -   [ ] differential testing
        -   [ ] invariant testing
    -   [ ] Static analysers: **mythril**, **slither** (GitHub actions), securify, smartcheck, oyente
        -   _Note: solidity smt checker can be used on top for formal verification testing_
    -   [ ] Symbolic execution: manticore
    -   [ ] Mutation testing: SuMo, Gambit, universalmutator
    -   [ ] Audit report generator: MythX

_Note: For more complex contract **Paper code review** should be considered to check for conception & logic errors._

Other tools for a deeper analysis:

-   static binary EVM analysis: rattle
-   control flow graph: surya (integrated into VSCode extension), evm_cfg_builder
-   disassemble EVM code: ethersplay, pyevmasm
-   runtime verification: scribble (also done by: mythril, harvey, mythx)
-   JSON RPC multiplexer, analysis tool wrapper & test integration tool: etheno (Ethereum testing Swiss Army knife)
    -   _eliminates the complexity of tools like Echidna on large, multi-contract projects_

## Deployed Addresses

TBD

## Git Release Flow

`beta-*` is forked off `dev` and merged into `rc-*` (once integratoin issues fixed). `rc-*` is merged into `main` (once audit fixes are done).

-   `beta-*` branches contain fixes found during frontend/backend integrations, updated ABIs & new testnet addresses
-   `rc-*` branches contain audit fixes, audit report and mainnet addresses
-   `main` branch freeze latest `rc-*`
