// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ToonzRoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name = "Toonz Royalties Wallet";
    uint[] private _shares = [60, 20, 20];
    address[] private _payees = [
        0x3898916E006aD1bb9dD739a789032Bd3CD27E992,
        0x7E4eFb7000285fD19Aaab081D0938cAad6D63248,
        0x6e041991037b7e2ec3B157442441a2f3354a008B
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