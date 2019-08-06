pragma solidity ^0.4.24;

import "./MultiSigWalletStorage.sol";

contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) public returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) public view returns (uint256 balance);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Forwarder {
  address public parentAddress;
  bool public state = false;
  event ForwarderDeposited(address from, uint value, bytes data);

  event TokensFlushed(
    address tokenContractAddress,
    uint value
  );

  constructor () public {
    parentAddress = msg.sender;
  }

  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  function() public payable {
    if(state != true) {
        revert();
    }

    parentAddress.transfer(msg.value);
    parentAddress.depositEther(msg.value);
    emit ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  function flushTokens(address tokenContractAddress) public onlyParent {
    require(state == true, "off state");
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
    emit TokensFlushed(tokenContractAddress, forwarderBalance);
  }

  function flush() public {
    require(state == true, "off state");
    parentAddress.transfer(address(this).balance);
  }

  function enable() public onlyParent {
      state = true;
  }

  function disable() public onlyParent {
      state = false;
  }

  function getState() public view returns(bool) {
      return state;
  }

  function depositERC20(address tokenAddress, address sender, uint256 amount) public {
    ERC20Interface(tokenAddress).transferFrom(sender, parentAddress, amount);
    parentAddress.depositERC20(tokenAddress, amount);
  }
}

contract WalletSimple {
  // Events
  event Deposited(address from, uint value, bytes data);
  event SafeModeActivated(address msgSender);
  event Transacted(
    address msgSender, // Address of the sender of the message initiating the transaction
    address otherSigner, // Address of the signer (second signature) used to initiate the transaction
    bytes32 operation, // Operation hash (sha3 of toAddress, value, data, expireTime, sequenceId)
    address toAddress, // The address the transaction was sent to
    uint value, // Amount of Wei sent to the address
    bytes data // Data sent when invoking the transaction
  );
  event TokenTransacted(
    address msgSender, // Address of the sender of the message initiating the transaction
    address otherSigner, // Address of the signer (second signature) used to initiate the transaction
    bytes32 operation, // Operation hash (sha3 of toAddress, value, tokenContractAddress, expireTime, sequenceId)
    address toAddress, // The address the transaction was sent to
    uint value, // Amount of token sent
    address tokenContractAddress // The contract address of the token
  );

  address[] public signers;
  bool public safeMode = false;

  uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint[10] recentSequenceIds;

  address[] public unassignedForwarder;
  address private storageAddress;

  modifier onlysigner {
    if (!isSigner(msg.sender)) {
      revert("not signer");
    }
    _;
  }

  constructor (address[] allowedSigners) public {
    if (allowedSigners.length != 3) {
      // Invalid number of signers
      revert();
    }
    signers = allowedSigners;
  }

  function showSender() public returns (address) {
      return msg.sender;
  }

  function() public payable {
    if (msg.value > 0) {
      MultiSigWalletStorage(storageAddress).depositEther(msg.sender, msg.value);
      emit Deposited(msg.sender, msg.value, msg.data);
    }
  }

  function setStorageAddress(address target) public onlysigner {
      storageAddress = target;
  }

  function depositEther(uint256 amount) public {
    if(storageAddress.isForwarder(msg.sender)) {
      storageAddress.depositEther(msg.sender, amount);
    }
  }

  function depositERC20(address tokenAddress, uint256 amount) public {
    if(storageAddress.isForwarder(msg.sender)) {
      storageAddress.depositERC20(tokenAddress, msg.sender, amount);
    }
  }

  function createForwarder() public onlysigner returns (address) {
    address forwarder = new Forwarder();
    unassignedForwarder.push(forwarder);
    return forwarder;
  }

  function assignForwarder(address client) public onlysigner returns (address) {
    require(getNumOfUnassignedForwarder() != 0, "not enough");
    uint256 len = unassignedForwarder.length;
    address targetForwarder = unassignedForwarder[len-1];
    Forwarder forwarder = Forwarder(targetForwarder);
    forwarder.enable();

    MultiSigWalletStorage instance = MultiSigWalletStorage(storageAddress);
    instance.addForwarder(targetForwarder, client);

    delete unassignedForwarder[len-1];
    unassignedForwarder.length--;

    return targetForwarder;
  }

  function showUnassignedForwarder() public view returns (address[]) {
      return unassignedForwarder;
  }

  function getNumOfUnassignedForwarder() public view returns (uint256) {
      return unassignedForwarder.length;
  }

  function sendMultiSig(address toAddress, uint value, bytes data, uint expireTime, uint sequenceId, bytes signature) public onlysigner {
    // Verify the other signer
    bytes32 operationHash = keccak256("ETHER", toAddress, value, data, expireTime, sequenceId);
    
    address otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);

    toAddress.transfer(value);

    emit Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
  }

  function sendMultiSigToken(address toAddress, uint value, address tokenContractAddress, uint expireTime, uint sequenceId, bytes signature) public onlysigner {
    // Verify the other signer
    bytes32 operationHash = keccak256("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId);
    
    address otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
    
    ERC20Interface instance = ERC20Interface(tokenContractAddress);

    instance.transfer(toAddress, value);

    emit TokenTransacted(msg.sender, otherSigner, operationHash, toAddress, value, tokenContractAddress);
  }

  function flushForwarderTokens(address forwarderAddress, address tokenContractAddress) public onlysigner {    
    Forwarder forwarder = Forwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }
  
  function verifyMultiSig(address toAddress, bytes32 operationHash, bytes signature, uint expireTime, uint sequenceId) private returns (address) {

    address otherSigner = recoverAddressFromSignature(operationHash, signature);

    // Verify if we are in safe mode. In safe mode, the wallet can only send to signers
    if (safeMode && !isSigner(toAddress)) {
      // We are in safe mode and the toAddress is not a signer. Disallow!
      revert();
    }
    // Verify that the transaction has not expired
    if (expireTime < block.timestamp) {
      // Transaction expired
      revert();
    }

    // Try to insert the sequence ID. Will throw if the sequence id was invalid
    tryInsertSequenceId(sequenceId);

    if (!isSigner(otherSigner)) {
      // Other signer not on this wallet or operation does not match arguments
      revert();
    }
    if (otherSigner == msg.sender) {
      // Cannot approve own transaction
      revert();
    }

    return otherSigner;
  }

  function activateSafeMode() public onlysigner {
    safeMode = true;
    emit SafeModeActivated(msg.sender);
  }

  function isSigner(address signer) public view returns (bool) {
    // Iterate through all signers on the wallet and
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }

  function recoverAddressFromSignature(bytes32 operationHash, bytes signature) private pure returns (address) {
    if (signature.length != 65) {
      revert();
    }
    // We need to unpack the signature, which is given as an array of 65 bytes (from eth.sign)
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) {
      v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
    }
    return ecrecover(operationHash, v, r, s);
  }

  function tryInsertSequenceId(uint sequenceId) onlysigner private {
    // Keep a pointer to the lowest value element in the window
    uint lowestValueIndex = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] == sequenceId) {
        // This sequence ID has been used before. Disallow!
        revert();
      }
      if (recentSequenceIds[i] < recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }
    if (sequenceId < recentSequenceIds[lowestValueIndex]) {
      // The sequence ID being used is lower than the lowest value in the window
      // so we cannot accept it as it may have been used before
      revert();
    }
    if (sequenceId > (recentSequenceIds[lowestValueIndex] + 10000)) {
      // Block sequence IDs which are much higher than the lowest value
      // This prevents people blocking the contract by using very large sequence IDs quickly
      revert();
    }
    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

  function getNextSequenceId() public view returns (uint) {
    uint highestSequenceId = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }

  function isSetted() public view returns (bool) {
    if(storageAddress == address(0)) {
        return false;
    } else {
        return true;
    }
  }
}