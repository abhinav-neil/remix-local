//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MotionMfers is ERC721A, Ownable, PaymentSplitter {
  using Strings for uint;

  string public baseURI;      //make private before mainnet launch?
  string public baseExtension;
  uint public price = 0.0169 ether;
  uint public maxSupply = 4200;
  bool public saleIsActive;

  constructor(address[] memory _payees, uint[] memory _shares) 
  ERC721A("Motion mfers", "mmfers")
  PaymentSplitter(_payees, _shares) {}

  function mint(uint _mintAmount) public payable {
    require(saleIsActive, "Sale is not active");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(totalSupply() + _mintAmount <= maxSupply, "Not enough supply");
    require(msg.value >= price * _mintAmount, "Please send the correct amount of ETH");
    _safeMint(msg.sender, _mintAmount);
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }
 
  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

// Payment splitter

  function etherBalanceOf(address _account) public view returns (uint256) {
        return
            ((address(this).balance + totalReleased()) * shares(_account)) /
            totalShares() -
            released(_account);
    }

    function release(address payable account) public override onlyOwner {
        super.release(account);
    }

    function withdraw() public {
        require(etherBalanceOf(msg.sender) > 0, "No funds to withdraw");
        super.release(payable(msg.sender));
    }
}