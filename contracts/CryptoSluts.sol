// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CryptoSluts is ERC721, Ownable, PaymentSplitter {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct SaleConfig {
      uint state; 
      uint maxSupply;
      uint maxTokensPerAddress;
      uint price;
  }
  
  bool public revealed;
  bool public isAirdropActive;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public maxSupply = 10460;
  Counters.Counter private _tokenId;
  uint private _reserveTokenId = 10049; // 412 reserved NFTs
  SaleConfig public saleConfig;

  mapping(address => bool) public isWhitelistedForPresale;
  mapping(address => bool) public isWhitelistedForAirdrop;
  
  constructor(address[] memory _team, uint[] memory _shares)
  ERC721("CryptoSluts", "SLUT")
  PaymentSplitter(_team, _shares) {}

  function mint(uint _mintAmount) public payable {
    require(saleConfig.state != 0, "Sale is not active");
    if (saleConfig.state == 1) {
        require(isWhitelistedForPresale[msg.sender], "Only whitelisted users allowed during presale");
    }
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(balanceOf(msg.sender) + _mintAmount <= saleConfig.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId.current() + _mintAmount <= saleConfig.maxSupply, "Max supply exceeded");
    require(msg.value >= saleConfig.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function batchGift(address[] calldata _recipients, uint8[] calldata _alllowances) public onlyOwner {
    for (uint i = 0; i < _recipients.length; i++) {
        require(_reserveTokenId + _alllowances[i] <= maxSupply, "Max reserve supply exceeded");
        for (uint j = 0; j < _alllowances[i]; ++j) {
            _safeMint(_recipients[i], _reserveTokenId + j);
        }
        _reserveTokenId += _alllowances[i];
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!revealed) {
        return notRevealedURI;
    }
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function totalSupply() public view returns(uint) {
    return _tokenId.current();
  }
  
  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function setSaleDetails(
      uint _state,
      uint _maxSupply,
      uint _maxTokensPerAddress,
      uint _price
      ) public onlyOwner {
          saleConfig.state = _state;
          saleConfig.maxSupply = _maxSupply;
          saleConfig.maxTokensPerAddress = _maxTokensPerAddress;
          saleConfig.price = _price;
  } 
  
  function whitelistForPresale(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelistedForPresale[_users[i]] = true;
      }
  }
  
  function unWhitelistForPresale(address[] calldata _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelistedForPresale[_users[i]] = false;
     }
  }

  function setAirdropActive(bool _state) public onlyOwner {
    isAirdropActive = _state;
  }

  function whitelistForAirdrop(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelistedForAirdrop[_users[i]] = true;
      }
  }

  // Payment splitter
  function etherBalanceOf(address _account) public view returns(uint) {
      return (address(this).balance + totalReleased()) * shares(_account) / totalShares() - released(_account);
  }
  
  function release(address payable account) public override onlyOwner {
      super.release(account);
  }
  
  function withdraw() public {
      require(etherBalanceOf(msg.sender) > 0, "No funds to withdraw");
      super.release(payable(msg.sender));
  }
}