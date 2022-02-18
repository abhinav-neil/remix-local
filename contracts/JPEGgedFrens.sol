// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract JPEGgedFrens is ERC721Enumerable, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Sale {
      uint state;
      uint maxSupply;
      uint totalMinted;
      uint maxTokensPerAddress;
      uint price;
  }

  string public baseURI;
  string public baseExtension;
  address public community = 0xD6FF0E9E54C7F430C7356c4586D3E08bc225259A;
  uint public maxPublicSupply = 9000;
  uint public maxReserveSupply = 530;
  Sale public sale;
  Counters.Counter private _tokenId;
  Counters.Counter private _reserveTokenId;
  mapping(address => bool) public isWhitelisted;
  mapping(address => mapping(uint => uint)) public tokensMintedByAddress;
  mapping(uint => uint) public tokensMintedPerWave;

  constructor() ERC721("JPEGged frens", "JF") {}
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function reserveTokensMinted() public view returns(uint) {
    return _reserveTokenId.current();
  }

  function mintFren(uint _mintAmount) public payable {
    require(sale.state != 0, "Sale is not active");
    require(isWhitelisted[msg.sender], "Only whitelisted users allowed");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(tokensMintedByAddress[msg.sender][sale.state] + _mintAmount <= sale.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId.current() + _mintAmount < sale.maxSupply, "Max limit exceeded for this wave");
    require(msg.value >= sale.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
    tokensMintedByAddress[msg.sender][sale.state] += _mintAmount; 
    sale.totalMinted += _mintAmount;
  }

  function gift(address _to, uint _mintAmount) public onlyOwner {
    require(_reserveTokenId.current() + _mintAmount <= maxReserveSupply, "Max reserve supply exceeded");
    for (uint i = 0; i < _mintAmount; i++) {
        _reserveTokenId.increment();
        _safeMint(_to, maxPublicSupply + _reserveTokenId.current());
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

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setSaleDetails(
      uint _state,
      uint _maxSupply, 
      uint _maxTokensPerAddress,
      uint _price
      ) public onlyOwner {
        require(_maxSupply <= maxPublicSupply, "Max public supply exceeded");
          sale.state = _state;
          sale.maxSupply = _maxSupply;
          sale.maxTokensPerAddress = _maxTokensPerAddress;
          sale.price = _price;
  } 

  function whitelist(address[] memory _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
     }
  }
 
  function withdraw() public onlyOwner {
    require(payable(community).send(address(this).balance * 70/100), "Funds transfer failed");
    require(payable(owner()).send(address(this).balance), "Funds transfer failed");
  }
}