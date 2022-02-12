// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CryptoSluts is ERC721Enumerable, Ownable, PaymentSplitter {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Sale {
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
  uint public maxPublicSupply = 10000;
  uint public maxReserveSupply = 530;
  Sale public sale;
  Counters.Counter private _tokenId;
  Counters.Counter private _reserveTokenId;

  mapping(address => bool) public isWhitelistedForPresale;
  mapping(address => bool) public isWhitelistedForAirdrop;

  uint[] private _shares = [10, 10, 10, 20, 50];
  address[] private _team = [
    0x60D406B91cDb2EC8491c18deAc5E2db11a635c82,
    0x2EfC57Cc412F66545F648F10Df85EDf8647d58f6,
    0xD30f5587aB758241263A2Eb63B8C281083ff99F0,
    0x41E0e334efc4fe67D85904Ae51BAA54B3e78322f,
    0xd577E026B4B9901ABEf9d28701C6d469F9F97413
  ];
  
  constructor() 
  ERC721("CryptoSluts", "SLUT")
  PaymentSplitter(_team, _shares) {}

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mintSlut(uint _mintAmount) public payable {
    require(sale.state != 0, "Sale is not active");
    if (sale.state == 1) {
        require(isWhitelistedForPresale[msg.sender], "Only whitelisted users allowed during presale");
    }
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(balanceOf(msg.sender) + _mintAmount <= sale.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId.current() + _mintAmount <= sale.maxSupply, "Max supply exceeded");
    require(msg.value >= sale.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function batchGift(address[] memory _recipients, uint8[] memory _alllowances) public onlyOwner {
    for (uint i = 0; i < _recipients.length; i++) {
        require(_reserveTokenId.current() + _alllowances[i] <= maxReserveSupply, "Max reserve supply exceeded");
        for (uint j = 0; j < _alllowances[i]; j++) {
            _reserveTokenId.increment();
            _safeMint(_recipients[i], maxPublicSupply + _reserveTokenId.current());
        }
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
  
  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
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

  function setSaleDetails(
      uint _state,
      uint _maxSupply,
      uint _maxTokensPerAddress,
      uint _price
      ) public onlyOwner {
          sale.state = _state;
          sale.maxSupply = _maxSupply;
          sale.maxTokensPerAddress = _maxTokensPerAddress;
          sale.price = _price;
  } 
  
  function whitelistForPresale(address[] memory _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelistedForPresale[_users[i]] = true;
      }
  }
  
  function unWhitelistForPresale(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelistedForPresale[_users[i]] = false;
     }
  }

  function setAirdropActive(bool _state) public onlyOwner {
    isAirdropActive = _state;
  }

  function whitelistForAirdrop(address[] memory _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelistedForAirdrop[_users[i]] = true;
      }
  }

  // Payment splitter
  function totalBalance() public view returns(uint) {
        return address(this).balance;
  }
        
  function totalReceived() public view returns(uint) {
      return totalBalance() + totalReleased();
  }
    
  function etherBalanceOf(address _account) public view returns(uint) {
      return totalReceived() * shares(_account) / totalShares() - released(_account);
  }
  
  function release(address payable account) public override onlyOwner {
      super.release(account);
  }
  
  function withdraw() public {
      require(balanceOf(msg.sender) > 0, "No funds to withdraw");
      super.release(payable(msg.sender));
  }
}