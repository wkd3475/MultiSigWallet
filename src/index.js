import {Spinner} from "spin.js";

var Web3 = require('web3');
var web3 = new Web3();
web3.setProvider(new Web3.providers.HttpProvider('http://localhost:8545'));

const UNIT = 10**18;
const tokenContract = new web3.eth.Contract(TOKEN_ABI, TOKEN_ADDRESS);
const depositMultiSigWalletContract = new web3.eth.Contract(DEPOSIT_MULTISIG_WALLET_ABI, DEPOSIT_MULTISIG_WALLET_ADDRESS);
const withdrawMultiSigWalletContract = new web3.eth.Contract(WITHDRAW_MULTISIG_WALLET_ABI, WITHDRAW_MULTISIG_WALLET_ADDRESS);
const multiSigStorageContract = new web3.eth.Contract(MULTISIG_WALLET_STORAGE_ABI, MULTISIG_WALLET_STORAGE_ADDRESS);

var auth = {
    admin1: '',
    admin2: '',
    signer1: '',
    signer2: '',
    client1: '',
    client2: '',
    client3: '',
};

const Home = {
    start: async function () {
        const pageSession = sessionStorage.getItem('page');
        const admin = await web3.eth.getAccounts();
        auth = {
            admin1: admin[0],
            admin2: admin[1],
            signer1: admin[2],
            signer2: admin[3],
            client1: admin[4],
            client2: admin[5],
            client3: admin[6],
        };

        document.getElementById('admin1-address').innerText = auth.admin1;
        document.getElementById('admin2-address').innerText = auth.admin2;
        document.getElementById('signer1-address').innerText = auth.signer1;
        document.getElementById('signer2-address').innerText = auth.signer2;
        document.getElementById('deposit-wallet-ether-balance').innerText = await web3.eth.getBalance(DEPOSIT_MULTISIG_WALLET_ADDRESS) + " wei";
        document.getElementById('deposit-wallet-token-balance').innerText = await this.getTokenBalance(DEPOSIT_MULTISIG_WALLET_ADDRESS) + " HD";
        document.getElementById('withdraw-wallet-ether-balance').innerText = await web3.eth.getBalance(WITHDRAW_MULTISIG_WALLET_ADDRESS) + " wei";
        document.getElementById('withdraw-wallet-token-balance').innerText = await this.getTokenBalance(WITHDRAW_MULTISIG_WALLET_ADDRESS) + " HD";


        if(pageSession == 'admin') {
            this.changeAdminPage();
        } else if(pageSession == 'client') {
            this.changeClientPage();
        }
    },

    getTokenBalance: async function (walletAddress) {
        return await tokenContract.methods.balanceOf(walletAddress).call();
    },
    
    changeClientPage: function () {
        let page = $('#client-page');
        if (page.is(':visible')) {
            page.hide();
            sessionStorage.removeItem('page');
        } else {
            $('#admin-page').hide();
            page.show();
            Client.start();
            sessionStorage.setItem('page', 'client');
        }
    },

    changeAdminPage: function () {
        let page = $('#admin-page');
        if (page.is(':visible')) {
            page.hide();
            sessionStorage.removeItem('page');
        } else {
            $('#client-page').hide();
            page.show();
            Admin.start();
            sessionStorage.setItem('page', 'admin');
        }
    },

    clipboard: function (element){
        var $temp = $("<input>");
        $("body").append($temp);
        $temp.val($(element).text()).select();
        document.execCommand("copy");
        $temp.remove();
    },
};

const Admin = {
    start: async function() {
        $("#num-of-forwarder").text(await depositMultiSigWalletContract.methods.getNumOfUnassignedForwarder().call());
        $("#is-setted").text(await depositMultiSigWalletContract.methods.isSetted().call());
    },

    createForwarder: async function() {
        try{
            await web3.eth.sendTransaction({
                from: auth.admin1,
                to: DEPOSIT_MULTISIG_WALLET_ADDRESS,
                gas: 1000000,
                data: await web3.eth.abi.encodeFunctionCall({
                    name: 'createForwarder',
                    type: 'function',
                    inputs: []
                }, [])
            });
        } catch(e) {
            console.log('createForwarder error: ', e);
        }
        $("#num-of-forwarder").text(await depositMultiSigWalletContract.methods.getNumOfUnassignedForwarder().call());
    },

    setMultisigWalletStorage: async function() {
        let targetAddress = MULTISIG_WALLET_STORAGE_ADDRESS;
        await this.setDepositToStorage(targetAddress);
        await this.setWithdrawToStorage(targetAddress);
        this.start();
    },

    setDepositToStorage: async function(targetAddress) {
        try{
            await web3.eth.sendTransaction({
                from: auth.admin1,
                to: DEPOSIT_MULTISIG_WALLET_ADDRESS,
                gas: 100000,
                data: web3.eth.abi.encodeFunctionCall({
                    name: 'setStorageAddress',
                    type: 'function',
                    inputs: [{
                        type: 'address',
                        name: 'target',
                    }]
                }, [targetAddress])
            });
        } catch(e) {
            console.log('setStorage error: ', e);
        }
    },

    setWithdrawToStorage: async function(targetAddress) {
        await web3.eth.sendTransaction({
            from: auth.admin2,
            to: WITHDRAW_MULTISIG_WALLET_ADDRESS,
            gas: 100000,
            data: web3.eth.abi.encodeFunctionCall({
                name: 'setStorageAddress',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'target',
                }]
            }, [targetAddress])
        });
    },
};

