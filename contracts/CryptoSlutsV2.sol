// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoSlutsV2 is ERC721Enumerable, Ownable {
  using Strings for uint;

  address private primaryWallet;
  address public airdropExec;
  string public baseURI;
  string public baseExtension = '.json';
  uint public startingIndex = 560; // reserve 100 for gang, 9 for founders, 150 + 150 + 150 for airdrops
  uint public maxSupply = 10000;
  uint public maxMintAmount = 10;
  uint public maxTokensOfOwner = 20;
  uint public saleState;        // Sale status, 0 = inactive, 1 = presale, 2 = open for all 
  string public hiddenURI;
  bool public revealed;
  mapping(address => bool) public isWhitelisted;
  //airdrop
//   struct Airdrop {
//       bool _state;
//       uint _startingTokenId;
//       uint _maxSupply;
//       uint _price;
//       mapping(address => bool) isWhitelistedForAirdrop;
//   }
//   bool public airdropIsActive;

  constructor(
    address payable _primaryWallet,
    address _airdropExec,
    string memory _name,
    string memory _symbol,
    string memory _hiddenURI,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
      primaryWallet = _primaryWallet;
      airdropExec = _airdropExec;
      baseURI = _initBaseURI;
      hiddenURI = _hiddenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function price() public view returns(uint) {
      if(saleState == 1) {
          return 0.1 ether;
      }
      else if(saleState == 2) {
          return 0.25 ether;
      }
  }

  function mint(uint _mintAmount) public payable {
    uint supply = startingIndex + totalSupply();
    require(saleState != 0, 'Sale is not active');
    if (saleState == 1) {
        require(isWhitelisted[msg.sender], 'Only whitelisted users allowed during presale');
    } 
    require(_mintAmount > 0, 'You must mint at least 1 NFT');
    require(_mintAmount <= maxMintAmount, 'You cannot mint more than 10 NFTs at a time');
    require(supply + _mintAmount <= maxSupply, 'Not enough supply');
    require(balanceOf(msg.sender) + _mintAmount <= maxTokensOfOwner, 'You cannot have more than 20 NFTs');
    require(msg.value >= price() * _mintAmount, 'Please send the correct amount of ETH');
    for (uint i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
    (bool success, ) = primaryWallet.call{value: msg.value}("");
    require(success);
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
        return hiddenURI;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setStartingIndex(uint _newStartingIndex) public onlyOwner() {
    startingIndex = _newStartingIndex;
  }

  function setMaxMintAmount(uint _newMaxMintAmount) public onlyOwner() {
    maxMintAmount = _newMaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setSaleState(uint _state) public onlyOwner {
    saleState = _state;
  }
  
  function setAirdropExec(address _newAirdropExec) public onlyOwner {
    airdropExec = _newAirdropExec;
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
  
  //airdrop
//   function whitelistForAirdrop(address[] memory _users) public onlyOwner {
//       for(uint i = 0; i < _users.length; i++) {
//           require(!isWhitelistedForAirdrop[_users[i]], 'already whitelisted');
//           isWhitelistedForAirdrop[_users[i]] = true;
//       }
//   }
  
//   function startAirdrop(uint _startingTokenId, uint _maxSupply, uint _price) public onlyOwner {
//       Airdrop storage airdrop = new Airdrop(true, _startingTokenId, _maxSupply, _price);
//   }

  function claimAirdrop(address _user, uint _tokenId) external {
    require(msg.sender == airdropExec, 'not authorized');
    // require(airdropIsActive, 'Airdrop is not active');
    // require(isWhitelistedForAirdrop[msg.sender], 'You are not listed for airdrops');
    // require(airdropTokenId <= maxAirdropTokenId, 'Airdrop has ended');
    _safeMint(_user, _tokenId);
    // airdropTokenId++;
    // isWhitelistedForAirdrop[msg.sender] = false;
  }
  
//   function setAirdropId(uint _startingTokenId, uint _maxTokenId) public onlyOwner {
//       airdropTokenId = _startingTokenId;
//       maxAirdropTokenId = _maxTokenId;
//   }
    
//   function flipAirdropState() public onlyOwner {
//     airdropIsActive = !airdropIsActive;
//   }
  
}