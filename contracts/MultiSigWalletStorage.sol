pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract MultiSigWalletStorage  {
    using SafeMath for uint256;

    address private _depositAddress;
    address private _withdrawAddress;

    modifier onlyDepositWallet {
    if (_depositAddress != msg.sender) {
      revert("not deposit wallet");
    }
    _;
  }

  modifier onlyWithdrawWallet {
    if (_withdrawAddress != msg.sender) {
      revert("not withdraw wallet");
    }
    _;
  }

    //_etherBalances: forwarder => balance
    //_ERC20Balances: tokenAddress => forwarder => balance
    mapping(address => uint256) private _etherBalances;
    mapping(address => mapping(address => uint256)) private _ERC20Balances;
    mapping(address => address) private _forwarderToClient;
    mapping(address => address) private _clientToForwarder;

    constructor (address depositAddress, address withdrawAddress) public {
        _depositAddress = depositAddress;
        _withdrawAddress = withdrawAddress;
    }

    //보안을 위해 이 기능은 업는 것도 고려해볼만함
    function delegateDepositAddress(address target) public onlyDepositWallet {
        _depositAddress = target;
    }

    //보안을 위해 이 기능은 업는 것도 고려해볼만함
    function delegateWithdrawAddress(address target) public onlyWithdrawWallet {
        _withdrawAddress = target;
    }

    function isForwarder(address forwarder) public view returns(bool) {
        if(_forwarderToClient[forwarder] == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function haveForwarder(address client) public view returns(bool) {
        if(_clientToForwarder[client] == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function addForwarder(address forwarder, address client) public onlyDepositWallet {
        _forwarderToClient[forwarder] = client;
        _clientToForwarder[client] = forwarder;
    }

    function getForwarderByClient(address client) public returns(address) {
        return _clientToForwarder[client];
    }

    function getClientByForwarder(address forwarder) public returns(address) {
        return _forwarderToClient[forwarder];
    }

    function getEtherBalance(address forwarder) public view returns(uint256) {
        return _etherBalances[forwarder];
    }

    function getERC20Balance(address tokenAddress, address forwarder) public view returns(uint256) {
        return _ERC20Balances[tokenAddress][forwarder];
    }
    
    function depositEther(address forwarder, uint256 amount) public onlyDepositWallet {
        require(amount > 0, "wrong amount");
        _etherBalances[forwarder] = _etherBalances[forwarder].add(amount);

        emit etherDeposited(forwarder, amount);
    }

    function depositERC20(address tokenAddress, address forwarder, uint256 amount) public onlyDepositWallet {
        require(amount > 0, "wrong amount");
       _ERC20Balances[tokenAddress][forwarder] = _ERC20Balances[tokenAddress][forwarder].add(amount);

        emit ERC20Deposited(tokenAddress, forwarder, amount);
    }

    function withdrawEther(address forwarder, uint256 amount) public onlyWithdrawWallet {
        //balance 체크 필요
        require(amount > 0, "wrong amount");
        
        _etherBalances[forwarder] = _etherBalances[forwarder].sub(amount);

        emit etherWithdrawed(forwarder, amount);
    }

    function withdrawERC20(address tokenAddress, address forwarder, uint256 amount) public onlyWithdrawWallet {
        //balance 체크 필요
        require(amount > 0, "wrong amount");
        
        _ERC20Balances[tokenAddress][forwarder] = _ERC20Balances[tokenAddress][forwarder].sub(amount);

        emit ERC20Withdrawed(tokenAddress, forwarder, amount);
    }

    function sendEtherMember(address from, address to, uint256) public {

    }

    event etherDeposited(address forwarder, uint256 amount);
    event ERC20Deposited(address tokenAddress, address forwarder, uint256 amount);
    event etherWithdrawed(address forwarder, uint256 amount);
    event ERC20Withdrawed(address tokenAddress, address forwarder, uint256 amount);
}