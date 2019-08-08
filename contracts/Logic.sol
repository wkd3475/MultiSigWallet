pragma solidity ^0.4.24;

import "./HotDogToken.sol";
import "./ProxyStorage.sol";

contract Logic {
    address public _proxyStorageAddress;

    function etherSendFree(address recipient, uint256 amount) public payable {
        require(recipient != address(0), "wrong recipient address");
        require(msg.value >= amount, "wrong amount");

        recipient.transfer(amount);

        msg.sender.transfer(msg.value - amount);
    }

    //수수료 처리 방법에 대한 고민 필요
    //전송하고 혹시라도 남은 이더리움은 어떻게 처리할지 고민 필요
    //god들에 대한 처리 방법 선정 필요
    function etherSendWithFee(address recipient, uint256 amount, address[] masters, uint256[] feeAmount) public payable {
        require(recipient != address(0), "wrong recipient address");
        require(masters.length == feeAmount.length, "wrong masters' info");
        uint256 totalFee;
        uint8 i;
        for(i = 0; i<feeAmount.length; i++) {
            totalFee += feeAmount[i];
        }
        require(msg.value >= amount + totalFee, "wrong amount");

        recipient.transfer(amount);
        for(i = 0; i<masters.length; i++) {
            masters[i].transfer(feeAmount[i]);
        }
    }

    //전송하고 혹시라도 남은 이더리움은 어떻게 처리할지 고민 필요
    function ERC20Send(address tokenAddress, address recipient, uint256 tokenAmount, address[] masters, uint256[] feeAmount) public payable {
        require(tokenAddress != address(0), "wrong token address");
        require(recipient != address(0), "wrong recipient address");
        require(masters.length == feeAmount.length, "wrong masters' info");
        uint256 balance = ERC20(tokenAddress).balanceOf(msg.sender);
        if(tokenAmount > balance) {
            revert("not enough token balance");
        }
        ERC20(tokenAddress).transferFrom(msg.sender, recipient, tokenAmount);
        uint8 i;
        for(i = 0; i<masters.length; i++) {
            masters[i].transfer(feeAmount[i]);
        }
    }
}