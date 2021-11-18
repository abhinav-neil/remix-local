// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VIPPass is ERC721Enumerable, ERC721Burnable, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  string public baseURI;
  string public baseExtension = '';
  uint public price = 0.1 ether;
  uint public maxTokensOfOwner = 10;
  uint public maxSupply = 500;
  uint public maxPublicSupply = 180;
  bool public saleIsActive; 
  mapping(address => bool) public isWhitelisted;
  Counters.Counter private _tokenId;
  Counters.Counter private _publicSupply;  
  
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    baseURI = _initBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint() public payable {
    require(saleIsActive, 'Sale is not active');
    require(isWhitelisted[msg.sender], 'Whitelisted users only');
    require(_tokenId.current() < maxSupply, 'Not enough supply');
    require(_publicSupply.current() < maxPublicSupply, 'Public sale has ended');
    require(balanceOf(msg.sender) < maxTokensOfOwner, 'You cannot have more than 10 passes');
    require(msg.value >= price, 'Please send the correct amount of ETH');
    _tokenId.increment();
    _safeMint(msg.sender, _tokenId.current());
    _publicSupply.increment();
  }
  
  function gift(uint _mintAmount, address _recipient) public onlyOwner {
    require(_mintAmount > 0, 'You need to mint at least 1 pass');
    require(_tokenId.current() + _mintAmount < maxSupply, 'max passes limit exceeded');
    if(_recipient != owner()) {
        require(balanceOf(_recipient) + _mintAmount < maxTokensOfOwner, 'Cannot have more than 10 passes');
    }
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(_recipient, _tokenId.current());
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

  function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
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
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }
  
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
  }  
  
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}  