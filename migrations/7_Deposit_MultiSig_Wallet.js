const DepositMultiSigWallet = artifacts.require("WalletSimple");
const fs = require('fs');

module.exports = function(deployer, network, accounts) {
    const signers = [accounts[0], accounts[2], accounts[3]];

    const defaultAccount = accounts[0];
    deployer.deploy(DepositMultiSigWallet, signers, {from: defaultAccount})
    .then(() => {
        if (DepositMultiSigWallet._json) {
            fs.writeFile('DepositMultiSigWalletABI', JSON.stringify(DepositMultiSigWallet._json.abi),
                (err) => {
                    if (err) throw err;
                    console.log("파일에 ABI 입력 성공");
                }
            )
            fs.writeFile('DepositMultiSigWalletAddress', DepositMultiSigWallet.address,
                (err) => {
                    if (err) throw err;
                    console.log("파일에 주소 입력 성공");
                }
            )
        }
    })
};
