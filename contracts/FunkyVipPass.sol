// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract FunkyVipPass is ERC721, Ownable, PaymentSplitter {
  using Strings for uint;
  using Counters for Counters.Counter;

  bool public saleIsActive;
  string public baseURI;
  string public baseExtension;
  uint public price = 0.08 ether;
  uint public maxSupply = 500;
  uint public maxReserveSupply = 50;
  uint public publicSupply;
  uint public reserveSupply;
  Counters.Counter private _tokenId;

  constructor(address[] memory _payees, uint[] memory _shares) 
  ERC721("Funky Vip Pass", "FVS")
  PaymentSplitter(_payees, _shares) {}

  function mintPass() public payable {
    require(saleIsActive, "Sale is not active");
    require(publicSupply <= maxSupply - maxReserveSupply, "Sold out");
    require(balanceOf(msg.sender) == 0, "Max 1 pass per address");
    require(msg.value >= price, "Please send the correct amount of ETH");
    _tokenId.increment();
    _safeMint(msg.sender, _tokenId.current());
    publicSupply++;
  }

  function batchGift(address[] calldata _recipients, uint8[] calldata _alllowances) public onlyOwner {
    for (uint i = 0; i < _recipients.length; i++) {
      require(reserveSupply + _alllowances[i] <= maxReserveSupply, "Max reserve supply exceeded");
      for (uint j = 0; j < _alllowances[i]; j++) {
          _tokenId.increment();
          _safeMint(_recipients[i], _tokenId.current());
      }
      reserveSupply += _alllowances[i];
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  // Payment splitter
  function etherBalanceOf(address _account) public view returns(uint) {
      return (address(this).balance + totalReleased()) * shares(_account) / totalShares() - released(_account);
  }
  
  function release(address payable account) public override onlyOwner {
      super.release(account);
  }
  
  function withdraw() public {
      require(balanceOf(msg.sender) > 0, "No funds to withdraw");
      super.release(payable(msg.sender));
  }
}