// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint;

  string public baseURI;
  uint public price = 0.02 ether;
  uint public maxSupply = 1000;
  uint public maxMintAmount = 3;
  uint public maxPresaleMintAmount = 1;
  uint public maxTokensOfOwner = 10;
  uint public reservedForOwner = 5;
  uint private _reserveSupply;
  uint private _publicSupply;
  uint public saleState;        // Sale status, 0 = inactive, 1 = presale, 2 = open for all
  
  mapping(address => bool) public isWhitelisted;

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
    require(saleState != 0, 'Sale is not active');
    uint _currentTokenId = reservedForOwner + _publicSupply;
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_currentTokenId + _mintAmount <= maxSupply, 'Not enough supply');
    if (msg.sender != owner()) {
        require(_mintAmount <= maxMintAmount, 'Max amount per mint exceeded');
        require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'Max token limit per address exceeded');
        require(msg.value >= price * _mintAmount, 'Please send the correct amount of ETH');
        if(saleState == 1) {
            require(isWhitelisted[msg.sender], 'Only whitelisted users allowed during presale');
            require(_mintAmount <= maxPresaleMintAmount, 'Max presale mint limit exceeded');
            isWhitelisted[msg.sender] = false;
        }
    }
    for (uint i = 1; i <= _mintAmount; i++) {
        _safeMint(msg.sender, _currentTokenId + i);
    }
    _publicSupply += _mintAmount;
  }

  function mintReserved(uint _mintAmount) public onlyOwner {
    uint _currentTokenId = _reserveSupply;
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_currentTokenId + _mintAmount <= reservedForOwner, 'Exceeds reserved supply');
    for (uint i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, _currentTokenId + i);
    } 
    _reserveSupply += _mintAmount;
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

  function setmaxPresaleMintAmount(uint _newmaxPresaleMintAmount) public onlyOwner() {
    maxPresaleMintAmount = _newmaxPresaleMintAmount;
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