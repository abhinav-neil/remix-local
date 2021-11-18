// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VIPPassV2 is ERC721, ERC721Enumerable, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    // bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    uint public price = 0.1 ether;
    uint public maxSupply = 500;
    uint public maxTokensOfOwner = 10;

    constructor() ERC721("VIPPass", "VPASS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function whitelist(address[] memory _users) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _users.length; i++) {
            grantRole(MINTER_ROLE, _users[i]);
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // function pause() public onlyRole(PAUSER_ROLE) {
    //     _pause();
    // }

    // function unpause() public onlyRole(PAUSER_ROLE) {
    //     _unpause();
    // }

    function mint() public payable onlyRole(MINTER_ROLE) {
        require(msg.value >= price, 'Please send the correct amount of ETH');
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        if(balanceOf(msg.sender) >= maxTokensOfOwner) {
            renounceRole(MINTER_ROLE, msg.sender);
        }
    }
    
    function gift(uint _mintAmount, address _recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_recipient, supply + i);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}