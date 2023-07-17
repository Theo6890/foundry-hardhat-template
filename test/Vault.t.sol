// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {Vault} from "../src/Vault.sol";

contract Vault_Test is Test {
    Vault public vault;

    function setUp() public {
        vault = new Vault();
    }

    function test_truthy() public {
        assertTrue(true);
    }
}
