// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SlutRoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name = "Slut Royalties Wallet";
    uint[] private _shares = [2, 1, 2, 1];
    address[] private _team = [
        0x60D406B91cDb2EC8491c18deAc5E2db11a635c82,
        0x2EfC57Cc412F66545F648F10Df85EDf8647d58f6,
        0xD30f5587aB758241263A2Eb63B8C281083ff99F0,
        0xd577E026B4B9901ABEf9d28701C6d469F9F97413
    ];

    constructor () PaymentSplitter(_team, _shares) payable {}
        
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