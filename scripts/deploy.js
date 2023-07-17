const hre = require('hardhat');

// npx hardhat run --network goerli scripts/deploy.js
async function main() {
    const VAULT = await hre.ethers.getContractFactory('VAULT');
    const vault = await VAULT.deploy();

    await vault.deployed();

    console.log(`Deployed to ${vault.address}`);

    await hre.run('verify:verify', {
        address: vault.address,
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
