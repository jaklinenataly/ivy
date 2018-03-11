/**
 * Start testrpc with the following command:
 *
 * testrpc -u 0 -u 1
 *
 * This starts testrpc and unlocks the first two users. Pick one of them's address and set the address below.
 */
var address = "0xc871b86b3f7057499b22d2111c9a72fb19004073";

/**
 * This is the bytecode for execution. You are already familiar with this.
 */
var lllBin = '604280600c6000396000f30063ac37eebb60e060020a600035041415601e5760043560005260206000f35b63cad0899b60e060020a6000350414156041576024356004350160005260206000f35b';
var bin = '7f0000000000000000000000000000000000000000000000000000000000000424807f00000000000000000000000000000000000000000000000000000000000000887f0000000000000000000000000000000000000000000000000000000000000000397f0000000000000000000000000000000000000000000000000000000000000000f30063cad0899b60e060020a6000350414157f0000000000000000000000000000000000000000000000000000000000000423577f0000000000000000000000000000000000000000000000000000000000000004357f0000000000000000000000000000000000000000000000000000000000000000527f0000000000000000000000000000000000000000000000000000000000000024357f0000000000000000000000000000000000000000000000000000000000000020527f00000000000000010000000000000000000000000000000000000000000000007f000000000000000000000000000000000000000000000000000000000000002051047f00000000000000010000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000005104017f00000000000000000000000000000000000000000000000000000000000000607f0000000000000000000000000000000000000000000000000000000000000007018181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f0000000000000000000000000000000000000000000000000000000000000100909104908181537f000000000000000000000000000000000000000000000000000000000000000190037f00000000000000000000000000000000000000000000000000000000000001009091049050507f00000000000000000000000000000000000000000000000000000000000000807f0000000000000000000000000000000000000000000000000000000000000060f35b';

var abi =
  [
    {
      "name": "sum",
      "type": "function",
      "constant": true,
      "payable": false,
      "inputs": [
        {
          "name": "a",
          "type":"uint256"
        },
        {
          "name": "b",
          "type":"uint256"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type":"uint256"
        }
      ]
    }
  ]

var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
var Contract = new web3.eth.Contract(abi, {data: bin, from: address, gasPrice: 20000000000, gas: 1000000 });
var deployment = Contract.deploy().send();
deployment.then(newContract => {
  // console.log(newContract.methods);
  newContract.methods.sum(3, 5).call().then(console.log);
  // newContract.methods.sum(4, 5).call().then(console.log);
});
