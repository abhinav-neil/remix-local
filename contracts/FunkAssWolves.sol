//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract FunkAssWolves is ERC721A, Ownable, PaymentSplitter {
  using Strings for uint;

  struct SaleConfig {
      uint state;  // 0: closed, 1: presale, 2: public sale
      uint maxSupply;  // presale: 3000, public: 12345
      uint maxTokensPerAddress;
      uint price;
  }

  string public baseURI;  // make private before mainnet launch?
  string public baseExtension;
  uint private _reserved = 550;
  uint private _publicSupply;
  SaleConfig public saleConfig;
  address public vipPass; // (include setter func?)
  mapping(address => bool) public isWhitelisted;
  mapping(uint => bool) public isPassRedeemed;
  uint[] _redeemedPasses;

  constructor(
    address _vipPass,
    address[] memory _payees,
    uint[] memory _shares
  ) 
  ERC721A("FunkAssWolves", "FAW")
  PaymentSplitter(_payees, _shares) {
    vipPass = _vipPass;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function isPassOwner(address _user) public view returns(bool) {
    return IERC721(vipPass).balanceOf(_user) > 0;
  }

  function mintWolves(uint _mintAmount) public payable {
    require(saleConfig.state != 0, "Sale is not active");
    if (saleConfig.state == 1) {
        require(isWhitelisted[msg.sender] || isPassOwner(msg.sender), "Not whitelisted");
    }
    require(_mintAmount > 0 && balanceOf(msg.sender) + _mintAmount <= saleConfig.maxTokensPerAddress, "Invalid mint amount");
    require(_publicSupply + _mintAmount < saleConfig.maxSupply - _reserved, "Max supply exceeded for this phase");
    require(msg.value >= saleConfig.price * _mintAmount, "Not enough ETH");
    _publicSupply += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function redeemPass() public {
      require(saleConfig.state != 0, "Sale is not active");
      require(isPassOwner(msg.sender), "Pass owners only");
      uint _passId = IERC721Enumerable(vipPass).tokenOfOwnerByIndex(msg.sender, 0);
      require(!isPassRedeemed[_passId], "Already redeemed");
      isPassRedeemed[_passId] = true;
      _redeemedPasses.push(_passId);
      _safeMint(msg.sender, 1);
  }

  function batchGift(address[] calldata _recipients, uint8[] calldata _amounts) public onlyOwner {
    for (uint i = 0; i < _recipients.length; i++) {
        uint _mintAmount = _amounts[i];
        _safeMint(_recipients[i], _mintAmount);
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(_baseURI(), tokenId.toString(), baseExtension)): "";
  }

  function getRedeemedPasses() public view returns(uint[] memory) {
    return _redeemedPasses;
  }

  function setBaseURI(string memory baseURI_, string memory _baseExtension) public onlyOwner {
    baseURI = baseURI_;
    baseExtension = _baseExtension;
  }

  function setSaleConfig(
      uint _state,
      uint _maxSupply, 
      uint _maxTokensPerAddress,
      uint _price
      ) public onlyOwner {
          saleConfig.state = _state;
          saleConfig.maxSupply = _maxSupply;
          saleConfig.maxTokensPerAddress = _maxTokensPerAddress;
          saleConfig.price = _price;
  } 

  function whitelist(address[] calldata _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] calldata _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
     }
  }

// Payment splitter
  function etherBalanceOf(address _account) public view returns (uint256) {
    return
        ((address(this).balance + totalReleased()) * shares(_account)) /
        totalShares() -
        released(_account);
  }

  function release(address payable account) public override onlyOwner {
      super.release(account);
  }

  function withdraw() public {
      require(etherBalanceOf(msg.sender) > 0, "No funds to withdraw");
      super.release(payable(msg.sender));
  }
}