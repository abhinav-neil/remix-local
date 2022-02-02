// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DegenToonz is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint;
  using Counters for Counters.Counter;

  bool public revealed;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public price = 0.085 ether;
  uint public maxPresaleSupply = 5000;
  uint public maxPublicSupply = 8738;
  uint public maxSupply = 8888;
  uint public maxTokensPerAddress = 10;
  uint public saleState;        // Sale status, 0 = inactive, 1 = presale, 2 = public sale        
  mapping(address => bool) public isWhitelisted;

  address private _partner = 0x85cbF39AfDB506CF9FA9A8Ea419c6De26C342cF0;
  Counters.Counter private _tokenId;
  uint private _reserveTokenId = maxPublicSupply;

  constructor(
    string memory _notRevealedURI,
    string memory baseURI_
  ) ERC721("DEGEN TOONZ", "TOONZ") {
    setNotRevealedURI(_notRevealedURI);
    setBaseURI(baseURI_);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
    function mintToon(uint _mintAmount) public payable nonReentrant {
    require(saleState != 0, "Sale is not active");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(balanceOf(msg.sender) + _mintAmount <= maxTokensPerAddress, "Max tokens per address limit exceeded");
    if (saleState == 1) {
        require(isWhitelisted[msg.sender], "Only whitelisted users allowed during presale");
        require(_tokenId.current() + _mintAmount <= maxPresaleSupply, "Max presale supply exceeded");
    }
    require(_tokenId.current() + _mintAmount <= maxPublicSupply, "Max public supply exceeded");
    require(msg.value >= price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function gift(address _to, uint _mintAmount) public onlyOwner {
    require(_reserveTokenId + _mintAmount <= maxSupply, "Max reserve supply exceeded");
    for (uint i = 0; i < _mintAmount; i++) {
      _reserveTokenId++;
      _safeMint(_to, _reserveTokenId);
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
    
    if(!revealed) {
        return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setMaxTokensPerAddress(uint _newMaxTokensPerAddress) public onlyOwner() {
    maxTokensPerAddress = _newMaxTokensPerAddress;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setSaleState(uint _state) public onlyOwner {
    saleState = _state;
  }
  
  function whitelist(address[] memory _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
     }
  }
 
  function withdraw() public payable onlyOwner {
    require(payable(_partner).send(address(this).balance * 45/100), "Funds transfer failed");
    require(payable(owner()).send(address(this).balance), "Funds transfer failed");
  }
}