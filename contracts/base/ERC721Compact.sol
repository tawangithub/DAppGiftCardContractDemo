// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract ERC721Compact {
    string public name;
    string public symbol;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) internal _approvals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    function _mint(address to, uint256 tokenId, string memory tokenURI) internal {
        require(_ownerOf[tokenId] == address(0), "Already minted");
        _ownerOf[tokenId] = to;
        _balanceOf[to]++;
        _tokenURIs[tokenId] = tokenURI;
        emit Transfer(address(0), to, tokenId);
    }
    mapping(uint256 => string) internal _tokenURIs;

    function balanceOf(address owner) public view virtual returns (uint256) {
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        // require(_ownerOf[tokenId] != address(0), "Token does not exist");
        return _ownerOf[tokenId];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(from == _ownerOf[tokenId] || _approvals[tokenId] == msg.sender, "Not the owner");
        // require(to != address(0), "Invalid address");
        _ownerOf[tokenId] = to;
        _approvals[tokenId] = address(0); // disapprove the card after transfer
        _balanceOf[from]--;
        _balanceOf[to]++;
    }

    function approve(address to, uint256 tokenId) public virtual {  
        // require(to != address(0), "Invalid address");
        _approvals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        // require(_ownerOf[tokenId] != address(0), "Token does not exist");
        return _approvals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        // require(operator != address(0), "Invalid address");
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURIs[tokenId];
    }
}