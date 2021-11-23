// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  string public baseURI;
  uint public price = 0.02 ether;
  uint public maxSupply = 10000;
  uint public maxMintAmount = 3;
  uint public maxTokensOfOwner = 10;
  bool public saleIsActive;
  uint public saleState;        // Sale status, 0 = inactive, 1 = presale, 2 = open for all
  
  mapping(address => bool) public isWhitelisted;
  
  Counters.Counter private _tokenId;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint _mintAmount) public payable {
    require(saleIsActive, 'Sale is not active');
    require(_mintAmount > 0, 'You must mint at least 1 NFT');
    require(_mintAmount <= maxMintAmount, 'You cannot mint more than 3 NFTs at a time');
    require(_tokenId.current() + _mintAmount < maxSupply, 'Not enough supply');
    require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'You cannot have more than 10 NFTs');
    if (msg.sender != owner()) {
        if(saleState == 1) {
            require(isWhitelisted[msg.sender], 'Only whitelisted users allowed during presale');
        }
        require(_mintAmount <= maxMintAmount, 'You cannot mint more than 10 NFTs at a time');
        require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'You cannot have more than 20 NFTs');
        require(msg.value >= price * _mintAmount, 'Please send the correct amount of ETH');
    }
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint[] memory)
  {
    uint ownerTokenCount = balanceOf(_owner);
    uint[] memory tokenIds = new uint[](ownerTokenCount);
    for (uint i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setmaxMintAmount(uint _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setSaleState(uint _state) public onlyOwner {
    saleState = _state;
  }
  
  function whitelist(address[] memory _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          require(!isWhitelisted[_users[i]], 'already whitelisted');
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          require(isWhitelisted[_users[i]], 'not whitelisted');
          isWhitelisted[_users[i]] = false;
     }
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(success);
  }
}