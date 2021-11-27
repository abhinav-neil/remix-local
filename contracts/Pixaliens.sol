// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pixaliens is ERC721Enumerable, Ownable {
  using Strings for uint;

  string public baseURI;
  uint public maxSupply = 10101;
  uint public maxMintAmount = 3;
  uint public maxTokensOfOwner = 10;
  uint public saleState;        // Sale status, 0 = inactive, 1 = presale, 2 = open for all
  uint public reservedForOwner = 1101;
  uint private _reserveSupply;
  uint private _publicSupply;
  address payable private wallet;
  
  mapping(address => bool) public isWhitelisted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address payable _wallet
  ) ERC721(_name, _symbol) {
    baseURI = _initBaseURI;
    wallet = _wallet;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
    
  function mint(uint _mintAmount) public payable {
    require(saleState != 0, 'Sale is not active');
    uint _currentTokenId = reservedForOwner + _publicSupply;
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_currentTokenId + _mintAmount <= maxSupply, 'Not enough supply');
    if (msg.sender != owner()) {
        if(saleState == 1) {
            require(isWhitelisted[msg.sender], 'Only whitelisted users allowed during presale');
        }
        require(_mintAmount <= maxMintAmount, 'You cannot mint more than 10 NFTs at a time');
        require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'You cannot have more than 20 NFTs');
        require(msg.value >= price() * _mintAmount, 'Please send the correct amount of ETH');
    }

    for (uint i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, _currentTokenId + i);
      _publicSupply++;
    }
    (bool success, ) = wallet.call{value: msg.value}("");
    require(success);
  }
  
  function mintReserved(uint _mintAmount) public onlyOwner {
    uint _currentTokenId = _reserveSupply;
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_currentTokenId + _mintAmount <= reservedForOwner, 'Exceeds reserved supply');
    for (uint i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, _currentTokenId + i);
      _reserveSupply++;
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
  
   function price() public view returns (uint) {
        uint _count = totalSupply();
        if (_count <= 1000 ){
            return 0.05 ether;
        } else if (_count <= 1500 ){
            return 0.05505 ether;
        } else if (_count <= 2000 ){
            return 0.06061 ether;
        } else if (_count <= 2500 ){
            return 0.05505 ether;
        } else if (_count <= 3000 ){
            return 0.07347 ether;
        } else if (_count <= 3500 ){
            return 0.08089 ether;
        } else if (_count <= 4000 ){
            return 0.08906 ether;
        } else if (_count <= 4500 ){
            return 0.09806 ether;
        } else if (_count <= 5000 ){
            return 0.10796 ether;
        } else if (_count <= 5500 ){
            return 0.11887 ether;
        } else if (_count <= 6000 ){
            return 0.13087 ether;
        } else if (_count <= 6500 ){
            return 0.14409 ether;
        } else if (_count <= 7000 ){
            return 0.15864 ether;
        } else if (_count <= 7500 ){
            return 0.17466 ether;
        } else if (_count <= 8000 ){
            return 0.19231 ether;
        } else if (_count <= 8500 ){
            return 0.21173 ether;
        } else if (_count <= 9000 ){
            return 0.23311 ether;
        } else if (_count <= 9500 ){
            return 0.25666 ether;
        } else {
            return 0.28258 ether;
        }
        
    }  

  //only owner
  function setMaxMintAmount(uint _newMaxMintAmount) public onlyOwner() {
    maxMintAmount = _newMaxMintAmount;
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

}