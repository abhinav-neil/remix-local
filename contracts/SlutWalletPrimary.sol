// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SlutWalletPrimary is PaymentSplitter, Ownable {
    
    string public name;
    address public ThePimp;
    address public TheMamaSan;
    address public TheBodyGuard;
    address public TheGang;
    address public SlutFund;

    constructor (
        string memory _name,
        address[] memory _payees, 
        uint256[] memory _shares) 
        PaymentSplitter(_payees, _shares) payable {
            require(_payees.length == 5, 'Enter 5 receiver addresses');
            name = _name;
            ThePimp = _payees[0];
            TheBodyGuard = _payees[1];
            TheMamaSan = _payees[2];
            TheGang = _payees[3];
            SlutFund = _payees[4];
        }
        
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
        require(balanceOf(msg.sender) > 0, 'No funds to withdraw');
        super.release(payable(msg.sender));
    }
    
}