const hre = require('hardhat');

// npx hardhat run --network bscTest scripts/verify.js
async function main() {
    await hre.run('verify:verify', {
        address: '',
        // see: https://hardhat.org/hardhat-runner/plugins/nomiclabs-hardhat-etherscan#using-programmatically
        constructorArguments: [],
    });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
