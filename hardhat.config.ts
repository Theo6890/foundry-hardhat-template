import '@typechain/hardhat';
import 'hardhat-preprocessor';
import { HardhatUserConfig, task } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-foundry';

import 'dotenv/config';
require('dotenv').config();

////////////// Secrets file reading //////////////
import fs from 'fs';
import path from 'path';
let secrets: any;
function readSecrets(fileName: string): any {
    return JSON.parse(
        fs.readFileSync(path.resolve(__dirname, fileName), 'utf-8')
    );
}
try {
    secrets = readSecrets('./secrets.json');
} catch (error) {
    secrets = readSecrets('./secrets.example.json');
}

const useTypeChainV5: boolean =
    process.env.USE_TYPECHAIN_V5 === 'true' ? true : false;
const SEED = secrets.accounts.deployerSeed;
const MAINNETS = secrets.rpcs.mainnets;
const TESTNETS = secrets.rpcs.testnets;
const API_KEYS = secrets.apiKeys;
const CMC = secrets.coinmarketcap;

const config: HardhatUserConfig = {
    networks: {
        ///////////// mainnets /////////////
        arb: {
            url: MAINNETS.arb,
            accounts: {
                mnemonic: SEED,
            },
        },
        avax: {
            url: MAINNETS.avax,
            accounts: {
                mnemonic: SEED,
            },
        },
        bsc: {
            url: MAINNETS.bsc.one,
            accounts: {
                mnemonic: SEED,
            },
        },
        eth: {
            url: MAINNETS.eth,
            accounts: {
                mnemonic: SEED,
            },
        },
        ftm: {
            url: MAINNETS.ftm.one,
            accounts: {
                mnemonic: SEED,
            },
        },
        polygon: {
            url: MAINNETS.polygon,
            accounts: {
                mnemonic: SEED,
            },
        },
        ///////////// tesnets /////////////
        arbSep: {
            url: TESTNETS.arbSep,
            accounts: {
                mnemonic: SEED,
            },
        },
        fuji: {
            // AVAX
            url: TESTNETS.fuji,
            accounts: {
                mnemonic: SEED,
            },
        },
        bscTest: {
            url: TESTNETS.bscTest.one,
            accounts: {
                mnemonic: SEED,
            },
        },
        sepolia: {
            // ETH
            url: TESTNETS.sepolia,
            accounts: {
                mnemonic: SEED,
            },
        },
        ftmTest: {
            url: TESTNETS.ftmTest.one,
            accounts: {
                mnemonic: SEED,
            },
        },
        mumbai: {
            // polygon
            url: TESTNETS.mumbai,
            accounts: {
                mnemonic: SEED,
            },
        },
        hardhat: {
            allowUnlimitedContractSize: true,
        },
    },
    // npx hardhat verify --list-networks
    etherscan: {
        apiKey: {
            // mainnets
            bsc: API_KEYS.bscscan ?? '',
            mainnet: API_KEYS.etherscan ?? '',
            polygon: API_KEYS.polygonscan ?? '',
            opera: API_KEYS.ftmscan ?? '',
            arbitrumOne: API_KEYS.arbiscan ?? '',
            avalanche: 'snowtrace', // no api key on snowtrace, though placeholder compulsory
            // testnet
            bscTestnet: API_KEYS.bscscan ?? '',
            sepolia: API_KEYS.etherscan ?? '',
            ftmTestnet: API_KEYS.ftmscan ?? '',
            avalancheFujiTestnet: 'snowtrace', // no api key on snowtrace, though placeholder compulsory
            polygonMumbai: API_KEYS.polygonscan ?? '',
            arbitrumGoerli: API_KEYS.arbiscan ?? '', // change to arb sepolia
        },
    },
    solidity: {
        version: '0.8.23',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: true,
        },
    },
    typechain: {
        target: useTypeChainV5 ? 'ethers-v5' : 'ethers-v6',
        outDir: useTypeChainV5 ? 'typechain-v5' : 'typechain-v6',
    },
    paths: {
        sources: './src', // Use ./src rather than ./contracts as Hardhat expects
        cache: './cache_hardhat', // Use a different cache for Hardhat than Foundry
        tests: './test/hardhat', // Use a different cache for Hardhat than Foundry
    },
    mocha: {
        timeout: 200000,
    },
};

export default config;