const Client = {
    start: async function () {
        $('#token-total').text('total supply : ' + await this.getTotalSupply());
        $('#token-address').text(TOKEN_ADDRESS);
        $('#account1-ether').text(await web3.eth.getBalance(auth.client1) + " wei");
        $('#account2-ether').text(await web3.eth.getBalance(auth.client2) + " wei");
        $('#account3-ether').text(await web3.eth.getBalance(auth.client3) + " wei");
        $('#account1').text(auth.client1);
        $('#account2').text(auth.client2);
        $('#account3').text(auth.client3);
    },

    etherTransferHandler: function(element) {
        const walletAddress = $(element).text();
        this.etherTransfer(walletAddress);
    },

    showEtherSendBoxHandler: function(element) {
        if ($('#ether-send-box').is(':visible')) {
            $('#ether-send-box').hide();
        } else {
            $('#ether-send-box').show()
        }
    },

    ERC20TransferHandler: function(element) {
        const walletAddress = $(element).text();
        this.erc20Transfer(walletAddress);
    },

    showERC20SendBoxHandler: function () {
        if ($('#erc20-send-box').is(':visible')) {
            $('#erc20-send-box').hide();
        } else {
            $('#erc20-send-box').show()
        }
    },

    ERC20DepositHandler: function () {
        const _walletAddress = $('#setted-account').text();
        const _tokenAddress = $('#deposit-token-address').val();
        const _recipient = DEPOSIT_MULTISIG_WALLET_ADDRESS;
        const _forwarder = $('#your-forwarder').text();
        const _amount = BigInt(parseFloat($('#deposit-amount').val()) * UNIT).toString(10);

        this.ERC20Deposit(_walletAddress, _tokenAddress, _recipient, _forwarder, _amount);
    },

    showDepositBoxHandler: function () {
        if ($('#deposit-send-box').is(':visible')) {
            $('#deposit-send-box').hide();
        } else {
            $('#deposit-send-box').show()
        }
    },

    setAccountHandler: async function (element) {
        const walletAddress = $(element).text();
        this.setAccount(walletAddress);
        $('#account-info').show();
    },

    setAccount: async function (walletAddress) {
        $('#setted-account').text(walletAddress);
        $('#setted-account-token-balance').text(await this.getTokenBalance(walletAddress));
        const forwarder = await this.getForwarder(walletAddress);
        $('#your-forwarder').text(forwarder);
        $('#forwarder-ether-balance').text(await this.getForwarderEtherBalance(forwarder));
        $('#forwarder-token-balance').text(await this.getForwarderTokenBalance(TOKEN_ADDRESS,forwarder));
    },

    getForwarder: async function (walletAddress) {
        return await multiSigStorageContract.methods.getForwarderByClient(walletAddress).call();
    },

    getForwarderEtherBalance: async function (forwarder) {
        return await multiSigStorageContract.methods.getEtherBalance(forwarder).call();
    },

    getForwarderTokenBalance: async function (tokenAddress, forwarder) {
        return await multiSigStorageContract.methods.getERC20Balance(tokenAddress, forwarder).call();
    },

    getTokenBalance: async function (walletAddress) {
        return await tokenContract.methods.balanceOf(walletAddress).call();
    },

    getAccount: function (walletAddress) {
        $('#setted-account').text(walletAddress);
    },

    getTotalSupply: async function () {
        return await tokenContract.methods.totalSupply().call();
    },

    etherTransfer: async function(walletAddress) {
        if (walletAddress) {
            let amount = BigInt(parseFloat($('#ether-amount').val()) * UNIT).toString(10);
            let recipient = $('#ether-recipient').val().toString();
            
            if (amount && recipient) {
                var spinner = this.showSpinner();
                try {
                    await this.etherSend(walletAddress, recipient, amount);
                } catch(e) {
                    console.log('etherTransfer error: ', e);
                }
                spinner.stop();
                location.reload();
            } else {
                alert("wrong input");
            }
        }
        $('#ether-send-box').hide();
    },

    etherSend: async function(walletAddress, recipient, amount) {
        await web3.eth.sendTransaction({
            from: walletAddress,
            to: recipient,
            gas: 1000000,
            value: amount,
        });
    },

    erc20Transfer: async function(walletAddress) {
        if (walletAddress) {
            let amount = BigInt(parseFloat($('#erc20-amount').val()) * UNIT).toString(10);
            let recipient = $('#erc20-recipient').val().toString();
            let tokenAddress = $('#erc20-address').val().toString();
            const godList = ["0xf402f8d845e659b53858c9b0394a3224089aec26", "0xfa50c5c818d98af46af11b1f6518d70377fc6d27"];
            const feeList = ['100000000000000000', '100000000000000000'];
            
            if (amount && recipient) {
                var spinner = this.showSpinner();
                try {
                    await this.approve(walletAddress, tokenAddress, PROXY_ADDRESS, amount);
                    //NUM_GOD, godList, feeList는 이미 db에 저장된 값으로 정해니는 값임
                    await this.erc20TokenSend(walletAddress, tokenAddress, recipient, amount, godList, feeList);
                } catch(e) {
                    console.log('feeTransfer error: ', e);
                }
                spinner.stop();
                location.reload();
            } else {
                alert("wrong input");
            }
        }
        $('#fee-send-box').hide();
    },

    erc20TokenSend: async function (walletAddress, tokenAddress, recipient, tokenAmount, godList, feeList) {
        let totalFee = 0;
        for(let i=0; i<feeList.length; i++) {
            totalFee += parseInt(feeList[i]);
        }
        await web3.eth.sendTransaction({
            from: walletAddress,
            to: PROXY_ADDRESS,
            gas: 250000,
            value: totalFee,
            data: web3.eth.abi.encodeFunctionCall({
                name: 'ERC20Send',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'tokenAddress',
                }, {
                    type: 'address',
                    name: 'recipient',
                }, {
                    type: 'uint256',
                    name: 'tokenAmount'
                }, {
                    type: 'address[]',
                    name: 'gods',
                }, {
                    type: 'uint256[]',
                    name: 'feeAmount'
                }]
            }, [tokenAddress, recipient, tokenAmount, godList, feeList])
        });
    },

    ERC20Deposit: async function (walletAddress, tokenAddress, recipient, forwarder, amount) {
        var spinner = this.showSpinner();
        try {
            await this.approve(walletAddress, tokenAddress, forwarder, amount);
            await this.transferFrom(tokenAddress, forwarder, walletAddress, amount);
        } catch(e) {
            alert("wrong input");
        }
        
        spinner.stop();
        location.reload();
    },

    approve: async function (walletAddress, tokenAddress, spender, amount) {
        await web3.eth.sendTransaction({
            from: walletAddress,
            to: tokenAddress,
            gas: 300000,
            data: web3.eth.abi.encodeFunctionCall({
                name: 'approve',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'spender',
                }, {
                    type: 'uint256',
                    name: 'value',
                }]
            }, [spender, amount])
        });
    },

    transferFrom: async function (tokenAddress, spender, sender, amount) {
        await web3.eth.sendTransaction({
            from: sender,
            to: spender,
            gas: 300000,
            data: web3.eth.abi.encodeFunctionCall({
                name: 'depositERC20',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'tokenAddress',
                },{
                    type: 'address',
                    name: 'sender',
                }, {
                    type: 'uint256',
                    name: 'amount',
                }]
            }, [tokenAddress, sender, amount])
        });
    },

    requestRegistration: async function (element) {
        const walletAddress = $(element).text();
        if(walletAddress == "") {
            alert("choose account");
            return;
        }
        let haveForwarder = await multiSigStorageContract.methods.haveForwarder(walletAddress).call();
        if(haveForwarder) {
            alert("already have forwarder");
            return;
        }

        try {
            await web3.eth.sendTransaction({
                from: auth.admin1,
                to: DEPOSIT_MULTISIG_WALLET_ADDRESS,
                gas: 1000000,
                data: web3.eth.abi.encodeFunctionCall({
                    name: 'assignForwarder',
                    type: 'function',
                    inputs: [{
                        type: 'address',
                        name: 'client',
                    }]
                }, [walletAddress])
            });
        } catch (e) {
            console.log('createForwarder error: ', e);
            alert("not enough forwarder");
        }

        location.reload();
    },

    showSpinner: function () {
        var target = document.getElementById("spin");
        return new Spinner(opts).spin(target);
    },
};

window.Admin = Admin;
window.Home = Home;
window.Client = Client;

window.addEventListener("load", function() {
    Home.start();
});

var opts = {
    lines: 10, // The number of lines to draw
    length: 30, // The length of each line
    width: 17, // The line thickness
    radius: 45, // The radius of the inner circle
    scale: 1, // Scales overall size of the spinner
    corners: 1, // Corner roundness (0..1)
    color: '#5bc0de', // CSS color or array of colors
    fadeColor: 'transparent', // CSS color or array of colors
    speed: 1, // Rounds per second
    rotate: 0, // The rotation offset
    animation: 'spinner-line-fade-quick', // The CSS animation name for the lines
    direction: 1, // 1: clockwise, -1: counterclockwise
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    className: 'spinner', // The CSS class to assign to the spinner
    top: '50%', // Top position relative to parent
    left: '50%', // Left position relative to parent
    shadow: '0 0 1px transparent', // Box-shadow for the lines
    position: 'absolute' // Element positioning
};