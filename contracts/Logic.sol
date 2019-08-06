pragma solidity ^0.4.24;

import "./HotDogToken.sol";
import "./ProxyStorage.sol";

contract Logic {
    address public _proxyStorageAddress;

    function etherSendFree(address recipient, uint256 amount) public payable {
        require(recipient != address(0), "wrong recipient address");
        require(msg.value >= amount, "wrong amount");

        recipient.transfer(amount);
    }

    //수수료 처리 방법에 대한 고민 필요
    function etherSendWithFee(address recipient, uint256 amount, address[] gods, uint256[] feeAmount) public payable {
        require(recipient != address(0), "wrong recipient address");
        require(gods.length == feeAmount.length, "wrong gods' info");
        require(msg.value >= amount, "wrong amount");

        recipient.transfer(amount);
        for(uint256 i=0; i<gods.length; i++) {
            gods[i].transfer(feeAmount[i]);
        }
    }

    function ERC20Send(address tokenAddress, address recipient, uint256 tokenAmount, address[] gods, uint256[] feeAmount) public payable {
        require(tokenAddress != address(0), "wrong token address");
        require(recipient != address(0), "wrong recipient address");
        require(gods.length == feeAmount.length, "wrong gods' info");
        uint256 balance = ERC20(tokenAddress).balanceOf(msg.sender);
        if(tokenAmount > balance) {
            return;
        }
        ERC20(tokenAddress).transferFrom(msg.sender, recipient, tokenAmount);
        for(uint256 i=0; i<gods.length; i++) {
            gods[i].transfer(feeAmount[i]);
        }
    }
}