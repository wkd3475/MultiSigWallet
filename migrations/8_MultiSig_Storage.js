const MultiSigWalletStorage = artifacts.require("MultiSigWalletStorage");
const fs = require('fs');
const depositMultiSigWalletAddress = fs.readFileSync('../DepositMultiSigWalletAddress', 'utf8').replace(/\n|\r/g, "");
const withdrawMultiSigWalletAddress = fs.readFileSync('../WithdrawMultiSigWalletAddress', 'utf8').replace(/\n|\r/g, "");

module.exports = function(deployer, network, accounts) {
    const defaultAccount = accounts[0];

    deployer.deploy(MultiSigWalletStorage, depositMultiSigWalletAddress, withdrawMultiSigWalletAddress, {from: defaultAccount})
    .then(() => {
        if (MultiSigWalletStorage._json) {
            fs.writeFile('MultiSigWalletStorageABI', JSON.stringify(MultiSigWalletStorage._json.abi),
                (err) => {
                    if (err) throw err;
                    console.log("파일에 ABI 입력 성공");
                }
            )
            fs.writeFile('MultiSigWalletStorageAddress', MultiSigWalletStorage.address,
                (err) => {
                    if (err) throw err;
                    console.log("파일에 주소 입력 성공");
                }
            )
        }
    })
};
