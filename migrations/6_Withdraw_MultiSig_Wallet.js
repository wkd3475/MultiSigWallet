const WithdrawMultiSigWallet = artifacts.require("WalletSimple");
const fs = require('fs');

module.exports = function(deployer, network, accounts) {
    const signers = [accounts[1], accounts[2], accounts[3]];
    const defaultAccount = accounts[1];

    deployer.deploy(WithdrawMultiSigWallet, signers, {from: defaultAccount})
    .then(() => {
        if (WithdrawMultiSigWallet._json) {
            fs.writeFile('WithdrawMultiSigWalletABI', JSON.stringify(WithdrawMultiSigWallet._json.abi),
                (err) => {
                    if (err) throw err;
                    console.log("파일에 ABI 입력 성공");
                }
            )
            fs.writeFile('WithdrawMultiSigWalletAddress', WithdrawMultiSigWallet.address,
                (err) => {
                    if (err) throw err;
                    console.log("파일에 주소 입력 성공");
                }
            )
        }
    })
};
