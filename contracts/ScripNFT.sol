// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract ScripNFT is ERC721Enumerable, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  string public baseURI;
  uint public price = 0.1 ether;
  uint public maxSupply = 1000;
  uint public maxMintAmount = 3;
  uint public maxTokensOfOwner = 10;
  bool public saleIsActive;
  uint public reservedForFounders = 100;
  uint private _reserveSupply;
  uint private _publicSupply;
  mapping(address => bool) public isFounder;

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
  uint _currentTokenId = reservedForFounders + _publicSupply;
  require(_mintAmount > 0, "You must mint at least 1 NFT");
  require(_currentTokenId + _mintAmount <= maxSupply, 'Not enough supply');
  if (msg.sender != owner()) {
      require(_mintAmount <= maxMintAmount, 'Max mint amount limit exceeded');
      require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'Max tokens per address limit exceeded');
      require(msg.value >= price * _mintAmount, 'Please send the correct amount of ETH');
  }

  for (uint i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, _currentTokenId + i);
  }
  _publicSupply += _mintAmount;
  }

  function mintReserved(uint _mintAmount) public {
  uint _currentTokenId = _reserveSupply;
  require(isFounder[msg.sender], 'Access restricted to founders only');
  require(_mintAmount > 0, "You must mint at least 1 NFT");
  require(_currentTokenId + _mintAmount <= reservedForFounders, 'Exceeds reserved supply');
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

  function setMaxSupply(uint _newMaxSupply) public onlyOwner() {
    maxSupply = _newMaxSupply;
  }

  function setmaxMintAmount(uint _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setFounders(address[] memory _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          require(!isFounder[_users[i]], 'already listed');
          isFounder[_users[i]] = true;
      }
  } 
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(success);
  }
}