require('dotenv').config();

var HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = process.env["MNEMONIC"];
const ROPSTEN_PROJECT_ID = process.env["ROPSTEN_PROJECT_ID"];

module.exports = {
  networks: {
   dev: {
     host: "127.0.0.1",
     port: 7545,
     network_id: "5777",
   },
   ropsten: {
      provider: function() {
        // return new HDWalletProvider(MNEMONIC, "https://ropsten.infura.io/v3/"+ROPSTEN_PROJECT_ID,0,5)
        return new HDWalletProvider(MNEMONIC, "https://ropsten.infura.io/v3/"+ROPSTEN_PROJECT_ID)
      },
      network_id: 3,
      gas: 4000000,      //make sure this gas allocation isn't over 4M, which is the max
    }
  },
  compilers: {
    solc: {
      version: "0.8.1",
      settings: {
        optimizer: {
          "enabled": true,
          "runs": 1000
        }
      }
    }
   }
};
