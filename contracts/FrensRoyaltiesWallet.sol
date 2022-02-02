// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FrensRoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name = "Frens Royalties Wallet";
    uint[] private _shares = [20, 80];
    address[] private _payees = [
        0x2017fFe2B5cE7c4726f95B62807305aeB6527E2D,
        0xD6FF0E9E54C7F430C7356c4586D3E08bc225259A,
    ];

    constructor () PaymentSplitter(_payees, _shares) payable {}
        
    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
        
    function totalReceived() public view returns(uint) {
        return totalBalance() + totalReleased();
    }
    
    function balanceOf(address _account) public view returns(uint) {
        return totalReceived() * shares(_account) / totalShares() - released(_account);
    }
    
    function release(address payable account) public override onlyOwner {
        super.release(account);
    }
    
    function withdraw() public {
        require(balanceOf(msg.sender) > 0, "No funds to withdraw");
        super.release(payable(msg.sender));
    }
    
}