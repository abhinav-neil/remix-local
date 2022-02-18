// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CryptoSluts is ERC721Enumerable, Ownable, PaymentSplitter {
  using Strings for uint;

  struct SaleConfig {
      uint state; 
      uint maxSupply;
      uint maxTokensPerAddress;
      uint price;
  }
  
  bool public revealed;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public reserveSupply;
  uint public maxReserveSupply = 412; //412 reserved NFTs
  uint public maxSupply = 10460;
  uint private _tokenId = maxReserveSupply;
  SaleConfig public saleConfig;
  mapping(address => bool) public isWhitelisted;
  
  constructor(address[] memory _team, uint[] memory _shares)
  ERC721("CryptoSluts", "SLUT")
  PaymentSplitter(_team, _shares) {}

  function mint(uint _mintAmount) public payable {
    require(saleConfig.state != 0, "Sale is not active");
    if (saleConfig.state == 1) {
        require(isWhitelisted[msg.sender], "Only whitelisted users allowed during presale");
    }
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(balanceOf(msg.sender) + _mintAmount <= saleConfig.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId + _mintAmount <= saleConfig.maxSupply, "Max supply exceeded");
    require(msg.value >= saleConfig.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _safeMint(msg.sender, ++_tokenId);
    }
  }

  function gift(address _to, uint[] memory _tokenIds) public onlyOwner {
    uint _numTokens = _tokenIds.length;
    require(reserveSupply + _numTokens <= maxReserveSupply, "Max reserve supply exceeded");
    for (uint i = 0; i < _numTokens; i++) {
        require(_tokenIds[i] <= maxReserveSupply, "Cannot gift from outside reseve")
        _safeMint(_to, _tokenIds[i]);
    }
    reserveSupply += _numTokens;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!revealed) {
        return notRevealedURI;
    }
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function walletOfOwner(address _owner) public view returns (uint[] memory) {
    uint ownerTokenCount = balanceOf(_owner);
    uint[] memory tokenIds = new uint[](ownerTokenCount);
    for (uint i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

  function setSaleConfig(
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
  
  function whitelist(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] calldata _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
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