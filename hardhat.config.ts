import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();


const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    matic:{
      url: process.env.MATIC_RPC_URL || '',
      chainId: 137,
      accounts:[process.env.DEPLOY_PRIVATE_KEY || '']
    },

    mumbai:{
      url: "https://polygon-mumbai.g.alchemy.com/v2/wDIt_c5Zl3Gn4wIugQgP-lXCb9Lb_VMZ",
      chainId: 80001,
      accounts:["c965cd0f8776a46fa0ef9c47af6ebd3659ba02dfc26eec45653378c367fb5b94"]
    },

    sepolia:{
      url: "https://rpc.sepolia.org",
      chainId: 11155111,
      accounts:["c965cd0f8776a46fa0ef9c47af6ebd3659ba02dfc26eec45653378c367fb5b94"]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

export default config;
