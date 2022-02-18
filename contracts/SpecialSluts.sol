// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SpecialSluts is ERC721Enumerable, Ownable, PaymentSplitter {
  using Strings for uint;
  using Counters for Counters.Counter;

  bool public revealed;
  bool public isAirdropActive;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public price = 0.25 ether;
  uint public maxSupply = 500;
  uint public maxTokensPerAddress = 2;
  bool public saleIsActive;
  Counters.Counter private _tokenId;
  mapping(address => bool) public isWhitelistedForAirdrop;
  address cryptosluts = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

  constructor(address[] memory _team, uint[] memory _shares)
  ERC721("SpecialSluts", "SSLUT")
  PaymentSplitter(_team, _shares) {}

  function mint(uint _mintAmount) public payable {
    require(saleIsActive, "Sale is not active");
    require(IERC721(cryptosluts).balanceOf(msg.sender) > 0, "Slut owners only");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_tokenId.current() + _mintAmount <= maxSupply, "Not enough supply");
    require(balanceOf(msg.sender) + _mintAmount <= maxTokensPerAddress, "Max tokens per address limit exceeded");
    require(msg.value >= price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function claimAirdrop() public {
    require(isAirdropActive, "Airdrop is inactive");  
    require(isWhitelistedForAirdrop[msg.sender], "You have no airdrops to claim");
    require(_tokenId.current() < maxSupply, "Max supply exceeded");
    _tokenId.increment();
    _safeMint(msg.sender, _tokenId.current());
    isWhitelistedForAirdrop[msg.sender] = false;
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

  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setAirdropActive(bool _state) public onlyOwner {
    isAirdropActive = _state;
  }

  function whitelistForAirdrop(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelistedForAirdrop[_users[i]] = true;
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